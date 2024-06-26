; High Level Code Overview
; 1. Verify that we are in the shop menu
; 2. Validate its the right type of shop
; 3. Determine the item type
; 4. Use it to initialize the correct starting memory address
; 5. Get the attack/def stat for the item and store it in memory
; 6. loop through all characters
;   Get the item id at HeroStatPointer
;   Get atk/def stat for this characters item
;   Compare, and set visual to proper one
;   Keep going until done

hirom

bank $7E
dpbase $0000
optimize dp always
optimize address mirrors

incsrc "macros.asm"

; ====== Table Starting Pointers ======
ItemDataStart = $D10000
ShopDataStart = $D12D40

; ====== Game RAM Addresses ======
ShopCursorIdx = $155
ShopIdx = $135

; ====== Our RAM Addresses
HeroStatPointer = $90 ; 2 byte
ShopAtkDef = $92    ; 1 byte
ShopItemFirstByte = $93
TmpWorking = $94    ; Two byte


; ====== Starting RAM Item locations ======
;LeftHandShield = #$511
;RightHandShield = #$512
;LeftHandWeapon = #$513
;RightHandWeapon = #$514
;HelmItem = #$50E
;BodyItem = #$50F
;RelicItem = #$510

; Assumptions:
;   * Always in 8-bit mode unless we need to switch to 16 bit
;   * When function starts we are axy16,

org $C2EF1F          ; STZ $F1
JSL BetterShop      ; STZ $7E

org $CFDC00
BetterShop:
    PHA
    PHX
    PHY
    PHP
    %axy8()

; Validate against RAM that we're in the right menu screen
IsShopMenu:
    LDA $134            ; Quit early if we're not in a shop
    CMP #$02            
    BEQ IsShopTypeEquipment
    JMP return

; Validate that the shop type is weapons or equipment
IsShopTypeEquipment:
    JSL GetShopType
    AND #$0F
    CMP #$01
    BEQ +
    CMP #$02
    BEQ +
    JMP return
+

; Store item atk/def aka byte 7 of item data
    JSL GetShopItemId
    LDY #$07
    JSL GetItemByte
    STA ShopAtkDef

; Store item type
    JSL GetShopItemId
    LDY #$00
    JSL GetItemByte
    
; Switch statement to set initial RAM location for character stats
    TAY
    %a16()
    CPY #$01
    BEQ relicDefense
    CPY #$02
    BEQ armorDefense
    CPY #$04
    BEQ helmDefense

weaponAttack:
    LDA #$513
    BRA storeStat

helmDefense:
    LDA #$50E
    BRA storeStat

armorDefense:
    LDA #$50F
    BRA storeStat

relicDefense:
    LDA #$510
    BRA storeStat

; Prepare registers for character loop
storeStat:
    STA HeroStatPointer ; a16() here
    LDA #$0000
    LDX #$00
    %axy8()

loop:
; Get current characters stat and compare
    LDA (HeroStatPointer)
    CMP #$00                
    BEQ CompareRightHand    ; Left hand is empty, empty equipment is $80
    LDY #$07
    JSL GetItemByte
    CMP ShopAtkDef
    BEQ CurrEqual
    BCC BetterOption
    BRA WorseOption         ; TODO: need to actually check if we can equip 2 weapons here

; IF (lefthand is non-zero and worse AND we can dual wield) OR lefthand is zero
; THEN compare right hand as well
; TODO: try reduce code duplication here
; TODO: get this working for left and right hand shields too
CompareRightHand:
    LDY #$01
    LDA (HeroStatPointer), Y
    LDY #$07
    JSL GetItemByte
    CMP ShopAtkDef
    BEQ CurrEqual
    BCC BetterOption

WorseOption:              ; Draw character crouched
    LDA $242,X
    CLC
    ADC #$04
    STA $242,X
    LDA $246,X
    CLC
    ADC #$04
    STA $246,X
    BRA end

BetterOption:             ; Draw character with arms up
    LDA $242,X
    INC
    INC
    STA $242,X
    BRA end

CurrEqual:                 ; Dont modify visual if its the same
    BRA end

; Each character is $50 bytes of data, so increment by that to get next character
end:
    %a16()
    LDA HeroStatPointer
    CLC
    ADC #$0050
    STA HeroStatPointer
    AND #$00FF              ; Clear high byte so next mult works for item
    %a8()
    TXA
    CLC
    ADC #$08
    TAX
    CPX #$20                ; Breakpoint, i.e 4 iterations
    BNE loop

return:
    %a16()            ; X,Y are 8bit mode
    PLP
    PLY
    PLX
    %xy8()            ; A is 16bit mode
    PLA
    STZ $F1 ;; Native code
    STZ $7E
RTL

org $CFDE00

; GetItemByte gets the Yth byte of data from an 
; Keeps current state of X
GetItemByte:
    PHX
    JSR Mult12 ; A in 16bit
    %xy16()
    STY TmpWorking
    CLC
    ADC TmpWorking
    TAX
    LDA ItemDataStart, X
    AND #$00FF
    %axy8()
    PLX
    RTL

; GetShopType sets A to first byte of shop data
; Doesn't modify 8/16bit
GetShopType:
    LDA ShopIdx
    JSR Mult9
    TAX
    %a8()
    LDA ShopDataStart, X
    RTL

; GetShopItemId sets A to the item id based on the current cursors index
; Doesn't modify 8/16bit
GetShopItemId:
    LDA ShopIdx
    JSR Mult9
    %a8()
    CLC
    ADC ShopCursorIdx   ; TODO: does this add in 8bit mode screw up anything?
    TAX
    LDA $D12D40, X
    RTL

; Multiplies an 8-bit value in A by 9 and keeps it in A
; Doesn't modify 8/16bit
Mult9:
    STA $2A
    %a16()
    ASL
    ASL
    ASL
    %a8()
    ADC $2A
    RTS

; Multiplies an 8-bit value in A by 12 and keeps it in A
; Sets A to 16-bit
Mult12:
    %a16()
    ASL
    ASL         ; x4
    STA $002A     
    ASL         ; x8
    ADC $002A     ; x(8+4)
    RTS 
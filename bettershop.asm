hirom

NIDISP     = $2100     ; inital settings for screen
OBJSEL      = $2101     ; object size $ object data area designation
OAMADDL     = $2102     ; address for accessing OAM
OAMADDH     = $2103
OAMDATA     = $2104     ; data for OAM write
VMAINC      = $2115     ; VRAM address increment value designation
VMADDL      = $2116     ; address for VRAM read and write
VMADDH      = $2117
VMDATAL     = $2118     ; data for VRAM write
VMDATAH     = $2119     ; data for VRAM write
CGADD       = $2121     ; address for CGRAM read and write
CGDATA      = $2122     ; data for CGRAM write
TM          = $212c     ; main screen designation
NMITIMEN    = $4200     ; enable flaog for v-blank
RDNMI       = $4210     ; read the NMI flag status

;FF5 C2 bank sets DBR to $7E and D to $0000
bank $7E
dpbase $0000
optimize dp always
optimize address mirrors

StatPointer = $60
OAMPointer = $62
YValue = $63

ItemDataStart = $D10000
ShopDataStart = $D12D40

; Already existing memory
ShopCursorIdx = $155
ShopID = $135
CurrAttack = $544
NewAttack = $1F

incsrc "macros.asm"

;org $C2EF59         ; LDA $240,Y ; SEC
;JSL CheckBetter     ; SBC #$000C

org $C2EF1F          ; STZ $F1
JSL CheckBetter      ; STZ $7E

org $CFDC00
CheckBetter: 
; All of this is done once
    PHA
    PHX
    PHY
    PHP
    %axy8() ; 8bit mode
    LDA $134            ; Quit early if we're not in a shop
    CMP #$02            ; This feels like a hack until i know where to hook in
    BNE end
    JSL GetShopType
    AND #$0F
    CMP #$01
    BNE end
    CLC
    TXA
    ADC ShopCursorIdx    ; 9*shopId + cursorIdx
    TAX
    LDA $D12D40, X      ; Index into shop data

    ;STA $2A              ; 12 * itemID + 7 for attack
    ;LDA $12A             ; Item id
    %axy16()              ; 16-bit
    JSR Mult12
    ADC #$0007
    TAX
    LDA #$544           ; Setup attack pointer
    STA $0160 
    %a8()        
    LDA $D10000, X
    %axy8()       
    STA NewAttack       ; Store the new attack power
    LDY #$00
    LDA #$47
    STA YValue
    LDX #$00


; Need to check against each party member
; X = OAM offset

loop:
    ;LDA $240            ; Make sure we can equip TODO: read this better
    ;CMP #$E2            
    ;BEQ CantEquip

    LDA (StatPointer)         ; Get current atk in left hand
    ;AND #$00FF
    CMP NewAttack      ; Compare against current
    BCC CurrBetter
    ;BEQ CurrEqual

    BCC CurrBetter
    BEQ CurrEqual

CurrWorse:              ; Draw character crouched
    LDA $242,X
    CLC
    ADC #$04
    STA $242,X
    LDA $246,X
    CLC
    ADC #$04
    STA $246,X
    BRA end

CurrEqual:
    BRA end

CurrBetter:             ; Draw character with arms up
    LDA $242,X
    INC
    INC
    STA $242,X
    BRA end

end:
    %a16()
    LDA StatPointer
    CLC
    ADC #$0050
    STA StatPointer
    %a8()
    TXA
    CLC
    ADC #$08
    TAX
    CPX #$20
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

CantEquip:
    LDA $00
    STA $20C,X
    STA $20D,X
    STA $20E,X
    STA $20F,X
    BRA end

Mult12:
    ASL
    ASL         ; x4
    STA $002A     
    ASL         ; x8
    ADC $002A     ; x(8+4)
    RTS 

org $0FDE00
GetShopType:
    LDA $135            ; ShopId
    %a16()
    JSR Mult9
    TAX
    %a8()
    LDA ShopDataStart,X        ; Get the type of shop
    RTL

; Sets A to itemId
GetItemId:
    LDA ShopID
    JSR Mult9
    CLC
    ADC ShopCursorIdx
    TAX
    LDA $D12D40, X
    RTL

Mult9:
    STA $002A
    ASL
    ASL
    ASL
    ADC $002A
    RTS


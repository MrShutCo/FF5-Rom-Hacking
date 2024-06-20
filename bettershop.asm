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

AttackPointer = $60
OAMPointer = $62
YValue = $63

; Already existing memory
ShopCursorIdx = $155
ShopID = $135
CurrAttack = $544
NewAttack = $1F

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
    SEP #$30 ; 8bit mode
    LDA $134            ; Quit early if we're not in a shop
    CMP #$02            ; This feels like a hack until i know where to hook in
    BNE end
    LDA $135            ; ShopId
    ;REP #$30       ; 16bit
    JSR Mult9
    ;SEP #$30
    TAX
    LDA $D12D40,X        ; Get the type of shop
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
    REP #$30              ; 16-bit
    JSR Mult12
    ADC #$0007
    TAX
    LDA #$544           ; Setup attack pointer
    STA $0160 
    SEP #$20        
    LDA $D10000, X
    SEP #$30       
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

    LDA (AttackPointer)         ; Get current atk in left hand
    ;AND #$00FF
    CMP NewAttack      ; Compare against current
    BCC CurrBetter
    ;BEQ CurrEqual

CurrWorse:
    ; Do something
    LDA #$D0
    STA $20C,X
    LDA YValue
    STA $20D,X
    LDA #$02
    STA $20E,X
    LDA #$28
    STA $20F,X
    BRA end

CurrEqual:
    ; Do something
    ;BRA end

CurrBetter:
    ; Draw cursor if its better
    LDA #$D0
    STA $20C,X
    LDA YValue
    STA $20D,X
    LDA #$02
    STA $20E,X
    LDA #$2A
    STA $20F,X

end:
    REP #$20
    LDA AttackPointer
    CLC
    ADC #$0050
    STA AttackPointer
    SEP #$20
    LDA YValue          ; Increase cursor position
    CLC
    ADC #$1C
    STA YValue
    INX                 ; OAM offset
    INX
    INX
    INX
    CPX #$10
    BNE loop
    REP #$20            ; X,Y are 8bit mode
    PLP
    PLY
    PLX
    SEP #$10            ; A is 16bit mode
    PLA
    
    ;LDA $240,Y
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

Mult9:
    STA $002A
    ASL
    ASL
    ASL
    ADC $002A
    RTS

Mult12:
    ASL
    ASL         ; x4
    STA $002A     
    ASL         ; x8
    ADC $002A     ; x(8+4)
    RTS 
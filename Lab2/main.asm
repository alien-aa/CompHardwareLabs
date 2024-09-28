.def TMP = R20
.def N1R = R0
.def N11R = R1
.def N2R = R2
.def N22R = R5
.def N3R = R3
.def N33R = R4
.def SR_REG = R12

.equ NUM1 = 0xFF ; режим 1
.equ NUM11 = 0x00
.equ NUM2 = 0xAA ; режим 2
.equ NUM22 = 0x55
; режим 3: y/-y 0x55 по умолчанию, прямой код

.equ ADDR_MODE = 0 ; адрес ячейки EEPROM для хранения режима


.org $000
JMP  reset; Указатель на начало программы


.org INT0addr
JMP INT0_HANDLER ; Указатель на обработчик прерывания int0
.org INT1addr
JMP INT1_HANDLER ; Указатель на обработчик прерывания int1


EEPROM_read:
; Wait for completion of previous write
SBIC EECR,EEWE
RJMP EEPROM_read
; Set up address (r18:r17) in address register
OUT EEARH, r18
OUT EEARL, r17
; Start eeprom read by writing EERE
SBI EECR,EERE
; Read data from data register
IN r16,EEDR
RET

EEPROM_write:
; Wait for completion of previous write
SBIC EECR,EEWE
RJMP EEPROM_write
; Set up address (r18:r17) in address register
OUT EEARH, r18
OUT EEARL, r17
; Write data (r16) to data register
OUT EEDR, r16
; Write logical one to EEMWE
SBI EECR,EEMWE
; Start eeprom write by setting EEWE
SBI EECR,EEWE
RET

delay:
	CPI R31, 0
	BREQ base_delay
   	CPI R31, 1 ; сравнение
	BREQ first_time
	CPI R31, 2
	BREQ second_time
	CPI R31, 3
	BREQ third_time
	ret

base_delay:;2Гц начальная частота
   LDI R25, 10;  y
   LDI R28, 255; x
   LDI R29, 255
delay_sub:
   DEC R29
   BRNE delay_sub
   DEC R28
   BRNE delay_sub
   DEC R25
   BRNE delay_sub
   NOP
   NOP
   RET
	
first_time:;0.25Гц
LDI R16, 1
LDI R18, 0
LDI R17, 1
call EEPROM_write
LDI R21, 0b00000001
OR R21, R19; + смотрим состояние в R19
OUT PORTD, R21
LDI R25, 5
 LDI R28, 223
 LDI R29, 188
delay_sub_250:
 DEC R29
 NOP
 NOP
 NOP
 BRNE delay_sub_250
 DEC R28
 BRNE delay_sub_250
 DEC R25
 BRNE delay_sub_250
 NOP
 NOP
RET

second_time:;0.5Гц
LDI R16, 2
LDI R18, 0
LDI R17, 1
call EEPROM_write
LDI R23, 0b00000010
OR R23, R19; + смотрим состояние в R19
OUT PORTD, R23
LDI R25, 10
 LDI R28, 240
 LDI R29, 188
delay_sub_500:
 DEC R29
 NOP
 NOP
 NOP
 BRNE delay_sub_500
 DEC R28
 BRNE delay_sub_500
 DEC R25
 BRNE delay_sub_500
 NOP
 NOP
RET

third_time:;1Гц
LDI R16, 3
LDI R18, 0
LDI R17, 1
call EEPROM_write
LDI R24, 0b00000011
OR R24, R19; + смотрим состояние в R19
OUT PORTD, R24
 LDI R25, 20
 LDI R28, 240
 LDI R29, 188
delay_sub_1000:
 DEC R29
 NOP
 NOP
 NOP
 BRNE delay_sub_1000
 DEC R28
 BRNE delay_sub_1000
 DEC R25
 BRNE delay_sub_1000
 NOP
 NOP
RET

; Начальная настройка
reset:
; Запись чисел для работы в регистры, оттуда их будет читать программа в соответствующем режиме
 LDI TMP, NUM1
 MOV N1R, TMP
 LDI TMP, NUM2
 MOV N2R, TMP
 LDI TMP, NUM22
 MOV N22R, TMP
 CLR TMP
 LDI TMP, NUM22;
 MOV N3R, TMP; y
 MOV N33R, TMP
 LDI TMP, 0b10000000
 ADD N33R, TMP
 CLR TMP
  ; настройка портов ввода-вывода
 LDI TMP, NUM11 ; 0x00
 MOV N11R, TMP ; Вход
 OUT DDRC, TMP
 CLR TMP;
 SER TMP ; 0xFF
 OUT DDRA, TMP ; Выход
 OUT DDRB, TMP ; Выход
 CLR TMP;
 LDI TMP, 0b01110011
 OUT DDRD, TMP ; Часть битов на вход, часть на выход (см. задание)
 ;Настройка указателя стека
 LDI R22, 0b00000000
LDI R22, HIGH(RAMEND) ; Старшие разряды адреса. HIGH(RAMEND)- адрес вершины стека
OUT SPH, R22 ; SPH (Stack Pointer High) - старший регистр указателя стека
LDI R22, LOW(RAMEND)  ; Младшие разряды адреса
OUT SPL, R22 ;SPL (Stack Pointer Low) - младший регистр указателя стека
; Настройка регистров для работы с прерываниями
LDI R16, 0x0A
OUT MCUCR, R16 ; int0 и int1 работают на перепаде 0/1
LDI R16, 0xC0
OUT GICR, R16 ; разрешить int0 и int1
LDI R16, 0x00 
OUT GIFR, R16 ; Предотвращение срабатывания int0 и int1 при включении прерываний
SEI ; Глобальное разрешение прерываний

LDI R18, 0 
LDI R17, 0 ; (r18:r17) занесется в регистр адреса
call EEPROM_read ; считали данные из EEPROM в R16, потом запишем их в R30 - какой режим?
MOV R30, R16

LDI R18, 0
LDI R17, 1; (r18:r17) занесется в регистр адреса
call EEPROM_read ; считали данные из EEPROM в R16, потом запишем их в R31 - какая частота?
MOV R31, R16

LDI R18, 0
LDI R17, 2 ; (r18:r17) занесется в регистр адреса
call EEPROM_read ; считали данные из EEPROM в R16 - какое число y?
; тут восстанавливается y из памяти
CLR N3R
MOV N33R, R16
MOV N3R, R16
LDI TMP, 0b10000000
ADD N33R, TMP ; меняем знаковый бит числа - прямой код
CLR TMP


choice:
IN TMP, PIND ; Считывание PIND в TMP
SBRC TMP, 7; Если 7 бит PIND очищен, то следующая команда пропускается
CALL read_y ;
CPI R30, 0
BREQ choice_0
CPI R30, 1
BREQ choice_1
CPI R30, 2
BREQ choice_2
 
read_y:
   IN TMP, PIND ; Считывание PIND в TMP
   SBRC TMP, 7 ; Если 7 бит PIND установлен, следующая команда выполняется
   RJMP y_in_mode ; Переход если кнопка отпущена
   RET

y_in_mode:
; считали число
   IN N3R, PINC 
   MOV N33R, N3R
   ; сохранили в EEPROM
   MOV R16, N3R
   LDI R18, 0
   LDI R17, 2
   call EEPROM_write
   ; Вычислили -y (как было выше)
   LDI TMP, 0b10000000
   ADD N33R, TMP
   CLR TMP
   
   RJMP read_y
 
 choice_0: ; 0xFF/0x00

LDI R19, 0b00010000
OUT PORTD, R19
OUT PORTA, N1R
OUT PORTB, N11R
 call delay
LDI R19, 0b01010000
OUT PORTD, R19
OUT PORTA, N11R
OUT PORTB, N1R
  call delay
 jmp choice

  choice_1: ; 0xAA/0x55

LDI R19, 0b00100000
OUT PORTD, R19
OUT PORTA, N2R
OUT PORTB, N22R
 call delay
LDI R19, 0b01100000
OUT PORTD, R19
OUT PORTA, N22R
OUT PORTB, N2R
  call delay
 jmp choice

choice_2: ; y/-y

LDI R19, 0b00110000
OUT PORTD, R19
out PORTA, N3R
out PORTB, N33R
 call delay
LDI R19, 0b01110000
OUT PORTD, R19
out PORTA, N33R
out PORTB, N3R 
  call delay
 jmp choice
 
ch_mode_0:
ldi R30, 0
LDI R16, 0
LDI R18, 0
LDI R17, 0
call EEPROM_write

	POP R15 ; Восстановление значения R16 из стека
	OUT SREG, R15 ; Восстановление значения SREG из стека
reti

ch_mode_1:
ldi R30, 1
ldi R16, 1
LDI R18, 0
LDI R17, 0
call EEPROM_write

	POP R15 ; Восстановление значения R16 из стека
	OUT SREG, R15 ; Восстановление значения SREG из стека
reti

ch_mode_2:
ldi R30, 2
ldi R16, 2
LDI R18, 0
LDI R17, 0
call EEPROM_write

	POP R15 ; Восстановление значения R16 из стека
	OUT SREG, R15 ; Восстановление значения SREG из стека
reti


INT0_HANDLER:
	IN R15, SREG
	PUSH R15 ; Сохранение текущего значения SREG в стеке

    INC R30
	CPI R30, 0		
	BREQ ch_mode_0
	CPI R30, 1
	BREQ ch_mode_1
	CPI R30, 2
	BREQ ch_mode_2
	CPI R30, 3
	BREQ ch_mode_0

;int0_new:
;;	LDI R30, 0
	;RETI  

	          
INT1_HANDLER:
	IN R15, SREG
	PUSH R15 ; Сохранение текущего значения SREG в стеке

	INC R31			;Изменить время ожидания
	CPI R31, 4		;Проверить, что время ожидания не вышло за пределы {0.25, 0.5, 1.0}
	BREQ x_of
	
	POP R15 ; Восстановление значения R16 из стека
	OUT SREG, R15 ; Восстановление значения SREG из стека

	RETI            ; Возврат из обработчика прерываний
		       
x_of:
	LDI R31, 1
	
	POP R15 ; Восстановление значения R16 из стека
	OUT SREG, R15 ; Восстановление значения SREG из стека
	RETI            ; Возврат из обработчика прерываний


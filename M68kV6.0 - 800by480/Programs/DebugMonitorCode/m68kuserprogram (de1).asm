; C:\CPEN412\LAB1\M68KV6.0 - 800BY480\PROGRAMS\DEBUGMONITORCODE\M68KUSERPROGRAM (DE1).C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include <stdio.h>
; #include <string.h>
; #include <ctype.h>
; //IMPORTANT
; //
; // Uncomment one of the two #defines below
; // Define StartOfExceptionVectorTable as 08030000 if running programs from sram or
; // 0B000000 for running programs from dram
; //
; // In your labs, you will initially start by designing a system with SRam and later move to
; // Dram, so these constants will need to be changed based on the version of the system you have
; // building
; //
; // The working 68k system SOF file posted on canvas that you can use for your pre-lab
; // is based around Dram so #define accordingly before building
; #define StartOfExceptionVectorTable 0x08030000
; //#define StartOfExceptionVectorTable 0x0B000000
; /**********************************************************************************************
; **	Parallel port addresses
; **********************************************************************************************/
; #define PortA   *(volatile unsigned char *)(0x00400000)
; #define PortB   *(volatile unsigned char *)(0x00400002)
; #define PortC   *(volatile unsigned char *)(0x00400004)
; #define PortD   *(volatile unsigned char *)(0x00400006)
; #define PortE   *(volatile unsigned char *)(0x00400008)
; /*********************************************************************************************
; **	Hex 7 seg displays port addresses
; *********************************************************************************************/
; #define HEX_A        *(volatile unsigned char *)(0x00400010)
; #define HEX_B        *(volatile unsigned char *)(0x00400012)
; #define HEX_C        *(volatile unsigned char *)(0x00400014)    // de2 only
; #define HEX_D        *(volatile unsigned char *)(0x00400016)    // de2 only
; /**********************************************************************************************
; **	LCD display port addresses
; **********************************************************************************************/
; #define LCDcommand   *(volatile unsigned char *)(0x00400020)
; #define LCDdata      *(volatile unsigned char *)(0x00400022)
; /********************************************************************************************
; **	Timer Port addresses
; *********************************************************************************************/
; #define Timer1Data      *(volatile unsigned char *)(0x00400030)
; #define Timer1Control   *(volatile unsigned char *)(0x00400032)
; #define Timer1Status    *(volatile unsigned char *)(0x00400032)
; #define Timer2Data      *(volatile unsigned char *)(0x00400034)
; #define Timer2Control   *(volatile unsigned char *)(0x00400036)
; #define Timer2Status    *(volatile unsigned char *)(0x00400036)
; #define Timer3Data      *(volatile unsigned char *)(0x00400038)
; #define Timer3Control   *(volatile unsigned char *)(0x0040003A)
; #define Timer3Status    *(volatile unsigned char *)(0x0040003A)
; #define Timer4Data      *(volatile unsigned char *)(0x0040003C)
; #define Timer4Control   *(volatile unsigned char *)(0x0040003E)
; #define Timer4Status    *(volatile unsigned char *)(0x0040003E)
; /*********************************************************************************************
; **	RS232 port addresses
; *********************************************************************************************/
; #define RS232_Control     *(volatile unsigned char *)(0x00400040)
; #define RS232_Status      *(volatile unsigned char *)(0x00400040)
; #define RS232_TxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_RxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_Baud        *(volatile unsigned char *)(0x00400044)
; /*********************************************************************************************
; **	PIA 1 and 2 port addresses
; *********************************************************************************************/
; #define PIA1_PortA_Data     *(volatile unsigned char *)(0x00400050)         // combined data and data direction register share same address
; #define PIA1_PortA_Control *(volatile unsigned char *)(0x00400052)
; #define PIA1_PortB_Data     *(volatile unsigned char *)(0x00400054)         // combined data and data direction register share same address
; #define PIA1_PortB_Control *(volatile unsigned char *)(0x00400056)
; #define PIA2_PortA_Data     *(volatile unsigned char *)(0x00400060)         // combined data and data direction register share same address
; #define PIA2_PortA_Control *(volatile unsigned char *)(0x00400062)
; #define PIA2_PortB_data     *(volatile unsigned char *)(0x00400064)         // combined data and data direction register share same address
; #define PIA2_PortB_Control *(volatile unsigned char *)(0x00400066)
; /*********************************************************************************************************************************
; (( DO NOT initialise global variables here, do it main even if you want 0
; (( it's a limitation of the compiler
; (( YOU HAVE BEEN WARNED
; *********************************************************************************************************************************/
; unsigned int i, x, y, z, PortA_Count;
; unsigned char Timer1Count, Timer2Count, Timer3Count, Timer4Count ;
; /*******************************************************************************************
; ** Function Prototypes
; *******************************************************************************************/
; void Wait1ms(void);
; void Wait3ms(void);
; void Init_LCD(void) ;
; void LCDOutchar(int c);
; void LCDOutMess(char *theMessage);
; void LCDClearln(void);
; void LCDline1Message(char *theMessage);
; void LCDline2Message(char *theMessage);
; int sprintf(char *out, const char *format, ...) ;
; void ReadMemory(char* StartRamPtr, char* EndRamPtr, unsigned char FillData, int config);
; void FillMemory(char* StartRamPtr, char* EndRamPtr, unsigned char FillData, int config);
; int Get7HexDigits(char one, char two, char three, char four, char five, char six, char seven);
; int Get8HexDigits(char pat);
; int Get4HexDigits(char pat);
; int Get2HexDigits(char pat);
; char xtod(int c);
; /*****************************************************************************************
; **	Interrupt service routine for Timers
; **
; **  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
; **  out which timer is producing the interrupt
; **
; *****************************************************************************************/
; void Timer_ISR()
; {
       section   code
       xdef      _Timer_ISR
_Timer_ISR:
; if(Timer1Status == 1) {         // Did Timer 1 produce the Interrupt?
       move.b    4194354,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_1
; Timer1Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194354
; PortA = Timer1Count++ ;     // increment an LED count on PortA with each tick of Timer 1
       move.b    _Timer1Count.L,D0
       addq.b    #1,_Timer1Count.L
       move.b    D0,4194304
Timer_ISR_1:
; }
; if(Timer2Status == 1) {         // Did Timer 2 produce the Interrupt?
       move.b    4194358,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_3
; Timer2Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194358
; PortC = Timer2Count++ ;     // increment an LED count on PortC with each tick of Timer 2
       move.b    _Timer2Count.L,D0
       addq.b    #1,_Timer2Count.L
       move.b    D0,4194308
Timer_ISR_3:
; }
; if(Timer3Status == 1) {         // Did Timer 3 produce the Interrupt?
       move.b    4194362,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_5
; Timer3Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194362
; HEX_A = Timer3Count++ ;     // increment a HEX count on Port HEX_A with each tick of Timer 3
       move.b    _Timer3Count.L,D0
       addq.b    #1,_Timer3Count.L
       move.b    D0,4194320
Timer_ISR_5:
; }
; if(Timer4Status == 1) {         // Did Timer 4 produce the Interrupt?
       move.b    4194366,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_7
; Timer4Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194366
; HEX_B = Timer4Count++ ;     // increment a HEX count on HEX_B with each tick of Timer 4
       move.b    _Timer4Count.L,D0
       addq.b    #1,_Timer4Count.L
       move.b    D0,4194322
Timer_ISR_7:
       rts
; }
; }
; /*****************************************************************************************
; **	Interrupt service routine for ACIA. This device has it's own dedicate IRQ level
; **  Add your code here to poll Status register and clear interrupt
; *****************************************************************************************/
; void ACIA_ISR()
; {}
       xdef      _ACIA_ISR
_ACIA_ISR:
       rts
; /***************************************************************************************
; **	Interrupt service routine for PIAs 1 and 2. These devices share an IRQ level
; **  Add your code here to poll Status register and clear interrupt
; *****************************************************************************************/
; void PIA_ISR()
; {}
       xdef      _PIA_ISR
_PIA_ISR:
       rts
; /***********************************************************************************
; **	Interrupt service routine for Key 2 on DE1 board. Add your own response here
; ************************************************************************************/
; void Key2PressISR()
; {}
       xdef      _Key2PressISR
_Key2PressISR:
       rts
; /***********************************************************************************
; **	Interrupt service routine for Key 1 on DE1 board. Add your own response here
; ************************************************************************************/
; void Key1PressISR()
; {}
       xdef      _Key1PressISR
_Key1PressISR:
       rts
; /************************************************************************************
; **   Delay Subroutine to give the 68000 something useless to do to waste 1 mSec
; ************************************************************************************/
; void Wait1ms(void)
; {
       xdef      _Wait1ms
_Wait1ms:
       move.l    D2,-(A7)
; int  i ;
; for(i = 0; i < 1000; i ++)
       clr.l     D2
Wait1ms_1:
       cmp.l     #1000,D2
       bge.s     Wait1ms_3
       addq.l    #1,D2
       bra       Wait1ms_1
Wait1ms_3:
       move.l    (A7)+,D2
       rts
; ;
; }
; /************************************************************************************
; **  Subroutine to give the 68000 something useless to do to waste 3 mSec
; **************************************************************************************/
; void Wait3ms(void)
; {
       xdef      _Wait3ms
_Wait3ms:
       move.l    D2,-(A7)
; int i ;
; for(i = 0; i < 3; i++)
       clr.l     D2
Wait3ms_1:
       cmp.l     #3,D2
       bge.s     Wait3ms_3
; Wait1ms() ;
       jsr       _Wait1ms
       addq.l    #1,D2
       bra       Wait3ms_1
Wait3ms_3:
       move.l    (A7)+,D2
       rts
; }
; /*********************************************************************************************
; **  Subroutine to initialise the LCD display by writing some commands to the LCD internal registers
; **  Sets it for parallel port and 2 line display mode (if I recall correctly)
; *********************************************************************************************/
; void Init_LCD(void)
; {
       xdef      _Init_LCD
_Init_LCD:
; LCDcommand = 0x0c ;
       move.b    #12,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDcommand = 0x38 ;
       move.b    #56,4194336
; Wait3ms() ;
       jsr       _Wait3ms
       rts
; }
; /*********************************************************************************************
; **  Subroutine to initialise the RS232 Port by writing some commands to the internal registers
; *********************************************************************************************/
; void Init_RS232(void)
; {
       xdef      _Init_RS232
_Init_RS232:
; RS232_Control = 0x15 ; //  %00010101 set up 6850 uses divide by 16 clock, set RTS low, 8 bits no parity, 1 stop bit, transmitter interrupt disabled
       move.b    #21,4194368
; RS232_Baud = 0x1 ;      // program baud rate generator 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
       move.b    #1,4194372
       rts
; }
; /*********************************************************************************************************
; **  Subroutine to provide a low level output function to 6850 ACIA
; **  This routine provides the basic functionality to output a single character to the serial Port
; **  to allow the board to communicate with HyperTerminal Program
; **
; **  NOTE you do not call this function directly, instead you call the normal putchar() function
; **  which in turn calls _putch() below). Other functions like puts(), printf() call putchar() so will
; **  call _putch() also
; *********************************************************************************************************/
; int _putch( int c)
; {
       xdef      __putch
__putch:
       link      A6,#0
; while((RS232_Status & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
_putch_1:
       move.b    4194368,D0
       and.b     #2,D0
       cmp.b     #2,D0
       beq.s     _putch_3
       bra       _putch_1
_putch_3:
; ;
; RS232_TxData = (c & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
       move.l    8(A6),D0
       and.l     #127,D0
       move.b    D0,4194370
; return c ;                                              // putchar() expects the character to be returned
       move.l    8(A6),D0
       unlk      A6
       rts
; }
; /*********************************************************************************************************
; **  Subroutine to provide a low level input function to 6850 ACIA
; **  This routine provides the basic functionality to input a single character from the serial Port
; **  to allow the board to communicate with HyperTerminal Program Keyboard (your PC)
; **
; **  NOTE you do not call this function directly, instead you call the normal getchar() function
; **  which in turn calls _getch() below). Other functions like gets(), scanf() call getchar() so will
; **  call _getch() also
; *********************************************************************************************************/
; int _getch( void )
; {
       xdef      __getch
__getch:
       link      A6,#-4
; char c ;
; while((RS232_Status & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
_getch_1:
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     _getch_3
       bra       _getch_1
_getch_3:
; ;
; return (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character
       move.b    4194370,D0
       and.l     #255,D0
       and.l     #127,D0
       unlk      A6
       rts
; }
; /******************************************************************************
; **  Subroutine to output a single character to the 2 row LCD display
; **  It is assumed the character is an ASCII code and it will be displayed at the
; **  current cursor position
; *******************************************************************************/
; void LCDOutchar(int c)
; {
       xdef      _LCDOutchar
_LCDOutchar:
       link      A6,#0
; LCDdata = (char)(c);
       move.l    8(A6),D0
       move.b    D0,4194338
; Wait1ms() ;
       jsr       _Wait1ms
       unlk      A6
       rts
; }
; /**********************************************************************************
; *subroutine to output a message at the current cursor position of the LCD display
; ************************************************************************************/
; void LCDOutMessage(char *theMessage)
; {
       xdef      _LCDOutMessage
_LCDOutMessage:
       link      A6,#-4
; char c ;
; while((c = *theMessage++) != 0)     // output characters from the string until NULL
LCDOutMessage_1:
       move.l    8(A6),A0
       addq.l    #1,8(A6)
       move.b    (A0),-1(A6)
       move.b    (A0),D0
       beq.s     LCDOutMessage_3
; LCDOutchar(c) ;
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _LCDOutchar
       addq.w    #4,A7
       bra       LCDOutMessage_1
LCDOutMessage_3:
       unlk      A6
       rts
; }
; /******************************************************************************
; *subroutine to clear the line by issuing 24 space characters
; *******************************************************************************/
; void LCDClearln(void)
; {
       xdef      _LCDClearln
_LCDClearln:
       move.l    D2,-(A7)
; int i ;
; for(i = 0; i < 24; i ++)
       clr.l     D2
LCDClearln_1:
       cmp.l     #24,D2
       bge.s     LCDClearln_3
; LCDOutchar(' ') ;       // write a space char to the LCD display
       pea       32
       jsr       _LCDOutchar
       addq.w    #4,A7
       addq.l    #1,D2
       bra       LCDClearln_1
LCDClearln_3:
       move.l    (A7)+,D2
       rts
; }
; /******************************************************************************
; **  Subroutine to move the LCD cursor to the start of line 1 and clear that line
; *******************************************************************************/
; void LCDLine1Message(char *theMessage)
; {
       xdef      _LCDLine1Message
_LCDLine1Message:
       link      A6,#0
; LCDcommand = 0x80 ;
       move.b    #128,4194336
; Wait3ms();
       jsr       _Wait3ms
; LCDClearln() ;
       jsr       _LCDClearln
; LCDcommand = 0x80 ;
       move.b    #128,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDOutMessage(theMessage) ;
       move.l    8(A6),-(A7)
       jsr       _LCDOutMessage
       addq.w    #4,A7
       unlk      A6
       rts
; }
; /******************************************************************************
; **  Subroutine to move the LCD cursor to the start of line 2 and clear that line
; *******************************************************************************/
; void LCDLine2Message(char *theMessage)
; {
       xdef      _LCDLine2Message
_LCDLine2Message:
       link      A6,#0
; LCDcommand = 0xC0 ;
       move.b    #192,4194336
; Wait3ms();
       jsr       _Wait3ms
; LCDClearln() ;
       jsr       _LCDClearln
; LCDcommand = 0xC0 ;
       move.b    #192,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDOutMessage(theMessage) ;
       move.l    8(A6),-(A7)
       jsr       _LCDOutMessage
       addq.w    #4,A7
       unlk      A6
       rts
; }
; /*********************************************************************************************************************************
; **  IMPORTANT FUNCTION
; **  This function install an exception handler so you can capture and deal with any 68000 exception in your program
; **  You pass it the name of a function in your code that will get called in response to the exception (as the 1st parameter)
; **  and in the 2nd parameter, you pass it the exception number that you want to take over (see 68000 exceptions for details)
; **  Calling this function allows you to deal with Interrupts for example
; ***********************************************************************************************************************************/
; void InstallExceptionHandler( void (*function_ptr)(), int level)
; {
       xdef      _InstallExceptionHandler
_InstallExceptionHandler:
       link      A6,#-4
; volatile long int *RamVectorAddress = (volatile long int *)(StartOfExceptionVectorTable) ;   // pointer to the Ram based interrupt vector table created in Cstart in debug monitor
       move.l    #134414336,-4(A6)
; RamVectorAddress[level] = (long int *)(function_ptr);                       // install the address of our function into the exception table
       move.l    -4(A6),A0
       move.l    12(A6),D0
       lsl.l     #2,D0
       move.l    8(A6),0(A0,D0.L)
       unlk      A6
       rts
; }
; /*
; * Support functions for changing memory contents
; */
; // converts hex char to 4 bit binary equiv in range 0000-1111 (0-F)
; // char assumed to be a valid hex char 0-9, a-f, A-F
; char xtod(int c)
; {
       xdef      _xtod
_xtod:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; if ((char)(c) <= (char)('9'))
       cmp.b     #57,D2
       bgt.s     xtod_1
; return c - (char)(0x30);    // 0 - 9 = 0x30 - 0x39 so convert to number by sutracting 0x30
       move.b    D2,D0
       sub.b     #48,D0
       bra.s     xtod_3
xtod_1:
; else if ((char)(c) > (char)('F'))    // assume lower case
       cmp.b     #70,D2
       ble.s     xtod_4
; return c - (char)(0x57);    // a-f = 0x61-66 so needs to be converted to 0x0A - 0x0F so subtract 0x57
       move.b    D2,D0
       sub.b     #87,D0
       bra.s     xtod_3
xtod_4:
; else
; return c - (char)(0x37);    // A-F = 0x41-46 so needs to be converted to 0x0A - 0x0F so subtract 0x37
       move.b    D2,D0
       sub.b     #55,D0
xtod_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; int Get2HexDigits(char pat)
; {
       xdef      _Get2HexDigits
_Get2HexDigits:
       link      A6,#0
       move.l    D2,-(A7)
; register int i = (xtod(pat) << 4) | (xtod(pat));
       move.b    11(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       and.l     #255,D0
       asl.l     #4,D0
       move.l    D0,-(A7)
       move.b    11(A6),D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,D2
; return i;
       move.l    D2,D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; int Get4HexDigits(char pat)
; {
       xdef      _Get4HexDigits
_Get4HexDigits:
       link      A6,#0
; return (Get2HexDigits(pat) << 8) | (Get2HexDigits(pat));
       move.b    11(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.b    11(A6),D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       or.l      D1,D0
       unlk      A6
       rts
; }
; int Get8HexDigits(char pat)
; {
       xdef      _Get8HexDigits
_Get8HexDigits:
       link      A6,#0
; return (Get4HexDigits(pat) << 16) | (Get4HexDigits(pat));
       move.b    11(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       asl.l     #8,D0
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.b    11(A6),D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       or.l      D1,D0
       unlk      A6
       rts
; }
; int Get7HexDigits(char one, char two, char three, char four, char five, char six, char seven)
; {
       xdef      _Get7HexDigits
_Get7HexDigits:
       link      A6,#0
       movem.l   D2/A2,-(A7)
       lea       _xtod.L,A2
; register int i = (xtod(one) << 24) | (xtod(two) << 20) | (xtod(three) << 16) | (xtod(four) << 12) | (xtod(five) << 8) | (xtod(six) << 4) | (xtod(seven));
       move.b    11(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
       and.l     #255,D0
       asl.l     #8,D0
       asl.l     #8,D0
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.b    15(A6),D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       jsr       (A2)
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       asl.l     #8,D1
       asl.l     #8,D1
       asl.l     #4,D1
       or.l      D1,D0
       move.l    D0,-(A7)
       move.b    19(A6),D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       jsr       (A2)
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       asl.l     #8,D1
       asl.l     #8,D1
       or.l      D1,D0
       move.l    D0,-(A7)
       move.b    23(A6),D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       jsr       (A2)
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       asl.l     #8,D1
       asl.l     #4,D1
       or.l      D1,D0
       move.l    D0,-(A7)
       move.b    27(A6),D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       jsr       (A2)
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       asl.l     #8,D1
       or.l      D1,D0
       move.l    D0,-(A7)
       move.b    31(A6),D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       jsr       (A2)
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       asl.l     #4,D1
       or.l      D1,D0
       move.l    D0,-(A7)
       move.b    35(A6),D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       jsr       (A2)
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,D2
; return i;
       move.l    D2,D0
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; void FillMemory(char* StartRamPtr, char* EndRamPtr, unsigned char FillData, int config)
; {
       xdef      _FillMemory
_FillMemory:
       link      A6,#0
       movem.l   D2/D3/D4/D5,-(A7)
       move.l    12(A6),D3
       move.b    19(A6),D4
       and.l     #255,D4
       move.l    20(A6),D5
; char* start = StartRamPtr;
       move.l    8(A6),D2
; printf("\r\nFilling Addresses [$%08X - $%08X] with $%02X", StartRamPtr, EndRamPtr, FillData);
       and.l     #255,D4
       move.l    D4,-(A7)
       move.l    D3,-(A7)
       move.l    8(A6),-(A7)
       pea       @m68kus~1_1.L
       jsr       _printf
       add.w     #16,A7
; if (config == 1) {
       cmp.l     #1,D5
       bne.s     FillMemory_5
; while (start <= EndRamPtr){
FillMemory_3:
       cmp.l     D3,D2
       bhi.s     FillMemory_5
; *start++ = FillData;
       move.l    D2,A0
       addq.l    #1,D2
       move.b    D4,(A0)
       bra       FillMemory_3
FillMemory_5:
; }
; }
; if (config == 2) {
       cmp.l     #2,D5
       bne.s     FillMemory_10
; while (start <= EndRamPtr) {
FillMemory_8:
       cmp.l     D3,D2
       bhi.s     FillMemory_10
; *start = FillData;
       move.l    D2,A0
       move.b    D4,(A0)
; start += 2;
       addq.l    #2,D2
       bra       FillMemory_8
FillMemory_10:
; }
; }
; if (config == 3) {
       cmp.l     #3,D5
       bne.s     FillMemory_15
; while (start <= EndRamPtr) {
FillMemory_13:
       cmp.l     D3,D2
       bhi.s     FillMemory_15
; *start = FillData;
       move.l    D2,A0
       move.b    D4,(A0)
; start += 4;
       addq.l    #4,D2
       bra       FillMemory_13
FillMemory_15:
       movem.l   (A7)+,D2/D3/D4/D5
       unlk      A6
       rts
; }
; }
; }
; void ReadMemory(char* StartRamPtr, char* EndRamPtr, unsigned char FillData, int config)
; {
       xdef      _ReadMemory
_ReadMemory:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/A2,-(A7)
       move.b    19(A6),D3
       and.l     #255,D3
       lea       _printf.L,A2
       move.l    12(A6),D4
       move.l    20(A6),D5
; int counter = 0;
       clr.l     -4(A6)
; unsigned char* start = StartRamPtr;
       move.l    8(A6),D2
; printf("\r\nReading Addresses [$%08X - $%08X] for $%02X", StartRamPtr, EndRamPtr, FillData);
       and.l     #255,D3
       move.l    D3,-(A7)
       move.l    D4,-(A7)
       move.l    8(A6),-(A7)
       pea       @m68kus~1_2.L
       jsr       (A2)
       add.w     #16,A7
; if (config == 1) {
       cmp.l     #1,D5
       bne       ReadMemory_5
; while (start <= EndRamPtr) {
ReadMemory_3:
       cmp.l     D4,D2
       bhi       ReadMemory_5
; if (*start != FillData)
       move.l    D2,A0
       cmp.b     (A0),D3
       beq.s     ReadMemory_6
; printf("\r\nValue incorrect at addresses $%08X ... should be $%02X but found $%02X", start, FillData, *start);
       move.l    D2,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       and.l     #255,D3
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       pea       @m68kus~1_3.L
       jsr       (A2)
       add.w     #16,A7
ReadMemory_6:
; printf("\r\nValue: $%02X found at Address: $%08X", *start, start);
       move.l    D2,-(A7)
       move.l    D2,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_4.L
       jsr       (A2)
       add.w     #12,A7
; start++;
       addq.l    #1,D2
       bra       ReadMemory_3
ReadMemory_5:
; }
; }
; if (config == 2) {
       cmp.l     #2,D5
       bne       ReadMemory_12
; while (start <= EndRamPtr) {
ReadMemory_10:
       cmp.l     D4,D2
       bhi       ReadMemory_12
; if(*start != FillData)
       move.l    D2,A0
       cmp.b     (A0),D3
       beq.s     ReadMemory_13
; printf("\r\nValue incorrect at addresses $%08X ... should be $%02X but found $%02X", start, FillData, *start);
       move.l    D2,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       and.l     #255,D3
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       pea       @m68kus~1_3.L
       jsr       (A2)
       add.w     #16,A7
ReadMemory_13:
; printf("\r\nValue: $%02X $%02X found at Address: $%08X - $%08X", *start, *(start+1), start, (start+1));
       move.l    D2,D1
       addq.l    #1,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       move.l    D2,A0
       move.b    1(A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_5.L
       jsr       (A2)
       add.w     #20,A7
; start += 2;
       addq.l    #2,D2
       bra       ReadMemory_10
ReadMemory_12:
; }
; }
; if (config == 3) {
       cmp.l     #3,D5
       bne       ReadMemory_19
; while (start <= EndRamPtr) {
ReadMemory_17:
       cmp.l     D4,D2
       bhi       ReadMemory_19
; if (*start != FillData)
       move.l    D2,A0
       cmp.b     (A0),D3
       beq.s     ReadMemory_20
; printf("\r\nValue incorrect at addresses $%08X ... should be $%02X but found $%02X", start, FillData, *start);
       move.l    D2,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       and.l     #255,D3
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       pea       @m68kus~1_3.L
       jsr       (A2)
       add.w     #16,A7
ReadMemory_20:
; printf("\r\nValue: $%02X $%02X $%02X $%02X found at Address: $%08X - $%08X", *start, *(start+3), start, (start+3));
       move.l    D2,D1
       addq.l    #3,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       move.l    D2,A0
       move.b    3(A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kus~1_6.L
       jsr       (A2)
       add.w     #20,A7
; start += 4;
       addq.l    #4,D2
       bra       ReadMemory_17
ReadMemory_19:
       movem.l   (A7)+,D2/D3/D4/D5/A2
       unlk      A6
       rts
; }
; }
; }
; /******************************************************************************************************************************
; * Start of user program
; ******************************************************************************************************************************/
; void main()
; {
       xdef      _main
_main:
       link      A6,#-196
       movem.l   D2/D3/D4/A2/A3/A4/A5,-(A7)
       lea       -8(A6),A2
       lea       _printf.L,A3
       lea       -16(A6),A4
       lea       _scanf.L,A5
; unsigned int row, i = 0, count = 0, counter1 = 1;
       clr.l     -192(A6)
       clr.l     -188(A6)
       move.l    #1,-184(A6)
; char c, text[150] ;
; int PassFailFlag = 1 ;
       move.l    #1,-28(A6)
; int test_config = 0;
       clr.l     -24(A6)
; int test_pattern = 0;
       clr.l     -20(A6)
; char start_addr[7];
; int start_val = 0;
       clr.l     D3
; char end_addr[7];
; int end_val = 0;
       clr.l     D2
; char digit;
; i = x = y = z = PortA_Count = 0;
       clr.l     _PortA_Count.L
       clr.l     _z.L
       clr.l     _y.L
       clr.l     _x.L
       clr.l     -192(A6)
; Timer1Count = Timer2Count = Timer3Count = Timer4Count = 0;
       clr.b     _Timer4Count.L
       clr.b     _Timer3Count.L
       clr.b     _Timer2Count.L
       clr.b     _Timer1Count.L
; InstallExceptionHandler(PIA_ISR, 25) ;          // install interrupt handler for PIAs 1 and 2 on level 1 IRQ
       pea       25
       pea       _PIA_ISR.L
       jsr       _InstallExceptionHandler
       addq.w    #8,A7
; InstallExceptionHandler(ACIA_ISR, 26) ;		    // install interrupt handler for ACIA on level 2 IRQ
       pea       26
       pea       _ACIA_ISR.L
       jsr       _InstallExceptionHandler
       addq.w    #8,A7
; InstallExceptionHandler(Timer_ISR, 27) ;		// install interrupt handler for Timers 1-4 on level 3 IRQ
       pea       27
       pea       _Timer_ISR.L
       jsr       _InstallExceptionHandler
       addq.w    #8,A7
; InstallExceptionHandler(Key2PressISR, 28) ;	    // install interrupt handler for Key Press 2 on DE1 board for level 4 IRQ
       pea       28
       pea       _Key2PressISR.L
       jsr       _InstallExceptionHandler
       addq.w    #8,A7
; InstallExceptionHandler(Key1PressISR, 29) ;	    // install interrupt handler for Key Press 1 on DE1 board for level 5 IRQ
       pea       29
       pea       _Key1PressISR.L
       jsr       _InstallExceptionHandler
       addq.w    #8,A7
; Timer1Data = 0x10;		// program time delay into timers 1-4
       move.b    #16,4194352
; Timer2Data = 0x20;
       move.b    #32,4194356
; Timer3Data = 0x15;
       move.b    #21,4194360
; Timer4Data = 0x25;
       move.b    #37,4194364
; Timer1Control = 3;		// write 3 to control register to Bit0 = 1 (enable interrupt from timers) 1 - 4 and allow them to count Bit 1 = 1
       move.b    #3,4194354
; Timer2Control = 3;
       move.b    #3,4194358
; Timer3Control = 3;
       move.b    #3,4194362
; Timer4Control = 3;
       move.b    #3,4194366
; Init_LCD();             // initialise the LCD display to use a parallel data interface and 2 lines of display
       jsr       _Init_LCD
; Init_RS232() ;          // initialise the RS232 port for use with hyper terminal
       jsr       _Init_RS232
; /*************************************************************************************************
; **  Test of scanf function
; *************************************************************************************************/
; scanflush() ;                       // flush any text that may have been typed ahead
       jsr       _scanflush
; /*
; * User prompts
; */
; // Prompt the user to entre a test configuration
; printf("\r\nEnter memory test configuration(1 - bytes, 2 - words, 3 - long words): ");
       pea       @m68kus~1_7.L
       jsr       (A3)
       addq.w    #4,A7
; scanf("%d", &test_config);
       pea       -24(A6)
       pea       @m68kus~1_8.L
       jsr       (A5)
       addq.w    #8,A7
; // Check for invalid configuration entry and re-prompt if needed
; while (test_config > 3 || test_config < 1) {
main_1:
       move.l    -24(A6),D0
       cmp.l     #3,D0
       bgt.s     main_4
       move.l    -24(A6),D0
       cmp.l     #1,D0
       bge.s     main_3
main_4:
; printf("\r\nConfiguration invalid, try again");
       pea       @m68kus~1_9.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nEnter memory test configuration(1 - bytes, 2 - words, 3 - long words): ");
       pea       @m68kus~1_7.L
       jsr       (A3)
       addq.w    #4,A7
; scanf("%d", &test_config);
       pea       -24(A6)
       pea       @m68kus~1_8.L
       jsr       (A5)
       addq.w    #8,A7
       bra       main_1
main_3:
; }
; // Prompt the user to entre a test pattern
; printf("\r\nChoose between different memory test patterns(1 - 5, 2 - A, 3 - F, 4 - 0): ");
       pea       @m68kus~1_10.L
       jsr       (A3)
       addq.w    #4,A7
; scanf("%d", &test_pattern);
       pea       -20(A6)
       pea       @m68kus~1_8.L
       jsr       (A5)
       addq.w    #8,A7
; // Check for invalid pattern entry and re-prompt if needed
; while (test_pattern > 4 || test_pattern < 1) {
main_5:
       move.l    -20(A6),D0
       cmp.l     #4,D0
       bgt.s     main_8
       move.l    -20(A6),D0
       cmp.l     #1,D0
       bge.s     main_7
main_8:
; printf("\r\nPattern invalid, try again");
       pea       @m68kus~1_11.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nChoose between different memory test patterns(1 - 5, 2 - A, 3 - F, 4 - 0): ");
       pea       @m68kus~1_10.L
       jsr       (A3)
       addq.w    #4,A7
; scanf("%d", &test_pattern);
       pea       -20(A6)
       pea       @m68kus~1_8.L
       jsr       (A5)
       addq.w    #8,A7
       bra       main_5
main_7:
; }
; // Prompt the user to entre a starting address
; printf("\r\nEnter starting address(8020000 - 8030000 inclusive): ");
       pea       @m68kus~1_12.L
       jsr       (A3)
       addq.w    #4,A7
; scanf("%s", &start_addr);
       move.l    A4,-(A7)
       pea       @m68kus~1_13.L
       jsr       (A5)
       addq.w    #8,A7
; start_val = Get7HexDigits(start_addr[0], start_addr[1], start_addr[2], start_addr[3], start_addr[4], start_addr[5], start_addr[6]);
       move.b    6(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    5(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    4(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    3(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    2(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    1(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    (A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _Get7HexDigits
       add.w     #28,A7
       move.l    D0,D3
; // Check for invalid start address and re-prompt if needed
; while (start_val < 0x8020000 || start_val > 0x8030000 || strlen(start_addr) > 7) { // start address must be 7 chars and within bounds
main_9:
       cmp.l     #134348800,D3
       blt.s     main_12
       cmp.l     #134414336,D3
       bgt.s     main_12
       move.l    A4,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #7,D0
       ble       main_11
main_12:
; printf("\r\nStarting address out of bounds.. try again");
       pea       @m68kus~1_14.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nEnter starting address(8020000 - 8030000 inclusive): ");
       pea       @m68kus~1_12.L
       jsr       (A3)
       addq.w    #4,A7
; scanf("%s", &start_addr);
       move.l    A4,-(A7)
       pea       @m68kus~1_13.L
       jsr       (A5)
       addq.w    #8,A7
; start_val = Get7HexDigits(start_addr[0], start_addr[1], start_addr[2], start_addr[3], start_addr[4], start_addr[5], start_addr[6]);
       move.b    6(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    5(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    4(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    3(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    2(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    1(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    (A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _Get7HexDigits
       add.w     #28,A7
       move.l    D0,D3
       bra       main_9
main_11:
; }
; // Check for illegal address, start address must be even if writing words or long words to memory
; while (start_val % 2 != 0 && test_config != 1) {
main_13:
       move.l    D3,-(A7)
       pea       2
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       beq       main_15
       move.l    -24(A6),D0
       cmp.l     #1,D0
       beq       main_15
; printf("\r\nOdd starting address.. try again");
       pea       @m68kus~1_15.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nEnter starting address(8020000 - 8030000 inclusive): ");
       pea       @m68kus~1_12.L
       jsr       (A3)
       addq.w    #4,A7
; scanf("%s", &start_addr);
       move.l    A4,-(A7)
       pea       @m68kus~1_13.L
       jsr       (A5)
       addq.w    #8,A7
; start_val = Get7HexDigits(start_addr[0], start_addr[1], start_addr[2], start_addr[3], start_addr[4], start_addr[5], start_addr[6]);
       move.b    6(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    5(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    4(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    3(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    2(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    1(A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    (A4),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _Get7HexDigits
       add.w     #28,A7
       move.l    D0,D3
       bra       main_13
main_15:
; }
; // Prompt the user to entre an ending address
; printf("\r\nEnter ending address(8020000 - 8030000 inclusive): ");
       pea       @m68kus~1_16.L
       jsr       (A3)
       addq.w    #4,A7
; scanf("%s", &end_addr);
       move.l    A2,-(A7)
       pea       @m68kus~1_13.L
       jsr       (A5)
       addq.w    #8,A7
; end_val = Get7HexDigits(end_addr[0], end_addr[1], end_addr[2], end_addr[3], end_addr[4], end_addr[5], end_addr[6]);
       move.b    6(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    5(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    4(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    3(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    2(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    1(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    (A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _Get7HexDigits
       add.w     #28,A7
       move.l    D0,D2
; while (end_val < 0x8020000 || end_val > 0x8030000 || strlen(end_addr) > 7) { // end address must be 7 chars and within bounds
main_16:
       cmp.l     #134348800,D2
       blt.s     main_19
       cmp.l     #134414336,D2
       bgt.s     main_19
       move.l    A2,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       cmp.l     #7,D0
       ble       main_18
main_19:
; printf("\r\nEnding address out of bounds.. try again");
       pea       @m68kus~1_17.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nEnter ending address(8020000 - 8030000 inclusive): ");
       pea       @m68kus~1_16.L
       jsr       (A3)
       addq.w    #4,A7
; scanf("%s", &end_addr);
       move.l    A2,-(A7)
       pea       @m68kus~1_13.L
       jsr       (A5)
       addq.w    #8,A7
; end_val = Get7HexDigits(end_addr[0], end_addr[1], end_addr[2], end_addr[3], end_addr[4], end_addr[5], end_addr[6]);
       move.b    6(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    5(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    4(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    3(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    2(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    1(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    (A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _Get7HexDigits
       add.w     #28,A7
       move.l    D0,D2
       bra       main_16
main_18:
; }
; while (end_val < start_val) {
main_20:
       cmp.l     D3,D2
       bge       main_22
; printf("\r\nInvalid ending address.. try again");
       pea       @m68kus~1_18.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nEnter ending address(8020000 - 8030000 inclusive): ");
       pea       @m68kus~1_16.L
       jsr       (A3)
       addq.w    #4,A7
; scanf("%s", &end_addr);
       move.l    A2,-(A7)
       pea       @m68kus~1_13.L
       jsr       (A5)
       addq.w    #8,A7
; end_val = Get7HexDigits(end_addr[0], end_addr[1], end_addr[2], end_addr[3], end_addr[4], end_addr[5], end_addr[6]);
       move.b    6(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    5(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    4(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    3(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    2(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    1(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    (A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _Get7HexDigits
       add.w     #28,A7
       move.l    D0,D2
       bra       main_20
main_22:
; }
; // When writing words, the given address range should be a multiple of 2 bytes (size of a word)
; while ((end_val - start_val + 1) % 2 != 0  && test_config == 2) {
main_23:
       move.l    D2,D0
       sub.l     D3,D0
       addq.l    #1,D0
       move.l    D0,-(A7)
       pea       2
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       beq       main_25
       move.l    -24(A6),D0
       cmp.l     #2,D0
       bne       main_25
; printf("\r\nInvalid address range is too small.. try again");
       pea       @m68kus~1_19.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nEnter ending address(8020000 - 8030000 inclusive): ");
       pea       @m68kus~1_16.L
       jsr       (A3)
       addq.w    #4,A7
; scanf("%s", &end_addr);
       move.l    A2,-(A7)
       pea       @m68kus~1_13.L
       jsr       (A5)
       addq.w    #8,A7
; end_val = Get7HexDigits(end_addr[0], end_addr[1], end_addr[2], end_addr[3], end_addr[4], end_addr[5], end_addr[6]);
       move.b    6(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    5(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    4(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    3(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    2(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    1(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    (A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _Get7HexDigits
       add.w     #28,A7
       move.l    D0,D2
       bra       main_23
main_25:
; }
; // When writing long words, the given address range should be a multiple of 4 bytes (size of a long word)
; while ((end_val - start_val + 1) % 4 != 0 && test_config == 3) {
main_26:
       move.l    D2,D0
       sub.l     D3,D0
       addq.l    #1,D0
       move.l    D0,-(A7)
       pea       4
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       beq       main_28
       move.l    -24(A6),D0
       cmp.l     #3,D0
       bne       main_28
; printf("\r\nInvalid range is too small.. try again");
       pea       @m68kus~1_20.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nEnter ending address(8020000 - 8030000 inclusive): ");
       pea       @m68kus~1_16.L
       jsr       (A3)
       addq.w    #4,A7
; scanf("%s", &end_addr);
       move.l    A2,-(A7)
       pea       @m68kus~1_13.L
       jsr       (A5)
       addq.w    #8,A7
; end_val = Get7HexDigits(end_addr[0], end_addr[1], end_addr[2], end_addr[3], end_addr[4], end_addr[5], end_addr[6]);
       move.b    6(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    5(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    4(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    3(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    2(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    1(A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    (A2),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _Get7HexDigits
       add.w     #28,A7
       move.l    D0,D2
       bra       main_26
main_28:
; }
; printf("\r\nWriting to SRAM ...");
       pea       @m68kus~1_21.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\n............................................................................................................");
       pea       @m68kus~1_22.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\n............................................................................................................");
       pea       @m68kus~1_22.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\n............................................................................................................");
       pea       @m68kus~1_22.L
       jsr       (A3)
       addq.w    #4,A7
; switch (test_pattern) {
       move.l    -20(A6),D0
       subq.l    #1,D0
       blo       main_29
       cmp.l     #4,D0
       bhs.s     main_29
       asl.l     #1,D0
       move.w    main_31(PC,D0.L),D0
       jmp       main_31(PC,D0.W)
main_31:
       dc.w      main_32-main_31
       dc.w      main_33-main_31
       dc.w      main_34-main_31
       dc.w      main_35-main_31
main_32:
; case 1: digit = '5';
       moveq     #53,D4
; break;
       bra.s     main_30
main_33:
; case 2: digit = 'A';
       moveq     #65,D4
; break;
       bra.s     main_30
main_34:
; case 3: digit = 'F';
       moveq     #70,D4
; break;
       bra.s     main_30
main_35:
; case 4: digit = '0';
       moveq     #48,D4
; break;
       bra.s     main_30
main_29:
; default: digit = '5';
       moveq     #53,D4
main_30:
; }
; switch (test_config) {
       move.l    -24(A6),D0
       cmp.l     #2,D0
       beq       main_40
       bgt.s     main_43
       cmp.l     #1,D0
       beq.s     main_39
       bra       main_37
main_43:
       cmp.l     #3,D0
       beq       main_41
       bra       main_37
main_39:
; case 1: FillMemory(start_val, end_val, Get2HexDigits(digit), 1);
       pea       1
       move.l    D0,-(A7)
       ext.w     D4
       ext.l     D4
       move.l    D4,-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       jsr       _FillMemory
       add.w     #16,A7
; break;
       bra       main_38
main_40:
; case 2: FillMemory(start_val, end_val, Get4HexDigits(digit), 2);
       pea       2
       move.l    D0,-(A7)
       ext.w     D4
       ext.l     D4
       move.l    D4,-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       jsr       _FillMemory
       add.w     #16,A7
; break;
       bra       main_38
main_41:
; case 3: FillMemory(start_val, end_val, Get8HexDigits(digit), 3);
       pea       3
       move.l    D0,-(A7)
       ext.w     D4
       ext.l     D4
       move.l    D4,-(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       jsr       _FillMemory
       add.w     #16,A7
; break;
       bra.s     main_38
main_37:
; default: FillMemory(start_val, end_val, Get2HexDigits(digit), 1);;
       pea       1
       move.l    D0,-(A7)
       ext.w     D4
       ext.l     D4
       move.l    D4,-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       jsr       _FillMemory
       add.w     #16,A7
main_38:
; }
; printf("\r\nFinished writing to SRAM .");
       pea       @m68kus~1_23.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nCheck SRAM content");
       pea       @m68kus~1_24.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nReading from SRAM ...");
       pea       @m68kus~1_25.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nPrinting out every 10k location from SRAM ...");
       pea       @m68kus~1_26.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\n............................................................................................................");
       pea       @m68kus~1_22.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\n............................................................................................................");
       pea       @m68kus~1_22.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\n............................................................................................................");
       pea       @m68kus~1_22.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\n....................... begin reading");
       pea       @m68kus~1_27.L
       jsr       (A3)
       addq.w    #4,A7
; switch (test_config) {
       move.l    -24(A6),D0
       cmp.l     #2,D0
       beq       main_47
       bgt.s     main_50
       cmp.l     #1,D0
       beq.s     main_46
       bra       main_44
main_50:
       cmp.l     #3,D0
       beq       main_48
       bra       main_44
main_46:
; case 1: ReadMemory(start_val, end_val, Get2HexDigits(digit), 1);
       pea       1
       move.l    D0,-(A7)
       ext.w     D4
       ext.l     D4
       move.l    D4,-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       jsr       _ReadMemory
       add.w     #16,A7
; break;
       bra       main_45
main_47:
; case 2: ReadMemory(start_val, end_val, Get4HexDigits(digit), 2);
       pea       2
       move.l    D0,-(A7)
       ext.w     D4
       ext.l     D4
       move.l    D4,-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       jsr       _ReadMemory
       add.w     #16,A7
; break;
       bra       main_45
main_48:
; case 3: ReadMemory(start_val, end_val, Get8HexDigits(digit), 3);
       pea       3
       move.l    D0,-(A7)
       ext.w     D4
       ext.l     D4
       move.l    D4,-(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       jsr       _ReadMemory
       add.w     #16,A7
; break;
       bra.s     main_45
main_44:
; default: ReadMemory(start_val, end_val, Get2HexDigits(digit), 1);;
       pea       1
       move.l    D0,-(A7)
       ext.w     D4
       ext.l     D4
       move.l    D4,-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       jsr       _ReadMemory
       add.w     #16,A7
main_45:
; }
; printf("\r\nFinished reading from SRAM ...");
       pea       @m68kus~1_28.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nend of program ...");
       pea       @m68kus~1_29.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\n............................................................................................................");
       pea       @m68kus~1_22.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\n............................................................................................................");
       pea       @m68kus~1_22.L
       jsr       (A3)
       addq.w    #4,A7
; // printf("\r\nEnter Integer: ") ;
; // scanf("%d", &i) ;
; // printf("You entered %d", i) ;
; // sprintf(text, "Hello CPEN 412 Student") ;
; // LCDLine1Message(text) ;
; // printf("\r\nHello CPEN 412 Student\r\nYour LEDs should be Flashing") ;
; // printf("\r\nYour LCD should be displaying") ;
; while(1);
main_51:
       bra       main_51
; // programs should NOT exit as there is nothing to Exit TO !!!!!!
; // There is no OS - just press the reset button to end program and call debug
; }
       section   const
@m68kus~1_1:
       dc.b      13,10,70,105,108,108,105,110,103,32,65,100,100
       dc.b      114,101,115,115,101,115,32,91,36,37,48,56,88
       dc.b      32,45,32,36,37,48,56,88,93,32,119,105,116,104
       dc.b      32,36,37,48,50,88,0
@m68kus~1_2:
       dc.b      13,10,82,101,97,100,105,110,103,32,65,100,100
       dc.b      114,101,115,115,101,115,32,91,36,37,48,56,88
       dc.b      32,45,32,36,37,48,56,88,93,32,102,111,114,32
       dc.b      36,37,48,50,88,0
@m68kus~1_3:
       dc.b      13,10,86,97,108,117,101,32,105,110,99,111,114
       dc.b      114,101,99,116,32,97,116,32,97,100,100,114,101
       dc.b      115,115,101,115,32,36,37,48,56,88,32,46,46,46
       dc.b      32,115,104,111,117,108,100,32,98,101,32,36,37
       dc.b      48,50,88,32,98,117,116,32,102,111,117,110,100
       dc.b      32,36,37,48,50,88,0
@m68kus~1_4:
       dc.b      13,10,86,97,108,117,101,58,32,36,37,48,50,88
       dc.b      32,102,111,117,110,100,32,97,116,32,65,100,100
       dc.b      114,101,115,115,58,32,36,37,48,56,88,0
@m68kus~1_5:
       dc.b      13,10,86,97,108,117,101,58,32,36,37,48,50,88
       dc.b      32,36,37,48,50,88,32,102,111,117,110,100,32
       dc.b      97,116,32,65,100,100,114,101,115,115,58,32,36
       dc.b      37,48,56,88,32,45,32,36,37,48,56,88,0
@m68kus~1_6:
       dc.b      13,10,86,97,108,117,101,58,32,36,37,48,50,88
       dc.b      32,36,37,48,50,88,32,36,37,48,50,88,32,36,37
       dc.b      48,50,88,32,102,111,117,110,100,32,97,116,32
       dc.b      65,100,100,114,101,115,115,58,32,36,37,48,56
       dc.b      88,32,45,32,36,37,48,56,88,0
@m68kus~1_7:
       dc.b      13,10,69,110,116,101,114,32,109,101,109,111
       dc.b      114,121,32,116,101,115,116,32,99,111,110,102
       dc.b      105,103,117,114,97,116,105,111,110,40,49,32
       dc.b      45,32,98,121,116,101,115,44,32,50,32,45,32,119
       dc.b      111,114,100,115,44,32,51,32,45,32,108,111,110
       dc.b      103,32,119,111,114,100,115,41,58,32,0
@m68kus~1_8:
       dc.b      37,100,0
@m68kus~1_9:
       dc.b      13,10,67,111,110,102,105,103,117,114,97,116
       dc.b      105,111,110,32,105,110,118,97,108,105,100,44
       dc.b      32,116,114,121,32,97,103,97,105,110,0
@m68kus~1_10:
       dc.b      13,10,67,104,111,111,115,101,32,98,101,116,119
       dc.b      101,101,110,32,100,105,102,102,101,114,101,110
       dc.b      116,32,109,101,109,111,114,121,32,116,101,115
       dc.b      116,32,112,97,116,116,101,114,110,115,40,49
       dc.b      32,45,32,53,44,32,50,32,45,32,65,44,32,51,32
       dc.b      45,32,70,44,32,52,32,45,32,48,41,58,32,0
@m68kus~1_11:
       dc.b      13,10,80,97,116,116,101,114,110,32,105,110,118
       dc.b      97,108,105,100,44,32,116,114,121,32,97,103,97
       dc.b      105,110,0
@m68kus~1_12:
       dc.b      13,10,69,110,116,101,114,32,115,116,97,114,116
       dc.b      105,110,103,32,97,100,100,114,101,115,115,40
       dc.b      56,48,50,48,48,48,48,32,45,32,56,48,51,48,48
       dc.b      48,48,32,105,110,99,108,117,115,105,118,101
       dc.b      41,58,32,0
@m68kus~1_13:
       dc.b      37,115,0
@m68kus~1_14:
       dc.b      13,10,83,116,97,114,116,105,110,103,32,97,100
       dc.b      100,114,101,115,115,32,111,117,116,32,111,102
       dc.b      32,98,111,117,110,100,115,46,46,32,116,114,121
       dc.b      32,97,103,97,105,110,0
@m68kus~1_15:
       dc.b      13,10,79,100,100,32,115,116,97,114,116,105,110
       dc.b      103,32,97,100,100,114,101,115,115,46,46,32,116
       dc.b      114,121,32,97,103,97,105,110,0
@m68kus~1_16:
       dc.b      13,10,69,110,116,101,114,32,101,110,100,105
       dc.b      110,103,32,97,100,100,114,101,115,115,40,56
       dc.b      48,50,48,48,48,48,32,45,32,56,48,51,48,48,48
       dc.b      48,32,105,110,99,108,117,115,105,118,101,41
       dc.b      58,32,0
@m68kus~1_17:
       dc.b      13,10,69,110,100,105,110,103,32,97,100,100,114
       dc.b      101,115,115,32,111,117,116,32,111,102,32,98
       dc.b      111,117,110,100,115,46,46,32,116,114,121,32
       dc.b      97,103,97,105,110,0
@m68kus~1_18:
       dc.b      13,10,73,110,118,97,108,105,100,32,101,110,100
       dc.b      105,110,103,32,97,100,100,114,101,115,115,46
       dc.b      46,32,116,114,121,32,97,103,97,105,110,0
@m68kus~1_19:
       dc.b      13,10,73,110,118,97,108,105,100,32,97,100,100
       dc.b      114,101,115,115,32,114,97,110,103,101,32,105
       dc.b      115,32,116,111,111,32,115,109,97,108,108,46
       dc.b      46,32,116,114,121,32,97,103,97,105,110,0
@m68kus~1_20:
       dc.b      13,10,73,110,118,97,108,105,100,32,114,97,110
       dc.b      103,101,32,105,115,32,116,111,111,32,115,109
       dc.b      97,108,108,46,46,32,116,114,121,32,97,103,97
       dc.b      105,110,0
@m68kus~1_21:
       dc.b      13,10,87,114,105,116,105,110,103,32,116,111
       dc.b      32,83,82,65,77,32,46,46,46,0
@m68kus~1_22:
       dc.b      13,10,46,46,46,46,46,46,46,46,46,46,46,46,46
       dc.b      46,46,46,46,46,46,46,46,46,46,46,46,46,46,46
       dc.b      46,46,46,46,46,46,46,46,46,46,46,46,46,46,46
       dc.b      46,46,46,46,46,46,46,46,46,46,46,46,46,46,46
       dc.b      46,46,46,46,46,46,46,46,46,46,46,46,46,46,46
       dc.b      46,46,46,46,46,46,46,46,46,46,46,46,46,46,46
       dc.b      46,46,46,46,46,46,46,46,46,46,46,46,46,46,46
       dc.b      46,46,46,46,46,0
@m68kus~1_23:
       dc.b      13,10,70,105,110,105,115,104,101,100,32,119
       dc.b      114,105,116,105,110,103,32,116,111,32,83,82
       dc.b      65,77,32,46,0
@m68kus~1_24:
       dc.b      13,10,67,104,101,99,107,32,83,82,65,77,32,99
       dc.b      111,110,116,101,110,116,0
@m68kus~1_25:
       dc.b      13,10,82,101,97,100,105,110,103,32,102,114,111
       dc.b      109,32,83,82,65,77,32,46,46,46,0
@m68kus~1_26:
       dc.b      13,10,80,114,105,110,116,105,110,103,32,111
       dc.b      117,116,32,101,118,101,114,121,32,49,48,107
       dc.b      32,108,111,99,97,116,105,111,110,32,102,114
       dc.b      111,109,32,83,82,65,77,32,46,46,46,0
@m68kus~1_27:
       dc.b      13,10,46,46,46,46,46,46,46,46,46,46,46,46,46
       dc.b      46,46,46,46,46,46,46,46,46,46,32,98,101,103
       dc.b      105,110,32,114,101,97,100,105,110,103,0
@m68kus~1_28:
       dc.b      13,10,70,105,110,105,115,104,101,100,32,114
       dc.b      101,97,100,105,110,103,32,102,114,111,109,32
       dc.b      83,82,65,77,32,46,46,46,0
@m68kus~1_29:
       dc.b      13,10,101,110,100,32,111,102,32,112,114,111
       dc.b      103,114,97,109,32,46,46,46,0
       section   bss
       xdef      _i
_i:
       ds.b      4
       xdef      _x
_x:
       ds.b      4
       xdef      _y
_y:
       ds.b      4
       xdef      _z
_z:
       ds.b      4
       xdef      _PortA_Count
_PortA_Count:
       ds.b      4
       xdef      _Timer1Count
_Timer1Count:
       ds.b      1
       xdef      _Timer2Count
_Timer2Count:
       ds.b      1
       xdef      _Timer3Count
_Timer3Count:
       ds.b      1
       xdef      _Timer4Count
_Timer4Count:
       ds.b      1
       xref      LDIV
       xref      _strlen
       xref      _scanf
       xref      _scanflush
       xref      _printf

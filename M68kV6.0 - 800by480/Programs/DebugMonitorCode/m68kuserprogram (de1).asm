; C:\CPEN412\GITHUB_STEUP\M68KV6.0 - 800BY480\PROGRAMS\DEBUGMONITORCODE\M68KUSERPROGRAM (DE1).C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
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
; /* SPI declarations*/
; /*************************************************************
; ** SPI Controller registers
; **************************************************************/
; // SPI Registers
; #define SPI_Control         (*(volatile unsigned char *)(0x00408020))
; #define SPI_Status          (*(volatile unsigned char *)(0x00408022))
; #define SPI_Data            (*(volatile unsigned char *)(0x00408024))
; #define SPI_Ext             (*(volatile unsigned char *)(0x00408026))
; #define SPI_CS              (*(volatile unsigned char *)(0x00408028))
; // these two macros enable or disable the flash memory chip enable off SSN_O[7..0]
; // in this case we assume there is only 1 device connected to SSN_O[0] so we can
; // write hex FE to the SPI_CS to enable it (the enable on the flash chip is active low)
; // and write FF to disable it
; #define   Enable_SPI_CS()             SPI_CS = 0xFE
; #define   Disable_SPI_CS()            SPI_CS = 0xFF
; /* end */
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
; void enableWrite(void);
; int WriteSPIChar(int c);
; int WriteSPI(int num);
; void pollSPI(void);
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
; //if (CheckSumPtr)
; //  *CheckSumPtr += i;
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
; //if (CheckSumPtr)
; //  *CheckSumPtr += i;
; return i;
       move.l    D2,D0
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; /* SPI functions */
; /******************************************************************************************
; ** The following code is for the SPI controller
; *******************************************************************************************/
; // return true if the SPI has finished transmitting a byte (to say the Flash chip) return false otherwise
; // this can be used in a polling algorithm to know when the controller is busy or idle.
; int TestForSPITransmitDataComplete(void) {
       xdef      _TestForSPITransmitDataComplete
_TestForSPITransmitDataComplete:
; /* TODO replace 0 below with a test for status register SPIF bit and if set, return true */
; return (SPI_Status >= 0x80);
       move.b    4227106,D0
       and.w     #255,D0
       cmp.w     #128,D0
       blo.s     TestForSPITransmitDataComplete_1
       moveq     #1,D0
       bra.s     TestForSPITransmitDataComplete_2
TestForSPITransmitDataComplete_1:
       clr.l     D0
TestForSPITransmitDataComplete_2:
       rts
; }
; /************************************************************************************
; ** initialises the SPI controller chip to set speed, interrupt capability etc.
; ************************************************************************************/
; void SPI_Init(void)
; {
       xdef      _SPI_Init
_SPI_Init:
; //TODO
; //
; // Program the SPI Control, EXT, CS and Status registers to initialise the SPI controller
; // Don't forget to call this routine from main() before you do anything else with SPI
; //
; // Here are some settings we want to create
; //
; // Control Reg     - interrupts disabled, core enabled, Master mode, Polarity and Phase of clock = [0,0], speed =  divide by 32 = approx 700Khz
; // Ext Reg         - in conjunction with control reg, sets speed above and also sets interrupt flag after every completed transfer (each byte)
; // SPI_CS Reg      - control selection of slave SPI chips via their CS# signals
; // Status Reg      - status of SPI controller chip and used to clear any write collision and interrupt on transmit complete flag
; /* setting up control register */
; if ((SPI_Control & 0x20) == 0)
       move.b    4227104,D0
       and.b     #32,D0
       bne.s     SPI_Init_1
; SPI_Control = 0x53; //writing a 0 to reserved bit at position 5
       move.b    #83,4227104
       bra.s     SPI_Init_2
SPI_Init_1:
; else
; SPI_Control = 0x73; //writing a 1 to reserved bit at position 5
       move.b    #115,4227104
SPI_Init_2:
; /* setting up extension register */
; SPI_Ext = SPI_Ext & 0x3c;
       move.b    4227110,D0
       and.b     #60,D0
       move.b    D0,4227110
; /* enable chip */
; // Enable_SPI_CS();
; Disable_SPI_CS(); //change to disable
       move.b    #255,4227112
; /* setting up status register */
; // SPI_Status = SPI_Status & 0x3f;
; SPI_Status = 0xff;
       move.b    #255,4227106
       rts
; //TODO: figure out what value to write to reserved bits, is there a way to maintain the value of the reerved bit?
; //TODO: How to write to individual bit positions
; //assume data can be changed in such a way such that the reserved bits are not updated, may need to read the data first
; }
; /************************************************************************************
; ** return ONLY when the SPI controller has finished transmitting a byte
; ************************************************************************************/
; void WaitForSPITransmitComplete(void)
; {
       xdef      _WaitForSPITransmitComplete
_WaitForSPITransmitComplete:
; // TODO : poll the status register SPIF bit looking for completion of transmission
; // once transmission is complete, clear the write collision and interrupt on transmit complete flags in the status register (read documentation)
; // just in case they were set
; /* loop for polling */
; while (TestForSPITransmitDataComplete() == 0) {
WaitForSPITransmitComplete_1:
       jsr       _TestForSPITransmitDataComplete
       tst.l     D0
       bne.s     WaitForSPITransmitComplete_3
; //do nothing
; }
       bra       WaitForSPITransmitComplete_1
WaitForSPITransmitComplete_3:
; /* clear bits in the status register */
; // SPI_Status = SPI_Status & 0x3f;
; SPI_Status = 0xff;
       move.b    #255,4227106
       rts
; }
; /************************************************************************************
; ** Write a byte to the SPI flash chip via the controller and returns (reads) whatever was
; ** given back by SPI device at the same time (removes the read byte from the FIFO)
; ************************************************************************************/
; int WriteSPIChar(int c) //change int to char to take into account 1 byte
; {
       xdef      _WriteSPIChar
_WriteSPIChar:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/A2/A3/A4,-(A7)
       lea       _WriteSPI.L,A2
       lea       _printf.L,A3
       lea       _Get2HexDigitsVoid.L,A4
; // todo - write the byte in parameter 'c' to the SPI data register, this will start it transmitting to the flash device
; // wait for completion of transmission
; // return the received data from Flash chip (which may not be relevent depending upon what we are doing)
; // by reading fom the SPI controller Data Register.
; // note however that in order to get data from an SPI slave device (e.g. flash) chip we have to write a dummy byte to it
; //
; // modify '0' below to return back read byte from data register
; //
; int ret, upper, mid, lower, dummy;
; // eraseChip();
; printf("\r\n\nEnter upper byte: ");
       pea       @m68kus~1_1.L
       jsr       (A3)
       addq.w    #4,A7
; upper = Get2HexDigitsVoid();
       jsr       (A4)
       move.l    D0,D4
; printf("\r\n\nUPPER BYTE: %x ", upper);
       move.l    D4,-(A7)
       pea       @m68kus~1_2.L
       jsr       (A3)
       addq.w    #8,A7
; printf("\r\n\nEnter mid byte: ");
       pea       @m68kus~1_3.L
       jsr       (A3)
       addq.w    #4,A7
; mid = Get2HexDigitsVoid();
       jsr       (A4)
       move.l    D0,D3
; printf("\r\n\nMID BYTE: %x ", mid);
       move.l    D3,-(A7)
       pea       @m68kus~1_4.L
       jsr       (A3)
       addq.w    #8,A7
; printf("\r\n\nEnter lower byte: ");
       pea       @m68kus~1_5.L
       jsr       (A3)
       addq.w    #4,A7
; lower = Get2HexDigitsVoid();
       jsr       (A4)
       move.l    D0,D2
; printf("\r\n\nLOWER BYTE: %x ", lower);
       move.l    D2,-(A7)
       pea       @m68kus~1_6.L
       jsr       (A3)
       addq.w    #8,A7
; enableWrite();
       jsr       _enableWrite
; //5: write to flash
; printf("5: write to flash \n\n");
       pea       @m68kus~1_7.L
       jsr       (A3)
       addq.w    #4,A7
; Enable_SPI_CS(); //enable cs#
       move.b    #254,4227112
; WriteSPI(0x02);
       pea       2
       jsr       (A2)
       addq.w    #4,A7
; WriteSPI(upper);
       move.l    D4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPI(mid);
       move.l    D3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPI(lower);
       move.l    D2,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPI(c);
       move.l    8(A6),-(A7)
       jsr       (A2)
       addq.w    #4,A7
; Disable_SPI_CS(); //disable cs#
       move.b    #255,4227112
; pollSPI();
       jsr       _pollSPI
; //7: reading flash chip for verification
; printf("7: reading flash chip for verification \n\n");
       pea       @m68kus~1_8.L
       jsr       (A3)
       addq.w    #4,A7
; Enable_SPI_CS(); //enable cs#
       move.b    #254,4227112
; WriteSPI(0x03);
       pea       3
       jsr       (A2)
       addq.w    #4,A7
; WriteSPI(upper);
       move.l    D4,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPI(mid);
       move.l    D3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPI(lower);
       move.l    D2,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; /* collecting data into var */
; ret = WriteSPI(0xee);
       pea       238
       jsr       (A2)
       addq.w    #4,A7
       move.l    D0,D5
; printf("\r\n\nret: %x ", ret);
       move.l    D5,-(A7)
       pea       @m68kus~1_9.L
       jsr       (A3)
       addq.w    #8,A7
; Disable_SPI_CS(); // disable cs#
       move.b    #255,4227112
; return ret;
       move.l    D5,D0
       movem.l   (A7)+,D2/D3/D4/D5/A2/A3/A4
       unlk      A6
       rts
; }
; int readSPI(void) {
       xdef      _readSPI
_readSPI:
       link      A6,#-4
       movem.l   D2/D3/D4/D5/A2/A3/A4,-(A7)
       lea       _printf.L,A2
       lea       _WriteSPI.L,A3
       lea       _Get2HexDigitsVoid.L,A4
; int ret, upper, mid, lower, dummy;
; printf("\r\n\nEnter upper byte:");
       pea       @m68kus~1_10.L
       jsr       (A2)
       addq.w    #4,A7
; upper = Get2HexDigitsVoid();
       jsr       (A4)
       move.l    D0,D5
; printf("\r\n\nUPPER BYTE: %x", upper);
       move.l    D5,-(A7)
       pea       @m68kus~1_11.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n\nEnter mid byte:");
       pea       @m68kus~1_12.L
       jsr       (A2)
       addq.w    #4,A7
; mid = Get2HexDigitsVoid();
       jsr       (A4)
       move.l    D0,D4
; printf("\r\n\nMID BYTE: %x", mid);
       move.l    D4,-(A7)
       pea       @m68kus~1_13.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n\nEnter lower byte:");
       pea       @m68kus~1_14.L
       jsr       (A2)
       addq.w    #4,A7
; lower = Get2HexDigitsVoid();
       jsr       (A4)
       move.l    D0,D3
; printf("\r\n\nLOWER BYTE: %x", lower);
       move.l    D3,-(A7)
       pea       @m68kus~1_15.L
       jsr       (A2)
       addq.w    #8,A7
; // reading flash chip for verification
; printf("\r\nReading flash chip for verification");
       pea       @m68kus~1_16.L
       jsr       (A2)
       addq.w    #4,A7
; Enable_SPI_CS(); //enable cs#
       move.b    #254,4227112
; WriteSPI(0x03);
       pea       3
       jsr       (A3)
       addq.w    #4,A7
; WriteSPI(upper);
       move.l    D5,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; WriteSPI(mid);
       move.l    D4,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; WriteSPI(lower);
       move.l    D3,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; /* collecting data into var */
; ret = WriteSPI(0xee);
       pea       238
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,D2
; printf("\r\n\nret: %x ", ret);
       move.l    D2,-(A7)
       pea       @m68kus~1_9.L
       jsr       (A2)
       addq.w    #8,A7
; Disable_SPI_CS(); // disable cs#
       move.b    #255,4227112
; return ret;
       move.l    D2,D0
       movem.l   (A7)+,D2/D3/D4/D5/A2/A3/A4
       unlk      A6
       rts
; }
; void enableWrite(void) {
       xdef      _enableWrite
_enableWrite:
; //enable write
; Enable_SPI_CS(); //enable cs#
       move.b    #254,4227112
; WriteSPI(0x06);
       pea       6
       jsr       _WriteSPI
       addq.w    #4,A7
; Disable_SPI_CS(); //disable cs#
       move.b    #255,4227112
       rts
; }
; void pollSPI(void) {
       xdef      _pollSPI
_pollSPI:
       movem.l   D2/A2,-(A7)
       lea       _WriteSPI.L,A2
; int status;
; //poll flash chip to see if rdy
; printf("\r\nPolling flash chip to see if ready \n\n");
       pea       @m68kus~1_17.L
       jsr       _printf
       addq.w    #4,A7
; Enable_SPI_CS(); //enable cs#
       move.b    #254,4227112
; WriteSPI(0x05);
       pea       5
       jsr       (A2)
       addq.w    #4,A7
; status = WriteSPI(0xee);
       pea       238
       jsr       (A2)
       addq.w    #4,A7
       move.l    D0,D2
; while (status & 0x01 == 1) {
pollSPI_1:
       move.l    D2,D0
       and.l     #1,D0
       beq.s     pollSPI_3
; status = WriteSPI(0xee);
       pea       238
       jsr       (A2)
       addq.w    #4,A7
       move.l    D0,D2
       bra       pollSPI_1
pollSPI_3:
; }
; Disable_SPI_CS(); // disable cs#
       move.b    #255,4227112
       movem.l   (A7)+,D2/A2
       rts
; }
; void eraseChip(void) {
       xdef      _eraseChip
_eraseChip:
; //enable write
; enableWrite();
       jsr       _enableWrite
; //erase chip
; printf("\r\nErase chip");
       pea       @m68kus~1_18.L
       jsr       _printf
       addq.w    #4,A7
; Enable_SPI_CS(); //enable cs#
       move.b    #254,4227112
; WriteSPI(0xc7);
       pea       199
       jsr       _WriteSPI
       addq.w    #4,A7
; Disable_SPI_CS(); // disable cs#
       move.b    #255,4227112
; //poll spi
; pollSPI();
       jsr       _pollSPI
       rts
; }
; int WriteSPI(int num) {
       xdef      _WriteSPI
_WriteSPI:
       link      A6,#0
; SPI_Data = num;
       move.l    8(A6),D0
       move.b    D0,4227108
; WaitForSPITransmitComplete();
       jsr       _WaitForSPITransmitComplete
; return SPI_Data;
       move.b    4227108,D0
       and.l     #255,D0
       unlk      A6
       rts
; }
; void menueSPI(void) {
       xdef      _menueSPI
_menueSPI:
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _printf.L,A2
; int option, val_to_pass, ret;
; // char pat;
; while (1) {
menueSPI_1:
; scanflush();
       jsr       _scanflush
; printf("\r\n\nEnter SPI operation(1 - Erase Chip, 2 - Write to SPI, 3 - Read from SPI): ");
       pea       @m68kus~1_19.L
       jsr       (A2)
       addq.w    #4,A7
; option = xtod(_getch());
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       and.l     #255,D0
       move.l    D0,D4
; printf("\r\n\nSPI operation: %x ", option);
       move.l    D4,-(A7)
       pea       @m68kus~1_20.L
       jsr       (A2)
       addq.w    #8,A7
; switch (option) {
       cmp.l     #2,D4
       beq.s     menueSPI_7
       bgt.s     menueSPI_10
       cmp.l     #1,D4
       beq.s     menueSPI_6
       bra       menueSPI_4
menueSPI_10:
       cmp.l     #3,D4
       beq       menueSPI_8
       bra       menueSPI_4
menueSPI_6:
; case 1:
; printf("\r\nChip erase operation selected");
       pea       @m68kus~1_21.L
       jsr       (A2)
       addq.w    #4,A7
; eraseChip();
       jsr       _eraseChip
; printf("\r\nEnd of erase operation ...");
       pea       @m68kus~1_22.L
       jsr       (A2)
       addq.w    #4,A7
; break;
       bra       menueSPI_5
menueSPI_7:
; case 2:
; printf("\r\n\nWrite operation selected \n\n");
       pea       @m68kus~1_23.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n\nEnter a value for write: ");
       pea       @m68kus~1_24.L
       jsr       (A2)
       addq.w    #4,A7
; val_to_pass = Get2HexDigitsVoid();
       jsr       _Get2HexDigitsVoid
       move.l    D0,D3
; printf("\r\nValue to write: %x", val_to_pass);
       move.l    D3,-(A7)
       pea       @m68kus~1_25.L
       jsr       (A2)
       addq.w    #8,A7
; ret = WriteSPIChar(val_to_pass);
       move.l    D3,-(A7)
       jsr       _WriteSPIChar
       addq.w    #4,A7
       move.l    D0,D2
; printf("\r\nValue returned: %x", ret);
       move.l    D2,-(A7)
       pea       @m68kus~1_26.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\nend of write operation ...");
       pea       @m68kus~1_27.L
       jsr       (A2)
       addq.w    #4,A7
; break;
       bra       menueSPI_5
menueSPI_8:
; case 3:
; printf("\r\n\nRead operation selected");
       pea       @m68kus~1_28.L
       jsr       (A2)
       addq.w    #4,A7
; ret = readSPI();
       jsr       _readSPI
       move.l    D0,D2
; printf("\r\n\nValue returned: %x ", ret);
       move.l    D2,-(A7)
       pea       @m68kus~1_29.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n\nend of read operation ...");
       pea       @m68kus~1_30.L
       jsr       (A2)
       addq.w    #4,A7
; break;
       bra.s     menueSPI_5
menueSPI_4:
; default:
; printf("\r\n\nInvalid operation ...");
       pea       @m68kus~1_31.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n\nTry again!!!!!");
       pea       @m68kus~1_32.L
       jsr       (A2)
       addq.w    #4,A7
menueSPI_5:
       bra       menueSPI_1
; }
; }
; }
; void executeSPI(void) {
       xdef      _executeSPI
_executeSPI:
; printf("\r\nIntializing SPI\n");
       pea       @m68kus~1_33.L
       jsr       _printf
       addq.w    #4,A7
; SPI_Init();
       jsr       _SPI_Init
; menueSPI();
       jsr       _menueSPI
       rts
; }
; void readID(void) {
       xdef      _readID
_readID:
       link      A6,#-16
       movem.l   A2/A3,-(A7)
       lea       _WriteSPI.L,A2
       lea       _printf.L,A3
; int man, dev, dev2;
; int dummy;
; printf("READING ID !!!!!!  \n\n");
       pea       @m68kus~1_34.L
       jsr       (A3)
       addq.w    #4,A7
; Enable_SPI_CS(); //enable cs#
       move.b    #254,4227112
; WriteSPI(0x90);
       pea       144
       jsr       (A2)
       addq.w    #4,A7
; WriteSPI(0x00);
       clr.l     -(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPI(0x00);
       clr.l     -(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPI(0x00);
       clr.l     -(A7)
       jsr       (A2)
       addq.w    #4,A7
; man = WriteSPI(0xee);
       pea       238
       jsr       (A2)
       addq.w    #4,A7
       move.l    D0,-16(A6)
; dev = WriteSPI(0xee);
       pea       238
       jsr       (A2)
       addq.w    #4,A7
       move.l    D0,-12(A6)
; Disable_SPI_CS(); //disable cs#
       move.b    #255,4227112
; printf("\r\n\nMan: %x ", man);
       move.l    -16(A6),-(A7)
       pea       @m68kus~1_35.L
       jsr       (A3)
       addq.w    #8,A7
; printf("\r\n\nDev: %x ", dev);
       move.l    -12(A6),-(A7)
       pea       @m68kus~1_36.L
       jsr       (A3)
       addq.w    #8,A7
       movem.l   (A7)+,A2/A3
       unlk      A6
       rts
; }
; /* end */
; /* other spare functions */
; int Get2HexDigitsVoid(void)
; {
       xdef      _Get2HexDigitsVoid
_Get2HexDigitsVoid:
       move.l    D2,-(A7)
; register int i = (xtod(_getch()) << 4) | (xtod(_getch()));
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       and.l     #255,D0
       asl.l     #4,D0
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       __getch
       move.l    (A7)+,D1
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
       rts
; }
; /******************************************************************************************************************************
; * Start of user program
; ******************************************************************************************************************************/
; void main()
; {
       xdef      _main
_main:
       link      A6,#-212
       move.l    A2,-(A7)
       lea       _InstallExceptionHandler.L,A2
; unsigned int row, i=0, count=0, counter1=1;
       clr.l     -208(A6)
       clr.l     -204(A6)
       move.l    #1,-200(A6)
; char c, text[150] ;
; int PassFailFlag = 1 ;
       move.l    #1,-44(A6)
; int test_config=0;
       clr.l     -40(A6)
; int test_pattern=0;
       clr.l     -36(A6)
; char start_addr[7];
; int start_val = 0;
       clr.l     -24(A6)
; char end_addr[7];
; int end_val = 0;
       clr.l     -12(A6)
; int val_to_pass, ret;
; i = x = y = z = PortA_Count =0;
       clr.l     _PortA_Count.L
       clr.l     _z.L
       clr.l     _y.L
       clr.l     _x.L
       clr.l     -208(A6)
; Timer1Count = Timer2Count = Timer3Count = Timer4Count = 0;
       clr.b     _Timer4Count.L
       clr.b     _Timer3Count.L
       clr.b     _Timer2Count.L
       clr.b     _Timer1Count.L
; InstallExceptionHandler(PIA_ISR, 25) ;          // install interrupt handler for PIAs 1 and 2 on level 1 IRQ
       pea       25
       pea       _PIA_ISR.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(ACIA_ISR, 26) ;		    // install interrupt handler for ACIA on level 2 IRQ
       pea       26
       pea       _ACIA_ISR.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(Timer_ISR, 27) ;		// install interrupt handler for Timers 1-4 on level 3 IRQ
       pea       27
       pea       _Timer_ISR.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(Key2PressISR, 28) ;	    // install interrupt handler for Key Press 2 on DE1 board for level 4 IRQ
       pea       28
       pea       _Key2PressISR.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(Key1PressISR, 29) ;	    // install interrupt handler for Key Press 1 on DE1 board for level 5 IRQ
       pea       29
       pea       _Key1PressISR.L
       jsr       (A2)
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
; * SPI Program HERE
; */
; executeSPI();
       jsr       _executeSPI
; while(1)
main_1:
       bra       main_1
; ;
; // programs should NOT exit as there is nothing to Exit TO !!!!!!
; // There is no OS - just press the reset button to end program and call debug
; }
       section   const
@m68kus~1_1:
       dc.b      13,10,10,69,110,116,101,114,32,117,112,112,101
       dc.b      114,32,98,121,116,101,58,32,0
@m68kus~1_2:
       dc.b      13,10,10,85,80,80,69,82,32,66,89,84,69,58,32
       dc.b      37,120,32,0
@m68kus~1_3:
       dc.b      13,10,10,69,110,116,101,114,32,109,105,100,32
       dc.b      98,121,116,101,58,32,0
@m68kus~1_4:
       dc.b      13,10,10,77,73,68,32,66,89,84,69,58,32,37,120
       dc.b      32,0
@m68kus~1_5:
       dc.b      13,10,10,69,110,116,101,114,32,108,111,119,101
       dc.b      114,32,98,121,116,101,58,32,0
@m68kus~1_6:
       dc.b      13,10,10,76,79,87,69,82,32,66,89,84,69,58,32
       dc.b      37,120,32,0
@m68kus~1_7:
       dc.b      53,58,32,119,114,105,116,101,32,116,111,32,102
       dc.b      108,97,115,104,32,10,10,0
@m68kus~1_8:
       dc.b      55,58,32,114,101,97,100,105,110,103,32,102,108
       dc.b      97,115,104,32,99,104,105,112,32,102,111,114
       dc.b      32,118,101,114,105,102,105,99,97,116,105,111
       dc.b      110,32,10,10,0
@m68kus~1_9:
       dc.b      13,10,10,114,101,116,58,32,37,120,32,0
@m68kus~1_10:
       dc.b      13,10,10,69,110,116,101,114,32,117,112,112,101
       dc.b      114,32,98,121,116,101,58,0
@m68kus~1_11:
       dc.b      13,10,10,85,80,80,69,82,32,66,89,84,69,58,32
       dc.b      37,120,0
@m68kus~1_12:
       dc.b      13,10,10,69,110,116,101,114,32,109,105,100,32
       dc.b      98,121,116,101,58,0
@m68kus~1_13:
       dc.b      13,10,10,77,73,68,32,66,89,84,69,58,32,37,120
       dc.b      0
@m68kus~1_14:
       dc.b      13,10,10,69,110,116,101,114,32,108,111,119,101
       dc.b      114,32,98,121,116,101,58,0
@m68kus~1_15:
       dc.b      13,10,10,76,79,87,69,82,32,66,89,84,69,58,32
       dc.b      37,120,0
@m68kus~1_16:
       dc.b      13,10,82,101,97,100,105,110,103,32,102,108,97
       dc.b      115,104,32,99,104,105,112,32,102,111,114,32
       dc.b      118,101,114,105,102,105,99,97,116,105,111,110
       dc.b      0
@m68kus~1_17:
       dc.b      13,10,80,111,108,108,105,110,103,32,102,108
       dc.b      97,115,104,32,99,104,105,112,32,116,111,32,115
       dc.b      101,101,32,105,102,32,114,101,97,100,121,32
       dc.b      10,10,0
@m68kus~1_18:
       dc.b      13,10,69,114,97,115,101,32,99,104,105,112,0
@m68kus~1_19:
       dc.b      13,10,10,69,110,116,101,114,32,83,80,73,32,111
       dc.b      112,101,114,97,116,105,111,110,40,49,32,45,32
       dc.b      69,114,97,115,101,32,67,104,105,112,44,32,50
       dc.b      32,45,32,87,114,105,116,101,32,116,111,32,83
       dc.b      80,73,44,32,51,32,45,32,82,101,97,100,32,102
       dc.b      114,111,109,32,83,80,73,41,58,32,0
@m68kus~1_20:
       dc.b      13,10,10,83,80,73,32,111,112,101,114,97,116
       dc.b      105,111,110,58,32,37,120,32,0
@m68kus~1_21:
       dc.b      13,10,67,104,105,112,32,101,114,97,115,101,32
       dc.b      111,112,101,114,97,116,105,111,110,32,115,101
       dc.b      108,101,99,116,101,100,0
@m68kus~1_22:
       dc.b      13,10,69,110,100,32,111,102,32,101,114,97,115
       dc.b      101,32,111,112,101,114,97,116,105,111,110,32
       dc.b      46,46,46,0
@m68kus~1_23:
       dc.b      13,10,10,87,114,105,116,101,32,111,112,101,114
       dc.b      97,116,105,111,110,32,115,101,108,101,99,116
       dc.b      101,100,32,10,10,0
@m68kus~1_24:
       dc.b      13,10,10,69,110,116,101,114,32,97,32,118,97
       dc.b      108,117,101,32,102,111,114,32,119,114,105,116
       dc.b      101,58,32,0
@m68kus~1_25:
       dc.b      13,10,86,97,108,117,101,32,116,111,32,119,114
       dc.b      105,116,101,58,32,37,120,0
@m68kus~1_26:
       dc.b      13,10,86,97,108,117,101,32,114,101,116,117,114
       dc.b      110,101,100,58,32,37,120,0
@m68kus~1_27:
       dc.b      13,10,101,110,100,32,111,102,32,119,114,105
       dc.b      116,101,32,111,112,101,114,97,116,105,111,110
       dc.b      32,46,46,46,0
@m68kus~1_28:
       dc.b      13,10,10,82,101,97,100,32,111,112,101,114,97
       dc.b      116,105,111,110,32,115,101,108,101,99,116,101
       dc.b      100,0
@m68kus~1_29:
       dc.b      13,10,10,86,97,108,117,101,32,114,101,116,117
       dc.b      114,110,101,100,58,32,37,120,32,0
@m68kus~1_30:
       dc.b      13,10,10,101,110,100,32,111,102,32,114,101,97
       dc.b      100,32,111,112,101,114,97,116,105,111,110,32
       dc.b      46,46,46,0
@m68kus~1_31:
       dc.b      13,10,10,73,110,118,97,108,105,100,32,111,112
       dc.b      101,114,97,116,105,111,110,32,46,46,46,0
@m68kus~1_32:
       dc.b      13,10,10,84,114,121,32,97,103,97,105,110,33
       dc.b      33,33,33,33,0
@m68kus~1_33:
       dc.b      13,10,73,110,116,105,97,108,105,122,105,110
       dc.b      103,32,83,80,73,10,0
@m68kus~1_34:
       dc.b      82,69,65,68,73,78,71,32,73,68,32,33,33,33,33
       dc.b      33,33,32,32,10,10,0
@m68kus~1_35:
       dc.b      13,10,10,77,97,110,58,32,37,120,32,0
@m68kus~1_36:
       dc.b      13,10,10,68,101,118,58,32,37,120,32,0
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
       xref      _scanflush
       xref      _printf

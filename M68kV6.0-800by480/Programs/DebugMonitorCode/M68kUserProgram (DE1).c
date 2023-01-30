#include <stdio.h>
#include <string.h>
#include <ctype.h>


//IMPORTANT
//
// Uncomment one of the two #defines below
// Define StartOfExceptionVectorTable as 08030000 if running programs from sram or
// 0B000000 for running programs from dram
//
// In your labs, you will initially start by designing a system with SRam and later move to
// Dram, so these constants will need to be changed based on the version of the system you have
// building
//
// The working 68k system SOF file posted on canvas that you can use for your pre-lab
// is based around Dram so #define accordingly before building

#define StartOfExceptionVectorTable 0x08030000
//#define StartOfExceptionVectorTable 0x0B000000

/**********************************************************************************************
**	Parallel port addresses
**********************************************************************************************/

#define PortA   *(volatile unsigned char *)(0x00400000)
#define PortB   *(volatile unsigned char *)(0x00400002)
#define PortC   *(volatile unsigned char *)(0x00400004)
#define PortD   *(volatile unsigned char *)(0x00400006)
#define PortE   *(volatile unsigned char *)(0x00400008)

/*********************************************************************************************
**	Hex 7 seg displays port addresses
*********************************************************************************************/

#define HEX_A        *(volatile unsigned char *)(0x00400010)
#define HEX_B        *(volatile unsigned char *)(0x00400012)
#define HEX_C        *(volatile unsigned char *)(0x00400014)    // de2 only
#define HEX_D        *(volatile unsigned char *)(0x00400016)    // de2 only

/**********************************************************************************************
**	LCD display port addresses
**********************************************************************************************/

#define LCDcommand   *(volatile unsigned char *)(0x00400020)
#define LCDdata      *(volatile unsigned char *)(0x00400022)

/********************************************************************************************
**	Timer Port addresses
*********************************************************************************************/

#define Timer1Data      *(volatile unsigned char *)(0x00400030)
#define Timer1Control   *(volatile unsigned char *)(0x00400032)
#define Timer1Status    *(volatile unsigned char *)(0x00400032)

#define Timer2Data      *(volatile unsigned char *)(0x00400034)
#define Timer2Control   *(volatile unsigned char *)(0x00400036)
#define Timer2Status    *(volatile unsigned char *)(0x00400036)

#define Timer3Data      *(volatile unsigned char *)(0x00400038)
#define Timer3Control   *(volatile unsigned char *)(0x0040003A)
#define Timer3Status    *(volatile unsigned char *)(0x0040003A)

#define Timer4Data      *(volatile unsigned char *)(0x0040003C)
#define Timer4Control   *(volatile unsigned char *)(0x0040003E)
#define Timer4Status    *(volatile unsigned char *)(0x0040003E)

/*********************************************************************************************
**	RS232 port addresses
*********************************************************************************************/

#define RS232_Control     *(volatile unsigned char *)(0x00400040)
#define RS232_Status      *(volatile unsigned char *)(0x00400040)
#define RS232_TxData      *(volatile unsigned char *)(0x00400042)
#define RS232_RxData      *(volatile unsigned char *)(0x00400042)
#define RS232_Baud        *(volatile unsigned char *)(0x00400044)

/*********************************************************************************************
**	PIA 1 and 2 port addresses
*********************************************************************************************/

#define PIA1_PortA_Data     *(volatile unsigned char *)(0x00400050)         // combined data and data direction register share same address
#define PIA1_PortA_Control *(volatile unsigned char *)(0x00400052)
#define PIA1_PortB_Data     *(volatile unsigned char *)(0x00400054)         // combined data and data direction register share same address
#define PIA1_PortB_Control *(volatile unsigned char *)(0x00400056)

#define PIA2_PortA_Data     *(volatile unsigned char *)(0x00400060)         // combined data and data direction register share same address
#define PIA2_PortA_Control *(volatile unsigned char *)(0x00400062)
#define PIA2_PortB_data     *(volatile unsigned char *)(0x00400064)         // combined data and data direction register share same address
#define PIA2_PortB_Control *(volatile unsigned char *)(0x00400066)


/*********************************************************************************************************************************
(( DO NOT initialise global variables here, do it main even if you want 0
(( it's a limitation of the compiler
(( YOU HAVE BEEN WARNED
*********************************************************************************************************************************/

unsigned int i, x, y, z, PortA_Count;
unsigned char Timer1Count, Timer2Count, Timer3Count, Timer4Count ;

/*******************************************************************************************
** Function Prototypes
*******************************************************************************************/
void Wait1ms(void);
void Wait3ms(void);
void Init_LCD(void) ;
void LCDOutchar(int c);
void LCDOutMess(char *theMessage);
void LCDClearln(void);
void LCDline1Message(char *theMessage);
void LCDline2Message(char *theMessage);
int sprintf(char *out, const char *format, ...) ;
void ReadMemory(char* StartRamPtr, char* EndRamPtr, unsigned char FillData, int config);
void FillMemory(char* StartRamPtr, char* EndRamPtr, unsigned char FillData, int config);
int Get7HexDigits(char one, char two, char three, char four, char five, char six, char seven);
int Get8HexDigits(char pat);
int Get4HexDigits(char pat);
int Get2HexDigits(char pat);
char xtod(int c);

/*****************************************************************************************
**	Interrupt service routine for Timers
**
**  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
**  out which timer is producing the interrupt
**
*****************************************************************************************/

void Timer_ISR()
{
   	if(Timer1Status == 1) {         // Did Timer 1 produce the Interrupt?
   	    Timer1Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
   	    PortA = Timer1Count++ ;     // increment an LED count on PortA with each tick of Timer 1
   	}

  	if(Timer2Status == 1) {         // Did Timer 2 produce the Interrupt?
   	    Timer2Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
   	    PortC = Timer2Count++ ;     // increment an LED count on PortC with each tick of Timer 2
   	}

   	if(Timer3Status == 1) {         // Did Timer 3 produce the Interrupt?
   	    Timer3Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
        HEX_A = Timer3Count++ ;     // increment a HEX count on Port HEX_A with each tick of Timer 3
   	}

   	if(Timer4Status == 1) {         // Did Timer 4 produce the Interrupt?
   	    Timer4Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
        HEX_B = Timer4Count++ ;     // increment a HEX count on HEX_B with each tick of Timer 4
   	}
}

/*****************************************************************************************
**	Interrupt service routine for ACIA. This device has it's own dedicate IRQ level
**  Add your code here to poll Status register and clear interrupt
*****************************************************************************************/

void ACIA_ISR()
{}

/***************************************************************************************
**	Interrupt service routine for PIAs 1 and 2. These devices share an IRQ level
**  Add your code here to poll Status register and clear interrupt
*****************************************************************************************/

void PIA_ISR()
{}

/***********************************************************************************
**	Interrupt service routine for Key 2 on DE1 board. Add your own response here
************************************************************************************/
void Key2PressISR()
{}

/***********************************************************************************
**	Interrupt service routine for Key 1 on DE1 board. Add your own response here
************************************************************************************/
void Key1PressISR()
{}

/************************************************************************************
**   Delay Subroutine to give the 68000 something useless to do to waste 1 mSec
************************************************************************************/
void Wait1ms(void)
{
    int  i ;
    for(i = 0; i < 1000; i ++)
        ;
}

/************************************************************************************
**  Subroutine to give the 68000 something useless to do to waste 3 mSec
**************************************************************************************/
void Wait3ms(void)
{
    int i ;
    for(i = 0; i < 3; i++)
        Wait1ms() ;
}

/*********************************************************************************************
**  Subroutine to initialise the LCD display by writing some commands to the LCD internal registers
**  Sets it for parallel port and 2 line display mode (if I recall correctly)
*********************************************************************************************/
void Init_LCD(void)
{
    LCDcommand = 0x0c ;
    Wait3ms() ;
    LCDcommand = 0x38 ;
    Wait3ms() ;
}

/*********************************************************************************************
**  Subroutine to initialise the RS232 Port by writing some commands to the internal registers
*********************************************************************************************/
void Init_RS232(void)
{
    RS232_Control = 0x15 ; //  %00010101 set up 6850 uses divide by 16 clock, set RTS low, 8 bits no parity, 1 stop bit, transmitter interrupt disabled
    RS232_Baud = 0x1 ;      // program baud rate generator 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
}

/*********************************************************************************************************
**  Subroutine to provide a low level output function to 6850 ACIA
**  This routine provides the basic functionality to output a single character to the serial Port
**  to allow the board to communicate with HyperTerminal Program
**
**  NOTE you do not call this function directly, instead you call the normal putchar() function
**  which in turn calls _putch() below). Other functions like puts(), printf() call putchar() so will
**  call _putch() also
*********************************************************************************************************/

int _putch( int c)
{
    while((RS232_Status & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
        ;

    RS232_TxData = (c & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
    return c ;                                              // putchar() expects the character to be returned
}

/*********************************************************************************************************
**  Subroutine to provide a low level input function to 6850 ACIA
**  This routine provides the basic functionality to input a single character from the serial Port
**  to allow the board to communicate with HyperTerminal Program Keyboard (your PC)
**
**  NOTE you do not call this function directly, instead you call the normal getchar() function
**  which in turn calls _getch() below). Other functions like gets(), scanf() call getchar() so will
**  call _getch() also
*********************************************************************************************************/
int _getch( void )
{
    char c ;
    while((RS232_Status & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
        ;

    return (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character
}

/******************************************************************************
**  Subroutine to output a single character to the 2 row LCD display
**  It is assumed the character is an ASCII code and it will be displayed at the
**  current cursor position
*******************************************************************************/
void LCDOutchar(int c)
{
    LCDdata = (char)(c);
    Wait1ms() ;
}

/**********************************************************************************
*subroutine to output a message at the current cursor position of the LCD display
************************************************************************************/
void LCDOutMessage(char *theMessage)
{
    char c ;
    while((c = *theMessage++) != 0)     // output characters from the string until NULL
        LCDOutchar(c) ;
}

/******************************************************************************
*subroutine to clear the line by issuing 24 space characters
*******************************************************************************/
void LCDClearln(void)
{
    int i ;
    for(i = 0; i < 24; i ++)
        LCDOutchar(' ') ;       // write a space char to the LCD display
}

/******************************************************************************
**  Subroutine to move the LCD cursor to the start of line 1 and clear that line
*******************************************************************************/
void LCDLine1Message(char *theMessage)
{
    LCDcommand = 0x80 ;
    Wait3ms();
    LCDClearln() ;
    LCDcommand = 0x80 ;
    Wait3ms() ;
    LCDOutMessage(theMessage) ;
}

/******************************************************************************
**  Subroutine to move the LCD cursor to the start of line 2 and clear that line
*******************************************************************************/
void LCDLine2Message(char *theMessage)
{
    LCDcommand = 0xC0 ;
    Wait3ms();
    LCDClearln() ;
    LCDcommand = 0xC0 ;
    Wait3ms() ;
    LCDOutMessage(theMessage) ;
}

/*********************************************************************************************************************************
**  IMPORTANT FUNCTION
**  This function install an exception handler so you can capture and deal with any 68000 exception in your program
**  You pass it the name of a function in your code that will get called in response to the exception (as the 1st parameter)
**  and in the 2nd parameter, you pass it the exception number that you want to take over (see 68000 exceptions for details)
**  Calling this function allows you to deal with Interrupts for example
***********************************************************************************************************************************/

void InstallExceptionHandler( void (*function_ptr)(), int level)
{
    volatile long int *RamVectorAddress = (volatile long int *)(StartOfExceptionVectorTable) ;   // pointer to the Ram based interrupt vector table created in Cstart in debug monitor

    RamVectorAddress[level] = (long int *)(function_ptr);                       // install the address of our function into the exception table
}

/*
* Support functions for changing memory contents
*/

// converts hex char to 4 bit binary equiv in range 0000-1111 (0-F)
// char assumed to be a valid hex char 0-9, a-f, A-F

char xtod(int c)
{
    if ((char)(c) <= (char)('9'))
        return c - (char)(0x30);    // 0 - 9 = 0x30 - 0x39 so convert to number by sutracting 0x30
    else if ((char)(c) > (char)('F'))    // assume lower case
        return c - (char)(0x57);    // a-f = 0x61-66 so needs to be converted to 0x0A - 0x0F so subtract 0x57
    else
        return c - (char)(0x37);    // A-F = 0x41-46 so needs to be converted to 0x0A - 0x0F so subtract 0x37
}

int Get2HexDigits(char pat)
{
    register int i = (xtod(pat) << 4) | (xtod(pat));

   // if (CheckSumPtr)
     //   *CheckSumPtr += i;

    return i;
}

int Get4HexDigits(char pat)
{
    return (Get2HexDigits(pat) << 8) | (Get2HexDigits(pat));
}

int Get8HexDigits(char pat)
{
    return (Get4HexDigits(pat) << 16) | (Get4HexDigits(pat));
}

int Get7HexDigits(char one, char two, char three, char four, char five, char six, char seven)
{
    register int i = (xtod(one) << 24) | (xtod(two) << 20) | (xtod(three) << 16) | (xtod(four) << 12) | (xtod(five) << 8) | (xtod(six) << 4) | (xtod(seven));

    //if (CheckSumPtr)
      //  *CheckSumPtr += i;

    return i;
}

void FillMemory(char* StartRamPtr, char* EndRamPtr, unsigned char FillData, int config)
{
    char* start = StartRamPtr;

    ////char* StartRamPtr, * EndRamPtr;
    ////unsigned char FillData;

    //printf("\r\nFill Memory Block");
    //printf("\r\nEnter Start Address: ");
    //StartRamPtr = Get8HexDigits(0);

    //printf("\r\nEnter End Address: ");
    //EndRamPtr = Get8HexDigits(0);

    //printf("\r\nEnter Fill Data: ");
    //FillData = Get2HexDigits(0);
    printf("\r\nFilling Addresses [$%08X - $%08X] with $%02X", StartRamPtr, EndRamPtr, FillData);

    //char* start = 0;
    //start = StartRamPtr;

    if (config == 1) {
        while (start <= EndRamPtr){
            *start++ = FillData;
            }
    }

    if (config == 2) {
        while (start <= EndRamPtr) {
            *start = FillData;
            start += 2;
        }
    }

    if (config == 3) {
        while (start <= EndRamPtr) {
            *start = FillData;
            start += 4;
        }
    }


}

void ReadMemory(char* StartRamPtr, char* EndRamPtr, unsigned char FillData, int config)
{
    int counter = 0;
    char* start = StartRamPtr;

    printf("\r\nReading Addresses [$%08X - $%08X] for $%02X", StartRamPtr, EndRamPtr, FillData);

    //char* start = StartRamPtr;

   // register int counter = 0;

    if (config == 1) {
        while (start <= EndRamPtr) {
            if (*start != FillData)
                printf("\r\nValue incorrect at addresses $%08X ... should be $%02X but found $%02X", start, FillData, *start);

            if (counter == 400) {
                counter = 0;
                printf("\r\nValue: $%02X found at Address: $%08X", *start, start);
            }
            else
                counter++;

            start++;
        }
    }

    if (config == 2) {
        while (start <= EndRamPtr) {
            if(*start != FillData)
                printf("\r\nValue incorrect at addresses $%08X ... should be $%02X but found $%02X", start, FillData, *start);

            if (counter == 400) {
                counter = 0;
                printf("\r\nValue: $%02X found at Address: $%08X", *start, start);
            }
            else
                counter++;

            start += 2;
        }
    }

    if (config == 3) {
        while (start <= EndRamPtr) {
            if (*start != FillData)
                printf("\r\nValue incorrect at addresses $%08X ... should be $%02X but found $%02X", start, FillData, *start);

            if (counter == 400) {
                counter = 0;
                printf("\r\nValue: $%02X found at Address: $%08X", *start, start);
            }
            else
                counter++;

            start += 4;
        }
    }


}

/******************************************************************************************************************************
* Start of user program
******************************************************************************************************************************/

void main()
{
    unsigned int row, i=0, count=0, counter1=1;
    char c, text[150] ;

	int PassFailFlag = 1 ;

    int test_config=0;
    int test_pattern=0;
    char start_addr[7];
    int start_val = 0;
    char end_addr[7];
    int end_val = 0;

    i = x = y = z = PortA_Count =0;
    Timer1Count = Timer2Count = Timer3Count = Timer4Count = 0;

    InstallExceptionHandler(PIA_ISR, 25) ;          // install interrupt handler for PIAs 1 and 2 on level 1 IRQ
    InstallExceptionHandler(ACIA_ISR, 26) ;		    // install interrupt handler for ACIA on level 2 IRQ
    InstallExceptionHandler(Timer_ISR, 27) ;		// install interrupt handler for Timers 1-4 on level 3 IRQ
    InstallExceptionHandler(Key2PressISR, 28) ;	    // install interrupt handler for Key Press 2 on DE1 board for level 4 IRQ
    InstallExceptionHandler(Key1PressISR, 29) ;	    // install interrupt handler for Key Press 1 on DE1 board for level 5 IRQ

    Timer1Data = 0x10;		// program time delay into timers 1-4
    Timer2Data = 0x20;
    Timer3Data = 0x15;
    Timer4Data = 0x25;

    Timer1Control = 3;		// write 3 to control register to Bit0 = 1 (enable interrupt from timers) 1 - 4 and allow them to count Bit 1 = 1
    Timer2Control = 3;
    Timer3Control = 3;
    Timer4Control = 3;

    Init_LCD();             // initialise the LCD display to use a parallel data interface and 2 lines of display
    Init_RS232() ;          // initialise the RS232 port for use with hyper terminal

/*************************************************************************************************
**  Test of scanf function
*************************************************************************************************/

    scanflush() ;                       // flush any text that may have been typed ahead

    /*
    * User prompts
    */
    //int test_config=0;
    printf("\r\nEnter memory test configuration(1 - bytes, 2 - words, 3 - long words): ");
    scanf("%d", &test_config);
    if (test_config > 3 || test_config < 1) {
        printf("\r\nConfiguration invalid, try again");
    }

    //int test_pattern=0;
    printf("\r\nChoose between different memory test patterns(1 - 5, 2 - A, 3 - F, 4 - 0): ");
    scanf("%d", &test_pattern);
    if (test_config > 4 || test_config < 1) {
        printf("\r\nPattern invalid, try again");
    }

    //char start_addr[7];
    printf("\r\nEnter starting address(8020000 - 8030000 inclusive): ");
    scanf("%s", &start_addr);
    //int start_val = 0;
    start_val = Get7HexDigits(start_addr[0], start_addr[1], start_addr[2], start_addr[3], start_addr[4], start_addr[5], start_addr[6]);
    if (start_val < 0x8020000 || start_val > 0x8030000) {
        printf("\r\nStarting address out of bounds, try again");
    }
    if (start_val % 2 != 0 && test_config == 2) {
        printf("\r\nOdd starting address, try again");
    }
    if (start_val % 2 != 0 && test_config == 3) {
        printf("\r\nOdd starting address, try again");
    }

    //char end_addr[7];
    printf("\r\nEnter ending address(8020000 - 8030000 inclusive): ");
    scanf("%s", &end_addr);
    //int end_val = 0;
    end_val = Get7HexDigits(end_addr[0], end_addr[1], end_addr[2], end_addr[3], end_addr[4], end_addr[5], end_addr[6]);
    if (end_val < 0x8020000 || end_val > 0x8030000) {
        printf("\r\nEnding address out of bounds, try again");
    }
    if (end_val < start_val) {
        printf("\r\nInvalid ending address, try again");
    }

    printf("\r\nWriting to SRAM ...");
    printf("\r\n............................................................................................................");
    printf("\r\n............................................................................................................");
    printf("\r\n............................................................................................................");

    if (test_config == 1) {
        if (test_pattern == 1)
            FillMemory(start_val, end_val, Get2HexDigits('5'), 1);
        if (test_pattern == 2)
            FillMemory(start_val, end_val, Get2HexDigits('A'), 1);
        if (test_pattern == 3)
            FillMemory(start_val, end_val, Get2HexDigits('F'), 1);
        if (test_pattern == 4)
            FillMemory(start_val, end_val, Get2HexDigits('0'), 1);
    }
    if (test_config == 2) {
        if (test_pattern == 1)
            FillMemory(start_val, end_val, Get4HexDigits('5'), 2);
        if (test_pattern == 2)
            FillMemory(start_val, end_val, Get4HexDigits('A'), 2);
        if (test_pattern == 3)
            FillMemory(start_val, end_val, Get4HexDigits('F'), 2);
        if (test_pattern == 4)
            FillMemory(start_val, end_val, Get4HexDigits('0'), 2);
    }
    if (test_config == 3) {
        if (test_pattern == 1)
            FillMemory(start_val, end_val, Get8HexDigits('5'), 3);
        if (test_pattern == 2)
            FillMemory(start_val, end_val, Get8HexDigits('A'), 3);
        if (test_pattern == 3)
            FillMemory(start_val, end_val, Get8HexDigits('F'), 3);
        if (test_pattern == 4)
            FillMemory(start_val, end_val, Get8HexDigits('0'), 3);
    }

    printf("\r\nFinished writing to SRAM .");
    printf("\r\nCheck SRAM content");

    printf("\r\nReading from SRAM ...");
    printf("\r\nPrinting out every 10k location from SRAM ...");
    printf("\r\n............................................................................................................");
    printf("\r\n............................................................................................................");
    printf("\r\n............................................................................................................");
    printf("\r\n....................... begin reading");

    if (test_config == 1) {
        if (test_pattern == 1)
            ReadMemory(start_val, end_val, Get2HexDigits('5'), 1);
        if (test_pattern == 2)
            ReadMemory(start_val, end_val, Get2HexDigits('A'), 1);
        if (test_pattern == 3)
            ReadMemory(start_val, end_val, Get2HexDigits('F'), 1);
        if (test_pattern == 4)
            ReadMemory(start_val, end_val, Get2HexDigits('0'), 1);
    }
    if (test_config == 2) {
        if (test_pattern == 1)
            ReadMemory(start_val, end_val, Get4HexDigits('5'), 2);
        if (test_pattern == 2)
            ReadMemory(start_val, end_val, Get4HexDigits('A'), 2);
        if (test_pattern == 3)
            ReadMemory(start_val, end_val, Get4HexDigits('F'), 2);
        if (test_pattern == 4)
            ReadMemory(start_val, end_val, Get4HexDigits('0'), 2);
    }
    if (test_config == 3) {
        if (test_pattern == 1)
            ReadMemory(start_val, end_val, Get8HexDigits('5'), 3);
        if (test_pattern == 2)
            ReadMemory(start_val, end_val, Get8HexDigits('A'), 3);
        if (test_pattern == 3)
            ReadMemory(start_val, end_val, Get8HexDigits('F'), 3);
        if (test_pattern == 4)
            ReadMemory(start_val, end_val, Get8HexDigits('0'), 3);
    }

    printf("\r\nFinished reading from SRAM ...");
    printf("\r\nend of program ...");
    printf("\r\n............................................................................................................");
    printf("\r\n............................................................................................................");



   // printf("\r\nEnter Integer: ") ;
   // scanf("%d", &i) ;
   // printf("You entered %d", i) ;

   // sprintf(text, "Hello CPEN 412 Student") ;
   // LCDLine1Message(text) ;

   // printf("\r\nHello CPEN 412 Student\r\nYour LEDs should be Flashing") ;
   // printf("\r\nYour LCD should be displaying") ;

    while(1)
        ;

   // programs should NOT exit as there is nothing to Exit TO !!!!!!
   // There is no OS - just press the reset button to end program and call debug
}
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include "Canbus controller routines - For students.c"


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

//#define StartOfExceptionVectorTable 0x08030000
#define StartOfExceptionVectorTable 0x0B000000

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

/* SPI declarations*/
/*************************************************************
** SPI Controller registers
**************************************************************/
// SPI Registers
#define SPI_Control         (*(volatile unsigned char *)(0x00408020))
#define SPI_Status          (*(volatile unsigned char *)(0x00408022))
#define SPI_Data            (*(volatile unsigned char *)(0x00408024))
#define SPI_Ext             (*(volatile unsigned char *)(0x00408026))
#define SPI_CS              (*(volatile unsigned char *)(0x00408028))
// these two macros enable or disable the flash memory chip enable off SSN_O[7..0]
// in this case we assume there is only 1 device connected to SSN_O[0] so we can
// write hex FE to the SPI_CS to enable it (the enable on the flash chip is active low)
// and write FF to disable it
#define   Enable_SPI_CS()             SPI_CS = 0xFE
#define   Disable_SPI_CS()            SPI_CS = 0xFF
/* end */

/*************************************************************
** I2C Controller registers
**************************************************************/
#define I2C_PRERlo         (*(volatile unsigned char *)(0x00408000))
#define I2C_PRERhi         (*(volatile unsigned char *)(0x00408002))
#define I2C_CTR            (*(volatile unsigned char *)(0x00408004))
#define I2C_TXR            (*(volatile unsigned char *)(0x00408006))
#define I2C_CR              (*(volatile unsigned char *)(0x00408008))

/*************************************************************
** end
**************************************************************/


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
void enableWrite(void);
int WriteSPIChar(int c);
int WriteSPI(int num);
void pollSPI(void);

/*canbus prototype*/
void Init_CanBus_Controller0(void);
void Init_CanBus_Controller1(void);
void CanBus0_Transmit(void);
void CanBus1_Receive(void);
void CanBus0_Receive(void);
void CanBus1_Transmit(void);
void CanBusTest(void);
void delay(void);

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

    //if (CheckSumPtr)
      //  *CheckSumPtr += i;

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


/* SPI functions */
/******************************************************************************************
** The following code is for the SPI controller
*******************************************************************************************/
// return true if the SPI has finished transmitting a byte (to say the Flash chip) return false otherwise
// this can be used in a polling algorithm to know when the controller is busy or idle.
int TestForSPITransmitDataComplete(void) {
    /* TODO replace 0 below with a test for status register SPIF bit and if set, return true */

    return (SPI_Status >= 0x80);
}

/************************************************************************************
** initialises the SPI controller chip to set speed, interrupt capability etc.
************************************************************************************/
void SPI_Init(void)
{
    //TODO
    //
    // Program the SPI Control, EXT, CS and Status registers to initialise the SPI controller
    // Don't forget to call this routine from main() before you do anything else with SPI
    //
    // Here are some settings we want to create
    //
    // Control Reg     - interrupts disabled, core enabled, Master mode, Polarity and Phase of clock = [0,0], speed =  divide by 32 = approx 700Khz
    // Ext Reg         - in conjunction with control reg, sets speed above and also sets interrupt flag after every completed transfer (each byte)
    // SPI_CS Reg      - control selection of slave SPI chips via their CS# signals
    // Status Reg      - status of SPI controller chip and used to clear any write collision and interrupt on transmit complete flag

    /* setting up control register */
    if ((SPI_Control & 0x20) == 0)
        SPI_Control = 0x53; //writing a 0 to reserved bit at position 5
    else
        SPI_Control = 0x73; //writing a 1 to reserved bit at position 5


    /* setting up extension register */
    SPI_Ext = SPI_Ext & 0x3c;


    /* enable chip */
   // Enable_SPI_CS();
    Disable_SPI_CS(); //change to disable


    /* setting up status register */
   // SPI_Status = SPI_Status & 0x3f;

    SPI_Status = 0xff;

    //TODO: figure out what value to write to reserved bits, is there a way to maintain the value of the reerved bit?
    //TODO: How to write to individual bit positions
    //assume data can be changed in such a way such that the reserved bits are not updated, may need to read the data first


}

void I2C_Init(void) {
    //Using I2C_PRERlo and I2C_PRERhi to convert clock to 100kHz
    I2C_PRERlo = 0x31;
    I2C_PRERhi = 0x31; //converts 45MHz to 100kHz
    //config clock when the en bit is cleared
    //TODO: Do we need to configure both reg?

    //Using I2C_CTR to enable core and disable interrupt
    I2C_CTR = 0x80;
    //TODO: do we need to enable core here?



}

int I2C_Check_ACK(void) {
    int value = I2C_CR;

    return ((value & 0x80) == 0x00);
}

int I2C_Check_Busy(void) {
    int value = I2C_CR;

    return ((value & 0x40) > 0x00);
}

int TestForI2CTransmitDataComplete(void) {
    int value = I2C_CR;

    return ((value & 0x02) == 0x00);
}

int I2C_Check_Read(void) {
    int value = I2C_CR;

    return ((value & 0x01) == 0x01);

}

void WaitForI2CRead(void) {
    while (I2C_Check_Read() == 0) {
        //do nothing
    }
}


void WaitForI2CTransmitComplete(void)
{

    /* loop for polling */
    while (TestForI2CTransmitDataComplete() == 0) {
        //do nothing
    }

}

void WaitForI2CSlaveACK(void) {
    /* loop for polling */
    while (I2C_Check_ACK() == 0) {
        //do nothing
    }
}

void WaitForI2CBusy(void) {
    while (I2C_Check_Busy() == 1) {
        //do nothing
    }
}







void WriteI2CBlock(int upper, int lower, int n, int b, int data) {
    int mod;
    int i;
    int sum;
    int addr = (upper << 8) | (lower);
    i = -1;

    if (n / 128 > 0) {
        for (i = 0; i < (n / 128); i++) {
            sum = addr + 128 * i;
            if (sum <= 0xffff) {
                WriteI2CPage((sum >> 8), (sum & 0x00ff), 128, b, data);
            }
            else
                break;
        }
    }

    if (i == -1)
        i = 0;

    mod = n % 128;
    sum = addr + 128 * i;

    if(mod>0) {
        if (sum <= 0xffff) {
            WriteI2CPage((sum >> 8), (sum & 0x00ff), mod, b, data);
        }
    }

    return;
}

void WriteI2CPage(int upper, int lower, int n, int b, int data) {

    int i;
    int addr = (upper << 8) | (lower);

    WaitForI2CBusy();

    if (b == 0) {
        I2C_TXR = 0xa0;
    }
    else {
        I2C_TXR = 0xa2;
    }
    
    I2C_CR = 0x91;

    WaitForI2CTransmitComplete();

    WaitForI2CSlaveACK();

    I2C_TXR = upper;

    I2C_CR = 0x11;

    WaitForI2CTransmitComplete();

    WaitForI2CSlaveACK();

    I2C_TXR = lower;

    I2C_CR = 0x11;

    WaitForI2CTransmitComplete();

    WaitForI2CSlaveACK();

    for (i = 0; i < n; i++) {
        if (addr == 0xffff) {
            I2C_TXR = data;

            I2C_CR = 0x51;

            WaitForI2CTransmitComplete();

            WaitForI2CSlaveACK();

            break;
        }
        else {
            if (i == n - 1) {
                I2C_TXR = data;

                I2C_CR = 0x51;

                WaitForI2CTransmitComplete();

                WaitForI2CSlaveACK();
            }
            else {
                I2C_TXR = data;

                I2C_CR = 0x11;

                WaitForI2CTransmitComplete();

                WaitForI2CSlaveACK();
            }

            addr++;
        }
        
    }

    return;
   
}

void WriteI2C128k(int upper, int lower, int n, int b, int data) {

    int addr = (b << 16) | (upper << 8) | (lower);

    if (addr < 0x10000 && (addr + n - 1) >= 0x10000) {
        WriteI2CBlock(upper, lower, 0x10000 - addr, 0, data);
        WriteI2CBlock(0x00, 0x00, n - (0x10000 - addr), 1, data);
    }
    else {
        WriteI2CBlock(upper, lower, n, b, data);
    }

    return;
}




int ReadI2CChar(int upper, int lower) {
    int ret;
    WaitForI2CBusy();
    printf("finished checking bus availability ... \n");
    I2C_TXR = 0xa0;
    I2C_CR = 0x91;
    WaitForI2CTransmitComplete();
    printf("start condition transmitted ... \n");
    WaitForI2CSlaveACK();
    printf("start condition acknowledged ... \n");
    I2C_TXR = upper;
    I2C_CR = 0x11;
    WaitForI2CTransmitComplete();
    printf("upper address transmitted ... \n");
    WaitForI2CSlaveACK();
    printf("upper address acknowledged ... \n");
    I2C_TXR = lower;
    I2C_CR = 0x11;
    WaitForI2CTransmitComplete();
    printf("lower address transmitted ... \n");
    WaitForI2CSlaveACK();
    printf("lower address acknowledged ... \n");
    I2C_TXR = 0xa1;
    I2C_CR = 0x91;
    WaitForI2CTransmitComplete();
    WaitForI2CSlaveACK();
    I2C_CR = 0x69;
    printf("stop condition transmitted ... \n");
    WaitForI2CRead();
    printf("read value ready ... \n");
    ret = I2C_TXR;

    printf("\r\n\nEEPROM Value: %x \n", ret);
}

void WriteI2CChar(int upper, int lower, int data) {
    WaitForI2CBusy();
    printf("finished checking bus availability ... \n");
    I2C_TXR = 0xa0;
    I2C_CR = 0x91;
    WaitForI2CTransmitComplete();
    printf("start condition transmitted ... \n");
    WaitForI2CSlaveACK();
    printf("start condition acknowledged ... \n");
    I2C_TXR = upper;
    I2C_CR = 0x11;
    WaitForI2CTransmitComplete();
    printf("upper address transmitted ... \n");
    WaitForI2CSlaveACK();
    printf("upper address acknowledged ... \n");
    I2C_TXR = lower;
    I2C_CR = 0x11;
    WaitForI2CTransmitComplete();
    printf("lower address transmitted ... \n");
    WaitForI2CSlaveACK();
    printf("lower address acknowledged ... \n");
    I2C_TXR = data;
    I2C_CR = 0x51;
    WaitForI2CTransmitComplete();
    printf("data transmitted ... \n");
    WaitForI2CSlaveACK();
    printf("data acknowledged ... \n");
}


void ReadI2CPage(int upper, int lower, int n, int b) {
    int ret;
    int i;
    int addr;
    WaitForI2CBusy();
    printf("finished checking bus availability ... \n");
    if (b == 0) {
        I2C_TXR = 0xa0;
    }
    else {
        I2C_TXR = 0xa2;
    }
    I2C_CR = 0x91;
    WaitForI2CTransmitComplete();
    printf("start condition transmitted ... \n");
    WaitForI2CSlaveACK();
    printf("start condition acknowledged ... \n");
    I2C_TXR = upper;
    I2C_CR = 0x11;
    WaitForI2CTransmitComplete();
    printf("upper address transmitted ... \n");
    WaitForI2CSlaveACK();
    printf("upper address acknowledged ... \n");
    I2C_TXR = lower;
    I2C_CR = 0x11;
    WaitForI2CTransmitComplete();
    printf("lower address transmitted ... \n");
    WaitForI2CSlaveACK();
    printf("lower address acknowledged ... \n");
    if (b == 0) {
        I2C_TXR = 0xa1;
    }
    else {
        I2C_TXR = 0xa3;
    }
    I2C_CR = 0x91;
    WaitForI2CTransmitComplete();
    WaitForI2CSlaveACK();
    for (i = 0; i < n-1; i++) {
        I2C_CR = 0x21;
        WaitForI2CRead();
        ret = I2C_TXR;
        addr = (b << 16) | (upper << 8) | (lower);
        printf("\r\n\nEEPROM value %x read at address %x  \n", ret,addr+i);
    }
    I2C_CR = 0x69;
    WaitForI2CRead();
    ret = I2C_TXR;
    addr = (b << 16) | (upper << 8) | (lower);
    printf("\r\n\nEEPROM value %x read at address %x  \n", ret, addr + i);
}

void ReadI2CBlock(int upper, int lower, int n, int b) {
    int addr = (b << 16) | (upper << 8) | (lower);

    if (addr < 0x10000 && (addr + n - 1) >= 0x10000) {
        ReadI2CPage(upper, lower, 0x10000 - addr, 0);
        if (n - (0x10000 - addr) <= 0x10000) {
            ReadI2CPage(0x00, 0x00, n - (0x10000 - addr), 1);
        }
        else {
            ReadI2CPage(0x00, 0x00, 0x10000, 1);
        }
        
    }
    else {
        if (addr < 0x10000) {
            ReadI2CPage(upper, lower, n, 0);
        }
        else {
            if (n <= 0x10000) {
                ReadI2CPage(upper, lower, n, 1);
            }
            else {
                ReadI2CPage(upper, lower, 0x10000, 1);
            }
        }

    }

    return;
}


void menueI2C(void) {
    int option, val_to_pass, ret, upper, lower, b, n;
    // char pat;

    while (1) {
        scanflush();

        printf("\r\n\nEnter I2C operation(1 - Write Byte EEPROM, 2 - Read Byte EEPROM, 3 - Write Block EEPROM, 4 - Read Block EEPROM, 5 - Write LED, 6 - Read Photo Resistor, 7 - Read Thermistor, 8 - Read Potentiometer, 9 - Stop LED): ");
        option = xtod(_getch());
        printf("\r\n\nI2C operation: %x ", option);

        switch (option) {
        case 1:
            printf("\r\nWrite byte EEPROM operation selected");
            printf("\r\n\nEnter the upper address: ");
            upper = Get2HexDigitsVoid();
            printf("\r\n\nEntered: %x", upper);
            printf("\r\n\nEnter the lower address: ");
            lower = Get2HexDigitsVoid();
            printf("\r\n\nEntered: %x", lower);
            printf("\r\n\nEnter data: ");
            val_to_pass = Get2HexDigitsVoid();
            printf("\r\n\nEntered: %x \n", val_to_pass);
            WriteI2CChar(upper, lower, val_to_pass);
            printf("\r\nEnd of write byte EEPROM operation ...");
            break;
        case 2:
            printf("\r\nRead byte EEPROM operation selected");
            printf("\r\n\nEnter the upper address: ");
            upper = Get2HexDigitsVoid();
            printf("\r\n\nEntered: %x", upper);
            printf("\r\n\nEnter the lower address: ");
            lower = Get2HexDigitsVoid();
            printf("\r\n\nEntered: %x \n", lower);
            ret = ReadI2CChar(upper, lower);
            printf("\r\nEnd of read byte EEPROM operation ...");
            break;
        case 3:
            printf("\r\nWrite block EEPROM operation selected");
            printf("\r\n\nEnter the upper address: ");
            upper = Get2HexDigitsVoid();
            printf("\r\n\nEntered: %x", upper);
            printf("\r\n\nEnter the lower address: ");
            lower = Get2HexDigitsVoid();
            printf("\r\n\nEntered: %x", lower);
            printf("\r\n\nEnter the block number: ");
            b = xtod(_getch());
            printf("\r\n\nEntered: %x", b);
            printf("\r\n\nEnter data: ");
            val_to_pass = Get2HexDigitsVoid();
            printf("\r\n\nEntered: %x", val_to_pass);
            printf("\r\n\nEnter number of bytes to write: ");
            n = Get5HexDigitsVoid();
            printf("\r\n\nEntered: %x", n);
            WriteI2C128k(upper, lower, n, b, val_to_pass);
            printf("\r\nEnd of write block EEPROM operation ...");
            break;
        case 4:
            printf("\r\nRead block EEPROM operation selected");
            printf("\r\n\nEnter the upper address: ");
            upper = Get2HexDigitsVoid();
            printf("\r\n\nEntered: %x", upper);
            printf("\r\n\nEnter the lower address: ");
            lower = Get2HexDigitsVoid();
            printf("\r\n\nEntered: %x", lower);
            printf("\r\n\nEnter the block number: ");
            b = xtod(_getch());
            printf("\r\n\nEntered: %x", b);
            printf("\r\n\nEnter number of bytes to read: ");
            n = Get5HexDigitsVoid();
            printf("\r\n\nEntered: %x", n);
            ReadI2CBlock(upper, lower, n, b);
            printf("\r\nEnd of read block EEPROM operation ...");
            break;
        case 5:
            printf("\r\nWrite LED operation selected");
            Repeat_LED();
            break;
        case 6:
            printf("\r\nRead photo resistor operation selected");
            Repeat_READ_ADC(0x02);
            break;
        case 7:
            printf("\r\nRead thermistor operation selected");
            Repeat_READ_ADC(0x03);
            break;
        case 8:
            printf("\r\nRead potentiometer operation selected");
            Repeat_READ_ADC(0x01);
            break;
        case 9:
            printf("\r\nStop LED operation selected");
            Write_LED(0x00);
            break;
        default:
            printf("\r\n\nInvalid operation ...");
            printf("\r\n\nTry again!!!!!");
        }
    }

}

void executeI2C(void) {
    printf("\r\nIntializing I2C\n");
    I2C_Init();
    menueI2C();
}

void Write_LED(int data) {
    WaitForI2CBusy();
    I2C_TXR = 0x90;
    I2C_CR = 0x91;
    WaitForI2CTransmitComplete();
    WaitForI2CSlaveACK();
    I2C_TXR = 0x40;
    I2C_CR = 0x11;
    WaitForI2CTransmitComplete();
    WaitForI2CSlaveACK();
    I2C_TXR = data;
    I2C_CR = 0x51;
    WaitForI2CTransmitComplete();
    WaitForI2CSlaveACK();
}


void Repeat_LED(void) {
    int data;
    int flag;
    data = 0;
    flag = 0;
    while (1) {
        Write_LED(data);
        if (flag == 0) {
            data = data + 1;
            if (data > 0xc0) {
                data = 0xc0 - 1;
                flag = 1;
            }
        }
        else {
            if (data == 0x50) {
                data = 0x51;
                flag = 0;
            }
            else {
                data = data - 1;
            }
        }
    }
}

void Read_ADC(int data) {
    int ret;
    WaitForI2CBusy();
    I2C_TXR = 0x90;
    I2C_CR = 0x91;
    WaitForI2CTransmitComplete();
    WaitForI2CSlaveACK();
    I2C_TXR = data;
    I2C_CR = 0x11;
    WaitForI2CTransmitComplete();
    WaitForI2CSlaveACK();
    I2C_TXR = 0x91;
    I2C_CR = 0x91;
    WaitForI2CTransmitComplete();
    WaitForI2CSlaveACK();
    I2C_CR = 0x69;
    WaitForI2CRead();
    ret = I2C_TXR;
    //printf("ADC value: %x \n", ret);
    ret = I2C_TXR;
    printf("ADC value: %x \n", ret);
}

void Repeat_READ_ADC(int data) {
    while (1) {
        Read_ADC(data);
    }
}

int Read_ADC_Ret(int data) {
    int ret;
    WaitForI2CBusy();
    I2C_TXR = 0x90;
    I2C_CR = 0x91;
    WaitForI2CTransmitComplete();
    WaitForI2CSlaveACK();
    I2C_TXR = data;
    I2C_CR = 0x11;
    WaitForI2CTransmitComplete();
    WaitForI2CSlaveACK();
    I2C_TXR = 0x91;
    I2C_CR = 0x91;
    WaitForI2CTransmitComplete();
    WaitForI2CSlaveACK();
    I2C_CR = 0x69;
    WaitForI2CRead();
    ret = I2C_TXR;
    //printf("ADC value: %x \n", ret);
    ret = I2C_TXR;
    printf("ADC value: %x \n", ret);

    return ret;
}



/************************************************************************************
** return ONLY when the SPI controller has finished transmitting a byte
************************************************************************************/
void WaitForSPITransmitComplete(void)
{
    // TODO : poll the status register SPIF bit looking for completion of transmission
    // once transmission is complete, clear the write collision and interrupt on transmit complete flags in the status register (read documentation)
    // just in case they were set

    /* loop for polling */
    while (TestForSPITransmitDataComplete() == 0) {
        //do nothing
    }

    /* clear bits in the status register */
   // SPI_Status = SPI_Status & 0x3f;

    SPI_Status = 0xff;

}

/************************************************************************************
** Write a byte to the SPI flash chip via the controller and returns (reads) whatever was
** given back by SPI device at the same time (removes the read byte from the FIFO)
************************************************************************************/
int WriteSPIChar(int c) //change int to char to take into account 1 byte
{
    // todo - write the byte in parameter 'c' to the SPI data register, this will start it transmitting to the flash device
    // wait for completion of transmission
    // return the received data from Flash chip (which may not be relevent depending upon what we are doing)
    // by reading fom the SPI controller Data Register.
    // note however that in order to get data from an SPI slave device (e.g. flash) chip we have to write a dummy byte to it
    //
    // modify '0' below to return back read byte from data register
    //

    int ret, upper, mid, lower, dummy;

   // eraseChip();


    printf("\r\n\nEnter upper byte: ");
    upper = Get2HexDigitsVoid();
    printf("\r\n\nUPPER BYTE: %x ", upper);

    printf("\r\n\nEnter mid byte: ");
    mid = Get2HexDigitsVoid();
    printf("\r\n\nMID BYTE: %x ", mid);

    printf("\r\n\nEnter lower byte: ");
    lower = Get2HexDigitsVoid();
    printf("\r\n\nLOWER BYTE: %x ", lower);

    enableWrite();

    //5: write to flash
    printf("5: write to flash \n\n");
    Enable_SPI_CS(); //enable cs#
    WriteSPI(0x02);
    WriteSPI(upper);
    WriteSPI(mid);
    WriteSPI(lower);
    WriteSPI(c);
    Disable_SPI_CS(); //disable cs#


    pollSPI();

    //7: reading flash chip for verification
    printf("7: reading flash chip for verification \n\n");
    Enable_SPI_CS(); //enable cs#
    WriteSPI(0x03);
    WriteSPI(upper);
    WriteSPI(mid);
    WriteSPI(lower);
    /* collecting data into var */
    ret = WriteSPI(0xee);
    printf("\r\n\nret: %x ", ret);
    Disable_SPI_CS(); // disable cs#

    return ret;
}

int readSPI(void) {
    int ret, upper, mid, lower, dummy;

    printf("\r\n\nEnter upper byte:");
    upper = Get2HexDigitsVoid();
    printf("\r\n\nUPPER BYTE: %x", upper);

    printf("\r\n\nEnter mid byte:");
    mid = Get2HexDigitsVoid();
    printf("\r\n\nMID BYTE: %x", mid);

    printf("\r\n\nEnter lower byte:");
    lower = Get2HexDigitsVoid();
    printf("\r\n\nLOWER BYTE: %x", lower);

    // reading flash chip for verification
    printf("\r\nReading flash chip for verification");
    Enable_SPI_CS(); //enable cs#
    WriteSPI(0x03);
    WriteSPI(upper);
    WriteSPI(mid);
    WriteSPI(lower);
    /* collecting data into var */
    ret = WriteSPI(0xee);
    printf("\r\n\nret: %x ", ret);
    Disable_SPI_CS(); // disable cs#

    return ret;
}

void enableWrite(void) {
    //enable write
    Enable_SPI_CS(); //enable cs#
    WriteSPI(0x06);
    Disable_SPI_CS(); //disable cs#
}

void pollSPI(void) {
    int status;
    //poll flash chip to see if rdy
    printf("\r\nPolling flash chip to see if ready \n\n");
    Enable_SPI_CS(); //enable cs#
    WriteSPI(0x05);
    status = WriteSPI(0xee);
    while (status & 0x01 == 1) {
        status = WriteSPI(0xee);
    }
    Disable_SPI_CS(); // disable cs#
}

void eraseChip(void) {
    //enable write
    enableWrite();

    //erase chip
    printf("\r\nErase chip");
    Enable_SPI_CS(); //enable cs#
    WriteSPI(0xc7);
    Disable_SPI_CS(); // disable cs#

    //poll spi
    pollSPI();
}

int WriteSPI(int num) {
    SPI_Data = num;
    WaitForSPITransmitComplete();
    return SPI_Data;
}

void menueSPI(void) {
    int option, val_to_pass, ret;
   // char pat;

    while (1) {
        scanflush();

        printf("\r\n\nEnter SPI operation(1 - Erase Chip, 2 - Write to SPI, 3 - Read from SPI): ");
        option = xtod(_getch());
        printf("\r\n\nSPI operation: %x ", option);

        switch (option) {
        case 1:
            printf("\r\nChip erase operation selected");
            eraseChip();
            printf("\r\nEnd of erase operation ...");
            break;
        case 2:
            printf("\r\n\nWrite operation selected \n\n");
            printf("\r\n\nEnter a value for write: ");
            val_to_pass = Get2HexDigitsVoid();
            printf("\r\nValue to write: %x", val_to_pass);
            ret = WriteSPIChar(val_to_pass);
            printf("\r\nValue returned: %x", ret);
            printf("\r\nend of write operation ...");
            break;
        case 3:
            printf("\r\n\nRead operation selected");
            ret = readSPI();
            printf("\r\n\nValue returned: %x ", ret);
            printf("\r\n\nend of read operation ...");
            break;
        default:
            printf("\r\n\nInvalid operation ...");
            printf("\r\n\nTry again!!!!!");
        }
    }

}

void executeSPI(void) {
    printf("\r\nIntializing SPI\n");
    SPI_Init();
    menueSPI();
}


void readID(void) {
    int man, dev, dev2;
     int dummy;
    printf("READING ID !!!!!!  \n\n");
    Enable_SPI_CS(); //enable cs#
    WriteSPI(0x90);
    WriteSPI(0x00);
    WriteSPI(0x00);
    WriteSPI(0x00);
    man = WriteSPI(0xee);
    dev = WriteSPI(0xee);
    Disable_SPI_CS(); //disable cs#

    printf("\r\n\nMan: %x ", man);
    printf("\r\n\nDev: %x ", dev);
}
/* end */

/* other spare functions */
int Get2HexDigitsVoid(void)
{
    register int i = (xtod(_getch()) << 4) | (xtod(_getch()));


    return i;
}

int Get5HexDigitsVoid(void)
{
    register int i = (xtod(_getch()) << 16) | (xtod(_getch()) << 12) | (xtod(_getch()) << 8) | (xtod(_getch()) << 4) | (xtod(_getch()));


    return i;
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

    int val_to_pass, ret;

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
    * I2C Program HERE
    */



   // executeI2C();

    //Repeat_READ_ADC(0x02);

    //////////////////////////////////////////////
    ////////////////////////////////////////////// test for canbus
    I2C_Init();
    Init_CanBus_Controller0();
    Init_CanBus_Controller1();


    while (1) {
        printf("Canbus0 Transmit  Canbus1 Receive\n");
        CanBus0_Transmit();
        CanBus1_Receive();
        printf("\n");

        printf("Canbus1 Transmit  Canbus0 Receive\n");
        CanBus1_Transmit();
        CanBus0_Receive();
        printf("\n");

    }
    
    //////////////////////////////////////////////
    //////////////////////////////////////////////


    while(1)
        ;

   // programs should NOT exit as there is nothing to Exit TO !!!!!!
   // There is no OS - just press the reset button to end program and call debug
}
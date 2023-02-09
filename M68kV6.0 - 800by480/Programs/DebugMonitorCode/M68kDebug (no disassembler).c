#include "DebugMonitor.h"

// use 08030000 for a system running from sram or 0B000000 for system running from dram
//#define StartOfExceptionVectorTable 0x08030000
#define StartOfExceptionVectorTable 0x0B000000

// use 0C000000 for dram or hex 08040000 for sram
//#define TopOfStack 0x08040000
#define TopOfStack 0x0C000000

/* DO NOT INITIALISE GLOBAL VARIABLES - DO IT in MAIN() */
unsigned int i, x, y, z, PortA_Count;
int     Trace, GoFlag, Echo;                       // used in tracing/single stepping

// 68000 register dump and preintialise value (these can be changed by the user program when it is running, e.g. stack pointer, registers etc

unsigned int d0,d1,d2,d3,d4,d5,d6,d7 ;
unsigned int a0,a1,a2,a3,a4,a5,a6 ;
unsigned int PC, SSP, USP ;
unsigned short int SR;

// Breakpoint variables
unsigned int BreakPointAddress[8];                      //array of 8 breakpoint addresses
unsigned short int BreakPointInstruction[8] ;           // to hold the instruction opcode at the breakpoint
unsigned int BreakPointSetOrCleared[8] ;
unsigned int InstructionSize ;

// watchpoint variables
unsigned int WatchPointAddress[8];                      //array of 8 breakpoint addresses
unsigned int WatchPointSetOrCleared[8] ;
char WatchPointString[8][100] ;

char    TempString[100] ;

/************************************************************************************
*Subroutine to give the 68000 something useless to do to waste 1 mSec
************************************************************************************/
void Wait1ms(void)
{
    long int  i ;
    for(i = 0; i < 1000; i ++)
        ;
}

/************************************************************************************
*Subroutine to give the 68000 something useless to do to waste 3 mSec
**************************************************************************************/
void Wait3ms(void)
{
    int i ;
    for(i = 0; i < 3; i++)
        Wait1ms() ;
}

/*********************************************************************************************
*Subroutine to initialise the display by writing some commands to the LCD internal registers
*********************************************************************************************/
void Init_LCD(void)
{
    LCDcommand = (char)(0x0c) ;
    Wait3ms() ;
    LCDcommand = (char)(0x38) ;
    Wait3ms() ;
}

/******************************************************************************
*subroutine to output a single character held in d1 to the LCD display
*it is assumed the character is an ASCII code and it will be displayed at the
*current cursor position
*******************************************************************************/
void Outchar(int c)
{
    LCDdata = (char)(c);
    Wait1ms() ;
}

/**********************************************************************************
*subroutine to output a message at the current cursor position of the LCD display
************************************************************************************/
void OutMess(char *theMessage)
{
    char c ;
    while((c = *theMessage++) != (char)(0))
        Outchar(c) ;
}

/******************************************************************************
*subroutine to clear the line by issuing 24 space characters
*******************************************************************************/
void Clearln(void)
{
    unsigned char i ;
    for(i = 0; i < 24; i ++)
        Outchar(' ') ;  /* write a space char to the LCD display */
}

/******************************************************************************
*subroutine to move the cursor to the start of line 1 and clear that line
*******************************************************************************/
void Oline0(char *theMessage)
{
    LCDcommand = (char)(0x80) ;
    Wait3ms();
    Clearln() ;
    LCDcommand = (char)(0x80) ;
    Wait3ms() ;
    OutMess(theMessage) ;
}

/******************************************************************************
*subroutine to move the cursor to the start of line 2 and clear that line
*******************************************************************************/
void Oline1(char *theMessage)
{
    LCDcommand = (char)(0xC0) ;
    Wait3ms();
    Clearln() ;
    LCDcommand = (char)(0xC0) ;
    Wait3ms() ;
    OutMess(theMessage) ;
}

void InstallExceptionHandler( void (*function_ptr)(), int level)
{
    volatile long int *RamVectorAddress = (volatile long int *)(StartOfExceptionVectorTable) ;   // pointer to the Ram based interrupt vector table created in Cstart in debug monitor

    RamVectorAddress[level] = (long int *)(function_ptr);
}


void TestLEDS(void)
{
    int delay ;
    unsigned char count = 0 ;

    while(1)    {
        PortA = PortB = PortC = PortD = HEX_A = HEX_B = HEX_C = HEX_D = ((count << 4) + (count & 0x0f)) ;
        for(delay = 0; delay < 200000; delay ++)
            ;
        count ++;
    }
}

void SwitchTest(void)
{
    int i, switches = 0 ;

	printf("\r\n") ;

    while(1)    {
        switches = (PortB << 8) | (PortA) ;
        printf("\rSwitches SW[7-0] = ") ;
        for( i = (int)(0x00000080); i > 0; i = i >> 1)  {
            if((switches & i) == 0)
                printf("0") ;
            else
                printf("1") ;
        }
    }
}

/*********************************************************************************************
*Subroutine to initialise the RS232 Port by writing some commands to the internal registers
*********************************************************************************************/
void Init_RS232(void)
{
    RS232_Control = (char)(0x15) ; //  %00010101    divide by 16 clock, set rts low, 8 bits no parity, 1 stop bit transmitter interrupt disabled
    RS232_Baud = (char)(0x1) ;      // program baud rate generator 000 = 230k, 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
}

int kbhit(void)
{
    if(((char)(RS232_Status) & (char)(0x01)) == (char)(0x01))    // wait for Rx bit in status register to be '1'
        return 1 ;
    else
        return 0 ;
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
    while(((char)(RS232_Status) & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
        ;

    (char)(RS232_TxData) = ((char)(c) & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
    return c ;                                              // putchar() expects the character to be returned
}

/*********************************************************************************************************
**  Subroutine to provide a low level input function to 6850 ACIA
**  This routine provides the basic functionality to input a single character from the serial Port
**  to allow the board to communicate with HyperTerminal Program Keyboard (your PC)
**
**  NOTE you do not call this function directly, instead you call the normal _getch() function
**  which in turn calls _getch() below). Other functions like gets(), scanf() call _getch() so will
**  call _getch() also
*********************************************************************************************************/

int _getch( void )
{
    int c ;
    while(((char)(RS232_Status) & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
        ;

    c = (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character

    // shall we echo the character? Echo is set to TRUE at reset, but for speed we don't want to echo when downloading code with the 'L' debugger command
    if(Echo)
        _putch(c);

    return c ;
}

// flush the input stream for any unread characters

void FlushKeyboard(void)
{
    char c ;

    while(1)    {
        if(((char)(RS232_Status) & (char)(0x01)) == (char)(0x01))    // if Rx bit in status register is '1'
            c = ((char)(RS232_RxData) & (char)(0x7f)) ;
        else
            return ;
     }
}

// converts hex char to 4 bit binary equiv in range 0000-1111 (0-F)
// char assumed to be a valid hex char 0-9, a-f, A-F

char xtod(int c)
{
    if ((char)(c) <= (char)('9'))
        return c - (char)(0x30);    // 0 - 9 = 0x30 - 0x39 so convert to number by sutracting 0x30
    else if((char)(c) > (char)('F'))    // assume lower case
        return c - (char)(0x57);    // a-f = 0x61-66 so needs to be converted to 0x0A - 0x0F so subtract 0x57
    else
        return c - (char)(0x37);    // A-F = 0x41-46 so needs to be converted to 0x0A - 0x0F so subtract 0x37
}

int Get2HexDigits(char *CheckSumPtr)
{
    register int i = (xtod(_getch()) << 4) | (xtod(_getch()));

    if(CheckSumPtr)
        *CheckSumPtr += i ;

    return i ;
}

int Get4HexDigits(char *CheckSumPtr)
{
    return (Get2HexDigits(CheckSumPtr) << 8) | (Get2HexDigits(CheckSumPtr));
}

int Get6HexDigits(char *CheckSumPtr)
{
    return (Get4HexDigits(CheckSumPtr) << 8) | (Get2HexDigits(CheckSumPtr));
}

int Get8HexDigits(char *CheckSumPtr)
{
    return (Get4HexDigits(CheckSumPtr) << 16) | (Get4HexDigits(CheckSumPtr));
}

void DumpMemory(void)   // simple dump memory fn
{
    int i, j ;
    unsigned char *RamPtr,c ; // pointer to where the program is download (assumed)

    printf("\r\nDump Memory Block: <ESC> to Abort, <SPACE> to Continue") ;
    printf("\r\nEnter Start Address: ") ;
    RamPtr = Get8HexDigits(0);

    while(1)    {
        for(i = 0; i < 16; i ++)    {
            printf("\r\n%08x ", RamPtr) ;
            for(j=0; j < 16; j ++)  {
                printf("%02X",RamPtr[j]) ;
                putchar(' ') ;
            }

            // now display the data as ASCII at the end

            printf("  ") ;
            for(j = 0; j < 16; j++) {
                c = ((char)(RamPtr[j]) & 0x7f) ;
                if((c > (char)(0x7f)) || (c < ' '))
                    putchar('.') ;
                else
                    putchar(RamPtr[j]) ;
            }
            RamPtr = RamPtr + 16 ;
        }
        printf("\r\n") ;

        c = _getch() ;
        if(c == 0x1b)          // break on ESC
            break ;
     }
}

void FillMemory()
{
    char *StartRamPtr, *EndRamPtr ;
    unsigned char FillData ;

    printf("\r\nFill Memory Block") ;
    printf("\r\nEnter Start Address: ") ;
    StartRamPtr = Get8HexDigits(0) ;

    printf("\r\nEnter End Address: ") ;
    EndRamPtr = Get8HexDigits(0) ;

    printf("\r\nEnter Fill Data: ") ;
    FillData = Get2HexDigits(0) ;
    printf("\r\nFilling Addresses [$%08X - $%08X] with $%02X", StartRamPtr, EndRamPtr, FillData) ;

    while(StartRamPtr < EndRamPtr)
        *StartRamPtr++ = FillData ;
}

void Load_SRecordFile()
{
    int i, Address, AddressSize, DataByte, NumDataBytesToRead, LoadFailed, FailedAddress, AddressFail, SRecordCount = 0, ByteTotal = 0 ;
    int result, ByteCount ;

    char c, CheckSum, ReadCheckSum, HeaderType ;
    char *RamPtr ;                          // pointer to Memory where downloaded program will be stored

    LoadFailed = 0 ;                        //assume LOAD operation will pass
    AddressFail = 0 ;
    Echo = 0 ;                              // don't echo S records during download

    printf("\r\nUse HyperTerminal to Send Text File (.hex)\r\n") ;

    while(1)    {
        CheckSum = 0 ;
        do {
            c = toupper(_getch()) ;

            if(c == 0x1b )      // if break
                return;
         }while(c != (char)('S'));   // wait for S start of header

        HeaderType = _getch() ;

        if(HeaderType == (char)('0') || HeaderType == (char)('5'))       // ignore s0, s5 records
            continue ;

        if(HeaderType >= (char)('7'))
            break ;                 // end load on s7,s8,s9 records

// get the bytecount

        ByteCount = Get2HexDigits(&CheckSum) ;

// get the address, 4 digits for s1, 6 digits for s2, and 8 digits for s3 record

        if(HeaderType == (char)('1')) {
            AddressSize = 2 ;       // 2 byte address
            Address = Get4HexDigits(&CheckSum);
        }
        else if (HeaderType == (char)('2')) {
            AddressSize = 3 ;       // 3 byte address
            Address = Get6HexDigits(&CheckSum) ;
        }
        else    {
            AddressSize = 4 ;       // 4 byte address
            Address = Get8HexDigits(&CheckSum) ;
        }

        RamPtr = (char *)(Address) ;                            // point to download area

        NumDataBytesToRead = ByteCount - AddressSize - 1 ;


        for(i = 0; i < NumDataBytesToRead; i ++) {     // read in remaining data bytes (ignore address and checksum at the end
            DataByte = Get2HexDigits(&CheckSum) ;
            *RamPtr++ = DataByte ;                      // store downloaded byte in Ram at specified address
            ByteTotal++;
        }

// checksum is the 1's complement of the sum of all data pairs following the bytecount, i.e. it includes the address and the data itself

        ReadCheckSum = Get2HexDigits(0) ;

        if((~CheckSum&0Xff) != (ReadCheckSum&0Xff))   {
            LoadFailed = 1 ;
            FailedAddress = Address ;
            break;
        }

        SRecordCount++ ;

        // display feedback on progress
        if(SRecordCount % 25 == 0)
            putchar('.') ;
     }

     if(LoadFailed == 1) {
        printf("\r\nLoad Failed at Address = [$%08X]\r\n", FailedAddress) ;
     }

     else
        printf("\r\nSuccess: Downloaded %d bytes\r\n", ByteTotal) ;

     // pause at the end to wait for download to finish transmitting at the end of S8 etc

     for(i = 0; i < 400000; i ++)
        ;

     FlushKeyboard() ;
     Echo = 1;
}


void MemoryChange(void)
{
    unsigned char *RamPtr,c ; // pointer to memory
    int Data ;

    printf("\r\nExamine and Change Memory") ;
    printf("\r\n<ESC> to Stop, <SPACE> to Advance, '-' to Go Back, <DATA> to change") ;

    printf("\r\nEnter Address: ") ;
    RamPtr = Get8HexDigits(0) ;

    while(1)    {
        printf("\r\n[%08x] : %02x  ", RamPtr, *RamPtr) ;
        c = tolower(_getch()) ;

       if(c == (char)(0x1b))
            return ;                                // abort on escape

       else if((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')) {  // are we trying to change data at this location by entering a hex char
            Data = (xtod(c) << 4) | (xtod(_getch()));
            *RamPtr = (char)(Data) ;
            if(*RamPtr != Data) {
                printf("\r\nWarning Change Failed: Wrote [%02x], Read [%02x]", Data, *RamPtr) ;
            }
        }
        else if(c == (char)('-'))
            RamPtr -= 2 ; ;

        RamPtr ++ ;
    }
}

/*******************************************************************
** Write a program to SPI Flash Chip from memory and verify by reading back
********************************************************************/

void ProgramFlashChip(void)
{
    //
    // TODO : put your code here to program the 1st 256k of ram (where user program is held at hex 08000000) to SPI flash chip
    // TODO : then verify by reading it back and comparing to memory
    //
}

/*************************************************************************
** Load a program from SPI Flash Chip and copy to Dram
**************************************************************************/
void LoadFromFlashChip(void)
{
    printf("\r\nLoading Program From SPI Flash....") ;

    //
    // TODO : put your code here to read 256k of data from SPI flash chip and store in user ram starting at hex 08000000
    //

}



//////////////////////////////////////////////////////////////////////////////////////////////////
// IMPORTANT
// TG68 does not support the Native Trace mode of the original 68000 so tracing
// has to be done with an interrupt (IRQ Level 6)
//
// To allow the 68000 to execute one more instruction after each pseudo trace (IRQ6)
// the IRQ is removed in hardware once the TG68 reads the IRQ autovector (i.e. acknowledges the IRQ)
//
// on return from the IRQ service handler, the first access to the user memory program space
// generates a fresh IRQ (in hardware) to generate a new trace, this allows the tg68 to
// execute one more new instruction (without it the TG68 would trace on the same instruction
// each time and not after the next one). It also means it doesn't simgle step outside the user
// program area
//
// The bottom line is the Trace handler, which includes the Dump registers below
// cannot access the user memory to display for example the Instruction Opcode or to disassemble etc
// as this would lead to a new IRQ being reset and the TG68 would trace on same instruction
// NOT SURE THIS IS TRUE NOW THAT TRACE HANDLER HAS BEEN MODIVIED TO NOT AUTOMATICALLY GENERATE A TRACE EXCEPTION
// INSTEAD IT IS DONE IN THE 'N' COMMAND FOR NEXT
/////////////////////////////////////////////////////////////////////////////////////////////////////


void DumpRegisters()
{
    short i, x, j, k ;
    unsigned char c, *BytePointer;

// buld up strings for displaying watchpoints

    for(x = 0; x < (short)(8); x++)
    {
        if(WatchPointSetOrCleared[x] == 1)
        {
            sprintf(WatchPointString[x], "$%08X  ", WatchPointAddress[x]) ;
            BytePointer = (char *)(WatchPointAddress[x]) ;

            for(j = 0; j < (short)(16); j+=2)
            {
                for(k = 0; k < (short)(2); k++)
                {
                    sprintf(TempString, "%02X", BytePointer[j+k]) ;
                    strcat(WatchPointString[x], TempString) ;
                }
                strcat(WatchPointString[x]," ") ;
            }

            strcat(WatchPointString[x], "  ") ;
            BytePointer = (char *)(WatchPointAddress[x]) ;

            for(j = 0; j < (short)(16); j++)
            {
                c = ((char)(BytePointer[j]) & 0x7f) ;
                if((c > (char)(0x7f)) || (c < (char)(' ')))
                    sprintf(TempString, ".") ;
                else
                    sprintf(TempString, "%c", BytePointer[j]) ;
                strcat(WatchPointString[x], TempString) ;
            }
        }
        else
            strcpy(WatchPointString[x], "") ;
    }

    printf("\r\n\r\n D0 = $%08X  A0 = $%08X",d0,a0) ;
    printf("\r\n D1 = $%08X  A1 = $%08X",d1,a1) ;
    printf("\r\n D2 = $%08X  A2 = $%08X",d2,a2) ;
    printf("\r\n D3 = $%08X  A3 = $%08X",d3,a3) ;
    printf("\r\n D4 = $%08X  A4 = $%08X",d4,a4) ;
    printf("\r\n D5 = $%08X  A5 = $%08X",d5,a5) ;
    printf("\r\n D6 = $%08X  A6 = $%08X",d6,a6) ;
    printf("\r\n D7 = $%08X  A7 = $%08X",d7,((SR & (unsigned short int)(0x2000)) == ((unsigned short int)(0x2000))) ? SSP : USP) ;
    printf("\r\n\r\nUSP = $%08X  (A7) User SP", USP ) ;
    printf("\r\nSSP = $%08X  (A7) Supervisor SP", SSP) ;
    printf("\r\n SR = $%04X   ",SR) ;

// display the status word in characters etc.

    printf("   [") ;
    if((SR & (unsigned short int)(0x8000)) == (unsigned short int)(0x8000)) putchar('T') ; else putchar('-') ;      // Trace bit(bit 15)
    if((SR & (unsigned short int)(0x2000)) == (unsigned short int)(0x2000)) putchar('S') ; else putchar('U') ;      // supervisor bit  (bit 13)

    if((SR & (unsigned short int)(0x0400)) == (unsigned short int)(0x0400)) putchar('1') ; else putchar('0') ;      // IRQ2 Bit (bit 10)
    if((SR & (unsigned short int)(0x0200)) == (unsigned short int)(0x0200)) putchar('1') ; else putchar('0') ;      // IRQ1 Bit (bit 9)
    if((SR & (unsigned short int)(0x0100)) == (unsigned short int)(0x0100)) putchar('1') ; else putchar('0') ;      // IRQ0 Bit (bit 8)

    if((SR & (unsigned short int)(0x0010)) == (unsigned short int)(0x0010)) putchar('X') ; else putchar('-') ;      // X Bit (bit 4)
    if((SR & (unsigned short int)(0x0008)) == (unsigned short int)(0x0008)) putchar('N') ; else putchar('-') ;      // N Bit (bit 3)
    if((SR & (unsigned short int)(0x0004)) == (unsigned short int)(0x0004)) putchar('Z') ; else putchar('-') ;      // Z Bit (bit 2)
    if((SR & (unsigned short int)(0x0002)) == (unsigned short int)(0x0002)) putchar('V') ; else putchar('-') ;      // V Bit (bit 1)
    if((SR & (unsigned short int)(0x0001)) == (unsigned short int)(0x0001)) putchar('C') ; else putchar('-') ;      // C Bit (bit 0)
    putchar(']') ;

    printf("\r\n PC = $%08X  ", PC) ;
    if(*(unsigned short int *)(PC) == 0x4e4e)
        printf("[@ BREAKPOINT]") ;

    printf("\r\n") ;

    for(i=0; i < 8; i++)    {
        if(WatchPointSetOrCleared[i] == 1)
            printf("\r\nWP%d = %s", i, WatchPointString[i]) ;
    }

}

// Trace Exception Handler
void DumpRegistersandPause(void)
{
    printf("\r\n\r\n\r\n\r\n\r\n\r\nSingle Step  :[ON]") ;
    printf("\r\nBreak Points :[Disabled]") ;
    DumpRegisters() ;
    printf("\r\nPress <SPACE> to Execute Next Instruction");
    printf("\r\nPress <ESC> to Resume Program") ;
    menu() ;
}

void ChangeRegisters(void)
{
    // get register name d0-d7, a0-a7, up, sp, sr, pc

    int reg_val ;
    char c, reg[3] ;

    reg[0] = tolower(_getch()) ;
    reg[1] = c = tolower(_getch()) ;

    if(reg[0] == (char)('d'))  {    // change data register
        if((reg[1] > (char)('7')) || (reg[1] < (char)('0'))) {
            printf("\r\nIllegal Data Register : Use D0-D7.....\r\n") ;
            return ;
        }
        else {
            printf("\r\nD%c = ", c) ;
            reg_val = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
        }

        // bit cludgy but d0-d7 not stored as an array for good reason
        if(c == (char)('0'))
            d0 = reg_val ;
        else if(c == (char)('1'))
            d1 = reg_val ;
        else if(c == (char)('2'))
            d2 = reg_val ;
        else if(c == (char)('3'))
            d3 = reg_val ;
        else if(c == (char)('4'))
            d4 = reg_val ;
        else if(c == (char)('5'))
            d5 = reg_val ;
        else if(c == (char)('6'))
            d6 = reg_val ;
        else
            d7 = reg_val ;
    }
    else if(reg[0] == (char)('a'))  {    // change address register, a7 is the user stack pointer, sp is the system stack pointer
        if((c > (char)('7')) || (c < (char)('0'))) {
            printf("\r\nIllegal Address Register : Use A0-A7.....\r\n") ;
            return ;
        }
        else {
            printf("\r\nA%c = ", c) ;
            reg_val = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
        }
        // bit cludgy but a0-a7 not stored as an array for good reason
        if(c == (char)('0'))
            a0 = reg_val ;
        else if(c == (char)('1'))
            a1 = reg_val ;
        else if(c == (char)('2'))
            a2 = reg_val ;
        else if(c == (char)('3'))
            a3 = reg_val ;
        else if(c == (char)('4'))
            a4 = reg_val ;
        else if(c == (char)('5'))
            a5 = reg_val ;
        else if(c == (char)('6'))
            a6 = reg_val ;
        else
            USP = reg_val ;
    }
    else if((reg[0] == (char)('u')) && (c == (char)('s')))  {
           if(tolower(_getch()) == 'p')  {    // change user stack pointer
                printf("\r\nUser SP = ") ;
                USP = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
           }
           else {
                printf("\r\nIllegal Register....") ;
                return ;
           }
    }

    else if((reg[0] == (char)('s')) && (c == (char)('s')))  {
           if(tolower(_getch()) == 'p')  {    // change system stack pointer
                printf("\r\nSystem SP = ") ;
                SSP = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
           }
           else {
                printf("\r\nIllegal Register....") ;
                return ;
           }
    }

    else if((reg[0] == (char)('p')) && (c == (char)('c')))  {    // change program counter
          printf("\r\nPC = ") ;
          PC = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
    }

    else if((reg[0] == (char)('s')) && (c == (char)('r')))  {    // change status register
          printf("\r\nSR = ") ;
          SR = Get4HexDigits(0) ;    // read 16 bit value from user keyboard
    }
    else
        printf("\r\nIllegal Register: Use A0-A7, D0-D7, SSP, USP, PC or SR\r\n") ;

    DumpRegisters() ;
}

void BreakPointDisplay(void)
{
   int i, BreakPointsSet = 0 ;

// any break points  set

    for(i = 0; i < 8; i++)  {
       if(BreakPointSetOrCleared[i] == 1)
            BreakPointsSet = 1;
    }

    if(BreakPointsSet == 1) {
        printf("\r\n\r\nNum     Address      Instruction") ;
        printf("\r\n---     ---------    -----------") ;
    }
    else
        printf("\r\nNo BreakPoints Set") ;


    for(i = 0; i < 8; i++)  {
    // put opcode back, then put break point back
        if(BreakPointSetOrCleared[i] == 1)  {
            *(unsigned short int *)(BreakPointAddress[i]) = BreakPointInstruction[i];
            *(unsigned short int *)(BreakPointAddress[i]) = (unsigned short int)(0x4e4e) ;
            printf("\r\n%3d     $%08x",i, BreakPointAddress[i]) ;
        }
    }
    printf("\r\n") ;
}

void WatchPointDisplay(void)
{
   int i ;
   int WatchPointsSet = 0 ;

// any watchpoints set

    for(i = 0; i < 8; i++)  {
       if(WatchPointSetOrCleared[i] == 1)
            WatchPointsSet = 1;
    }

    if(WatchPointsSet == 1) {
        printf("\r\nNum     Address") ;
        printf("\r\n---     ---------") ;
    }
    else
        printf("\r\nNo WatchPoints Set") ;

    for(i = 0; i < 8; i++)  {
        if(WatchPointSetOrCleared[i] == 1)
            printf("\r\n%3d     $%08x",i, WatchPointAddress[i]) ;
     }
    printf("\r\n") ;
}

void BreakPointClear(void)
{
    unsigned int i ;
    volatile unsigned short int *ProgramBreakPointAddress ;

    BreakPointDisplay() ;

    printf("\r\nEnter Break Point Number: ") ;
    i = xtod(_getch()) ;           // get break pointer number

    if((i < 0) || (i > 7))   {
        printf("\r\nIllegal Range : Use 0 - 7") ;
        return ;
    }

    if(BreakPointSetOrCleared[i] == 1)  {       // if break point set
        ProgramBreakPointAddress = (volatile unsigned short int *)(BreakPointAddress[i]) ;     // point to the instruction in the user program we are about to change
        BreakPointAddress[i] = 0 ;
        BreakPointSetOrCleared[i] = 0 ;
        *ProgramBreakPointAddress = BreakPointInstruction[i] ;  // put original instruction back
        BreakPointInstruction[i] = 0 ;
        printf("\r\nBreak Point Cleared.....\r\n") ;
    }
    else
        printf("\r\nBreak Point wasn't Set.....") ;

    BreakPointDisplay() ;
    return ;
}

void WatchPointClear(void)
{
    unsigned int i ;

    WatchPointDisplay() ;

    printf("\r\nEnter Watch Point Number: ") ;
    i = xtod(_getch()) ;           // get watch pointer number

    if((i < 0) || (i > 7))   {
        printf("\r\nIllegal Range : Use 0 - 7") ;
        return ;
    }

    if(WatchPointSetOrCleared[i] == 1)  {       // if watch point set
        WatchPointAddress[i] = 0 ;
        WatchPointSetOrCleared[i] = 0 ;
        printf("\r\nWatch Point Cleared.....\r\n") ;
    }
    else
        printf("\r\nWatch Point Was not Set.....") ;

    WatchPointDisplay() ;
    return ;

}

void DisableBreakPoints(void)
{
   int i ;
   volatile unsigned short int *ProgramBreakPointAddress ;

   for(i = 0; i < 8; i++)  {
      if(BreakPointSetOrCleared[i] == 1)    {                                                    // if break point set
          ProgramBreakPointAddress = (volatile unsigned short int *)(BreakPointAddress[i]) ;     // point to the instruction in the user program where the break point has been set
          *ProgramBreakPointAddress = BreakPointInstruction[i];                                  // copy the instruction back to the user program overwritting the $4e4e
      }
   }
}

void EnableBreakPoints(void)
{
   int i ;
   volatile unsigned short int *ProgramBreakPointAddress ;

   for(i = 0; i < 8; i++)  {
      if(BreakPointSetOrCleared[i] == 1)    {                                                     // if break point set
           ProgramBreakPointAddress = (volatile unsigned short int *)(BreakPointAddress[i]) ;     // point to the instruction in the user program where the break point has been set
           *ProgramBreakPointAddress = (unsigned short int)(0x4e4e);                              // put the breakpoint back in user program
      }
   }
}

void KillAllBreakPoints(void)
{
   int i ;
   volatile unsigned short int *ProgramBreakPointAddress ;

   for(i = 0; i < 8; i++)  {
       // clear BP
       ProgramBreakPointAddress = (volatile unsigned short int *)(BreakPointAddress[i]) ;     // point to the instruction in the user program where the break point has been set
       *ProgramBreakPointAddress = BreakPointInstruction[i];                                  // copy the instruction back to the user program
       BreakPointAddress[i] = 0 ;                                                             // set BP address to NULL
       BreakPointInstruction[i] = 0 ;
       BreakPointSetOrCleared[i] = 0 ;                                                        // mark break point as cleared for future setting
   }
   //BreakPointDisplay() ;       // display the break points
}

void KillAllWatchPoints(void)
{
   int i ;

   for(i = 0; i < 8; i++)  {
       WatchPointAddress[i] = 0 ;                                                             // set BP address to NULL
       WatchPointSetOrCleared[i] = 0 ;                                                        // mark break point as cleared for future setting
   }
   //WatchPointDisplay() ;       // display the break points
}


void SetBreakPoint(void)
{
    int i ;
    int BPNumber;
    int BPAddress;
    volatile unsigned short int *ProgramBreakPointAddress ;

    // see if any free break points

    for(i = 0; i < 8; i ++) {
        if( BreakPointSetOrCleared[i] == 0)
            break ;         // if spare BP found allow user to set it
    }

    if(i == 8) {
        printf("\r\nNo FREE Break Points.....") ;
        return ;
    }

    printf("\r\nBreak Point Address: ") ;
    BPAddress = Get8HexDigits(0) ;
    ProgramBreakPointAddress = (volatile unsigned short int *)(BPAddress) ;     // point to the instruction in the user program we are about to change

    if((BPAddress & 0x00000001) == 0x00000001)  {   // cannot set BP at an odd address
        printf("\r\nError : Break Points CANNOT be set at ODD addresses") ;
        return ;
    }

    if(BPAddress < 0x00008000)  {   // cannot set BP in ROM
        printf("\r\nError : Break Points CANNOT be set for ROM in Range : [$0-$00007FFF]") ;
        return ;
    }

    // search for first free bp or existing same BP

    for(i = 0; i < 8; i++)  {
        if(BreakPointAddress[i] == BPAddress)   {
            printf("\r\nError: Break Point Already Exists at Address : %08x\r\n", BPAddress) ;
            return ;
        }
        if(BreakPointSetOrCleared[i] == 0) {
            // set BP here
            BreakPointSetOrCleared[i] = 1 ;                                 // mark this breakpoint as set
            BreakPointInstruction[i] = *ProgramBreakPointAddress ;          // copy the user program instruction here so we can put it back afterwards
            printf("\r\nBreak Point Set at Address: [$%08x]", ProgramBreakPointAddress) ;
            *ProgramBreakPointAddress = (unsigned short int)(0x4e4e)    ;   // put a Trap14 instruction at the user specified address
            BreakPointAddress[i] = BPAddress ;                              // record the address of this break point in the debugger
            printf("\r\n") ;
            BreakPointDisplay() ;       // display the break points
            return ;
        }
    }
}

void SetWatchPoint(void)
{
    int i ;
    int WPNumber;
    int WPAddress;
    volatile unsigned short int *ProgramWatchPointAddress ;

    // see if any free break points

    for(i = 0; i < 8; i ++) {
        if( WatchPointSetOrCleared[i] == 0)
            break ;         // if spare WP found allow user to set it
    }

    if(i == 8) {
        printf("\r\nNo FREE Watch Points.....") ;
        return ;
    }

    printf("\r\nWatch Point Address: ") ;
    WPAddress = Get8HexDigits(0) ;

    // search for first free wp or existing same wp

    for(i = 0; i < 8; i++)  {
        if(WatchPointAddress[i] == WPAddress && WPAddress != 0)   {     //so we can set a wp at 0
            printf("\r\nError: Watch Point Already Set at Address : %08x\r\n", WPAddress) ;
            return ;
        }
        if(WatchPointSetOrCleared[i] == 0) {
            WatchPointSetOrCleared[i] = 1 ;                                 // mark this watchpoint as set
            printf("\r\nWatch Point Set at Address: [$%08x]", WPAddress) ;
            WatchPointAddress[i] = WPAddress ;                              // record the address of this watch point in the debugger
            printf("\r\n") ;
            WatchPointDisplay() ;       // display the break points
            return ;
        }
    }
}


void HandleBreakPoint(void)
{
    volatile unsigned short int *ProgramBreakPointAddress ;

    // now we have to put the break point back to run the instruction
    // PC will contain the address of the TRAP instruction but advanced by two bytes so lets play with that

    PC = PC - 2 ;  // ready for user to resume after reaching breakpoint

    printf("\r\n\r\n\r\n\r\n@BREAKPOINT") ;
    printf("\r\nSingle Step : [ON]") ;
    printf("\r\nBreakPoints : [Enabled]") ;

    // now clear the break point (put original instruction back)

    ProgramBreakPointAddress = PC ;

    for(i = 0; i < 8; i ++) {
        if(BreakPointAddress[i] == PC) {        // if we have found the breakpoint
            BreakPointAddress[i] = 0 ;
            BreakPointSetOrCleared[i] = 0 ;
            *ProgramBreakPointAddress = BreakPointInstruction[i] ;  // put original instruction back
            BreakPointInstruction[i] = 0 ;
        }
    }

    DumpRegisters() ;
    printf("\r\nPress <SPACE> to Execute Next Instruction");
    printf("\r\nPress <ESC> to Resume User Program\r\n") ;
    menu() ;
}

void UnknownCommand()
{
    printf("\r\nUnknown Command.....\r\n") ;
    Help() ;
}

// system when the users program executes a TRAP #15 instruction to halt program and return to debug monitor

void CallDebugMonitor(void)
{
    printf("\r\nProgram Ended (TRAP #15)....") ;
    menu();
}

void Breakpoint(void)
{
       char c;
       c = toupper(_getch());

        if( c == (char)('D'))                                      // BreakPoint Display
            BreakPointDisplay() ;

        else if(c == (char)('K')) {                                 // breakpoint Kill
            printf("\r\nKill All Break Points...(y/n)?") ;
            c = toupper(_getch());
            if(c == (char)('Y'))
                KillAllBreakPoints() ;
        }
        else if(c == (char)('S')) {
            SetBreakPoint() ;
        }
        else if(c == (char)('C')) {
            BreakPointClear() ;
        }
        else
            UnknownCommand() ;
}

void Watchpoint(void)
{
       char c;
       c = toupper(_getch());

        if( c == (char)('D'))                                      // WatchPoint Display
            WatchPointDisplay() ;

        else if(c == (char)('K')) {                                 // wtahcpoint Kill
            printf("\r\nKill All Watch Points...(y/n)?") ;
            c = toupper(_getch());
            if(c == (char)('Y'))
                KillAllWatchPoints() ;
        }
        else if(c == (char)('S')) {
            SetWatchPoint() ;
        }
        else if(c == (char)('C')) {
            WatchPointClear() ;
        }
        else
            UnknownCommand() ;
}



void Help(void)
{
    char *banner = "\r\n----------------------------------------------------------------" ;

    printf(banner) ;
    printf("\r\n  Debugger Command Summary") ;
    printf(banner) ;
    printf("\r\n  .(reg)       - Change Registers: e.g A0-A7,D0-D7,PC,SSP,USP,SR");
    printf("\r\n  BD/BS/BC/BK  - Break Point: Display/Set/Clear/Kill") ;
    printf("\r\n  C            - Copy Program from Flash to Main Memory") ;
    printf("\r\n  D            - Dump Memory Contents to Screen") ;
    printf("\r\n  E            - Enter String into Memory") ;
    printf("\r\n  F            - Fill Memory with Data") ;
    printf("\r\n  G            - Go Program Starting at Address: $%08X", PC) ;
    printf("\r\n  L            - Load Program (.HEX file) from Laptop") ;
    printf("\r\n  M            - Memory Examine and Change");
    printf("\r\n  P            - Program Flash Memory with User Program") ;
    printf("\r\n  R            - Display 68000 Registers") ;
    printf("\r\n  S            - Toggle ON/OFF Single Step Mode") ;
    printf("\r\n  TM           - Test Memory") ;
    printf("\r\n  TS           - Test Switches: SW7-0") ;
    printf("\r\n  TD           - Test Displays: LEDs and 7-Segment") ;
    printf("\r\n  WD/WS/WC/WK  - Watch Point: Display/Set/Clear/Kill") ;
    printf(banner) ;
}


void menu(void)
{
    char c,c1 ;

    while(1)    {
        FlushKeyboard() ;               // dump unread characters from keyboard
        printf("\r\n#") ;
        c = toupper(_getch());

        if( c == (char)('L'))                  // load s record file
             Load_SRecordFile() ;

        else if( c == (char)('D'))             // dump memory
            DumpMemory() ;

        else if( c == (char)('E'))             // Enter String into memory
            EnterString() ;

        else if( c == (char)('F'))             // fill memory
            FillMemory() ;

        else if( c == (char)('G'))  {           // go user program
            printf("\r\nProgram Running.....") ;
            printf("\r\nPress <RESET> button <Key0> on DE1 to stop") ;
            GoFlag = 1 ;
            go() ;
        }

        else if( c == (char)('M'))           // memory examine and modify
             MemoryChange() ;

        else if( c == (char)('P'))            // Program Flash Chip
             ProgramFlashChip() ;

        else if( c == (char)('C'))             // copy flash chip to ram and go
             LoadFromFlashChip();

        else if( c == (char)('R'))             // dump registers
             DumpRegisters() ;

        else if( c == (char)('.'))           // change registers
             ChangeRegisters() ;

        else if( c == (char)('B'))              // breakpoint command
            Breakpoint() ;

        else if( c == (char)('T'))  {          // Test command
             c1 = toupper(_getch()) ;
             if(c1 == (char)('M'))                    // memory test
                MemoryTest() ;
             else if( c1 == (char)('S'))              // Switch Test command
                SwitchTest() ;
             else if( c1 == (char)('D'))              // display Test command
                TestLEDS() ;
             else
                UnknownCommand() ;
        }

        else if( c == (char)(' ')) {             // Next instruction command
            DisableBreakPoints() ;
            if(Trace == 1 && GoFlag == 1)   {    // if the program is running and trace mode on then 'N' is valid
                TraceException = 1 ;             // generate a trace exception for the next instruction if user wants to single step though next instruction
                return ;
            }
            else
                printf("\r\nError: Press 'G' first to start program") ;
        }

        else if( c == (char)('S')) {             // single step
             if(Trace == 0) {
                DisableBreakPoints() ;
                printf("\r\nSingle Step  :[ON]") ;
                printf("\r\nBreak Points :[Disabled]") ;
                SR = SR | (unsigned short int)(0x8000) ;    // set T bit in status register
                printf("\r\nPress 'G' to Trace Program from address $%08x.....",PC) ;
                printf("\r\nPush <RESET Button> to Stop.....") ;
                DumpRegisters() ;

                Trace = 1;
                TraceException = 1;
                x = *(unsigned int *)(0x00000074) ;       // simulate responding to a Level 5 IRQ by reading vector to reset Trace exception generator
            }
            else {
                Trace = 0 ;
                TraceException = 0 ;
                x = *(unsigned int *)(0x00000074) ;       // simulate responding to a Level 5 IRQ by reading vector to reset Trace exception generator
                EnableBreakPoints() ;
                SR = SR & (unsigned short int)(0x7FFF) ;    // clear T bit in status register
                printf("\r\nSingle Step : [OFF]") ;
                printf("\r\nBreak Points :[Enabled]") ;
                printf("\r\nPress <ESC> to Resume User Program.....") ;
            }
        }

        else if(c == (char)(0x1b))  {   // if user choses to end trace and run program
            Trace = 0;
            TraceException = 0;
            x = *(unsigned int *)(0x00000074) ;   // read IRQ 5 vector to reset trace vector generator
            EnableBreakPoints() ;
            SR = SR & (unsigned short int)(0x7FFF) ;    // clear T bit in status register

            printf("\r\nSingle Step  :[OFF]") ;
            printf("\r\nBreak Points :[Enabled]");
            printf("\r\nProgram Running.....") ;
            printf("\r\nPress <RESET> button <Key0> on DE1 to stop") ;
            return ;
        }

        else if( c == (char)('W'))              // Watchpoint command
            Watchpoint() ;

        else
            UnknownCommand() ;
    }
}

void PrintErrorMessageandAbort(char *string) {
    printf("\r\n\r\nProgram ABORT !!!!!!\r\n") ;
    printf("%s\r\n", string) ;
    menu() ;
}

void IRQMessage(int level) {
     printf("\r\n\r\nProgram ABORT !!!!!");
     printf("\r\nUnhandled Interrupt: IRQ%d !!!!!", level) ;
     menu() ;
}

void UnhandledIRQ1(void) {
     IRQMessage(1);
}

void UnhandledIRQ2(void) {
    IRQMessage(2);
}

void UnhandledIRQ3(void){
    IRQMessage(3);
}

void UnhandledIRQ4(void) {
     IRQMessage(4);
}

void UnhandledIRQ5(void) {
    IRQMessage(5);
}

void UnhandledIRQ6(void) {
    PrintErrorMessageandAbort("ADDRESS ERROR: 16 or 32 Bit Transfer to/from an ODD Address....") ;
    menu() ;
}

void UnhandledIRQ7(void) {
    IRQMessage(7);
}

void UnhandledTrap(void) {
    PrintErrorMessageandAbort("Unhandled Trap !!!!!") ;
}

void BusError() {
   PrintErrorMessageandAbort("BUS Error!") ;
}

void AddressError() {
   PrintErrorMessageandAbort("ADDRESS Error!") ;
}

void IllegalInstruction() {
    PrintErrorMessageandAbort("ILLEGAL INSTRUCTION") ;
}

void Dividebyzero() {
    PrintErrorMessageandAbort("DIVIDE BY ZERO") ;
}

void Check() {
   PrintErrorMessageandAbort("'CHK' INSTRUCTION") ;
}

void Trapv() {
   PrintErrorMessageandAbort("TRAPV INSTRUCTION") ;
}

void PrivError() {
    PrintErrorMessageandAbort("PRIVILEGE VIOLATION") ;
}

void UnitIRQ() {
    PrintErrorMessageandAbort("UNINITIALISED IRQ") ;
}

void Spurious() {
    PrintErrorMessageandAbort("SPURIOUS IRQ") ;
}

void EnterString(void)
{
    unsigned char *Start;
    unsigned char c;

    printf("\r\nStart Address in Memory: ") ;
    Start = Get8HexDigits(0) ;

    printf("\r\nEnter String (ESC to end) :") ;
    while((c = getchar()) != 0x1b)
        *Start++ = c ;

    *Start = 0x00;  // terminate with a null
}

// Memory test helper functions
int Get2HexDigitsForMemTest(char pat)
{
    return (xtod(pat) << 4) | (xtod(pat));
}

int Get4HexDigitsForMemTest(char pat)
{
    return (xtod(pat) << 12) | (xtod(pat) << 8) |(Get2HexDigitsForMemTest(pat));
}

int Get8HexDigitsForMemTest(char pat)
{
    return  (xtod(pat) << 28) | (xtod(pat) << 24) | (xtod(pat) << 20) | (xtod(pat) << 16) |(Get4HexDigitsForMemTest(pat));
}

int Get7HexDigitsForMemTest(char one, char two, char three, char four, char five, char six, char seven)
{
    return (xtod(one) << 24) | (xtod(two) << 20) | (xtod(three) << 16) | (xtod(four) << 12) | (xtod(five) << 8) | (xtod(six) << 4) | (xtod(seven));

}

int Get7HexDigits(void)
{
    register int i = (xtod(_getch()) << 24) | (xtod(_getch()) << 20) | (xtod(_getch()) << 16) | (xtod(_getch()) << 12) | (xtod(_getch()) << 8) | (xtod(_getch()) << 4) | (xtod(_getch()));

    return i;
}

void FillMemoryForMemTest(char* StartRamPtr, char* EndRamPtr, unsigned long FillData, int config)
{
    char* start = StartRamPtr;
    printf("\r\nFilling Addresses [$%08X - $%08X] with $%02X", StartRamPtr, EndRamPtr, FillData);

    if (config == 1) {
        while (start <= EndRamPtr){
            *start++ = FillData;
            }
    }

    if (config == 2) {
        while (start <= EndRamPtr) {
            *start = FillData;
            start += 1;
        }
    }

    if (config == 3) {
        while (start <= EndRamPtr) {
            *start = FillData;
            start += 1;
        }
    }


}

void ReadMemoryForMemTest(char* StartRamPtr, char* EndRamPtr, unsigned long FillData, int config)
{
    unsigned char* start = StartRamPtr;

    printf("\r\nReading Addresses [$%08X - $%08X] for $%02X", StartRamPtr, EndRamPtr, FillData);

    if (config == 1) {
        while (start <= EndRamPtr) {
            if (*start != FillData)
                printf("\r\nValue incorrect at addresses $%08X ... should be $%02X but found $%02X", start, FillData, *start);
            printf("\r\nValue: $%02X found at Address: $%08X", *start, start);
            start++;
        }
    }

    if (config == 2) {
        while (start <= EndRamPtr) {
            if(*start != FillData)
                printf("\r\nValue incorrect at addresses $%08X ... should be $%02X but found $%02X", start, FillData, *start);
            printf("\r\nValue: $%02X $%02X found at Address: $%08X and $%08X", *start, *(start + 1), start, (start + 1));
            start += 2;
        }
    }

    if (config == 3) {
        while (start <= EndRamPtr) {
            if (*start != FillData)
                printf("\r\nValue incorrect at addresses $%08X ... should be $%02X but found $%02X", start, FillData, *start);
             printf("\r\nValue: $%02X $%02X $%02X $%02X found at Address: $%08X - $%08X", *start, *(start + 1), *(start + 2), *(start + 3), start, (start + 3));
             start += 4;
        }
    }


}

void MemoryTest(void)
{
    unsigned int start_boundary = 0xF0000000;
    unsigned int end_boundary = 0xF3FFFFFF;
    int test_config = 0;
    int test_pattern = 0;
    char start_addr[7];
    int start_val = 0;
    char end_addr[7];
    int end_val = 0;
    char digit;

    scanflush();

    // Prompt the user to enter a test configuration
    printf("\r\nEnter memory test configuration(1 - bytes, 2 - words, 3 - long words): ");
    test_config = (int)(xtod(_getch()));
    // Check for invalid configuration entry and re-prompt if needed
    while (test_config > 3 || test_config < 1) {
        printf("\r\nConfiguration invalid %d, try again", test_config);
        printf("\r\nEnter memory test configuration(1 - bytes, 2 - words, 3 - long words): ");
        test_config = (int)(xtod(_getch()));
        //scanf("%d", &test_config);
    }

    // Prompt the user to enter a test pattern
    printf("\r\nChoose between different memory test patterns(1 - 5, 2 - A, 3 - F, 4 - 0): ");
    test_pattern = (int)(xtod(_getch()));
    // Check for invalid pattern entry and re-prompt if needed
    while (test_pattern > 4 || test_pattern < 1) {
        printf("\r\nPattern invalid, try again");
        printf("\r\nChoose between different memory test patterns(1 - 5, 2 - A, 3 - F, 4 - 0): ");
        //scanf("%d", &test_pattern);
        test_pattern = (int)(xtod(_getch()));
    }

    // Prompt the user to enter a starting address
    printf("\r\nEnter starting address(%X - %X inclusive): ", start_boundary, end_boundary);
    start_val = Get8HexDigits(0);
    // Check for invalid start address and re-prompt if needed
    // Check for illegal address, start address must be even if writing words or long words to memory
    while (start_val < start_boundary || start_val > end_boundary || strlen(start_addr) > 7 || (start_val % 2 != 0 && test_config != 1))
    { // start address must be 7 chars and within bounds
        printf("\r\nInvalid starting address.. try again");
        //printf("\r\nStarting address out of bounds.. try again");
        printf("\r\nEnter starting address(%X - %X inclusive): ", start_boundary, end_boundary);
        start_val = Get8HexDigits(0);
    }


    // Prompt the user to enter an ending address
        printf("\r\nEnter ending address(%X - %X inclusive): ", start_boundary, end_boundary);
        end_val = Get8HexDigits(0);
        // When writing words, the given address range should be a multiple of 2 bytes (size of a word)
        // When writing long words, the given address range should be a multiple of 4 bytes (size of a long word)
        while (end_val < start_boundary || end_val > end_boundary || strlen(end_addr) > 7 ||
               end_val < start_val || ((end_val - start_val + 1) % 2 != 0 && test_config == 2) ||
               ((end_val - start_val + 1) % 4 != 0 && test_config == 3))
        { // end address must be 7 chars and within bounds
             printf("\r\nEnding address out of bounds.. try again");
             printf("\r\nEnter ending address(%X - %X inclusive): ", start_boundary, end_boundary);
             end_val = Get8HexDigits(0);
    }

    printf("\r\nWriting to SRAM ...");
    printf("\r\n............................................................................................................");
    printf("\r\n............................................................................................................");
    printf("\r\n............................................................................................................");

    switch (test_pattern) {
        case 1: digit = '5';
                break;
        case 2: digit = 'A';
                break;
        case 3: digit = 'F';
                break;
        case 4: digit = '0';
                break;
        default: digit = '5';
    }


    switch (test_config) {
        case 1: FillMemoryForMemTest(start_val, end_val, Get2HexDigitsForMemTest(digit), 1);
                break;
        case 2: FillMemoryForMemTest(start_val, end_val, Get4HexDigitsForMemTest(digit), 2);
                break;
        case 3: FillMemoryForMemTest(start_val, end_val, Get8HexDigitsForMemTest(digit), 3);
                break;
        default: FillMemoryForMemTest(start_val, end_val, Get2HexDigitsForMemTest(digit), 1);;
    }


    printf("\r\nFinished writing to SRAM .");
    printf("\r\nCheck SRAM content");

    printf("\r\nReading from SRAM ...");
    printf("\r\n............................................................................................................");
    printf("\r\n............................................................................................................");
    printf("\r\n............................................................................................................");
    printf("\r\n....................... begin reading");


    switch (test_config) {
        case 1: ReadMemoryForMemTest(start_val, end_val, Get2HexDigitsForMemTest(digit), 1);
                break;
        case 2: ReadMemoryForMemTest(start_val, end_val, Get4HexDigitsForMemTest(digit), 2);
                break;
        case 3: ReadMemoryForMemTest(start_val, end_val, Get8HexDigitsForMemTest(digit), 3);
                break;
        default: ReadMemoryForMemTest(start_val, end_val, Get2HexDigitsForMemTest(digit), 1);;
    }


    printf("\r\nFinished reading from SRAM ...");
    printf("\r\nend of program ...");
    printf("\r\n............................................................................................................");
    printf("\r\n............................................................................................................");

}

void main(void)
{
    char c ;
    int i, j ;

    char *BugMessage = "DE1-68k Bug V1.77";
    char *CopyrightMessage = "Copyright (C) PJ Davies 2016";

    KillAllBreakPoints() ;

    i = x = y = z = PortA_Count = 0;
    Trace = GoFlag = 0;                       // used in tracing/single stepping
    Echo = 1 ;

    d0=d1=d2=d3=d4=d5=d6=d7=0 ;
    a0=a1=a2=a3=a4=a5=a6=0 ;


    PC = ProgramStart, SSP=TopOfStack, USP = TopOfStack;
    SR = 0x2000;                            // clear interrupts enable tracing  uses IRQ6

// Initialise Breakpoint variables

    for(i = 0; i < 8; i++)  {
        BreakPointAddress[i] = 0;               //array of 8 breakpoint addresses
        WatchPointAddress[i] = 0 ;
        BreakPointInstruction[i] = 0;           // to hold the instruction at the break point
        BreakPointSetOrCleared[i] = 0;          // indicates if break point set
        WatchPointSetOrCleared[i] = 0;
    }

    Init_RS232() ;     // initialise the RS232 port
    Init_LCD() ;

    for( i = 32; i < 48; i++)
       InstallExceptionHandler(UnhandledTrap, i) ;		        // install Trap exception handler on vector 32-47

    InstallExceptionHandler(menu, 47) ;		                   // TRAP #15 call debug and end program
    InstallExceptionHandler(UnhandledIRQ1, 25) ;		      // install handler for interrupts
    InstallExceptionHandler(UnhandledIRQ2, 26) ;		      // install handler for interrupts
    InstallExceptionHandler(UnhandledIRQ3, 27) ;		      // install handler for interrupts
    InstallExceptionHandler(UnhandledIRQ4, 28) ;		      // install handler for interrupts
    InstallExceptionHandler(UnhandledIRQ5, 29) ;		      // install handler for interrupts
    InstallExceptionHandler(UnhandledIRQ6, 30) ;		      // install handler for interrupts
    InstallExceptionHandler(UnhandledIRQ7, 31) ;		      // install handler for interrupts


    InstallExceptionHandler(HandleBreakPoint, 46) ;		           // install Trap 14 Break Point exception handler on vector 46
    InstallExceptionHandler(DumpRegistersandPause, 29) ;		   // install TRACE handler for IRQ5 on vector 29

    InstallExceptionHandler(BusError,2) ;                          // install Bus error handler
    InstallExceptionHandler(AddressError,3) ;                      // install address error handler (doesn't work on soft core 68k implementation)
    InstallExceptionHandler(IllegalInstruction,4) ;                // install illegal instruction exception handler
    InstallExceptionHandler(Dividebyzero,5) ;                      // install /0 exception handler
    InstallExceptionHandler(Check,6) ;                             // install check instruction exception handler
    InstallExceptionHandler(Trapv,7) ;                             // install trapv instruction exception handler
    InstallExceptionHandler(PrivError,8) ;                         // install Priv Violation exception handler
    InstallExceptionHandler(UnitIRQ,15) ;                          // install uninitialised IRQ exception handler
    InstallExceptionHandler(Check,24) ;                            // install spurious IRQ exception handler


    FlushKeyboard() ;                        // dump unread characters from keyboard
    TraceException = 0 ;                     // clear trace exception port to remove any software generated single step/trace


    // test for auto flash boot and run from Flash by reading switch 9 on DE1-soc board. If set, copy program from flash into Dram and run

    while(((char)(PortB & 0x02)) == (char)(0x02))    {
        LoadFromFlashChip();
        printf("\r\nRunning.....") ;
        Oline1("Running.....") ;
        GoFlag = 1;
        go() ;
    }

    // otherwise start the debug monitor

    Oline0(BugMessage) ;
    Oline1("By: PJ Davies") ;

    printf("\r\n%s", BugMessage) ;
    printf("\r\n%s", CopyrightMessage) ;
    printf("\r\nNancy Makar - 33464918 and Steven Chin - 40108540 - version 1");

    menu();
}
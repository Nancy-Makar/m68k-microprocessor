#include <stdio.h>


/*********************************************************************************************
**	RS232 port addresses defined as pointers
*********************************************************************************************/

#define RS232_Control     (*(volatile unsigned char *)(0x00400040))
#define RS232_Status      (*(volatile unsigned char *)(0x00400040))
#define RS232_TxData      (*(volatile unsigned char *)(0x00400042))
#define RS232_RxData      (*(volatile unsigned char *)(0x00400042))
#define RS232_Baud        (*(volatile unsigned char *)(0x00400044))

/*********************************************************************************************
**  Subroutine to initialise the RS232 Port by writing some commands to the internal registers
**	Call this function at the start of the program before you attempt to read or write to hyperterminal
*********************************************************************************************/
void Init_RS232(void)
{
    RS232_Control = 0x15 ; //  %00010101 set up serial port to use divide by 16 clock, set RTS low, 8 bits no parity, 1 stop bit, transmitter interrupt disabled
    RS232_Baud = 0x1 ;      // program serial port speed: 000 = 230 kbaud, 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
}

/*********************************************************************************************************
**  Subroutine to provide a low level output function to 6850 ACIA
**  This routine provides the basic functionality to output a single character to the serial Port
**  to allow the board to communicate with HyperTerminal Program
**
**  NOTE you do NOT call this function directly, instead  call the normal putchar() function
**  which in turn calls _putch() below.
**
**	Other functions like puts(), printf() call putchar() so will
**  call _putch() below so it's fully integrates into the C standard library routines
*********************************************************************************************************/

int _putch(int c)
{
// write the character to the RS232 port first - comment out if not wanted

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
**  which in turn calls _getch() below).
**	Other functions like gets(), scanf() call getchar() so will
**  call _getch() below so it's fully integrates into the C standard library routines
*********************************************************************************************************/
int _getch( void )
{
    while((RS232_Status & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
        ;

    return (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character
}


int a[100][100], b[100][100], c[100][100];
int i, j, k, sum;

int main(void)
{
    Init_RS232();

    printf("\n\nStart.....");
    for(i=0; i <50; i ++)  {
        printf("%d ", i);
        for(j=0; j < 50; j++)  {
            sum = 0 ;
            for(k=0; k <50; k++)   {
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
                sum = sum + b[i][k] * b[k][j] + a[i][k] * c[i][j];
            }
            c[i][j] = sum ;
        }
    }
    printf("\n\nDone.....");
    return 0 ;
}
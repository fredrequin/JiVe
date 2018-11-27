
/****************************************************************************
 * Types
 ****************************************************************************/

typedef unsigned int   uint32_t;    // 32 Bit
typedef signed   int    int32_t;    // 32 Bit

typedef unsigned short uint16_t;    // 16 Bit
typedef signed   short  int16_t;    // 16 Bit

typedef unsigned char   uint8_t;    // 8 Bit
typedef signed   char    int8_t;    // 8 Bit

/****************************************************************************
 * CPU related
 ****************************************************************************/
 
#define RAM_MIN_ADDR   ((uint32_t)0x80000000)
#define RAM_MAX_ADDR   ((uint32_t)0x80010000)

extern void halt(void);
extern void jump(uint32_t addr);

/***************************************************************************
 * Simple UART hardware
 ***************************************************************************/
 
typedef struct
{
    uint32_t   rx_tx_data;
} uart_hw_t;

#define UART_BASE ((uart_hw_t volatile *)0x00020000)

/***************************************************************************
 * UART routines
 ***************************************************************************/

// Read a character from the serial port
static uint32_t uart_getchar(uart_hw_t volatile *p)
{
    return p->rx_tx_data;
}

// Write a character to the serial port
static void uart_putchar(uart_hw_t volatile *p, char c)
{
    p->rx_tx_data = (uint32_t)c;
}

// Read an hexadecimal number from the serial port
static uint32_t uart_gethex(uart_hw_t volatile *p, int n)
{
    uint32_t ch;
    uint32_t val = 0;

    while (n)
    {
        n--;
        val <<= 4;

        ch = p->rx_tx_data - '0';
        if (ch < 0) continue;
        if (ch >= 17) ch -= 7;
        val |= (ch & 15);
    }

    return val;
}

/***************************************************************************
 * UART bootloader
 ***************************************************************************/
 
int main(int argc, char **argv)
{
    
    uint32_t rec;
    
    uart_putchar(UART_BASE, 0x42); // 'B'
    uart_putchar(UART_BASE, 0x4F); // 'O'
    uart_putchar(UART_BASE, 0x4F); // 'O'
    uart_putchar(UART_BASE, 0x54); // 'T'
    
    /*
    // Loop-back test
    while (1)
    {
        rec = uart_getchar(UART_BASE);
        uart_putchar(UART_BASE, rec);
    }
    */
    
    // Read S-Record lines from the serial port
    rec = 0;
    while (rec < 0x37)
    {
        uint32_t tmp;
        uint32_t len;
        uint8_t *addr;
        uint32_t cks;
    
        // Check 'S' character
        tmp = uart_getchar(UART_BASE);
        if (tmp != 0x53) goto error; // 'S'
    
        // Check record type
        tmp = uart_getchar(UART_BASE);
        switch(tmp)
        {
            case 0x30 : // S0 record
            case 0x31 : // S1 record
            case 0x35 : // S5 record
            case 0x39 : // S9 record
            {
                // Keep the record type
                rec = tmp;
    
                // Initialize checksum
                cks = uart_gethex(UART_BASE, 2);
    
                // Update length
                len = cks - 2;
    
                // Get 16-bit address
                tmp = uart_gethex(UART_BASE, 4);
    
                break;
            }
            case 0x32 : // S2 record
            case 0x38 : // S8 record
            {
                // Keep the record type
                rec = tmp;
    
                // Initialize checksum
                cks = uart_gethex(UART_BASE, 2);
    
                // Update length
                len = cks - 3;
    
                // Get 24-bit address
                tmp = uart_gethex(UART_BASE, 6);
    
                // Update checksum
                cks += (tmp >> 16);
    
                break;
            }
            case 0x33 : // S3 record
            case 0x37 : // S7 record
            {
                // Keep the record type
                rec = tmp;
    
                // Initialize checksum
                cks = uart_gethex(UART_BASE, 2);
    
                // Update length
                len = cks - 4;
    
                // Get 32-bit address
                tmp = uart_gethex(UART_BASE, 8);
    
                // Update checksum
                cks += (tmp >> 24);
                cks += (tmp >> 16);
    
                break;
            }
            default : // Unknown record
            {
                goto error;
            }
        }
    
        // Update checksum
        cks += (tmp >> 8);
        cks += tmp;
    
        // Check address range
        if (((tmp < RAM_MIN_ADDR) || ((tmp + len) > RAM_MAX_ADDR)) &&
             (tmp != 0)) goto error;
        addr = (uint8_t *)tmp;
    
        // Read data
        while (len > 1)
        {
            tmp = uart_gethex(UART_BASE, 2);
            cks += tmp;
            len--;
    
            if ((rec == 0x31) || (rec == 0x32) || (rec == 0x33)) // S1, S2 or S3 record
            {
                // Write data to memory
                *addr++ = (uint8_t)tmp;
            }
            if (rec == 0x30)
            {
                // Echo header
                uart_putchar(UART_BASE, (char)tmp);
            }
        }
    
        // Read checksum
        cks += uart_gethex(UART_BASE, 2);
        cks &= 0xFF;
        if (cks != 0xFF) goto error;
    
        // Flush CR/LF
        if (uart_getchar(UART_BASE) != 0x0D) goto error;
        if (uart_getchar(UART_BASE) != 0x0A) goto error;
        uart_putchar(UART_BASE, '.');
    }
    // Finished
    uart_putchar(UART_BASE, 0x0D);
    uart_putchar(UART_BASE, 0x0A);
            
    // Jump to application SW
    jump(RAM_MIN_ADDR);
    
error:
    // Error : halt CPU
    uart_putchar(UART_BASE, '!');
    
    halt();
    
    return 0;
}

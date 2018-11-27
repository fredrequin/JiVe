#include "Vjive_soc_top.h"
#include "verilated.h"
#include "clock_gen/clock_gen.h"
#include "riscv_trace/riscv_trace.h"

#include <ctime>

#if VM_TRACE
#include "verilated_vcd_c.h"
#endif

// Period for a 100 MHz clock
#define PERIOD_100MHz_ps      ((vluint64_t)10000)

// Clocks generation (global)
ClockGen *clk;

// RISC-V tracing (global)
RISCVTrace *trc;

// 64KB RAM block initialization
vluint8_t ram_blk_init[65536];

static vluint32_t fgethex(FILE *fh, int digit)
{
    vluint32_t val = 0;
    int ch;

    while (digit)
    {
        digit--;
        val <<= 4;
        
        ch = fgetc(fh) - '0';
        if (ch < 0) break;
        if (ch >= 17) ch -= 7;
        val |= (ch & 15);
    }
    
    return val;
}

static int read_srec(FILE *fh, vluint32_t offs, vluint32_t size, vluint8_t *ptr)
{
    int rec = 0;
    int line = 1;
    
    while (rec < 0x37)
    {
        int ch;
        vluint32_t cks;
        vluint32_t len;
        vluint32_t tmp;
        vluint32_t addr;
        
        // Check 'S' character
        ch = fgetc(fh);
        if (ch != 'S')
        {
            printf("No starting S line #%d!\n", line);
            return -1;
        }
        
        // Check record type
        rec = fgetc(fh);
        switch (rec)
        {
            case '0' : // S0 record
            case '1' : // S1 record
            case '5' : // S5 record
            case '9' : // S9 record
            {
                cks = fgethex(fh, 2); // 8-bit length
                len = cks - 2;
                addr = fgethex(fh, 4); // 16-bit address
                break;
            }
            case '2' : // S2 record
            case '8' : // S8 record
            {
                cks = fgethex(fh, 2); // 8-bit length
                len = cks - 3;
                addr = fgethex(fh, 6); // 24-bit address
                cks += (addr >> 16);
                break;
            }
            case '3' : // S3 record
            case '7' : // S7 record
            {
                cks = fgethex(fh, 2); // 8-bit length
                len = cks - 4;
                addr = fgethex(fh, 8); // 32-bit address
                cks += (addr >> 24);
                cks += (addr >> 16);
                break;
            }
            default : // Unknown record
            {
                printf("Unknown record line #%d!\n", line);
                return -1;
            }
        }
        
        cks += (addr >> 8);
        cks += addr;
        
        while (len > 1)
        {
            tmp = fgethex(fh, 2);
            cks += tmp;
            len--;
            
            // S1, S2 or S3 record
            if ((rec == '1') || (rec == '2') || (rec == '3'))
            {
                // Write data to memory
                if ((addr >= offs) && (addr < (offs + size)))
                {
                    ptr[addr - offs] = tmp;
                }
                addr++;
            }
            
        }
        
        cks += fgethex(fh, 2);
        cks &= 0xFF;
        if (cks != 0xFF)
        {
            printf("Invalid checksum line #%d!\n", line);
            return -1;
        }
        
        if (fgetc(fh) != 0x0D)
        {
            printf("No EOL CR line #%d!\n", line);
            return -1;
        }
        if (fgetc(fh) != 0x0A)
        {
            printf("No EOL LF line #%d!\n", line);
            return -1;
        }
        
        line ++;
    }
    
    return 0;
}

int main(int argc, char **argv, char **env)
{
    // Simulation duration
    time_t beg, end;
    double secs;
    // Trace index
    int trc_idx = 0;
    int min_idx = 0;
    // File name generation
    char file_name[256];
    char trc_name[256];
    char vcd_name[256];
    // Simulation steps
    vluint64_t max_step;
    // Testbench configuration
    const char *arg;
    // Signature location
    vluint32_t sig_beg, sig_end;
    
    beg = time(0);
    
    // Parse parameters
    Verilated::commandArgs(argc, argv);
    
    // Default : 1 msec
    max_step = (vluint64_t)1000000000;
    
    // Simulation duration : +usec=<num>
    arg = Verilated::commandArgsPlusMatch("usec=");
    if ((arg) && (arg[0]))
    {
        arg += 6;
        max_step = (vluint64_t)atoi(arg) * (vluint64_t)1000000;
    }
    
    // Simulation duration : +msec=<num>
    arg = Verilated::commandArgsPlusMatch("msec=");
    if ((arg) && (arg[0]))
    {
        arg += 6;
        max_step = (vluint64_t)atoi(arg) * (vluint64_t)1000000000;
    }
    
    // S-Record file input for ROM / RAM initialization
    arg = Verilated::commandArgsPlusMatch("srec=");
    if ((arg) && (arg[0]))
    {
        FILE *fh;
        
        arg += 6;
        strncpy(file_name, arg, 255);
        fh = fopen(file_name, "rb");
        if (fh)
        {
            printf("Use file \"%s\" to initialize SPRAM\n", file_name);
            memset((void *)ram_blk_init, 0, 0x10000);
            read_srec(fh, 0x80000000, 0x10000, ram_blk_init);
            fclose(fh);
        }
    }
    
    // Symbols file input for signature location
    arg = Verilated::commandArgsPlusMatch("syms=");
    if ((arg) && (arg[0]))
    {
        FILE *fh;
        
        arg += 6;
        strncpy(file_name, arg, 255);
        fh = fopen(file_name, "rb");
        if (fh)
        {
            vluint32_t tmp1, tmp2;
            char ch, str1[32], str2[32];
            
            printf("Use file \"%s\" for signature location\n", file_name);
            while (!feof(fh))
            {
                if (fscanf(fh, "%08x %c       .%s  %08x %s", &tmp1, &ch, str1, &tmp2, str2) == 5)
                {
                    if ((ch == 'g') && (tmp2 == 0) && (!strcmp(str1, "data")))
                    {
                        if (!strcmp(str2, "begin_signature"))
                        {
                            sig_beg = tmp1;
                            printf("%s = %08X\n", str2, tmp1);
                        }
                        if (!strcmp(str2, "end_signature"))
                        {
                            sig_end = tmp1;
                            printf("%s = %08X\n", str2, tmp1);
                        }
                    }
                }
                //else
                //{
                //    printf("%08x %c       .%s  %08x %s", tmp1, ch, str1, tmp2, str2);
                //}
            }
            fclose(fh);
        }
    }
    else
    {
        sig_beg = (vluint32_t)0;
        sig_end = (vluint32_t)0;
    }
    
    arg = Verilated::commandArgsPlusMatch("trc=");
    if ((arg) && (arg[0]))
    {
        arg += 5;
        strncpy(trc_name, arg, 255);
    }
    else
    {
        strcpy(trc_name, "riscv");
    }
    
    arg = Verilated::commandArgsPlusMatch("vcd=");
    if ((arg) && (arg[0]))
    {
        arg += 5;
        strncpy(vcd_name, arg, 251);
    }
    else
    {
        strcpy(vcd_name, "riscv.vcd");
    }
    
    // Initialize top verilog instance
    Vjive_soc_top* top = new Vjive_soc_top;
    
    // Initialize clock generator    
    clk = new ClockGen(1, max_step);
    // 100 MHz clock
    clk->NewClock(0, PERIOD_100MHz_ps, 0);
    clk->StartClock(0);
    
    // Initialize RISC-V trace
    trc = new RISCVTrace(0x80000000, sig_beg, sig_end);
    trc->open(trc_name);
    
#if VM_TRACE
    // Initialize VCD trace dump
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace (tfp, 99);
    tfp->spTrace()->set_time_resolution ("1 ps");
    tfp->open (vcd_name);
#endif /* VM_TRACE */
  
    // Simulation loop
    while (!clk->EndOfSimulation())
    {
        clk->AdvanceClocks();
        top->clk = clk->GetClockStateDiv1(0,0);
        
        // Evaluate verilated model
        top->eval ();
        
        // RISC-V trace
        trc->dump (clk->GetTimeStampPs(), top->clk,
                   top->i_rd_ack,  top->i_address, top->i_rddata,
                   top->d_rd_ack,  top->d_wr_ack,  top->d_address,
                   top->d_byteena, top->d_rddata,  top->d_wrdata,
                   0,
                   top->wb_ena,    top->wb_idx,    top->wb_data);
    
#if VM_TRACE
        // Dump signals into VCD file
        if (tfp)
        {
            tfp->dump (clk->GetTimeStampPs());
        }
#endif /* VM_TRACE */

        if (Verilated::gotFinish()) break;
    }
    
#if VM_TRACE
    if (tfp) tfp->close();
#endif /* VM_TRACE */

    top->final();
    
    trc->close();
    
    delete top;
    
    delete trc;
    
    delete clk;
  
    // Calculate running time
    end = time(0);
    secs = difftime(end, beg);
    printf("\nSeconds elapsed : %f\n", secs);

    exit(0);
}

// DPI-C functions

char riscv_disasm(int instr, int pc, int idx)
{
    return trc->disasm((vluint32_t)instr, (vluint32_t)pc, idx);
}

int spram_init(int index)
{
    vluint32_t tmp;
    
    tmp = ((vluint32_t)ram_blk_init[((index & 16383) << 2) + 0] <<  0)
        | ((vluint32_t)ram_blk_init[((index & 16383) << 2) + 1] <<  8)
        | ((vluint32_t)ram_blk_init[((index & 16383) << 2) + 2] << 16)
        | ((vluint32_t)ram_blk_init[((index & 16383) << 2) + 3] << 24);
    
    return tmp;
}

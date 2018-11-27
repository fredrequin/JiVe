#include "verilated.h"
#include "riscv_trace.h"
#include <stdlib.h>
#include <stdio.h>

enum
{
    OPC_LOAD      = 0x03,
    OPC_LOAD_FP   = 0x07,
    OPC_FENCE     = 0x0F,
    OPC_OP_IMM    = 0x13,
    OPC_AUIPC     = 0x17,
    OPC_OP_IMM_32 = 0x1B,
    OPC_STORE     = 0x23,
    OPC_STORE_FP  = 0x27,
    OPC_AMO       = 0x2F,
    OPC_OP        = 0x33,
    OPC_LUI       = 0x37,
    OPC_OP_32     = 0x3B,
    OPC_MADD      = 0x43,
    OPC_MSUB      = 0x47,
    OPC_MMSUB     = 0x4B,
    OPC_MMADD     = 0x4F,
    OPC_OP_FP     = 0x53,
    OPC_BRANCH    = 0x63,
    OPC_JALR      = 0x67,
    OPC_JAL       = 0x6F,
    OPC_SYSTEM    = 0x73
};

// Hexadecimal conversion table
static const char hex_dig[16] =
{
  '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'
};

// Mnemonics tables
static const char load_str[8][8] =
{
    "lb     ", "lh     ", "lw     ", "l???   ",
    "lbu    ", "lhu    ", "l???   ", "l???   "
};
static const char store_str[8][8] =
{
    "sb     ", "sh     ", "sw     ", "s???   ",
    "s???   ", "s???   ", "s???   ", "s???   "
};
static const char op_imm_str[9][8] =
{
    "addi   ", "slli   ", "slti   ", "sltiu  ",
    "xori   ", "srli   ", "ori    ", "andi   ",
               "srai   "
};
static const char op_str[10][8] =
{
    "add    ", "sll    ", "slt    ", "sltu   ",
    "xor    ", "srl    ", "or     ", "and    ",
    "sub    ", "sra    "
};
static const char branch_str[8][8] =
{
    "beq    ", "bne    ", "b???   ", "b???   ",
    "blt    ", "bge    ", "bltu   ", "bgeu   "
};
static const char system_str[8][8] =
{
    "csr??? ", "csrrw  ", "csrrs  ", "csrrc  ",
    "csr??? ", "csrrwi ", "csrrsi ", "csrrci "
};

// Registers names
static const char reg_str[32][4] =
{
    "x0",  "ra",  "sp",  "x3",  "x4",  "x5",  "x6",  "x7",
    "x8",  "x9",  "x10", "x11", "x12", "x13", "x14", "x15",
    "x16", "x17", "x18", "x19", "x20", "x21", "x22", "x23",
    "x24", "x25", "x26", "x27", "x28", "x29", "x30", "x31"
};
static const char csr_str[216][16] =
{
    //   0 : 0x000 - 0x007
    "ustatus",        "fflags",         "frm",            "fcsr",
    "uie",            "utvec",          "csr006",         "csr007",
    //   8 : 0x040 - 0x047
    "uscratch",       "uepc",           "ucause",         "utval",
    "uip",            "csr045",         "csr046",         "csr047",
    //  16 : 0x100 - 0x107
    "sstatus",        "csr101",         "sedeleg",        "sideleg",
    "sie",            "stvec",          "scounteren",     "csr107",
    //  24 : 0x140 - 0x147
    "sscratch",       "sepc",           "scause",         "stval",
    "sip",            "csr145",         "csr146",         "csr147",
    //  32 : 0x180 - 0x187
    "satp",           "csr181",         "csr182",         "csr183",
    "csr184",         "csr185",         "csr186",         "csr187",
    //  40 : 0x300 - 0x307
    "mstatus",        "misa",           "medeleg",        "mideleg",
    "mie",            "mtvec",          "mcounteren",     "csr307",
    //  48 : 0x340 - 0x347
    "mscratch",       "mepc",           "mcause",         "mtval",
    "mip",            "csr345",         "csr346",         "csr347",
    //  56 : 0x3A0 - 0x3A7
    "pmpcfg0",        "pmpcfg1",        "pmpcfg2",        "pmpcfg3",
    "csr3A4",         "csr3A5",         "csr3A6",         "csr3A7",
    //  64 : 0x3B0 - 0x3B7
    "pmpaddr0",       "pmpaddr1",       "pmpaddr2",       "pmpaddr3",
    "pmpaddr4",       "pmpaddr5",       "pmpaddr6",       "pmpaddr7",
    // 72 : 0x3B8 - 0x3BF
    "pmpaddr8",       "pmpaddr9",       "pmpaddr10",      "pmpaddr11",
    "pmpaddr12",      "pmpaddr13",      "pmpaddr14",      "pmpaddr15",
    // 80 : 0xB00 - 0xB07
    "mcycle",         "csrB01",         "minstret",       "mhpmcounter3",
    "mhpmcounter4",   "mhpmcounter5",   "mhpmcounter6",   "mhpmcounter7",
    // 88 : 0xB08 - 0xB0F
    "mhpmcounter8",   "mhpmcounter9",   "mhpmcounter10",  "mhpmcounter11",
    "mhpmcounter12",  "mhpmcounter13",  "mhpmcounter14",  "mhpmcounter15",
    // 96 : 0xB10 - 0xB17
    "mhpmcounter16",  "mhpmcounter17",  "mhpmcounter18",  "mhpmcounter19",
    "mhpmcounter20",  "mhpmcounter21",  "mhpmcounter22",  "mhpmcounter23",
    // 104 : 0xB18 - 0xB1F
    "mhpmcounter24",  "mhpmcounter25",  "mhpmcounter26",  "mhpmcounter27",
    "mhpmcounter28",  "mhpmcounter29",  "mhpmcounter30",  "mhpmcounter31",
    // 112 : 0xB80 - 0xB87
    "mcycleh",        "csrB81",         "minstreth",      "mhpmcounter3h",
    "mhpmcounter4h",  "mhpmcounter5h",  "mhpmcounter6h",  "mhpmcounter7h",
    // 120 : 0xB88 - 0xB8F
    "mhpmcounter8h",  "mhpmcounter9h",  "mhpmcounter10h", "mhpmcounter11h",
    "mhpmcounter12h", "mhpmcounter13h", "mhpmcounter14h", "mhpmcounter15h",
    // 128 : 0xB90 - 0xB97
    "mhpmcounter16h", "mhpmcounter17h", "mhpmcounter18h", "mhpmcounter19h",
    "mhpmcounter20h", "mhpmcounter21h", "mhpmcounter22h", "mhpmcounter23h",
    // 136 : 0xB98 - 0xB9F
    "mhpmcounter24h", "mhpmcounter25h", "mhpmcounter26h", "mhpmcounter27h",
    "mhpmcounter28h", "mhpmcounter29h", "mhpmcounter30h", "mhpmcounter31h",
    // 144 : 0xC00 - 0xC07
    "cycle",          "time",           "instret",        "hpmcounter3",
    "hpmcounter4",    "hpmcounter5",    "hpmcounter6",    "hpmcounter7",
    // 152 : 0xC08 - 0xC0F
    "hpmcounter8",    "hpmcounter9",    "hpmcounter10",   "hpmcounter11",
    "hpmcounter12",   "hpmcounter13",   "hpmcounter14",   "hpmcounter15",
    // 160 : 0xC10 - 0xC17
    "hpmcounter16",   "hpmcounter17",   "hpmcounter18",   "hpmcounter19",
    "hpmcounter20",   "hpmcounter21",   "hpmcounter22",   "hpmcounter23",
    // 168 : 0xC18 - 0xC1F
    "hpmcounter24",   "hpmcounter25",   "hpmcounter26",   "hpmcounter27",
    "hpmcounter28",   "hpmcounter29",   "hpmcounter30",   "hpmcounter31",
    // 176 : 0xC80 - 0xC87
    "cycleh",         "timeh",          "instreth",       "hpmcounter3h",
    "hpmcounter4h",   "hpmcounter5h",   "hpmcounter6h",   "hpmcounter7h",
    // 184 : 0xC88 - 0xC8F
    "hpmcounter8h",   "hpmcounter9h",   "hpmcounter10h",  "hpmcounter11h",
    "hpmcounter12h",  "hpmcounter13h",  "hpmcounter14h",  "hpmcounter15h",
    // 192 : 0xC90 - 0xC97
    "hpmcounter16h",  "hpmcounter17h",  "hpmcounter18h",  "hpmcounter19h",
    "hpmcounter20h",  "hpmcounter21h",  "hpmcounter22h",  "hpmcounter23h",
    // 200 : 0xC98 - 0xC9F
    "hpmcounter24h",  "hpmcounter25h",  "hpmcounter26h",  "hpmcounter27h",
    "hpmcounter28h",  "hpmcounter29h",  "hpmcounter30h",  "hpmcounter31h",
    // 208 : 0xF10 - 0xF17
    "csrF10",         "mvendorid",      "marchid",        "mimpid",
    "mhartid",        "csrF15",         "csrF16",         "csrF17"
};

static const vluint32_t riscv_sra_table[32] =
{
    0x00000000, 0x80000000, 0xC0000000, 0xE0000000,
    0xF0000000, 0xF8000000, 0xFC000000, 0xFE000000,
    0xFF000000, 0xFF800000, 0xFFC00000, 0xFFE00000,
    0xFFF00000, 0xFFF80000, 0xFFFC0000, 0xFFFE0000,
    0xFFFF0000, 0xFFFF8000, 0xFFFFC000, 0xFFFFE000,
    0xFFFFF000, 0xFFFFF800, 0xFFFFFC00, 0xFFFFFE00,
    0xFFFFFF00, 0xFFFFFF80, 0xFFFFFFC0, 0xFFFFFFE0,
    0xFFFFFFF0, 0xFFFFFFF8, 0xFFFFFFFC, 0xFFFFFFFE
};

#define GET_BIT(A,N)    (((A) >> N) & 1)
#define SRA_32(A,N)     (((A) & 0x80000000) ? ((A) >> (N)) | riscv_sra_table[(N)] : ((A) >> (N)))

#define XFER_NONE       ((vluint8_t)0xFF)
#define XFER_LB         ((vluint8_t)0x00)
#define XFER_LH         ((vluint8_t)0x01)
#define XFER_LW         ((vluint8_t)0x02)
#define XFER_LBU        ((vluint8_t)0x04)
#define XFER_LHU        ((vluint8_t)0x05)
#define XFER_SB         ((vluint8_t)0x08)
#define XFER_SH         ((vluint8_t)0x09)
#define XFER_SW         ((vluint8_t)0x0A)

#define RAISE_NONE      ((vluint32_t)0xFFFFFFFF)
#define RAISE_IADDR_ERR ((vluint32_t)0x00000000)
#define RAISE_ILLEGAL   ((vluint32_t)0x00000002)
#define RAISE_EBREAK    ((vluint32_t)0x00000003)
#define RAISE_LADDR_ERR ((vluint32_t)0x00000004)
#define RAISE_SADDR_ERR ((vluint32_t)0x00000006)
#define RAISE_ECALL     ((vluint32_t)0x0000000B)

#define RAISE_SOFT_INT  ((vluint32_t)0x80000003)
#define RAISE_TIMER_INT ((vluint32_t)0x80000007)
#define RAISE_EXT_INT   ((vluint32_t)0x8000000B)

#define CSR_UTVEC       (0x005)
#define CSR_UEPC        (0x041)
#define CSR_UCAUSE      (0x042)
#define CSR_UTVAL       (0x043)
#define CSR_STVEC       (0x105)
#define CSR_SEPC        (0x141)
#define CSR_SCAUSE      (0x142)
#define CSR_STVAL       (0x143)
#define CSR_MTVEC       (0x305)
#define CSR_MEPC        (0x341)
#define CSR_MCAUSE      (0x342)
#define CSR_MTVAL       (0x343)

// Constructor
RISCVTrace::RISCVTrace(vluint32_t reset_vect, vluint32_t comp_data_beg, vluint32_t comp_data_end)
{
    // Initialize PC
    pc_reg = reset_vect & 0xFFFFFFFC;
    // Clear registers
    for (int i = 0; i < 16; i++)
    {
        gp_regs[i] = (vluint32_t)0;
    }
    // Files handles set to STDOUT
    tname[0]    = (char)0;
    oname[0]    = (char)0;
    tfh         = stdout;
    ofh         = stdout;
    // Internal variables cleared
    dasm_buf[0] = (char)0;
    prev_clk    = (vluint8_t)0;
    except_nr   = RAISE_NONE;
    mem_xfer    = XFER_NONE;
    mem_mask    = (vluint8_t)0xF;
    mem_addr    = (vluint32_t)0x00000000;
    // Compliance testing
    test_start  = comp_data_beg;
    test_stop   = comp_data_end;
    test_size   = comp_data_end - comp_data_beg;
    if (test_size)
    {
        test_ptr = new vluint8_t[test_size];
    }
    else
    {
        test_ptr = NULL;
    }
}

// Destructor
RISCVTrace::~RISCVTrace()
{
    this->close();
    
    if (test_ptr)
    {
        delete[] test_ptr;
        test_ptr = NULL;
    }
}

// Open trace file
int RISCVTrace::open(const char *name)
{
    FILE *fh;
    
    // Close previous file
    this->close();

    // Complete the trace file name
    //strncpy(tname, name, 246);
    //strcat(tname, "_0000.trc");
    strncpy(tname, name, 249);
    strcat(tname, ".out32");
    
    // Try to open the trace file for writing
    fh = fopen(tname, "w");
    if (!fh)
    {
        // Failure
        tname[0] = (char)0;
        return -1;
    }
    // Success
    tfh = fh;
    
    // Complete the output file name
    //strncpy(oname, name, 246);
    //strcat(oname, "_0000.out");
    strncpy(oname, name, 238);
    strcat(oname, "_signature.output");
    
    // Try to open the trace file for writing
    fh = fopen(oname, "w");
    if (!fh)
    {
        // Failure
        oname[0] = (char)0;
        return -1;
    }
    // Success
    ofh = fh;
    
    return 0;
}

// Open next trace & output files
int RISCVTrace::openNext(void)
{
    FILE *fh;
    int len;

    // Close previous file
    this->close();

    // Get filename length
    len = strlen(tname);
    if (!len) return -1;
    
    // Increment the trace file name
    /*
    if (tname[len-5] == '9')
    {
        tname[len-5] = '0';
        if (tname[len-6] == '9')
        {
            tname[len-6] = '0';
            if (tname[len-7] == '9')
            {
                tname[len-7] = '0';
                tname[len-8]++;
            }
            else
            {
                tname[len-7]++;
            }
        }
        else
        {
            tname[len-6]++;
        }
    }
    else
    {
        tname[len-5]++;
    }
    */
    
    // Try to open the trace file for writing
    fh = fopen(tname, "w");
    if (!fh)
    {
        // Failure
        tname[0] = (char)0;
        return -1;
    }
    // Success
    tfh = fh;
    
    // Increment the output file name
    /*
    oname[len-5] = tname[len-5];
    oname[len-6] = tname[len-6];
    oname[len-7] = tname[len-7];
    oname[len-8] = tname[len-8];
    */
    
    // Try to open the output file for writing
    fh = fopen(oname, "w");
    if (!fh)
    {
        // Failure
        oname[0] = (char)0;
        return -1;
    }
    // Success
    ofh = fh;
    
    return 0;
}

// Close trace file
void RISCVTrace::close(void)
{
    if (tfh != stdout)
    {
        fclose(tfh);
        tfh = stdout;
    }
    if (ofh != stdout)
    {
        for (vluint32_t i = 0; i < test_size; i = i + 16)
        {
            fprintf(ofh, "%02x", test_ptr[i+0xF]);
            fprintf(ofh, "%02x", test_ptr[i+0xE]);
            fprintf(ofh, "%02x", test_ptr[i+0xD]);
            fprintf(ofh, "%02x", test_ptr[i+0xC]);
            fprintf(ofh, "%02x", test_ptr[i+0xB]);
            fprintf(ofh, "%02x", test_ptr[i+0xA]);
            fprintf(ofh, "%02x", test_ptr[i+0x9]);
            fprintf(ofh, "%02x", test_ptr[i+0x8]);
            fprintf(ofh, "%02x", test_ptr[i+0x7]);
            fprintf(ofh, "%02x", test_ptr[i+0x6]);
            fprintf(ofh, "%02x", test_ptr[i+0x5]);
            fprintf(ofh, "%02x", test_ptr[i+0x4]);
            fprintf(ofh, "%02x", test_ptr[i+0x3]);
            fprintf(ofh, "%02x", test_ptr[i+0x2]);
            fprintf(ofh, "%02x", test_ptr[i+0x1]);
            fprintf(ofh, "%02x", test_ptr[i+0x0]);
            fprintf(ofh, "\n");
        }
        fclose(ofh);
        ofh = stdout;
    }
}

// Dump trace
void RISCVTrace::dump
(
    vluint64_t stamp,
    // Clock
    vluint8_t  clk,
    // Instruction fetch
    vluint8_t  i_rd_ack,
    vluint32_t i_address,
    vluint32_t i_rddata,
    // Data read/write
    vluint8_t  d_rd_ack,
    vluint8_t  d_wr_ack,
    vluint32_t d_address,
    vluint8_t  d_byteena,
    vluint32_t d_rddata,
    vluint32_t d_wrdata,
    // Interrupt Receiver
    vluint32_t inr_ir_irq,
    // Register write-back
    vluint8_t  wb_ena,
    vluint8_t  wb_idx,
    vluint32_t wb_data
)
{
    // Rising edge on clock
    if (clk && !prev_clk)
    {
        //ip_reg = ip_reg | inr_ir_irq & im_reg;
        if (wb_ena)
        {
            if (wb_idx != rd_idx)
            {
                fprintf(tfh, "!!! WRITEBACK INDEX MISMATCH !!!\n");
                fprintf(tfh, "Verilog : %2d, C-Model : %2d\n", wb_idx, rd_idx);
            }
            else if ((gp_regs[rd_idx] != wb_data) && (rd_idx))
            {
                fprintf(tfh, "!!! WRITEBACK DATA MISMATCH !!!\n");
                fprintf(tfh, "Verilog : %08X, C-Model : %08X\n", wb_data, gp_regs[rd_idx]);
            }
        }
        if (d_rd_ack)
        {
            fprintf(tfh, "Memory read @ $%08X : %08X\n", d_address, d_rddata);
            
            // Instruction simulation (memory/writeback)
            riscv_simu_rd(d_address, d_rddata);
        }
        if (d_wr_ack)
        {
            char buf[10];
            
            memcpy(buf + 6, (d_byteena & 1) ? uhex_to_str(d_wrdata >>  0, 2) : "$XX", 3);
            memcpy(buf + 4, (d_byteena & 2) ? uhex_to_str(d_wrdata >>  8, 2) : "$XX", 3);
            memcpy(buf + 2, (d_byteena & 4) ? uhex_to_str(d_wrdata >> 16, 2) : "$XX", 3);
            memcpy(buf + 0, (d_byteena & 8) ? uhex_to_str(d_wrdata >> 24, 2) : "$XX", 3);
            buf[9] = (char)0;
            
            fprintf(tfh, "Memory write @ $%08X : %s\n", d_address, buf);
            
            if ((test_ptr) && (d_address >= test_start) && (d_address < test_stop))
            {
                vluint32_t offs = (d_address & 0xFFFFFFFC) - test_start;
                if (d_byteena & 1) test_ptr[offs+0] = (vluint8_t)(d_wrdata >> 0);
                if (d_byteena & 2) test_ptr[offs+1] = (vluint8_t)(d_wrdata >> 8);
                if (d_byteena & 4) test_ptr[offs+2] = (vluint8_t)(d_wrdata >> 16);
                if (d_byteena & 8) test_ptr[offs+3] = (vluint8_t)(d_wrdata >> 24);
            }
            
            // Instruction simulation (memory)
            riscv_simu_wr(d_address, d_wrdata, d_byteena);
        }
        if (i_rd_ack)
        {
            char buf[80];
            
            // CPU registers
            fprintf(tfh, " x0 : %08X %08X %08X %08X %08X %08X %08X %08X\n",
                    gp_regs[ 0], gp_regs[ 1], gp_regs[ 2], gp_regs[ 3],
                    gp_regs[ 4], gp_regs[ 5], gp_regs[ 6], gp_regs[ 7]
                   );
            fprintf(tfh, " x8 : %08X %08X %08X %08X %08X %08X %08X %08X\n",
                    gp_regs[ 8], gp_regs[ 9], gp_regs[10], gp_regs[11],
                    gp_regs[12], gp_regs[13], gp_regs[14], gp_regs[15]
                   );
            fprintf(tfh, "x16 : %08X %08X %08X %08X %08X %08X %08X %08X\n",
                    gp_regs[16], gp_regs[17], gp_regs[18], gp_regs[19],
                    gp_regs[20], gp_regs[21], gp_regs[22], gp_regs[23]
                   );
            fprintf(tfh, "x24 : %08X %08X %08X %08X %08X %08X %08X %08X\n\n",
                    gp_regs[24], gp_regs[25], gp_regs[26], gp_regs[27],
                    gp_regs[28], gp_regs[29], gp_regs[30], gp_regs[31]
                   );
                   
            // Disassemble instruction being fetched
            riscv_dasm(buf, i_rddata, pc_reg);
            fprintf(tfh, "(%14llu ps) %08X : %08X %s\n", stamp, i_address, i_rddata, buf);
            
            // Instruction simulation (fetch/decode/execute/writeback)
            riscv_simu_if(i_address, i_rddata);
        }
    }
    prev_clk = clk;
}

// Disassemble one instruction
char RISCVTrace::disasm(vluint32_t inst, vluint32_t pc, int idx)
{
    if (idx == 0)
    {
        memset(dasm_buf, 0, 32);
        riscv_dasm(dasm_buf, inst, pc);
    }
    return dasm_buf[idx & 31];
}

/******************************************************************************/
/** uhex_to_str()                                                            **/
/** ------------------------------------------------------------------------ **/
/** Convert an unsigned 32-bit value into a hexadecimal string               **/
/**   val : 32-bit value                                                     **/
/**   dig : number of hexadecimal digits (1 - 8)                             **/
/******************************************************************************/

char *RISCVTrace::uhex_to_str(vluint32_t val, int dig)
{
    static char buf[12];
    char *p;
    
    dig <<= 2;
    p = buf;
    
    *p++ = '$';
    while (dig)
    {
        dig -= 4;
        // Convert one digit
        *p++ = hex_dig[(val >> dig) & 15];
    }
    *p = (char)0;
    
    return buf;
}

/******************************************************************************/
/** shex_to_str()                                                            **/
/** ------------------------------------------------------------------------ **/
/** Convert a signed 8/16/32-bit value into a hexadecimal string             **/
/**   val : 8/16/32-bit value                                                **/
/**   dig : number of hexadecimal digits (1 - 8)                             **/
/******************************************************************************/

char *RISCVTrace::shex_to_str(vluint32_t val, int dig)
{
    static char buf[12];
    char *p;
    vluint32_t msk;
    
    // 8, 16 or 32
    dig <<= 2;
    p = buf;
    
    // 0x80, 0x8000 or 0x80000000
    msk = (vluint32_t)1 << (dig - 1);
    if (val & msk)
    {
        val = (~val) + 1;
        *p++ = '-';
    }
    
    *p++ = '$';
    while (dig)
    {
        dig -= 4;
        // Convert one digit
        *p++ = hex_dig[(val >> dig) & 15];
    }
    *p = (char)0;
    
    return buf;
}

char *RISCVTrace::get_csr_str(int csr)
{
    static char buf[8];
    
    buf[0] = 0;
    switch (csr >> 3)
    {
        case 0x000: return (char *)csr_str[  0 + (csr & 7)];
        case 0x008: return (char *)csr_str[  8 + (csr & 7)];
        case 0x020: return (char *)csr_str[ 16 + (csr & 7)];
        case 0x028: return (char *)csr_str[ 24 + (csr & 7)];
        case 0x030: return (char *)csr_str[ 32 + (csr & 7)];
        case 0x060: return (char *)csr_str[ 40 + (csr & 7)];
        case 0x068: return (char *)csr_str[ 48 + (csr & 7)];
        case 0x074: return (char *)csr_str[ 56 + (csr & 7)];
        case 0x076: return (char *)csr_str[ 64 + (csr & 7)];
        case 0x077: return (char *)csr_str[ 72 + (csr & 7)];
        case 0x160: return (char *)csr_str[ 80 + (csr & 7)];
        case 0x161: return (char *)csr_str[ 88 + (csr & 7)];
        case 0x162: return (char *)csr_str[ 96 + (csr & 7)];
        case 0x163: return (char *)csr_str[104 + (csr & 7)];
        case 0x170: return (char *)csr_str[112 + (csr & 7)];
        case 0x171: return (char *)csr_str[120 + (csr & 7)];
        case 0x172: return (char *)csr_str[128 + (csr & 7)];
        case 0x173: return (char *)csr_str[136 + (csr & 7)];
        case 0x180: return (char *)csr_str[144 + (csr & 7)];
        case 0x181: return (char *)csr_str[152 + (csr & 7)];
        case 0x182: return (char *)csr_str[160 + (csr & 7)];
        case 0x183: return (char *)csr_str[168 + (csr & 7)];
        case 0x190: return (char *)csr_str[176 + (csr & 7)];
        case 0x191: return (char *)csr_str[184 + (csr & 7)];
        case 0x192: return (char *)csr_str[192 + (csr & 7)];
        case 0x193: return (char *)csr_str[200 + (csr & 7)];
        case 0x1E2: return (char *)csr_str[208 + (csr & 7)];
        default:
        {
            sprintf(buf, "csr%03X", csr);
        }
    }
    return buf;
}

void RISCVTrace::riscv_dasm(char *buf, vluint32_t inst, vluint32_t pc)
{
    vluint8_t func7;
    vluint8_t rd__idx;
    vluint8_t func3;
    vluint8_t rs1_idx;
    vluint8_t rs2_idx;
    
    vluint32_t i_immed;
    vluint32_t s_immed;
    vluint32_t u_immed;
    vluint32_t b_immed;
    vluint32_t j_immed;
    vluint32_t z_immed;
    
    func7   =  inst        & 0x7F;
    rd__idx = (inst >>  7) & 0x1F;
    func3   = (inst >> 12) & 0x07;
    rs1_idx = (inst >> 15) & 0x1F;
    rs2_idx = (inst >> 20) & 0x1F;
    
    i_immed =  (inst >> 20) & 0x00000FFF;
    s_immed = ((inst >> 20) & 0x00000FE0)
            | ((inst >>  7) & 0x0000001F);
    u_immed =   inst        & 0xFFFFF000;
    b_immed = ((inst >> 19) & 0x00001000)
            | ((inst >> 20) & 0x000007E0)
            | ((inst >>  7) & 0x0000001E)
            | ((inst <<  4) & 0x00000800);
    j_immed = ((inst >> 11) & 0x00100000)
            | ((inst >> 20) & 0x000007FE)
            | ((inst >>  9) & 0x00000800)
            |  (inst        & 0x000FF000);
    z_immed =  (inst >> 15) & 0x0000001F;
    
    switch (func7)
    {
        // 0x03
        case OPC_LOAD:
        {
            sprintf(buf, "%s %s,%s(%s)",
                    load_str[func3],
                    reg_str[rd__idx],
                    shex_to_str(i_immed, 3),
                    reg_str[rs1_idx]
                   );
            break;
        }
        
        // 0x0F
        case OPC_FENCE:
        {
            switch (func3)
            {
                case 0:
                {
                    sprintf(buf, "fence   %c%c%c%c,%c%c%c%c",
                            (i_immed & 0x80) ? 'i' : 0,
                            (i_immed & 0x40) ? 'o' : 0,
                            (i_immed & 0x20) ? 'r' : 0,
                            (i_immed & 0x10) ? 'w' : 0,
                            (i_immed & 0x08) ? 'i' : 0,
                            (i_immed & 0x04) ? 'o' : 0,
                            (i_immed & 0x02) ? 'r' : 0,
                            (i_immed & 0x01) ? 'w' : 0
                           );
                    break;
                }
                case 1:
                {
                    sprintf(buf, "fence.i");
                    break;
                }
                default:
                {
                    sprintf(buf, "f???   %s", uhex_to_str(inst, 8));
                }
            }
            break;
        }
        
        // 0x13
        case OPC_OP_IMM:
        {
            if ((func3 == 1) || (func3 == 5)) i_immed &= 31;
            if ((func3 == 5) && (GET_BIT(inst,30))) func3 = 8;
            sprintf(buf, "%s %s,%s,%s",
                    op_imm_str[func3],
                    reg_str[rd__idx],
                    reg_str[rs1_idx],
                    shex_to_str(i_immed, 3)
                   );
            break;
        }
        
        // 0x17
        case OPC_AUIPC:
        {
            sprintf(buf, "auipc   %s,%s",
                    reg_str[rd__idx],
                    uhex_to_str(u_immed, 8)
                   );
            break;
        }
        
        // 0x23
        case OPC_STORE:
        {
            sprintf(buf, "%s %s,%s(%s)",
                    store_str[func3],
                    reg_str[rs2_idx],
                    shex_to_str(s_immed, 3),
                    reg_str[rs1_idx]
                   );
            break;
        }
        
        // 0x33
        case OPC_OP:
        {
            if ((func3 == 0) && (GET_BIT(inst,30))) func3 = 8;
            if ((func3 == 5) && (GET_BIT(inst,30))) func3 = 9;
            sprintf(buf, "%s %s,%s,%s",
                    op_str[func3],
                    reg_str[rd__idx],
                    reg_str[rs1_idx],
                    reg_str[rs2_idx]
                   );
            break;
        }
        
        // 0x37
        case OPC_LUI:
        {
            sprintf(buf, "lui     %s,%s",
                    reg_str[rd__idx],
                    uhex_to_str(u_immed, 8)
                   );
            break;
        }
        
        // 0x63
        case OPC_BRANCH:
        {
            sprintf(buf, "%s %s,%s,%s",
                    branch_str[func3],
                    reg_str[rs1_idx],
                    reg_str[rs2_idx],
                    uhex_to_str(pc + b_immed, 8)
                   );
            break;
        }
        
        // 0x67
        case OPC_JALR:
        {
            sprintf(buf, "jalr    %s,%s(%s)",
                    reg_str[rd__idx],
                    shex_to_str(i_immed, 3),
                    reg_str[rs1_idx]
                   );
            break;
        }
        
        // 0x6F
        case OPC_JAL:
        {
            sprintf(buf, "jal     %s,%s",
                    reg_str[rd__idx],
                    uhex_to_str(pc + j_immed, 8)
                   );
            break;
        }
        
        // 0x73
        case OPC_SYSTEM:
        {
            int csr = i_immed & 0xFFF;
            
            if (func3)
            {
                sprintf(buf, "%s %s,%s,%s",
                        system_str[func3],
                        reg_str[rd__idx],
                        get_csr_str(csr),
                        (func3 & 4) ? uhex_to_str(z_immed, 2) : reg_str[rs1_idx]
                       );
            }
            else
            {
                switch (csr)
                {
                    case 0x000:
                    {
                        sprintf(buf, "ecall");
                        break;
                    }
                    case 0x001:
                    {
                        sprintf(buf, "ebreak");
                        break;
                    }
                    case 0x002:
                    {
                        sprintf(buf, "uret");
                        break;
                    }
                    case 0x102:
                    {
                        sprintf(buf, "sret");
                        break;
                    }
                    case 0x105:
                    {
                        sprintf(buf, "wfi");
                        break;
                    }
                    case 0x302:
                    {
                        sprintf(buf, "mret");
                        break;
                    }
                    default:
                    {
                        sprintf(buf, "csr??? %s", uhex_to_str(inst, 8));
                    }
                }
            }
            break;
        }
        
        default:
        {
            sprintf(buf, "op???   %s",  uhex_to_str(inst, 8));
        }
    }
}

void RISCVTrace::riscv_simu_if(vluint32_t addr, vluint32_t inst)
{
    vluint8_t func7;
    vluint8_t func3;
    vluint8_t rs1_idx;
    vluint8_t rs2_idx;
    
    vluint32_t i_immed;
    vluint32_t s_immed;
    vluint32_t u_immed;
    vluint32_t b_immed;
    vluint32_t j_immed;
    vluint32_t z_immed;
    
    vluint32_t jmp_addr;
    
    unsigned long uns_imm;
    signed   long sig_imm;
    unsigned long uns_rs1;
    signed   long sig_rs1;
    unsigned long uns_rs2;
    signed   long sig_rs2;
    
    if (addr != pc_reg)
    {
        fprintf(tfh, "!!! INST ADDRESS MISMATCH !!!\n");
        fprintf(tfh, "Verilog : %08X, C-Model : %08X\n", addr, pc_reg);
    }
    
    func7   =  inst        & 0x7F;
    rd_idx  = (inst >>  7) & 0x1F;
    func3   = (inst >> 12) & 0x07;
    rs1_idx = (inst >> 15) & 0x1F;
    rs2_idx = (inst >> 20) & 0x1F;
    
    i_immed =  (inst >> 20) & 0x00000FFF;
    s_immed = ((inst >> 20) & 0x00000FE0)
            | ((inst >>  7) & 0x0000001F);
    u_immed =   inst        & 0xFFFFF000;
    b_immed = ((inst >> 19) & 0x00001000)
            | ((inst >> 20) & 0x000007E0)
            | ((inst >>  7) & 0x0000001E)
            | ((inst <<  4) & 0x00000800);
    j_immed = ((inst >> 11) & 0x00100000)
            | ((inst >> 20) & 0x000007FE)
            | ((inst >>  9) & 0x00000800)
            |  (inst        & 0x000FF000);
    z_immed =  (inst >> 15) & 0x0000001F;
    
    if (GET_BIT(inst,31))
    {
        i_immed |= 0xFFFFF000;
        s_immed |= 0xFFFFF000;
        b_immed |= 0xFFFFE000;
        j_immed |= 0xFFE00000;
    }
    
    // Signed / unsigned value (for compare / branch)
    uns_imm = (unsigned long)i_immed;
    sig_imm = (uns_imm & 0x80000000) ? -((uns_imm ^ 0xFFFFFFFF) + 1) : uns_imm;
    uns_rs1 = (unsigned long)gp_regs[rs1_idx];
    sig_rs1 = (uns_rs1 & 0x80000000) ? -((uns_rs1 ^ 0xFFFFFFFF) + 1) : uns_rs1;
    uns_rs2 = (unsigned long)gp_regs[rs2_idx];
    sig_rs2 = (uns_rs2 & 0x80000000) ? -((uns_rs2 ^ 0xFFFFFFFF) + 1) : uns_rs2;
    
    switch (func7)
    {
        // 0x03
        case OPC_LOAD:
        {
            mem_addr = uns_rs1 + i_immed;
            mem_xfer = func3;
            switch (func3)
            {
                case 0: // LB
                case 4: // LBU
                {
                    mem_mask = (vluint8_t)0x1 << (mem_addr & 3);
                    pc_reg += 4;
                    break;
                }
                case 1: // LH
                case 5: // LHU
                {
                    if (mem_addr & 1)
                    {
                        // Unaligned address
                        mem_xfer = XFER_NONE;
                        mem_mask = (vluint8_t)0x0;
                        except_nr = RAISE_LADDR_ERR;
                    }
                    else
                    {
                        mem_mask = (vluint8_t)0x3 << (mem_addr & 2);
                        pc_reg += 4;
                    }
                    break;
                }
                case 2: // LW
                {
                    if (mem_addr & 3)
                    {
                        // Unaligned address
                        mem_xfer = XFER_NONE;
                        mem_mask = (vluint8_t)0x0;
                        except_nr = RAISE_LADDR_ERR;
                    }
                    else
                    {
                        mem_mask = (vluint8_t)0xF;
                        pc_reg += 4;
                    }
                    break;
                }
                default:
                {
                    // Invalid instruction
                    mem_xfer = XFER_NONE;
                    mem_mask = (vluint8_t)0x0;
                    except_nr = RAISE_ILLEGAL;
                }
            }
            break;
        }
        
        // 0x0F
        case OPC_FENCE:
        {
            pc_reg += 4; // NOP
            break;
        }
        
        // 0x13
        case OPC_OP_IMM:
        {
            switch (func3)
            {
                case 0: // ADDI
                {
                    if (rd_idx) gp_regs[rd_idx] = uns_rs1 + i_immed;
                    break;
                }
                case 1: // SLLI
                {
                    if (rd_idx) gp_regs[rd_idx] = uns_rs1 << (i_immed & 0x1F);
                    break;
                }
                case 2: // SLTI
                {
                    if (rd_idx) gp_regs[rd_idx] = (sig_rs1 < sig_imm) ? 1 : 0;
                    break;
                }
                case 3: // SLTIU
                {
                    if (rd_idx) gp_regs[rd_idx] = (uns_rs1 < uns_imm) ? 1 : 0;
                    break;
                }
                case 4: // XORI
                {
                    if (rd_idx) gp_regs[rd_idx] = uns_rs1 ^ i_immed;
                    break;
                }
                case 5: // SRLI / SRAI
                {
                    if (rd_idx)
                    {
                        gp_regs[rd_idx] = (GET_BIT(inst,30))
                                        ? SRA_32(uns_rs1, i_immed & 0x1F)
                                        : uns_rs1 >> (i_immed & 0x1F);
                    }
                    break;
                }
                case 6: // ORI
                {
                    if (rd_idx) gp_regs[rd_idx] = uns_rs1 | i_immed;
                    break;
                }
                case 7: // ANDI
                {
                    if (rd_idx) gp_regs[rd_idx] = uns_rs1 & i_immed;
                    break;
                }
            }
            pc_reg += 4;
            break;
        }
        
        // 0x17
        case OPC_AUIPC: // AUIPC
        {
            if (rd_idx) gp_regs[rd_idx] = pc_reg + u_immed;
            pc_reg += 4;
            break;
        }
        
        // 0x23
        case OPC_STORE:
        {
            mem_addr = uns_rs1 + s_immed;
            mem_xfer = func3 + 8;
            switch (func3)
            {
                case 0: // SB
                {
                    mem_data = (uns_rs2 & 0xFF) * 0x01010101;
                    mem_mask = (vluint8_t)0x1 << (mem_addr & 3);
                    pc_reg += 4;
                    break;
                }
                case 1: // SH
                {
                    if (mem_addr & 1)
                    {
                        // Unaligned address
                        mem_xfer = XFER_NONE;
                        mem_mask = (vluint8_t)0x0;
                        except_nr = RAISE_SADDR_ERR;
                    }
                    else
                    {
                        mem_data = (uns_rs2 & 0xFFFF) * 0x00010001;
                        mem_mask = (vluint8_t)0x3 << (mem_addr & 2);
                        pc_reg += 4;
                    }
                    break;
                }
                case 2: // SW
                {
                    if (mem_addr & 3)
                    {
                        // Unaligned address
                        mem_xfer = XFER_NONE;
                        mem_mask = (vluint8_t)0x0;
                        except_nr = RAISE_SADDR_ERR;
                    }
                    else
                    {
                        mem_data = uns_rs2;
                        mem_mask = (vluint8_t)0xF;
                        pc_reg += 4;
                    }
                    break;
                }
                default:
                {
                    // Invalid instruction
                    mem_xfer = XFER_NONE;
                    mem_mask = (vluint8_t)0x0;
                    except_nr = RAISE_ILLEGAL;
                }
            }
            break;
        }
        
        // 0x33
        case OPC_OP:
        {
            switch (func3)
            {
                case 0: // ADD / SUB
                {
                    if (rd_idx)
                    {
                        gp_regs[rd_idx] = (GET_BIT(inst,30))
                                        ? uns_rs1 - uns_rs2
                                        : uns_rs1 + uns_rs2;
                    }
                    break;
                }
                case 1: // SLL
                {
                    if (rd_idx) gp_regs[rd_idx] = uns_rs1 << (uns_rs2 & 0x1F);
                    break;
                }
                case 2: // SLT
                {
                    if (rd_idx) gp_regs[rd_idx] = (sig_rs1 < sig_rs2) ? 1 : 0;
                    break;
                }
                case 3: // SLTU
                {
                    if (rd_idx) gp_regs[rd_idx] = (uns_rs1 < uns_rs2) ? 1 : 0;
                    break;
                }
                case 4: // XOR
                {
                    if (rd_idx) gp_regs[rd_idx] = uns_rs1 ^ uns_rs2;
                    break;
                }
                case 5: // SRL / SRA
                {
                    if (rd_idx)
                    {
                        gp_regs[rd_idx] = (GET_BIT(inst,30))
                                        ? SRA_32(uns_rs1, uns_rs2 & 0x1F)
                                        : uns_rs1 >> (uns_rs2 & 0x1F);
                    }
                    break;
                }
                case 6: // OR
                {
                    if (rd_idx) gp_regs[rd_idx] = uns_rs1 | uns_rs2;
                    break;
                }
                case 7: // AND
                {
                    if (rd_idx) gp_regs[rd_idx] = uns_rs1 & uns_rs2;
                    break;
                }
            }
            pc_reg += 4;
            break;
        }
        
        // 0x37
        case OPC_LUI: // LUI
        {
            if (rd_idx) gp_regs[rd_idx] = u_immed;
            pc_reg += 4;
            break;
        }
        
        // 0x63
        case OPC_BRANCH:
        {
            bool branch;
            
            jmp_addr = pc_reg + b_immed;
            switch (func3)
            {
                case 0: // BEQ
                {
                    branch = (uns_rs1 == uns_rs2) ? true : false;
                    break;
                }
                case 1: // BNE
                {
                    branch = (uns_rs1 != uns_rs2) ? true : false;
                    break;
                }
                case 4: // BLT
                {
                    branch = (sig_rs1 < sig_rs2) ? true : false;
                    break;
                }
                case 5: // BGE
                {
                    branch = (sig_rs1 >= sig_rs2) ? true : false;
                    break;
                }
                case 6: // BLTU
                {
                    branch = (uns_rs1 < uns_rs2) ? true : false;
                    break;
                }
                case 7: // BGEU
                {
                    branch = (uns_rs1 >= uns_rs2) ? true : false;
                    break;
                }
                default:
                {
                    // Invalid instruction
                    except_nr = RAISE_ILLEGAL;
                    branch = false;
                }
            }
            
            if (branch)
            {
                if (jmp_addr & 3)
                {
                    except_nr = RAISE_IADDR_ERR;
                }
                else
                {
                    pc_reg = jmp_addr;
                }
            }
            else
            {
                if (except_nr == RAISE_NONE) pc_reg += 4;
            }
            
            break;
        }
        
        // 0x67
        case OPC_JALR: // JALR
        {
            if (rd_idx) gp_regs[rd_idx] = pc_reg + 4;
            jmp_addr = (uns_rs1 + i_immed) & 0xFFFFFFFE;
            if (jmp_addr & 2)
            {
                except_nr = RAISE_IADDR_ERR;
            }
            else
            {
                pc_reg = jmp_addr;
            }
            break;
        }
        
        // 0x6F
        case OPC_JAL: // JAL
        {
            if (rd_idx) gp_regs[rd_idx] = pc_reg + 4;
            jmp_addr = pc_reg + j_immed;
            if (jmp_addr & 3)
            {
                except_nr = RAISE_IADDR_ERR;
            }
            else
            {
                pc_reg = jmp_addr;
            }
            break;
        }
        
        // 0x73
        case OPC_SYSTEM:
        {
            int csr = i_immed & 0xFFF;
            
            switch (func3)
            {
                case 0:
                {
                    if (!rd_idx) // ECALL, EBREAK, MRET, WFI
                    {
                        switch (csr)
                        {
                            case 0x000: // ECALL
                            {
                                except_nr = RAISE_ECALL;
                                break;
                            }
                            case 0x001: // EBREAK
                            {
                                except_nr = RAISE_EBREAK;
                                break;
                            }
                            case 0x105: // WFI (NOP)
                            {
                                pc_reg += 4;
                                break;
                            }
                            case 0x302: // MRET
                            {
                                pc_reg = csr_regs[CSR_MEPC];
                                break;
                            }
                            default: // NOP ?
                            {
                                pc_reg += 4;
                            }
                        }
                    }
                    break;
                }
                case 1: // CSRRW
                {
                    if (rd_idx) gp_regs[rd_idx] = csr_regs[csr];
                    csr_regs[csr] = uns_rs1;
                    pc_reg += 4;
                    break;
                }
                case 2: // CSRRS
                {
                    if (rd_idx) gp_regs[rd_idx] = csr_regs[csr];
                    csr_regs[csr] |= uns_rs1;
                    pc_reg += 4;
                    break;
                }
                case 3: // CSRRC
                {
                    if (rd_idx) gp_regs[rd_idx] = csr_regs[csr];
                    csr_regs[csr] &= ~uns_rs1;
                    pc_reg += 4;
                    break;
                }
                case 5: // CSRRWI
                {
                    if (rd_idx) gp_regs[rd_idx] = csr_regs[csr];
                    csr_regs[csr] = z_immed;
                    pc_reg += 4;
                    break;
                }
                case 6: // CSRRSI
                {
                    if (rd_idx) gp_regs[rd_idx] = csr_regs[csr];
                    csr_regs[csr] |= z_immed;
                    pc_reg += 4;
                    break;
                }
                case 7: // CSRRCI
                {
                    if (rd_idx) gp_regs[rd_idx] = csr_regs[csr];
                    csr_regs[csr] &= ~z_immed;
                    pc_reg += 4;
                    break;
                }
                default:
                {
                    // Invalid instruction
                    except_nr = RAISE_ILLEGAL;
                }
            }
            break;
        }

        default:
        {
            // Invalid instruction
            except_nr = RAISE_ILLEGAL;
        }
    }
    
    /*
    // Interrupts handling
    if ((ip_reg) && (ie_reg & 1) && (except_nr == RAISE_NONE))
    {
        except_nr = RAISE_IRQ_PEND;
    }
    */
    
    // Exceptions handling
    if (except_nr != RAISE_NONE)
    {
        csr_regs[CSR_MEPC] = pc_reg;
        if (except_nr == RAISE_ILLEGAL)
        {
            csr_regs[CSR_MTVAL] = inst;
        }
        else if (except_nr == RAISE_IADDR_ERR)
        {
            csr_regs[CSR_MTVAL] = jmp_addr;
        }
        else if ((except_nr == RAISE_LADDR_ERR) || (except_nr == RAISE_SADDR_ERR))
        {
            csr_regs[CSR_MTVAL] = mem_addr;
        }
        else
        {
            csr_regs[CSR_MTVAL] = 0;
        }
        csr_regs[CSR_MCAUSE] = except_nr;
        pc_reg = csr_regs[CSR_MTVEC];
        except_nr = RAISE_NONE;
    }
}

void RISCVTrace::riscv_simu_rd(vluint32_t addr, vluint32_t data)
{
    //if (addr != (mem_addr & 0xFFFFFFFC))
    if (addr != mem_addr)
    {
        fprintf(tfh, "!!! DATA ADDRESS MISMATCH !!!\n");
        fprintf(tfh, "Verilog : %08X, C-Model : %08X\n", addr, mem_addr);
    }
    
    switch (mem_xfer)
    {
        case XFER_LB:
        {
            if (rd_idx)
            {
                switch (mem_addr & 3)
                {
                    case 0 : gp_regs[rd_idx] = (data >>  0) & 0xFF; break;
                    case 1 : gp_regs[rd_idx] = (data >>  8) & 0xFF; break;
                    case 2 : gp_regs[rd_idx] = (data >> 16) & 0xFF; break;
                    case 3 : gp_regs[rd_idx] = (data >> 24) & 0xFF; break;
                }
                if (GET_BIT(gp_regs[rd_idx],7)) gp_regs[rd_idx] |= 0xFFFFFF00;
            }
            break;
        }
        case XFER_LBU:
        {
            if (rd_idx)
            {
                switch (mem_addr & 3)
                {
                    case 0 : gp_regs[rd_idx] = (data >>  0) & 0xFF; break;
                    case 1 : gp_regs[rd_idx] = (data >>  8) & 0xFF; break;
                    case 2 : gp_regs[rd_idx] = (data >> 16) & 0xFF; break;
                    case 3 : gp_regs[rd_idx] = (data >> 24) & 0xFF; break;
                }
            }
            break;
        }
        case XFER_LH:
        {
            if (rd_idx)
            {
                switch (mem_addr & 2)
                {
                    case 0 : gp_regs[rd_idx] = (data >>  0) & 0xFFFF; break;
                    case 2 : gp_regs[rd_idx] = (data >> 16) & 0xFFFF; break;
                }
                if (GET_BIT(gp_regs[rd_idx],15)) gp_regs[rd_idx] |= 0xFFFF0000;
            }
            break;
        }
        case XFER_LHU:
        {
            if (rd_idx)
            {
                switch (mem_addr & 2)
                {
                    case 0 : gp_regs[rd_idx] = (data >>  0) & 0xFFFF; break;
                    case 2 : gp_regs[rd_idx] = (data >> 16) & 0xFFFF; break;
                }
            }
            break;
        }
        case XFER_LW:
        {
            if (rd_idx) gp_regs[rd_idx] = data;
            break;
        }
        default:
        {
            fprintf(tfh, "!!! DATA TRANSFER TYPE MISMATCH !!!\n");
        }
    }
    mem_xfer = XFER_NONE;
}

void RISCVTrace::riscv_simu_wr(vluint32_t addr, vluint32_t data, vluint8_t mask)
{
    
    //if (addr != (mem_addr & 0xFFFFFFFC))
    if (addr != mem_addr)
    {
        fprintf(tfh, "!!! DATA ADDRESS MISMATCH !!!\n");
        fprintf(tfh, "Verilog : %08X, C-Model : %08X\n", addr, mem_addr);
    }
    
    if (data != mem_data)
    {
        fprintf(tfh, "!!! DATA VALUE MISMATCH !!!\n");
        fprintf(tfh, "Verilog : %08X, C-Model : %08X\n", data, mem_data);
    }
    
    if (mask != mem_mask)
    {
        fprintf(tfh, "!!! DATA MASK MISMATCH !!!\n");
        fprintf(tfh, "Verilog : %1X, C-Model : %1X\n", mask, mem_mask);
    }
    mem_xfer = XFER_NONE;
}
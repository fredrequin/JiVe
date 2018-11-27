#ifndef _RISCV_TRACE_H_
#define _RISCV_TRACE_H_

#include "verilated.h"
#include <stdlib.h>
#include <stdio.h>

class RISCVTrace
{
    public:
        // Constructor and destructor
        RISCVTrace(vluint32_t reset_vect, vluint32_t comp_data_beg, vluint32_t comp_data_end);
        ~RISCVTrace();
        // Methods
        int  open(const char *name);
        int  openNext(void);
        void close(void);
        void dump(vluint64_t stamp,     vluint8_t  clk,
                  vluint8_t  i_rd_ack,  vluint32_t i_address, vluint32_t i_rddata,
                  vluint8_t  d_rd_ack,  vluint8_t  d_wr_ack,  vluint32_t d_address,
                  vluint8_t  d_byteena, vluint32_t d_rddata,  vluint32_t d_wrdata,
                  vluint32_t inr_ir_irq,
                  vluint8_t  wb_ena,    vluint8_t  wb_idx,    vluint32_t wb_data);
        char disasm(vluint32_t inst, vluint32_t pc, int idx);
    private:
        // Utility functions
        char       *uhex_to_str(vluint32_t val, int dig);
        char       *shex_to_str(vluint32_t val, int dig);
        char       *get_csr_str(int csr);
        // RISC-V disassembler
        void        riscv_dasm(char *buf, vluint32_t inst, vluint32_t pc);
        // RISC-V simulator
        void        riscv_simu_if(vluint32_t addr, vluint32_t inst);
        void        riscv_simu_rd(vluint32_t addr, vluint32_t data);
        void        riscv_simu_wr(vluint32_t addr, vluint32_t data, vluint8_t mask);
        // General purpose registers
        vluint32_t  gp_regs[32];
        // Program counter
        vluint32_t  pc_reg;
        // Compliance tests results
        vluint32_t  test_start;
        vluint32_t  test_stop;
        vluint32_t  test_size;
        vluint8_t  *test_ptr;
        // CSR registers
        vluint32_t  csr_regs[4096];
        // Disassembly buffer
        char        dasm_buf[32];
        // Trace file handle
        char        tname[256];
        FILE       *tfh;
        // Output file handle
        char        oname[256];
        FILE       *ofh;
        // Exception number
        vluint32_t  except_nr;
        // Previous clock state
        vluint8_t   prev_clk;
        // Register writeback
        vluint8_t   rd_idx;
        // Transfer type (load/store)
        vluint8_t   mem_xfer;
        // Bytes masking (load/store)
        vluint8_t   mem_mask;
        // Memory address (load/store)
        vluint32_t  mem_addr;
        // Memory data (store)
        vluint32_t  mem_data;
};

#endif /* _RISCV_TRACE_H_ */
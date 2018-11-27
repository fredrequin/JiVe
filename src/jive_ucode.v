
// w_rs1_sel[1:0] :
// ================
localparam [1:0]
    X_RS1     = 2'b00,
    X_DIN     = 2'b01,
    X_CSR     = 2'b10,
    X_ZIMM    = 2'b11;

// w_rs2_sel[1:0] :
// ================
localparam [1:0]
    Y_RS2     = 2'b00,
    Y_IMM     = 2'b01,
    Y_CSR     = 2'b10,
    Y_FOUR    = 2'b11;

// w_alu_op[4:0] :
// ===============
localparam [4:0]
    ALU_ADD   = 5'b00000,
    ALU_SUB   = 5'b00001,
    ALU_COMP  = 5'b00011,
    ALU_XOR   = 5'b00100,
    ALU_MSK   = 5'b00101,
    ALU_OR    = 5'b00110,
    ALU_AND   = 5'b00111,
    ALU_BYP   = 5'b01000,
    ALU_SLL   = 5'b01001,
    ALU_SRL   = 5'b01010,
    ALU_SRA   = 5'b01011,
    ALU_OP    = 5'b10000;

// { w_fetch, w_rden, w_wren, w_branch } :
// =======================================
localparam [3:0]
    BUS_NONE  = 4'b0000,
    BUS_COND  = 4'b0001,
    BUS_WRITE = 4'b0010,
    BUS_READ  = 4'b0100,
    BUS_FETCH = 4'b1000;
    
// w_csr_idx[6:0] :
// ================
localparam [6:0]
    CSR_ZERO   = 7'h00,
    CSR_PC     = 7'h07,
    CSR_MTVEC  = 7'h15,
    CSR_MEPC   = 7'h19,
    CSR_MCAUSE = 7'h1A,
    CSR_MTVAL  = 7'h1B,
    CSR_INSTR  = 7'h40;

// UCODE_INST_xx[ 1: 0] : Register source #1 select (w_rs1_sel[1:0])
// UCODE_INST_xx[ 3: 2] : Register source #2 select (w_rs2_sel[1:0])
// UCODE_INST_xx[ 8: 4] : Destination select (w_use_addr, w_csr_sel, w_rd_wren, w_upd_dout, w_upd_addr)
// UCODE_INST_xx[14:10] : ALU operation (w_alu_op[4:0])
// UCODE_INST_xx[   15] : Conditional branch (w_branch)
// UCODE_INST_xx[   16] : External bus data write enable (w_wren)
// UCODE_INST_xx[   17] : External bus data read enable (w_rden)
// UCODE_INST_xx[   18] : External bus instruction fetch (w_fetch)
// UCODE_INST_xx[25:19] : CSR index (w_csr_idx[6:0])
// UCODE_INST_xx[31:26] : Next microcode address (w_uc_addr[5:0])
localparam [31:0]
    UCODE_INST_00 = { 6'h02, CSR_ZERO,   BUS_READ,  ALU_ADD,  1'b0, 5'b00001, Y_IMM,  X_RS1  }, // 6'h00 : LOAD_0 -> LOAD_1
    UCODE_INST_01 = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h01 : ILLEGAL_0
    UCODE_INST_02 = { 6'h3C, CSR_ZERO,   BUS_NONE,  ALU_ADD,  1'b0, 5'b00100, Y_CSR,  X_DIN  }, // 6'h02 : LOAD_1 -> PC_INC_0
    UCODE_INST_03 = { 6'h00, CSR_PC,     BUS_FETCH, ALU_ADD,  1'b0, 5'b01101, Y_FOUR, X_CSR  }, // 6'h03 : FENCE_0 : NOP (end)
    UCODE_INST_04 = { 6'h3C, CSR_ZERO,   BUS_NONE,  ALU_OP,   1'b0, 5'b00100, Y_IMM,  X_RS1  }, // 6'h04 : OP_IMM_0 -> PC_INC_0
    UCODE_INST_05 = { 6'h3C, CSR_PC,     BUS_NONE,  ALU_ADD,  1'b0, 5'b00100, Y_IMM,  X_CSR  }, // 6'h05 : AUIPC_0 -> PC_INC_0
    UCODE_INST_06 = { 6'h07, CSR_ZERO,   BUS_NONE,  ALU_ADD,  1'b0, 5'b00001, Y_CSR,  X_RS1  }, // 6'h06 : OP_IMM_SH_0 -> OP_IMM_SH_1
    UCODE_INST_07 = { 6'h09, CSR_ZERO,   BUS_NONE,  ALU_OP,   1'b0, 5'b00000, Y_IMM,  X_CSR  }, // 6'h07 : OP_IMM_SH_1 -> ADDR_WB
    UCODE_INST_08 = { 6'h0A, CSR_ZERO,   BUS_NONE,  ALU_ADD,  1'b0, 5'b00001, Y_IMM,  X_RS1  }, // 6'h08 : STORE_0 -> STORE_1
    UCODE_INST_09 = { 6'h3C, CSR_ZERO,   BUS_NONE,  ALU_ADD,  1'b0, 5'b10100, Y_CSR,  X_CSR  }, // 6'h09 : ADDR_WB -> PC_INC_0
    UCODE_INST_0A = { 6'h3C, CSR_ZERO,   BUS_WRITE, ALU_ADD,  1'b0, 5'b00010, Y_RS2,  X_CSR  }, // 6'h0A : STORE_1 -> PC_INC_0
    UCODE_INST_0B = { 6'h3F, CSR_PC,     BUS_NONE,  ALU_ADD,  1'b0, 5'b00100, Y_FOUR, X_CSR  }, // 6'h0B : JALR_1 -> RESET_0
    UCODE_INST_0C = { 6'h3C, CSR_ZERO,   BUS_NONE,  ALU_OP,   1'b0, 5'b00100, Y_RS2,  X_RS1  }, // 6'h0C : OP_0 -> PC_INC_0
    UCODE_INST_0D = { 6'h3C, CSR_ZERO,   BUS_NONE,  ALU_ADD,  1'b0, 5'b00100, Y_IMM,  X_CSR  }, // 6'h0D : LUI_0 -> PC_INC_0
    UCODE_INST_0E = { 6'h0F, CSR_ZERO,   BUS_NONE,  ALU_ADD,  1'b0, 5'b00001, Y_CSR,  X_RS1  }, // 6'h0E : OP_SH_0 -> OP_SH_1
    UCODE_INST_0F = { 6'h09, CSR_ZERO,   BUS_NONE,  ALU_OP,   1'b0, 5'b00000, Y_RS2,  X_CSR  }, // 6'h0F : OP_SH_1 -> ADDR_WB
    UCODE_INST_10 = { 6'h1A, CSR_MCAUSE, BUS_NONE,  ALU_ADD,  1'b0, 5'b01100, Y_IMM,  X_ZIMM }, // 6'h10 : CAUSE_0 -> VECTOR_0
    UCODE_INST_11 = { 6'h31, CSR_INSTR,  BUS_NONE,  ALU_ADD,  1'b0, 5'b00001, Y_IMM,  X_CSR  }, // 6'h11 : CSRRW_0 -> CSRRW_1
    UCODE_INST_12 = { 6'h32, CSR_INSTR,  BUS_NONE,  ALU_ADD,  1'b0, 5'b00001, Y_IMM,  X_CSR  }, // 6'h12 : CSRRS_0 -> CSRRS_1
    UCODE_INST_13 = { 6'h33, CSR_INSTR,  BUS_NONE,  ALU_ADD,  1'b0, 5'b00001, Y_IMM,  X_CSR  }, // 6'h13 : CSRRC_0 -> CSRRC_1
    UCODE_INST_14 = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h14 : 
    UCODE_INST_15 = { 6'h35, CSR_INSTR,  BUS_NONE,  ALU_ADD,  1'b0, 5'b00001, Y_IMM,  X_CSR  }, // 6'h15 : CSRRWI_0 -> CSRRWI_1
    UCODE_INST_16 = { 6'h36, CSR_INSTR,  BUS_NONE,  ALU_ADD,  1'b0, 5'b00001, Y_IMM,  X_CSR  }, // 6'h16 : CSRRSI_0 -> CSRRSI_1
    UCODE_INST_17 = { 6'h37, CSR_INSTR,  BUS_NONE,  ALU_ADD,  1'b0, 5'b00001, Y_IMM,  X_CSR  }, // 6'h17 : CSRRCI_0 -> CSRRCI_1
    UCODE_INST_18 = { 6'h3C, CSR_ZERO,   BUS_COND,  ALU_COMP, 1'b0, 5'b00000, Y_RS2,  X_RS1  }, // 6'h18 : BRANCH_0 -> PC_INC_0 / PC_ADD_0
    UCODE_INST_19 = { 6'h0B, CSR_ZERO,   BUS_NONE,  ALU_ADD,  1'b0, 5'b00001, Y_IMM,  X_RS1  }, // 6'h19 : JALR_0 -> JALR_1 
    UCODE_INST_1A = { 6'h3F, CSR_MTVEC,  BUS_NONE,  ALU_ADD,  1'b0, 5'b00001, Y_IMM,  X_CSR  }, // 6'h1A : VECTOR_0 -> RESET_0
    UCODE_INST_1B = { 6'h3D, CSR_PC,     BUS_NONE,  ALU_ADD,  1'b0, 5'b00100, Y_FOUR, X_CSR  }, // 6'h1B : JAL_0 -> PC_ADD_0
    UCODE_INST_1C = { 6'h10, CSR_MEPC,   BUS_NONE,  ALU_ADD,  1'b0, 5'b11100, Y_IMM,  X_RS1  }, // 6'h1C : ECALL_0 -> CAUSE_0
    UCODE_INST_1D = { 6'h10, CSR_MEPC,   BUS_NONE,  ALU_ADD,  1'b0, 5'b11100, Y_IMM,  X_RS1  }, // 6'h1D : EBREAK_0 -> CAUSE_0
    UCODE_INST_1E = { 6'h3F, CSR_MEPC,   BUS_NONE,  ALU_ADD,  1'b0, 5'b00001, Y_CSR,  X_RS1  }, // 6'h1E : MRET_0 -> RESET_0
    UCODE_INST_1F = { 6'h00, CSR_PC,     BUS_FETCH, ALU_ADD,  1'b0, 5'b01101, Y_FOUR, X_CSR  }, // 6'h1F : WFI_0 : NOP (end)
    UCODE_INST_20 = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h20 : 
    UCODE_INST_21 = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h21 : 
    UCODE_INST_22 = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h22 : 
    UCODE_INST_23 = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h23 : 
    UCODE_INST_24 = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h24 : 
    UCODE_INST_25 = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h25 : 
    UCODE_INST_26 = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h26 : 
    UCODE_INST_27 = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h27 : 
    UCODE_INST_28 = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h28 :
    UCODE_INST_29 = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h29 : 
    UCODE_INST_2A = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h2A :
    UCODE_INST_2B = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h2B : 
    UCODE_INST_2C = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h2C :
    UCODE_INST_2D = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h2D :
    UCODE_INST_2E = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h2E : 
    UCODE_INST_2F = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h2F : 
    UCODE_INST_30 = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h30 : 
    UCODE_INST_31 = { 6'h09, CSR_INSTR,  BUS_NONE,  ALU_ADD,  1'b0, 5'b01100, Y_IMM,  X_RS1  }, // 6'h31 : CSRRW_1 -> ADDR_WB
    UCODE_INST_32 = { 6'h09, CSR_INSTR,  BUS_NONE,  ALU_OR,   1'b0, 5'b01100, Y_CSR,  X_RS1  }, // 6'h32 : CSRRS_1 -> ADDR_WB
    UCODE_INST_33 = { 6'h09, CSR_INSTR,  BUS_NONE,  ALU_MSK,  1'b0, 5'b01100, Y_CSR,  X_RS1  }, // 6'h33 : CSRRC_1 -> ADDR_WB
    UCODE_INST_34 = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h34 : 
    UCODE_INST_35 = { 6'h09, CSR_INSTR,  BUS_NONE,  ALU_ADD,  1'b0, 5'b01100, Y_IMM,  X_ZIMM }, // 6'h35 : CSRRWI_1 -> ADDR_WB
    UCODE_INST_36 = { 6'h09, CSR_INSTR,  BUS_NONE,  ALU_OR,   1'b0, 5'b01100, Y_CSR,  X_ZIMM }, // 6'h36 : CSRRSI_1 -> ADDR_WB
    UCODE_INST_37 = { 6'h09, CSR_INSTR,  BUS_NONE,  ALU_MSK,  1'b0, 5'b01100, Y_CSR,  X_ZIMM }, // 6'h37 : CSRRCI_1 -> ADDR_WB
    UCODE_INST_38 = { 6'h39, CSR_MTVAL,  BUS_NONE,  ALU_ADD,  1'b0, 5'b11100, Y_IMM,  X_CSR  }, // 6'h38 : IF_ERR_0 -> IF_ERR_1
    UCODE_INST_39 = { 6'h1C, CSR_PC,     BUS_NONE,  ALU_ADD,  1'b0, 5'b00001, Y_IMM,  X_CSR  }, // 6'h39 : IF_ERR_1 -> ECALL_0
    UCODE_INST_3A = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h3A : 
    UCODE_INST_3B = { 6'h00, 7'h00,      4'b0000,   5'b00000, 1'b0, 5'b00000, 2'b00,  2'b00  }, // 6'h3B : 
    UCODE_INST_3C = { 6'h38, CSR_PC,     BUS_FETCH, ALU_ADD,  1'b0, 5'b01101, Y_FOUR, X_CSR  }, // 6'h3C : PC_INC_0 (end) -> IF_ERR_0
    UCODE_INST_3D = { 6'h38, CSR_PC,     BUS_FETCH, ALU_ADD,  1'b0, 5'b01101, Y_IMM,  X_CSR  }, // 6'h3D : PC_ADD_0 (end) -> IF_ERR_0
    UCODE_INST_3E = { 6'h38, CSR_PC,     BUS_FETCH, ALU_ADD,  1'b0, 5'b01101, Y_IMM,  X_RS1  }, // 6'h3E : PC_REG_0 (end) -> IF_ERR_0
    UCODE_INST_3F = { 6'h38, CSR_PC,     BUS_FETCH, ALU_ADD,  1'b0, 5'b11100, Y_IMM,  X_CSR  }; // 6'h3F : RESET_0 (end)

// SB_RAM256x16 initialisation :
// =============================

// LSW
localparam [255:0]
    // Micro-code (8'h00 - 8'h3F)
    LO_UCODE_0 = { UCODE_INST_0F[15:0], UCODE_INST_0E[15:0], UCODE_INST_0D[15:0], UCODE_INST_0C[15:0],
                   UCODE_INST_0B[15:0], UCODE_INST_0A[15:0], UCODE_INST_09[15:0], UCODE_INST_08[15:0],
                   UCODE_INST_07[15:0], UCODE_INST_06[15:0], UCODE_INST_05[15:0], UCODE_INST_04[15:0],
                   UCODE_INST_03[15:0], UCODE_INST_02[15:0], UCODE_INST_01[15:0], UCODE_INST_00[15:0]
                 },
    LO_UCODE_1 = { UCODE_INST_1F[15:0], UCODE_INST_1E[15:0], UCODE_INST_1D[15:0], UCODE_INST_1C[15:0],
                   UCODE_INST_1B[15:0], UCODE_INST_1A[15:0], UCODE_INST_19[15:0], UCODE_INST_18[15:0],
                   UCODE_INST_17[15:0], UCODE_INST_16[15:0], UCODE_INST_15[15:0], UCODE_INST_14[15:0],
                   UCODE_INST_13[15:0], UCODE_INST_12[15:0], UCODE_INST_11[15:0], UCODE_INST_10[15:0]
                 },
    LO_UCODE_2 = { UCODE_INST_2F[15:0], UCODE_INST_2E[15:0], UCODE_INST_2D[15:0], UCODE_INST_2C[15:0],
                   UCODE_INST_2B[15:0], UCODE_INST_2A[15:0], UCODE_INST_29[15:0], UCODE_INST_28[15:0],
                   UCODE_INST_27[15:0], UCODE_INST_26[15:0], UCODE_INST_25[15:0], UCODE_INST_24[15:0],
                   UCODE_INST_23[15:0], UCODE_INST_22[15:0], UCODE_INST_21[15:0], UCODE_INST_20[15:0]
                 },
    LO_UCODE_3 = { UCODE_INST_3F[15:0], UCODE_INST_3E[15:0], UCODE_INST_3D[15:0], UCODE_INST_3C[15:0],
                   UCODE_INST_3B[15:0], UCODE_INST_3A[15:0], UCODE_INST_39[15:0], UCODE_INST_38[15:0],
                   UCODE_INST_37[15:0], UCODE_INST_36[15:0], UCODE_INST_35[15:0], UCODE_INST_34[15:0],
                   UCODE_INST_33[15:0], UCODE_INST_32[15:0], UCODE_INST_31[15:0], UCODE_INST_30[15:0]
                 },
    // x0 - x31 registers (8'h40 - 8'h7F)
    LO_UCODE_4 = 256'h0,
    LO_UCODE_5 = 256'h0,
    LO_UCODE_6 = 256'h0,
    LO_UCODE_7 = 256'h0,
    // CSR registers (8'h80 - 8'hFF)
    LO_UCODE_8 = {
                // special : pc   (scounteren)   (?tvec)        (?ie)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // (fcsr)         (frm)          (fflags)       (?status)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000
                 },
    LO_UCODE_9 = {
                // -undef-        -undef-        -undef-        (?ip)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // (?tval)        (?cause)       (?epc)         (?scratch)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000
                 },
    LO_UCODE_A = {
                // -undef-        mcounteren     mtvec          mie
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // mideleg        medeleg        misa           mstatus
                   32'h0000_0000, 32'h0000_0000, 32'h4000_0100, 32'h0000_0000
                 },
    LO_UCODE_B = {
                // -undef-        -undef-        -undef-        mip
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // mtval          mcause         mepc           mscratch
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000
                 },
    LO_UCODE_C = {
                // (hpmcounter)   (hpmcounter)   (hpmcounter)   (hpmcounter)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // (hpmcounter)   (instret)      time           cycle
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000
                 },
    LO_UCODE_D = {
                // (hpmcounterh)  (hpmcounterh)  (hpmcounterh)  (hpmcounterh)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // (hpmcounterh)  (instret)      timeh          cycleh
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000
                 },
    LO_UCODE_E = {
                // -undef-        -undef-        -undef-        (?ip)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // -undef-        -undef-        -undef-        (?ip)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000
                 },
    LO_UCODE_F = {
                // -undef-        -undef-        -undef-        mhartid
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // mimpid         marchid        mvendorid      -undef-
                   IMPL_ID,       ARCHI_ID,      VENDOR_ID,     32'h0000_0000
                 };

// MSW
localparam [255:0]
    // Micro-code (8'h00 - 8'h3F)
    HI_UCODE_0 = { UCODE_INST_0F[31:16], UCODE_INST_0E[31:16], UCODE_INST_0D[31:16], UCODE_INST_0C[31:16],
                   UCODE_INST_0B[31:16], UCODE_INST_0A[31:16], UCODE_INST_09[31:16], UCODE_INST_08[31:16],
                   UCODE_INST_07[31:16], UCODE_INST_06[31:16], UCODE_INST_05[31:16], UCODE_INST_04[31:16],
                   UCODE_INST_03[31:16], UCODE_INST_02[31:16], UCODE_INST_01[31:16], UCODE_INST_00[31:16]
                 },
    HI_UCODE_1 = { UCODE_INST_1F[31:16], UCODE_INST_1E[31:16], UCODE_INST_1D[31:16], UCODE_INST_1C[31:16],
                   UCODE_INST_1B[31:16], UCODE_INST_1A[31:16], UCODE_INST_19[31:16], UCODE_INST_18[31:16],
                   UCODE_INST_17[31:16], UCODE_INST_16[31:16], UCODE_INST_15[31:16], UCODE_INST_14[31:16],
                   UCODE_INST_13[31:16], UCODE_INST_12[31:16], UCODE_INST_11[31:16], UCODE_INST_10[31:16]
                 },
    HI_UCODE_2 = { UCODE_INST_2F[31:16], UCODE_INST_2E[31:16], UCODE_INST_2D[31:16], UCODE_INST_2C[31:16],
                   UCODE_INST_2B[31:16], UCODE_INST_2A[31:16], UCODE_INST_29[31:16], UCODE_INST_28[31:16],
                   UCODE_INST_27[31:16], UCODE_INST_26[31:16], UCODE_INST_25[31:16], UCODE_INST_24[31:16],
                   UCODE_INST_23[31:16], UCODE_INST_22[31:16], UCODE_INST_21[31:16], UCODE_INST_20[31:16]
                 },
    HI_UCODE_3 = { UCODE_INST_3F[31:16], UCODE_INST_3E[31:16], UCODE_INST_3D[31:16], UCODE_INST_3C[31:16],
                   UCODE_INST_3B[31:16], UCODE_INST_3A[31:16], UCODE_INST_39[31:16], UCODE_INST_38[31:16],
                   UCODE_INST_37[31:16], UCODE_INST_36[31:16], UCODE_INST_35[31:16], UCODE_INST_34[31:16],
                   UCODE_INST_33[31:16], UCODE_INST_32[31:16], UCODE_INST_31[31:16], UCODE_INST_30[31:16]
                 },
    // x0 - x31 registers (8'h40 - 8'h7F)
    HI_UCODE_4 = 256'h0,
    HI_UCODE_5 = 256'h0,
    HI_UCODE_6 = 256'h0,
    HI_UCODE_7 = 256'h0,
    // CSR registers (8'h80 - 8'hFF)
    HI_UCODE_8 = {
                // special : pc   (scounteren)   (?tvec)        (?ie)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // (fcsr)         (frm)          (fflags)       (?status)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000
                 },
    HI_UCODE_9 = {
                // -undef-        -undef-        -undef-        (?ip)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // (?tval)        (?cause)       (?epc)         (?scratch)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000
                 },
    HI_UCODE_A = {
                // -undef-        mcounteren     mtvec          mie
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // mideleg        medeleg        misa           mstatus
                   32'h0000_0000, 32'h0000_0000, 32'h4000_0100, 32'h0000_0000
                 },
    HI_UCODE_B = {
                // -undef-        -undef-        -undef-        mip
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // mtval          mcause         mepc           mscratch
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000
                 },
    HI_UCODE_C = {
                // (hpmcounter)   (hpmcounter)   (hpmcounter)   (hpmcounter)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // (hpmcounter)   (instret)      time           cycle
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000
                 },
    HI_UCODE_D = {
                // (hpmcounterh)  (hpmcounterh)  (hpmcounterh)  (hpmcounterh)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // (hpmcounterh)  (instret)      timeh          cycleh
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000
                 },
    HI_UCODE_E = {
                // -undef-        -undef-        -undef-        (?ip)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // -undef-        -undef-        -undef-        (?ip)
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000
                 },
    HI_UCODE_F = {
                // -undef-        -undef-        -undef-        mhartid
                   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
                // mimpid         marchid        mvendorid      -undef-
                   IMPL_ID,       ARCHI_ID,      VENDOR_ID,     32'h0000_0000
                 };

    `ifdef verilator3
    integer _fh;
    
    initial begin : WRITE_UCODE_SYN_MEM
        integer _i;
        reg [4095:0] _tmp;
    
        _fh = $fopen("../mem/jive_regfile_hi.mem", "w");
        _tmp = { HI_UCODE_F, HI_UCODE_E, HI_UCODE_D, HI_UCODE_C,
                 HI_UCODE_B, HI_UCODE_A, HI_UCODE_9, HI_UCODE_8,
                 HI_UCODE_7, HI_UCODE_6, HI_UCODE_5, HI_UCODE_4,
                 HI_UCODE_3, HI_UCODE_2, HI_UCODE_1, HI_UCODE_0 };
        for (_i = 0; _i < 256; _i = _i + 1) begin
             $fwrite(_fh, "%x\n", _tmp[15:0]);
             _tmp = { 16'b0, _tmp[4095:16] };
        end
        $fclose(_fh);
        
        _fh = $fopen("../mem/jive_regfile_lo.mem", "w");
        _tmp = { LO_UCODE_F, LO_UCODE_E, LO_UCODE_D, LO_UCODE_C,
                 LO_UCODE_B, LO_UCODE_A, LO_UCODE_9, LO_UCODE_8,
                 LO_UCODE_7, LO_UCODE_6, LO_UCODE_5, LO_UCODE_4,
                 LO_UCODE_3, LO_UCODE_2, LO_UCODE_1, LO_UCODE_0 };
        for (_i = 0; _i < 256; _i = _i + 1) begin
             $fwrite(_fh, "%x\n", _tmp[15:0]);
             _tmp = { 16'b0, _tmp[4095:16] };
        end
        $fclose(_fh);
    end
    `endif

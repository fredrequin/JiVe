module jive_decode
(
    input         clk,          // CPU clock
    
    input         id_ena,       // Decode stage active
    input         em_ena,       // Exception stage active
    
    input  [31:0] inst_reg_f,   // From fetch stage
    input   [6:0] except_src,   // From exception stage

    output  [4:0] rs1_idx_d,
    output  [4:0] rs2_idx_d,
    output  [2:0] func3_d,
    output  [4:0] rd_idx_d,
    output  [5:0] uc_addr_d,
    output  [3:0] alu_op_d,
    output [31:0] immed_d,
    output  [5:0] zimmed_d,
    output  [5:0] csr_idx_d,
    output        mret_d
);

    // ========================================================================
    // INSTRUCTION FIELDS
    // ========================================================================
    
    assign rs2_idx_d = inst_reg_f[24:20];
    assign rs1_idx_d = inst_reg_f[19:15];
    assign func3_d   = inst_reg_f[14:12];
    assign rd_idx_d  = inst_reg_f[11: 7];
    
    // ========================================================================
    // ALU OPERATIONS
    // ========================================================================
    
    localparam [3:0]
        OP_ADD = 4'b0000,
        OP_SUB = 4'b0001,
        OP_CMP = 4'b0011,
        OP_XOR = 4'b0100,
        OP_CLR = 4'b0101,
        OP_OR  = 4'b0110,
        OP_AND = 4'b0111,
        OP_BYP = 4'b1000,
        OP_SLL = 4'b1001,
        OP_SRL = 4'b1010,
        OP_SRA = 4'b1011;
    
    reg [3:0] r_alu_op_d;
    
    always @ (posedge clk) begin : ALU_OP
        
        // OP, OP_IMM
        case (inst_reg_f[14:12])
            3'b000 : r_alu_op_d <= (inst_reg_f[30] & inst_reg_f[5]) ? OP_SUB : OP_ADD;
            3'b001 : r_alu_op_d <= OP_SLL;
            3'b010 : r_alu_op_d <= OP_CMP;
            3'b011 : r_alu_op_d <= OP_CMP;
            3'b100 : r_alu_op_d <= OP_XOR;
            3'b101 : r_alu_op_d <= (inst_reg_f[30]) ? OP_SRA : OP_SRL;
            3'b110 : r_alu_op_d <= OP_OR;
            3'b111 : r_alu_op_d <= OP_AND;
        endcase
    end
    
    assign alu_op_d = r_alu_op_d;
    
    // ========================================================================
    // MICRO-CODE ADDRESS
    // ========================================================================
    
    /*
        5'b00000 : LOAD
        5'b00001 : ILLEGAL
        5'b00100 : OP_IMM
        5'b00101 : AUIPC
        5'b00110 : OP_IMM (shift)
        5'b01000 : STORE
        5'b01100 : OP
        5'b01101 : LUI
        5'b01110 : OP (shift)
        5'b10000 : CSRRW
        5'b10001 : CSRRS
        5'b10010 : (ILLEGAL)
        5'b10011 : CSRRC
        5'b10100 : CSRRWI
        5'b10101 : CSRRSI
        5'b10110 : (ILLEGAL)
        5'b10111 : CSRRCI
        5'b11000 : BRANCH
        5'b11001 : JALR
        5'b11011 : JAL
        5'b11100 : ECALL
        5'b11101 : EBREAK
        5'b11110 : MRET
        5'b11111 : WFI
    */
    
    localparam [5:0] ILLEGAL = 6'b000001;
    
    reg [5:0] w_addr;
    
    always @(*) begin : UC_ADDR
        reg [1:0] v_excep;
        reg [2:0] v_func3;
        reg       v_shift;
        reg       v_rd0;
        
        v_excep = { |inst_reg_f[22:21], inst_reg_f[20] };
        v_func3 =  inst_reg_f[14:12];
        v_shift = (inst_reg_f[13:12] == 2'b01) ? 1'b1 : 1'b0;
        v_rd0   = (inst_reg_f[11: 7] == 5'd0 ) ? 1'b1 : 1'b0;
    
        casez (inst_reg_f[6:0])
            7'b?????_00 : w_addr = ILLEGAL;   // Illegal
            7'b?????_01 : w_addr = ILLEGAL;   // Illegal
            7'b?????_10 : w_addr = ILLEGAL;   // Illegal
            7'b00000_11 : w_addr = 6'b000000; // LOAD
            7'b00001_11 : w_addr = ILLEGAL;   // LOAD_FP (not used)
            7'b00010_11 : w_addr = ILLEGAL;   // Illegal
            7'b00011_11 : w_addr = 6'b000011; // FENCE
            7'b00100_11 : w_addr = (v_shift) ? 6'b000110 : 6'b000100; // OP_IMM
            7'b00101_11 : w_addr = 6'b000101; // AUIPC
            7'b0011?_11 : w_addr = ILLEGAL;   // OP_IMM_32 (not used)
            7'b01000_11 : w_addr = 6'b001000; // STORE
            7'b01001_11 : w_addr = ILLEGAL;   // STORE_FP (not used)
            7'b0101?_11 : w_addr = ILLEGAL;   // Illegal
            7'b01100_11 : w_addr = (v_shift) ? 6'b001110 : 6'b001100; // OP
            7'b01101_11 : w_addr = 6'b001101; // LUI
            7'b0111?_11 : w_addr = ILLEGAL;   // OP_32 (not used)
            7'b10???_11 : w_addr = ILLEGAL;   // Illegal
            7'b11000_11 : w_addr = 6'b011000; // BRANCH
            7'b11001_11 : w_addr = 6'b011001; // JALR
            7'b11010_11 : w_addr = ILLEGAL;   // Illegal
            7'b11011_11 : w_addr = 6'b011011; // JAL
            7'b11100_11 : if (v_func3 == 3'd0)
                              w_addr = { 4'b0111, v_excep }; // ECALL, EBREAK, *RET, WFI
                          else
                              w_addr = { v_rd0, 2'b10, v_func3 }; // CSR*
            7'b11101_11 : w_addr = ILLEGAL;  // Illegal
            7'b1111?_11 : w_addr = ILLEGAL;  // Illegal
        endcase
    end
    
    assign uc_addr_d = w_addr;
    
    // ========================================================================
    // IMMEDIATE VALUES
    // ========================================================================
    
    wire [31:0] w_I_immed_f = { {21{inst_reg_f[31]}}, inst_reg_f[30:20] };
    wire [31:0] w_S_immed_f = { {21{inst_reg_f[31]}}, inst_reg_f[30:25], inst_reg_f[11:7] };
    wire [31:0] w_U_immed_f = { inst_reg_f[31:12], 12'b0 };
    wire [31:0] w_B_immed_f = { {20{inst_reg_f[31]}}, inst_reg_f[7], inst_reg_f[30:25], inst_reg_f[11:8], 1'b0 };
    wire [31:0] w_J_immed_f = { {12{inst_reg_f[31]}}, inst_reg_f[19:12], inst_reg_f[20], inst_reg_f[30:21], 1'b0 };
    
    reg  [31:0] r_immed_d;
    reg   [5:0] r_zimmed_d;
    reg         r_mret_d;
    
    always @ (posedge clk) begin : IMMED_VAL
        reg v_op_imm;
        reg v_load;
        reg v_store;
        reg v_lui;
        reg v_auipc;
        reg v_jal;
        reg v_jalr;
        reg v_branch;
        reg v_system;

        v_op_imm = (inst_reg_f[6:0] == 7'b00100_11) ? 1'b1 : 1'b0;
        v_load   = (inst_reg_f[6:0] == 7'b00000_11) ? 1'b1 : 1'b0;
        v_store  = (inst_reg_f[6:0] == 7'b01000_11) ? 1'b1 : 1'b0;
        v_lui    = (inst_reg_f[6:0] == 7'b01101_11) ? 1'b1 : 1'b0;
        v_auipc  = (inst_reg_f[6:0] == 7'b00101_11) ? 1'b1 : 1'b0;
        v_jal    = (inst_reg_f[6:0] == 7'b11011_11) ? 1'b1 : 1'b0;
        v_jalr   = (inst_reg_f[6:0] == 7'b11001_11) ? 1'b1 : 1'b0;
        v_branch = (inst_reg_f[6:0] == 7'b11000_11) ? 1'b1 : 1'b0;
        v_system = (inst_reg_f[6:0] == 7'b11100_11) ? 1'b1 : 1'b0;
        
        r_mret_d <= (inst_reg_f[21:7] == 15'b10_00000_000_00000) ? v_system : 1'b0;
        
        if (id_ena) begin
            r_immed_d <= w_I_immed_f & {32{v_op_imm | v_load | v_jalr}} // | v_system}}
                       | w_S_immed_f & {32{v_store}}
                       | w_U_immed_f & {32{v_lui | v_auipc}}
                       | w_B_immed_f & {32{v_branch}}
                       | w_J_immed_f & {32{v_jal}};
        end
        else if (em_ena) begin
            r_immed_d <= 32'd0;
        end
        
        if (id_ena) begin
            if (inst_reg_f[14]) begin
                // CSRRWI, CSRRSI, CSRRCI
                r_zimmed_d <= { 1'b0, inst_reg_f[19:15] };
            end
            else begin
                // ECALL, EBREAK
                r_zimmed_d <= (inst_reg_f[20]) ? 6'h03 : 6'h0B;
            end
        end
        else if (em_ena) begin
            r_zimmed_d <= 6'h00 & {6{except_src[0]}}  // Instruction address misaligned
                        | 6'h02 & {6{except_src[1]}}  // Illegal instruction
                        | 6'h04 & {6{except_src[2]}}  // Load address misaligned
                        | 6'h06 & {6{except_src[3]}}  // Store address misaligned
                        | 6'h13 & {6{except_src[4]}}  // Machine software interrupt
                        | 6'h17 & {6{except_src[5]}}  // Machine timer interrupt
                        | 6'h1B & {6{except_src[6]}}; // Machine external interrupt
        end
    end
    
    assign immed_d  = r_immed_d;
    assign zimmed_d = r_zimmed_d;
    assign mret_d   = r_mret_d;

    // ========================================================================
    // CSR INDEX & ACCESS
    // ========================================================================
    
    // Supported CSRs :
    // ================
    // 0x300 : mstatus (RW)
    // 0x301 : misa (RO?)
    // 0x304 : mie (RW)
    // 0x305 : mtvec (RW)
    // 0x340 : mscratch (RW)
    // 0x341 : mepc (RW)
    // 0x342 : mcause (RW)
    // 0x343 : mtval (RW)
    // 0x344 : mip (RW)
    // 0xB00 : mcycle (RO)
    // 0xC00 : cycle (RO)
    // 0xB80 : mcycleh (RO)
    // 0xC80 : cycleh (RO)
    // 0xF11 : mvendorid (RO)
    // 0xF12 : marchid (RO)
    // 0xF13 : mimpid (RO)
    // 0xF14 : mhartid (RO)
    
    reg [5:0] r_csr_idx;
    
    always @ (posedge clk) begin : CSR_INDEX
        
        case (inst_reg_f[31:28])
            4'b0000 : r_csr_idx[5:3] <= { 2'b00, inst_reg_f[26] };
            4'b0001 : r_csr_idx[5:3] <= { 2'b00, inst_reg_f[26] };
            4'b0010 : r_csr_idx[5:3] <= { 2'b00, inst_reg_f[26] };
            4'b0011 : r_csr_idx[5:3] <= { 2'b01, inst_reg_f[26] };
            4'b1111 : r_csr_idx[5:3] <= { 2'b11, inst_reg_f[24] };
            default : r_csr_idx[5:3] <= { 2'b10, inst_reg_f[27] };
        endcase
        r_csr_idx[2] <=  inst_reg_f[22];
        r_csr_idx[1] <=  inst_reg_f[21];
        r_csr_idx[0] <=  inst_reg_f[20];
    end
    
    assign csr_idx_d = r_csr_idx;

endmodule

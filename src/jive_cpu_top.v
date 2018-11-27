module jive_cpu_top
(
    input         rst,         // CPU reset
    input         clk,         // CPU clock
    
    output        fetch,       // Instruction fetch
    output        rden,        // Data read enable
    output        wren,        // Data write enable
    output  [3:0] bena,        // Byte enable
    output [31:0] addr,        // Instruction / Data address
    output [31:0] wdata,       // Data written
    input  [31:0] rdata,       // Instruction / Data read
    input         dtack,       // Data acknowledge
    
    input         ext_int,
    input         tmr_int
);
    parameter [31:0] RESET_PC  = 32'h00000000;
    parameter [31:0] VENDOR_ID = 32'h00000021;
    parameter [31:0] ARCHI_ID  = 32'h00000001;
    parameter [31:0] IMPL_ID   = 32'h00000001;
    
    // ========================================================================
    // CPU FINITE STATE MACHINE
    // ========================================================================
    
    localparam
        FSM_RESET   = 0,
        FSM_FETCH   = 1,
        FSM_DECODE  = 2,
        FSM_REGS_RD = 3,
        FSM_ALU_OP  = 4,
        FSM_ALU_WB  = 5,
        FSM_MULTI   = 6,
        FSM_LOAD    = 7,
        FSM_STORE   = 8,
        FSM_EXCEPT  = 9;
    
    reg   [9:0] r_cpu_fsm;
    wire        w_glb_int; // Global interrupt flag
    
    always @ (posedge rst or posedge clk) begin : CPU_FSM
        reg [4:0] v_cyc_ctr;
        reg       v_multi;
    
        if (rst) begin
            r_cpu_fsm <= 10'b000000001;
            v_cyc_ctr <= 5'd0;
        end
        else begin
            // Multi-cycle condition
            v_multi = |v_cyc_ctr[4:0];
            
            r_cpu_fsm <= 10'b000000000;
            case (1'b1)
                // CPU reset
                r_cpu_fsm[FSM_RESET] : begin
                    r_cpu_fsm[FSM_REGS_RD] <= 1'b1;
                end
                
                // Instruction fetch
                r_cpu_fsm[FSM_FETCH] : begin
                    r_cpu_fsm[FSM_DECODE]  <= dtack;
                    r_cpu_fsm[FSM_FETCH]   <= ~dtack;
                end
                
                // Instruction decode
                // Micro-instruction read
                r_cpu_fsm[FSM_DECODE] : begin
                    r_cpu_fsm[FSM_REGS_RD] <= 1'b1;
                end
                
                // Registers read
                r_cpu_fsm[FSM_REGS_RD] : begin
                    r_cpu_fsm[FSM_ALU_OP]  <= 1'b1;
                end
                
                // ALU operands select
                r_cpu_fsm[FSM_ALU_OP] : begin
                    r_cpu_fsm[FSM_ALU_WB]  <= 1'b1;
                end
                
                // ALU execute + writeback
                // Micro-instruction read
                r_cpu_fsm[FSM_ALU_WB] : begin
                    if (~r_msw_sel & r_alu_op[3]) begin
                        v_cyc_ctr <= w_rs2_data[4:0];
                    end
                    r_cpu_fsm[FSM_FETCH]   <= r_fetch;
                    r_cpu_fsm[FSM_LOAD]    <= r_rden;
                    r_cpu_fsm[FSM_STORE]   <= r_wren;
                    r_cpu_fsm[FSM_MULTI]   <= v_multi;
                    r_cpu_fsm[FSM_EXCEPT]  <=  r_if_err | r_ld_err | r_st_err | w_glb_int;
                    r_cpu_fsm[FSM_REGS_RD] <=
                        ~(r_fetch | r_rden | r_wren | v_multi | r_if_err | r_ld_err | r_st_err | w_glb_int);
                end
                
                // ALU multi-cycle execute (shift operations)
                r_cpu_fsm[FSM_MULTI] : begin
                    v_cyc_ctr <= v_cyc_ctr - 5'd1;
                    r_cpu_fsm[FSM_REGS_RD] <= ~(|v_cyc_ctr[4:1]);
                    r_cpu_fsm[FSM_MULTI]   <=   |v_cyc_ctr[4:1];
                end
                
                // Load from memory
                r_cpu_fsm[FSM_LOAD] : begin
                    r_cpu_fsm[FSM_REGS_RD] <= dtack;
                    r_cpu_fsm[FSM_LOAD]    <= ~dtack;
                end
                
                // Store to memory
                r_cpu_fsm[FSM_STORE] : begin
                    r_cpu_fsm[FSM_REGS_RD] <= dtack;
                    r_cpu_fsm[FSM_STORE]   <= ~dtack;
                end
                
                // Exception management
                r_cpu_fsm[FSM_EXCEPT] : begin
                    r_cpu_fsm[FSM_REGS_RD] <= 1'b1;
                end
            endcase
        end
    end

    // ========================================================================
    // INSTRUCTION FETCH
    // ========================================================================
    
    // Instruction register
    reg  [31:0] r_inst_reg_f;
    
    `ifdef verilator3
    // Instruction disassembly for impulse
    reg [31:0] r_dasm_f [0:7];
    import "DPI-C" function byte riscv_disasm(input int instr, input int pc, input int idx);
    /*
    // JavaScript code for impulse:
    for (var iter = new SamplesIterator(input); iter.hasNext(); )
    {
        var current = iter.next();
        var str = "";
        for (var i = 0; i < 8; i++)
        {
            if (!input[i].isNone())
            {
                var val = input[i].intValue();
                while (val)
                {
                    str += String.fromCharCode(val & 0xFF);
                    val >>= 8;
                }
            }
        }
        out.write(current,false,str);
    }
    
    In "Samples Configuration" window:
    Production: Javascript
    Primary Signal (in0): r_dasm_f(0)
    Additional: in1 r_dasm_f(1)
                ...
                in7 r_dasm_f(7)
    Process type: Discrete
    Signal type: Text
    */
    `endif
    
    always @ (posedge rst or posedge clk) begin : INST_FETCH
        integer i;
        reg [7:0] _dasm [0:31];
    
        if (rst) begin
            r_inst_reg_f <= { 12'b0, 5'b0, 3'b0, 5'b0, 7'b00100_11 }; // NOP
            `ifdef verilator3
            for (i = 0; i < 8; i = i + 1) r_dasm_f[i] = 32'h0;
            `endif
        end
        else begin
            if (r_cpu_fsm[FSM_FETCH] & dtack) begin
                r_inst_reg_f <= rdata;
                `ifdef verilator3
                for (i = 0; i < 32; i = i + 1) begin
                    _dasm[i] = riscv_disasm(rdata, addr, i);
                end
                r_dasm_f[0] = { _dasm[ 3], _dasm[ 2], _dasm[ 1], _dasm[ 0] };
                r_dasm_f[1] = { _dasm[ 7], _dasm[ 6], _dasm[ 5], _dasm[ 4] };
                r_dasm_f[2] = { _dasm[11], _dasm[10], _dasm[ 9], _dasm[ 8] };
                r_dasm_f[3] = { _dasm[15], _dasm[14], _dasm[13], _dasm[12] };
                r_dasm_f[4] = { _dasm[19], _dasm[18], _dasm[17], _dasm[16] };
                r_dasm_f[5] = { _dasm[23], _dasm[22], _dasm[21], _dasm[20] };
                r_dasm_f[6] = { _dasm[27], _dasm[26], _dasm[25], _dasm[24] };
                r_dasm_f[7] = { _dasm[31], _dasm[30], _dasm[29], _dasm[28] };
                `endif
            end
        end
    end
    
    // ========================================================================
    // INSTRUCTION DECODE
    // ========================================================================
    
    wire  [2:0] w_csr_mip;
    wire  [6:0] w_except_src = { w_csr_mip, r_st_err, r_ld_err, 1'b0, r_if_err};
    
    wire  [4:0] w_rs1_idx_d;
    wire  [4:0] w_rs2_idx_d;
    wire  [2:0] w_func3_d;
    wire  [4:0] w_rd_idx_d;
    wire  [5:0] w_uc_addr_d;
    wire  [3:0] w_alu_op_d;
    wire [31:0] w_immed_d;
    wire  [5:0] w_zimmed_d;
    wire        w_mret_d;
    wire  [5:0] w_csr_idx_d;

    jive_decode U_decode
    (
        .clk        (clk),
        
        .id_ena     (r_cpu_fsm[FSM_DECODE]),
        .em_ena     (r_cpu_fsm[FSM_EXCEPT]),
        
        .inst_reg_f (r_inst_reg_f),
        .except_src (w_except_src),
        
        .rs1_idx_d  (w_rs1_idx_d),
        .rs2_idx_d  (w_rs2_idx_d),
        .func3_d    (w_func3_d),
        .rd_idx_d   (w_rd_idx_d),
        .uc_addr_d  (w_uc_addr_d),
        .alu_op_d   (w_alu_op_d),
        .immed_d    (w_immed_d),
        .zimmed_d   (w_zimmed_d),
        .mret_d     (w_mret_d),
        .csr_idx_d  (w_csr_idx_d)
    );
    
    // ========================================================================
    // CPU MICRO-CODE
    // ========================================================================
    
    reg   [5:0] r_uc_addr;
    wire  [7:0] w_uc_addr = (r_cpu_fsm[FSM_DECODE]) ? { 2'b0, w_uc_addr_d } : { 2'b0, r_uc_addr };
    wire [31:0] w_uc_inst;
    
    wire  [5:0] w_csr_idx;  // For CSR read
    reg   [5:0] r_csr_idx;  // For CSR write
    reg         r_msw_sel;  // MSW (1) / LSW (0) select
    reg         r_upd_addr; // Bus address update
    reg         r_upd_dout; // Data output update
    reg         r_wb_wren;  // For RD/CSR write
    reg         r_use_addr; // For RD/CSR write
    reg         r_csr_sel;  // For CSR write
    reg   [3:0] r_alu_op;   // ALU operation
    reg         r_branch;   // Branch instruction
    reg         r_slt_br;   // SLTx / Bxx instruction 
    
    always @ (posedge rst or posedge clk) begin : UC_ADDR_REG
    
        if (rst) begin
            // RESET : load reset address
            r_uc_addr <= 6'h3F;
        end
        else begin
            // EXCEPTION or INTERRUPT : load 6'h38 or 6'h39
            if (r_cpu_fsm[FSM_ALU_WB] & (r_ld_err | r_st_err | w_glb_int)) begin
                r_uc_addr <= { 5'b11_100, w_glb_int }; // 6'h38 / 6'h39
            end
            // DECODE : load address from instcuction decoder
            else if (r_cpu_fsm[FSM_DECODE]) begin
                r_uc_addr <= w_uc_addr_d;
            end
            // EXECUTE : load address from micro-instruction
            else if (r_cpu_fsm[FSM_REGS_RD] & r_msw_sel) begin
                r_uc_addr <= w_uc_inst[31:26];
            end
        end
    end
    
    always @ (posedge clk) begin : UC_INST_REG
    
        // Latch micro-instruction field
        // (before they get changed by registers read)
        if (r_cpu_fsm[FSM_REGS_RD]) begin
            r_csr_idx  <= w_csr_idx;
            r_upd_addr <= w_uc_inst[4];
            r_upd_dout <= w_uc_inst[5];
            r_wb_wren  <= w_uc_inst[6];
            r_csr_sel  <= w_uc_inst[7];
            r_use_addr <= w_uc_inst[8];
            r_alu_op   <= (w_uc_inst[14]) ? w_alu_op_d : w_uc_inst[13:10];
            r_branch   <= w_uc_inst[15];
        end
        
        // Special flag for Bxx / SLTxx instructions
        r_slt_br <= (r_alu_op == 4'b0011) ? 1'b1 : 1'b0;
        
        // LSW / MSW operand select for ALU and registers
        if (|r_cpu_fsm[FSM_DECODE:FSM_RESET]) begin
            r_msw_sel <= 1'b0;
        end
        else if (r_cpu_fsm[FSM_ALU_WB]) begin
            r_msw_sel <= ~r_msw_sel;
        end
    end
    
    
    // ========================================================================
    // REGISTER FILE + MICRO-CODE ROM
    // ========================================================================
    
    assign      w_csr_idx = (w_uc_inst[25]) ? w_csr_idx_d : w_uc_inst[24:19];
    wire  [1:0] w_rs2_sel = w_uc_inst[3:2] ^ { w_alu_branch & r_branch, 1'b0 };
    wire  [1:0] w_rs1_sel = w_uc_inst[1:0];
    wire  [7:0] w_rs2_idx = (w_rs2_sel[1]) ? { 1'b1, w_csr_idx, r_msw_sel } : { 2'b01, w_rs2_idx_d, r_msw_sel };
    wire  [7:0] w_rs1_idx = (w_rs1_sel[1]) ? { 1'b1, w_csr_idx, r_msw_sel } : { 2'b01, w_rs1_idx_d, r_msw_sel };
    wire  [7:0] w_wb_idx  = (r_csr_sel)    ? { 1'b1, r_csr_idx, r_msw_sel } : { 2'b01, w_rd_idx_d,  r_msw_sel };
    reg         r_wb_pc;
    reg         r_wb_ena;
    
    wire [15:0] w_csr_rdata;
    wire [15:0] w_rs1_data;
    wire [15:0] w_rs2_data;
    wire [15:0] w_wb_data  = (r_use_addr)
                           ? (r_msw_sel)
                           ? addr[31:16]
                           : addr[15: 0]
                           : w_alu_result;
    
    `ifdef verilator3
    reg  [15:0] r_tb_wb_lsw;
    wire [31:0] w_tb_wb_data = (r_slt_br) ? { 16'b0, w_wb_data } : { w_wb_data, r_tb_wb_lsw };
    wire        w_tb_wb_ena  = (r_slt_br)
                             ? r_wb_ena & r_wb_wren & ~r_msw_sel & ~r_csr_sel
                             : r_wb_ena & r_wb_wren &  r_msw_sel & ~r_csr_sel;
    
    always @ (posedge clk) begin : TB_WB_DATA
    
        if (r_wb_ena & r_wb_wren & ~r_msw_sel & ~r_csr_sel) begin
            r_tb_wb_lsw <= w_wb_data;
        end
    end
    `endif
    
    always @ (posedge clk) begin : WB_ENA
    
        r_wb_ena <= r_cpu_fsm[FSM_ALU_OP]
                  | r_cpu_fsm[FSM_ALU_WB] & r_msw_sel & r_slt_br;
        r_wb_pc  <= (r_csr_idx == 6'd7) ? r_csr_sel : 1'b0;
    end
    
    jive_reg_file
    #(
        .VENDOR_ID  (VENDOR_ID),
        .ARCHI_ID   (ARCHI_ID),
        .IMPL_ID    (IMPL_ID)
    )
    U_reg_file
    (
        .rst        (rst),
        .clk        (clk),
        
        .zimmed     (w_zimmed_d),
        .immed      (w_immed_d),
        .rdata_a    (r_rdata_a),
        .csr_rdata  (w_csr_rdata),
        
        .uc_addr    (w_uc_addr),
        .uc_inst    (w_uc_inst),
        
        .msw_sel    (r_msw_sel),
        .rs_rden    (r_cpu_fsm[FSM_REGS_RD]),
        
        .rs1_sel    (w_rs1_sel),
        .rs1_idx    (w_rs1_idx),
        .rs1_data   (w_rs1_data),
        
        .rs2_sel    (w_rs2_sel),
        .rs2_idx    (w_rs2_idx),
        .rs2_data   (w_rs2_data),
        
        .wb_ena     (r_wb_ena),
        .wb_idx     (w_wb_idx),
        .wb_wren    (r_wb_wren),
        .wb_pc      (r_wb_pc),
        .wb_data    (w_wb_data)
    );
    
    // ========================================================================
    // 16-BIT ALU / 32-BIT SHIFTER
    // ========================================================================
    
    wire        w_alu_branch;
    wire [15:0] w_alu_result;
    
    jive_alu16
    #(
        .RESET_PC   (RESET_PC)
    )
    U_alu16
    (
        .rst        (rst),
        .clk        (clk),
        
        .wb_pc      (r_wb_pc),
        .wb_ena     (r_cpu_fsm[FSM_ALU_WB]),
        .sh_ena     (r_cpu_fsm[FSM_MULTI]),
        
        .x_operand  (w_rs1_data),
        .y_operand  (w_rs2_data),
        .msw_sel    (r_msw_sel),
        .upd_addr   (r_upd_addr),
        .upd_dout   (r_upd_dout),
        .func3_d    (w_func3_d),
        .alu_op_d   (r_alu_op),
        .slt_branch (r_slt_br),
        .alu_branch (w_alu_branch),
        .alu_result (w_alu_result),
        
        .mem_size_d (w_func3_d[1:0]),
        .mem_addr   (addr),
        .mem_data   (wdata)
    );
    
    // ========================================================================
    // EXTERNAL BUS
    // ========================================================================
    
    reg         r_fetch;    // Instruction fetch
    reg         r_rden;     // Data read
    reg         r_wren;     // Data write
    reg   [3:0] r_bena;     // Bytes enable
    reg  [31:0] r_rdata;    // Data read
    reg  [15:0] r_rdata_a;  // Data read (aligned)
    reg         r_if_err;   // Fetch address error
    reg         r_ld_err;   // Load address error
    reg         r_st_err;   // Store address error
    
    always @ (posedge clk) begin : EXT_BUS
        reg v_bad_addr;
        
        // Bad address on LOAD/STORE
        v_bad_addr = addr[0] & (|w_func3_d[1:0])
                   | addr[1] & w_func3_d[1];
    
        if (r_cpu_fsm[FSM_REGS_RD]) begin
            // External bus access
            r_fetch <= w_uc_inst[18] & r_msw_sel & ~addr[1];
            r_rden  <= w_uc_inst[17] & r_msw_sel & ~v_bad_addr;
            r_wren  <= w_uc_inst[16] & r_msw_sel & ~v_bad_addr;
            // Address errors
            r_if_err <= w_uc_inst[18] & r_msw_sel & addr[1];
            r_ld_err <= w_uc_inst[17] & r_msw_sel & v_bad_addr;
            r_st_err <= w_uc_inst[16] & r_msw_sel & v_bad_addr;
        end
        
        // Read data
        if (r_cpu_fsm[FSM_LOAD] & dtack) begin
            r_rdata <= rdata;
        end
        
        // Byte enable
        if (r_cpu_fsm[FSM_ALU_WB]) begin
            if (r_rden | r_wren) begin
                casez ({ w_func3_d[1:0], addr[1:0] })
                    // LB,LBU
                    4'b00_00 : r_bena <= 4'b0001;
                    4'b00_01 : r_bena <= 4'b0010;
                    4'b00_10 : r_bena <= 4'b0100;
                    4'b00_11 : r_bena <= 4'b1000;
                    // LH, LHU
                    4'b01_0? : r_bena <= 4'b0011;
                    4'b01_1? : r_bena <= 4'b1100;
                    // LW
                    default  : r_bena <= 4'b1111;
                endcase
            end
            else begin
                r_bena <= 4'b1111;
            end
        end
        
        // Align / sign extend data
        if (r_cpu_fsm[FSM_REGS_RD]) begin
            if (r_msw_sel) begin
                // MSW
                case (w_func3_d[2:1])
                    // LB, LH
                    2'b00   : r_rdata_a <= {16{r_rdata_a[15]}};
                    // LBU, LHU
                    2'b10   : r_rdata_a <= 16'h0000;
                    // LW
                    default : r_rdata_a <= r_rdata[31:16];
                endcase
            end
            else begin
                // LSW
                casez ({ w_func3_d, addr[1:0] })
                    // LB
                    5'b000_00 : r_rdata_a <= { {8{r_rdata[ 7]}}, r_rdata[ 7: 0] };
                    5'b000_01 : r_rdata_a <= { {8{r_rdata[15]}}, r_rdata[15: 8] };
                    5'b000_10 : r_rdata_a <= { {8{r_rdata[23]}}, r_rdata[23:16] };
                    5'b000_11 : r_rdata_a <= { {8{r_rdata[31]}}, r_rdata[31:24] };
                    // LH, LHU
                    5'b?01_0? : r_rdata_a <= r_rdata[15: 0];
                    5'b?01_1? : r_rdata_a <= r_rdata[31:16];
                    // LBU
                    5'b100_00 : r_rdata_a <= { 8'h00, r_rdata[ 7: 0] };
                    5'b100_01 : r_rdata_a <= { 8'h00, r_rdata[15: 8] };
                    5'b100_10 : r_rdata_a <= { 8'h00, r_rdata[23:16] };
                    5'b100_11 : r_rdata_a <= { 8'h00, r_rdata[31:24] };
                    // LW
                    default   : r_rdata_a <= r_rdata[15: 0];
                endcase
            end
        end
    end
    
    assign fetch = r_cpu_fsm[FSM_FETCH];
    assign rden  = r_cpu_fsm[FSM_LOAD];
    assign wren  = r_cpu_fsm[FSM_STORE];
    assign bena  = r_bena;
    
    // ========================================================================
    // CSR FOR INTERRUPT SUPPORT
    // ========================================================================
    
    jive_csr U_jive_csr
    (
        .rst        (rst),
        .clk        (clk),
        
        .msw_sel    (r_msw_sel),
        .csr_rd     (1'b1),
        .csr_wr     (r_csr_sel & r_wb_wren),
        .csr_idx    (r_csr_idx),
        .csr_wdata  (w_wb_data),
        .csr_rdata  (w_csr_rdata),
        
        .ext_int    (ext_int),
        .tmr_int    (tmr_int),
        .sft_int    (1'b0),
        .csr_mip    (w_csr_mip),
        
        .em_ena     (r_cpu_fsm[FSM_EXCEPT]),
        .mret_d     (w_mret_d),
        .glb_int    (w_glb_int)
    );
    
endmodule

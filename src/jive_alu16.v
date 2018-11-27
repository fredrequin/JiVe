module jive_alu16
(
    input         rst,
    input         clk,
    
    input         wb_pc,
    input         wb_ena,
    input         sh_ena,
    
    input  [15:0] x_operand,
    input  [15:0] y_operand,
    input         msw_sel,
    input         upd_addr,
    input         upd_dout,
    input   [2:0] func3_d,
    input   [3:0] alu_op_d,
    input         slt_branch,
    output        alu_branch,
    output [15:0] alu_result,
    
    input   [1:0] mem_size_d,
    output [31:0] mem_addr,
    output [31:0] mem_data
);
    parameter [31:0] RESET_PC = 32'h00000000;
    
/*
   alu_op_d :
   ==========
   4'b0000 : X + Y
   4'b0001 : X - Y
   4'b0010 : X + Y (branch)
   4'b0011 : X - Y (branch)
   4'b0100 : X ^ Y
   4'b0101 : X & ~Y
   4'b0110 : X | Y
   4'b0111 : X & Y
   4'b1?00 : R
   4'b1?01 : R << 1
   4'b1?10 : R >> 1
   4'b1?11 : R >> 1
*/

    // ========================================================================
    // ADDER
    // ========================================================================

    wire [17:0] w_x_oper;
    wire [17:0] w_y_oper;
    wire [17:0] w_adder;
    
    assign w_x_oper[17]   = 1'b0;
    assign w_x_oper[16:1] = x_operand;
    assign w_x_oper[0]    = (msw_sel) ? r_cout : alu_op_d[0];
    
    assign w_y_oper[17]   = 1'b0;
    assign w_y_oper[16:1] = y_operand ^ {16{alu_op_d[0]}};
    assign w_y_oper[0]    = (msw_sel) ? r_cout : alu_op_d[0];
    
    assign w_adder = w_x_oper + w_y_oper;
    
    // ========================================================================
    // LOGIC
    // ========================================================================
    
    reg  [15:0] w_logic;

    always @(*) begin : LOGIC
    
        case (alu_op_d[1:0])
            2'b00 : w_logic =  x_operand ^ y_operand;
            2'b01 : w_logic = ~x_operand & y_operand;
            2'b10 : w_logic =  x_operand | y_operand;
            2'b11 : w_logic =  x_operand & y_operand;
        endcase
    end
    
    // ========================================================================
    // BRANCH / SET EVALUATE
    // ========================================================================
    
    reg         r_branch;
    reg         w_branch;
    reg         r_cout;
    reg         r_equ;
    wire        w_equ;
    wire        w_over;
    
    //assign w_equ  = (x_operand == y_operand) ? ~msw_sel | r_equ : 1'b0;
    assign w_equ  = (w_adder[16:1] == 16'd0) ? ~msw_sel | r_equ : 1'b0;
    assign w_over = (~x_operand[15] &  y_operand[15] &  w_adder[16])
                  | ( x_operand[15] & ~y_operand[15] & ~w_adder[16]);
    
    always @(posedge clk) begin : BRANCH_FLAG
    
        if (wb_ena) begin
            r_cout <= w_adder[17];
            r_equ  <= w_equ;
            if (msw_sel) begin
                r_branch <= w_branch & slt_branch;
            end
        end
    end
    
    always @(*) begin : BRANCH_RESULT
    
        casez (func3_d)
            3'b000 : w_branch =   w_equ;                 // BEQ
            3'b001 : w_branch =  ~w_equ;                 // BNE
            3'b010 : w_branch =  (w_adder[16] ^ w_over); // SLT, SLTI
            3'b011 : w_branch =  ~w_adder[17];           // SLTU, SLTUI
            3'b100 : w_branch =  (w_adder[16] ^ w_over); // BLT
            3'b101 : w_branch = ~(w_adder[16] ^ w_over); // BGE
            3'b110 : w_branch =  ~w_adder[17];           // BLTU
            3'b111 : w_branch =   w_adder[17];           // BGEU
        endcase
    end
    
    // ========================================================================
    // DATA BUS REGISTERS
    // ========================================================================
    
    reg [15:0] r_data_msw;
    reg [15:0] r_data_lsw;
    
    always @(posedge clk) begin : DATA_OUT_REGS
        
        if (wb_ena) begin
            // Dout.hi
            if (upd_dout & msw_sel) begin
                case (mem_size_d)
                    2'b00 : r_data_msw <= r_data_lsw;
                    2'b01 : r_data_msw <= r_data_lsw;
                    2'b10 : r_data_msw <= y_operand[15:0];
                    2'b11 : r_data_msw <= y_operand[15:0];
                endcase
            end
            
            // Dout.lo
            if (upd_dout & ~msw_sel) begin
                case (mem_size_d)
                    2'b00 : r_data_lsw <= { y_operand[7:0], y_operand[7:0] };
                    2'b01 : r_data_lsw <= y_operand[15:0];
                    2'b10 : r_data_lsw <= y_operand[15:0];
                    2'b11 : r_data_lsw <= y_operand[15:0];
                endcase
            end
        end
    end
    
    reg [15:0] r_addr_msw;
    reg [15:0] r_addr_lsw;
    
    always @(posedge rst or posedge clk) begin : ADDR_OUT_REGS
    
        if (rst) begin
            r_addr_msw <= RESET_PC[31:16];
            r_addr_lsw <= RESET_PC[15: 0];
        end
        else begin
            // Addr.hi
            if (wb_ena & upd_addr & msw_sel) begin
                r_addr_msw <= w_adder[16:1];
            end
            else if (sh_ena) begin
                case (alu_op_d[1:0])
                    2'b00 : r_addr_msw <= { r_addr_msw[14:0], r_addr_lsw[15  ] };
                    2'b01 : r_addr_msw <= { r_addr_msw[14:0], r_addr_lsw[15  ] };
                    2'b10 : r_addr_msw <= {             1'b0, r_addr_msw[15:1] };
                    2'b11 : r_addr_msw <= { r_addr_msw[15  ], r_addr_msw[15:1] };
                endcase
            end
            
            // Addr.lo
            if (wb_ena & ~msw_sel) begin
                r_addr_lsw[15:1] <= (upd_addr) ? w_adder[16:2] : r_addr_lsw[15:1];
                r_addr_lsw[0]    <= (wb_pc) ? 1'b0
                                  : (upd_addr) ? w_adder[1] : r_addr_lsw[0];
            end
            else if (sh_ena) begin
                case (alu_op_d[1:0])
                    2'b00 : r_addr_lsw <= { r_addr_lsw[14:0], 1'b0 };
                    2'b01 : r_addr_lsw <= { r_addr_lsw[14:0], 1'b0 };
                    2'b10 : r_addr_lsw <= { r_addr_msw[   0], r_addr_lsw[15:1] };
                    2'b11 : r_addr_lsw <= { r_addr_msw[   0], r_addr_lsw[15:1] };
                endcase
            end
        end
    end
    
    // ========================================================================
    // RESULTS
    // ========================================================================
    
    assign alu_branch = r_branch;
    assign alu_result = (alu_op_d[2])
                      ? w_logic[15:0]
                      : (alu_op_d[1])
                      ? { 15'b0, r_branch }
                      : w_adder[16:1];
    
    assign mem_addr   = { r_addr_msw, r_addr_lsw }; // { R.hi,  R.lo }
    assign mem_data   = { r_data_msw, r_data_lsw }; // { Do.hi, Do.lo }
    
endmodule

module jive_reg_file
(
    input         rst,
    input         clk,
    
    input   [5:0] zimmed,         // Immediate value for CSR or MCAUSE value
    input  [31:0] immed,          // Sign extended immediate value for ALU
    input  [15:0] rdata_a,        // Value read from external bus
    input  [15:0] csr_rdata,      // CSR value
    
    input   [7:0] uc_addr,        // Microcode address
    output [31:0] uc_inst,        // Microcode instruction
    
    input         msw_sel,        // Most significant word select
    input         rs_rden,        // Source register read enable
    
    input   [1:0] rs1_sel,        // Source register #1 select
    input   [7:0] rs1_idx,        // Source register #1 index
    output [15:0] rs1_data,       // Source register #1 data
    
    input   [1:0] rs2_sel,        // Source register #2 select
    input   [7:0] rs2_idx,        // Source register #2 index
    output [15:0] rs2_data,       // Source register #2 data
    
    input         wb_ena,         // Writeback stage enable
    input   [7:0] wb_idx,         // Writeback register index
    input         wb_wren,        // Writeback register write enable
    input         wb_pc,          // Writeback register is PC (do not write bit #0)
    input  [15:0] wb_data         // Writeback register data
);
    parameter [31:0] VENDOR_ID = 32'h00000021;
    parameter [31:0] ARCHI_ID  = 32'h00000001;
    parameter [31:0] IMPL_ID   = 32'h00000001;
    
    // ========================================================================
    // INPUT CONTROL
    // ========================================================================
    
    wire       w_bad_pc;
    reg        r_bad_pc;
    
    assign w_bad_pc = wb_pc & wb_data[1] & ~wb_idx[0] & wb_ena;
    
    always @ (posedge clk) begin : BAD_PC
    
        if (wb_ena) r_bad_pc = w_bad_pc;
    end
    
    // ========================================================================
    // MEMORY INSTANTIATION
    // ========================================================================
    
    wire        w_wren_p0;
    wire  [7:0] w_waddr_p0;
    wire [15:0] w_wmask_p0;
    wire  [7:0] w_raddr_lo_p0;
    wire  [7:0] w_raddr_hi_p0;
    wire [15:0] w_rdata_lo_p1;
    wire [15:0] w_rdata_hi_p1;
    
    // Do not write x0 or MSW of unaligned PC
    assign w_wren_p0        = (wb_idx[5:1] != 5'd0) ? wb_wren & ~r_bad_pc : 1'b0;
    // Do not write LSW of unaligned PC
    assign w_wmask_p0[15:1] = {15{~w_bad_pc}};
    // Never write bit #0 of PC
    assign w_wmask_p0[0]    = ~wb_pc | wb_idx[0];
    
    assign w_waddr_p0       =  wb_idx;
    assign w_raddr_lo_p0    = (rs_rden) ? rs1_idx : uc_addr;
    assign w_raddr_hi_p0    = (rs_rden) ? rs2_idx : uc_addr;
    
    `ifdef verilator3
    `include "../../cpu_jive/src/jive_ucode.v"
    
    EBR_B
    #(
        .INIT_0       (LO_UCODE_0),
        .INIT_1       (LO_UCODE_1),
        .INIT_2       (LO_UCODE_2),
        .INIT_3       (LO_UCODE_3),
        .INIT_4       (LO_UCODE_4),
        .INIT_5       (LO_UCODE_5),
        .INIT_6       (LO_UCODE_6),
        .INIT_7       (LO_UCODE_7),
        .INIT_8       (LO_UCODE_8),
        .INIT_9       (LO_UCODE_9),
        .INIT_A       (LO_UCODE_A),
        .INIT_B       (LO_UCODE_B),
        .INIT_C       (LO_UCODE_C),
        .INIT_D       (LO_UCODE_D),
        .INIT_E       (LO_UCODE_E),
        .INIT_F       (LO_UCODE_F),
        .DATA_WIDTH_R (16),
        .DATA_WIDTH_W (16)
    )
    U_reg_file_lo
    (
        // Write port
        .WCLK         (clk),
        .WCLKE        (wb_ena),
        .WE           (w_wren_p0),
        .WADDR10      (1'b0),
        .WADDR9       (1'b0),
        .WADDR8       (1'b0),
        .WADDR7       (w_waddr_p0[7]),
        .WADDR6       (w_waddr_p0[6]),
        .WADDR5       (w_waddr_p0[5]),
        .WADDR4       (w_waddr_p0[4]),
        .WADDR3       (w_waddr_p0[3]),
        .WADDR2       (w_waddr_p0[2]),
        .WADDR1       (w_waddr_p0[1]),
        .WADDR0       (w_waddr_p0[0]),
        .MASK_N15     (w_wmask_p0[15]),
        .MASK_N14     (w_wmask_p0[14]),
        .MASK_N13     (w_wmask_p0[13]),
        .MASK_N12     (w_wmask_p0[12]),
        .MASK_N11     (w_wmask_p0[11]),
        .MASK_N10     (w_wmask_p0[10]),
        .MASK_N9      (w_wmask_p0[9]),
        .MASK_N8      (w_wmask_p0[8]),
        .MASK_N7      (w_wmask_p0[7]),
        .MASK_N6      (w_wmask_p0[6]),
        .MASK_N5      (w_wmask_p0[5]),
        .MASK_N4      (w_wmask_p0[4]),
        .MASK_N3      (w_wmask_p0[3]),
        .MASK_N2      (w_wmask_p0[2]),
        .MASK_N1      (w_wmask_p0[1]),
        .MASK_N0      (w_wmask_p0[0]),
        .WDATA15      (wb_data[15]),
        .WDATA14      (wb_data[14]),
        .WDATA13      (wb_data[13]),
        .WDATA12      (wb_data[12]),
        .WDATA11      (wb_data[11]),
        .WDATA10      (wb_data[10]),
        .WDATA9       (wb_data[9]),
        .WDATA8       (wb_data[8]),
        .WDATA7       (wb_data[7]),
        .WDATA6       (wb_data[6]),
        .WDATA5       (wb_data[5]),
        .WDATA4       (wb_data[4]),
        .WDATA3       (wb_data[3]),
        .WDATA2       (wb_data[2]),
        .WDATA1       (wb_data[1]),
        .WDATA0       (wb_data[0]),
        // Read port
        .RCLK         (clk),
        .RCLKE        (1'b1),
        .RE           (1'b1),
        .RADDR10      (1'b0),
        .RADDR9       (1'b0),
        .RADDR8       (1'b0),
        .RADDR7       (w_raddr_lo_p0[7]),
        .RADDR6       (w_raddr_lo_p0[6]),
        .RADDR5       (w_raddr_lo_p0[5]),
        .RADDR4       (w_raddr_lo_p0[4]),
        .RADDR3       (w_raddr_lo_p0[3]),
        .RADDR2       (w_raddr_lo_p0[2]),
        .RADDR1       (w_raddr_lo_p0[1]),
        .RADDR0       (w_raddr_lo_p0[0]),
        .RDATA15      (w_rdata_lo_p1[15]),
        .RDATA14      (w_rdata_lo_p1[14]),
        .RDATA13      (w_rdata_lo_p1[13]),
        .RDATA12      (w_rdata_lo_p1[12]),
        .RDATA11      (w_rdata_lo_p1[11]),
        .RDATA10      (w_rdata_lo_p1[10]),
        .RDATA9       (w_rdata_lo_p1[9]),
        .RDATA8       (w_rdata_lo_p1[8]),
        .RDATA7       (w_rdata_lo_p1[7]),
        .RDATA6       (w_rdata_lo_p1[6]),
        .RDATA5       (w_rdata_lo_p1[5]),
        .RDATA4       (w_rdata_lo_p1[4]),
        .RDATA3       (w_rdata_lo_p1[3]),
        .RDATA2       (w_rdata_lo_p1[2]),
        .RDATA1       (w_rdata_lo_p1[1]),
        .RDATA0       (w_rdata_lo_p1[0])
    );

    EBR_B
    #(
        .INIT_0       (HI_UCODE_0),
        .INIT_1       (HI_UCODE_1),
        .INIT_2       (HI_UCODE_2),
        .INIT_3       (HI_UCODE_3),
        .INIT_4       (HI_UCODE_4),
        .INIT_5       (HI_UCODE_5),
        .INIT_6       (HI_UCODE_6),
        .INIT_7       (HI_UCODE_7),
        .INIT_8       (HI_UCODE_8),
        .INIT_9       (HI_UCODE_9),
        .INIT_A       (HI_UCODE_A),
        .INIT_B       (HI_UCODE_B),
        .INIT_C       (HI_UCODE_C),
        .INIT_D       (HI_UCODE_D),
        .INIT_E       (HI_UCODE_E),
        .INIT_F       (HI_UCODE_F),
        .DATA_WIDTH_R (16),
        .DATA_WIDTH_W (16)
    )
    U_reg_file_hi
    (
        // Write port
        .WCLK         (clk),
        .WCLKE        (wb_ena),
        .WE           (w_wren_p0),
        .WADDR10      (1'b0),
        .WADDR9       (1'b0),
        .WADDR8       (1'b0),
        .WADDR7       (w_waddr_p0[7]),
        .WADDR6       (w_waddr_p0[6]),
        .WADDR5       (w_waddr_p0[5]),
        .WADDR4       (w_waddr_p0[4]),
        .WADDR3       (w_waddr_p0[3]),
        .WADDR2       (w_waddr_p0[2]),
        .WADDR1       (w_waddr_p0[1]),
        .WADDR0       (w_waddr_p0[0]),
        .MASK_N15     (w_wmask_p0[15]),
        .MASK_N14     (w_wmask_p0[14]),
        .MASK_N13     (w_wmask_p0[13]),
        .MASK_N12     (w_wmask_p0[12]),
        .MASK_N11     (w_wmask_p0[11]),
        .MASK_N10     (w_wmask_p0[10]),
        .MASK_N9      (w_wmask_p0[9]),
        .MASK_N8      (w_wmask_p0[8]),
        .MASK_N7      (w_wmask_p0[7]),
        .MASK_N6      (w_wmask_p0[6]),
        .MASK_N5      (w_wmask_p0[5]),
        .MASK_N4      (w_wmask_p0[4]),
        .MASK_N3      (w_wmask_p0[3]),
        .MASK_N2      (w_wmask_p0[2]),
        .MASK_N1      (w_wmask_p0[1]),
        .MASK_N0      (w_wmask_p0[0]),
        .WDATA15      (wb_data[15]),
        .WDATA14      (wb_data[14]),
        .WDATA13      (wb_data[13]),
        .WDATA12      (wb_data[12]),
        .WDATA11      (wb_data[11]),
        .WDATA10      (wb_data[10]),
        .WDATA9       (wb_data[9]),
        .WDATA8       (wb_data[8]),
        .WDATA7       (wb_data[7]),
        .WDATA6       (wb_data[6]),
        .WDATA5       (wb_data[5]),
        .WDATA4       (wb_data[4]),
        .WDATA3       (wb_data[3]),
        .WDATA2       (wb_data[2]),
        .WDATA1       (wb_data[1]),
        .WDATA0       (wb_data[0]),
        // Read port
        .RCLK         (clk),
        .RCLKE        (1'b1),
        .RE           (1'b1),
        .RADDR10      (1'b0),
        .RADDR9       (1'b0),
        .RADDR8       (1'b0),
        .RADDR7       (w_raddr_hi_p0[7]),
        .RADDR6       (w_raddr_hi_p0[6]),
        .RADDR5       (w_raddr_hi_p0[5]),
        .RADDR4       (w_raddr_hi_p0[4]),
        .RADDR3       (w_raddr_hi_p0[3]),
        .RADDR2       (w_raddr_hi_p0[2]),
        .RADDR1       (w_raddr_hi_p0[1]),
        .RADDR0       (w_raddr_hi_p0[0]),
        .RDATA15      (w_rdata_hi_p1[15]),
        .RDATA14      (w_rdata_hi_p1[14]),
        .RDATA13      (w_rdata_hi_p1[13]),
        .RDATA12      (w_rdata_hi_p1[12]),
        .RDATA11      (w_rdata_hi_p1[11]),
        .RDATA10      (w_rdata_hi_p1[10]),
        .RDATA9       (w_rdata_hi_p1[9]),
        .RDATA8       (w_rdata_hi_p1[8]),
        .RDATA7       (w_rdata_hi_p1[7]),
        .RDATA6       (w_rdata_hi_p1[6]),
        .RDATA5       (w_rdata_hi_p1[5]),
        .RDATA4       (w_rdata_hi_p1[4]),
        .RDATA3       (w_rdata_hi_p1[3]),
        .RDATA2       (w_rdata_hi_p1[2]),
        .RDATA1       (w_rdata_hi_p1[1]),
        .RDATA0       (w_rdata_hi_p1[0])
    );
    `else
    jive_regfile_lo U_jive_regfile_lo
    (
        .wr_clk_i     (clk),
        .wr_clk_en_i  (wb_ena),
        .wr_en_i      (w_wren_p0),
        .wr_addr_i    (w_waddr_p0),
        .wr_data_i    (wb_data & w_wmask_p0),
        
        .rd_clk_i     (clk),
        .rd_clk_en_i  (1'b1),
        .rd_en_i      (1'b1),
        .rd_addr_i    (w_raddr_lo_p0),
        .rd_data_o    (w_rdata_lo_p1)
    );

    jive_regfile_hi U_jive_regfile_hi
    (
        .wr_clk_i     (clk),
        .wr_clk_en_i  (wb_ena),
        .wr_en_i      (w_wren_p0),
        .wr_addr_i    (w_waddr_p0),
        .wr_data_i    (wb_data & w_wmask_p0),
        
        .rd_clk_i     (clk),
        .rd_clk_en_i  (1'b1),
        .rd_en_i      (1'b1),
        .rd_addr_i    (w_raddr_hi_p0),
        .rd_data_o    (w_rdata_hi_p1)
    );
    
    `endif

    // ========================================================================
    // OUTPUT CONTROL
    // ========================================================================

    reg         r_rs_rden_p1; // rs1/rs2 read enable flag
    reg   [1:0] r_rs1_sel_p1; // rs1 source select
    reg   [1:0] r_rs2_sel_p1; // rs2 source select
    
    always@(posedge clk) begin : OUTPUT_CTRL_P1
    
        // Read enable flags
        r_rs_rden_p1    <= rs_rden;
        r_rs1_sel_p1    <= rs1_sel;
        r_rs2_sel_p1    <= rs2_sel;
    end
    
    // ========================================================================
    // OUTPUTS REGISTERS
    // ========================================================================
    
    reg  [15:0] r_rdata_p2 [0:1];
    
    always@(posedge rst or posedge clk) begin : OUT_REGS_P2
    
        if (rst) begin
            r_rdata_p2[0] <= 16'h0000;
            r_rdata_p2[1] <= 16'h0000;
        end
        else begin
            if (r_rs_rden_p1) begin
                // Read rs1 / rdata / csr / zimmed
                case (r_rs1_sel_p1)
                    2'b00 : r_rdata_p2[0] <= w_rdata_lo_p1;
                    2'b01 : r_rdata_p2[0] <= rdata_a;
                    2'b10 : r_rdata_p2[0] <= w_rdata_lo_p1 | csr_rdata;
                    2'b11 : r_rdata_p2[0] <= (msw_sel) ? { zimmed[5], 15'b0 } : { 11'b0, zimmed[4:0] };
                endcase
                // Read rs2 / immed / csr / 4
                case (r_rs2_sel_p1)
                    2'b00 : r_rdata_p2[1] <= w_rdata_hi_p1;
                    2'b01 : r_rdata_p2[1] <= (msw_sel) ? immed[31:16] : immed[15:0];
                    2'b10 : r_rdata_p2[1] <= w_rdata_hi_p1 | csr_rdata;
                    2'b11 : r_rdata_p2[1] <= (msw_sel) ? 16'h0000 : 16'h0004;
                endcase
            end
        end
    end
    
    assign uc_inst  = { w_rdata_hi_p1, w_rdata_lo_p1 };
    assign rs1_data = r_rdata_p2[0];
    assign rs2_data = r_rdata_p2[1];
    
endmodule

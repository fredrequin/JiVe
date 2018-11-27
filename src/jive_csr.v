module jive_csr
(
    input         rst,
    input         clk,
    
    input         msw_sel,
    input         csr_rd,
    input         csr_wr,
    input   [5:0] csr_idx,
    input  [15:0] csr_wdata,
    output [15:0] csr_rdata,
    
    input         ext_int,    // External interrupt
    input         tmr_int,    // Timer interrupt
    input         sft_int,    // Software interrupt
    output  [2:0] csr_mip,    // mip register
    
    input         em_ena,     // Exception management state
    input         mret_d,     // MRET decode
    output        glb_int     // Global interrupt flag (to CPU FSM)
);

    //=========================================================================

    reg [63:0] r_csr_mcycle;
    reg  [2:0] r_csr_mie;
    reg  [2:0] r_csr_mip;
    reg        r_isr_on;
    
    always @ (posedge rst or posedge clk) begin : CSR_WRITE
        reg [3:1] v_inc;
    
        if (rst) begin
            r_csr_mcycle <= 64'd0;
            r_csr_mie    <= 3'b000;
            r_csr_mip    <= 3'b000;
            r_isr_on     <= 1'b0;
            //v_inc        <= 3'b000;
        end
        else begin
            if (csr_wr & ~msw_sel) begin
                if (csr_idx == 6'b01_0100) begin // 0x304
                    r_csr_mie[0] <= csr_wdata[3];
                    r_csr_mie[1] <= csr_wdata[7];
                    r_csr_mie[2] <= csr_wdata[11];
                end
            end
            
            r_csr_mip[2] <= ext_int & r_csr_mie[2];
            r_csr_mip[1] <= tmr_int & r_csr_mie[1];
            r_csr_mip[0] <= sft_int & r_csr_mie[0];
            
            r_isr_on <= (r_isr_on | em_ena) & ~mret_d;
            
            r_csr_mcycle <= r_csr_mcycle + 64'd1;
            /*
                             r_csr_mcycle[15: 0] <= r_csr_mcycle[15: 0] + 16'd1;
            if ( v_inc[  1]) r_csr_mcycle[31:16] <= r_csr_mcycle[31:16] + 16'd1;
            if (&v_inc[2:1]) r_csr_mcycle[47:32] <= r_csr_mcycle[47:32] + 16'd1;
            if (&v_inc[3:1]) r_csr_mcycle[63:48] <= r_csr_mcycle[63:48] + 16'd1;
            
            v_inc[1] <= (r_csr_mcycle[15: 0] == 16'hFFFE) ? 1'b1 : 1'b0;
            v_inc[2] <= (r_csr_mcycle[31:16] == 16'hFFFF) ? 1'b1 : 1'b0;
            v_inc[3] <= (r_csr_mcycle[47:32] == 16'hFFFF) ? 1'b1 : 1'b0;
            */
        end
    end
    
    assign csr_mip = r_csr_mip;
    assign glb_int = (|r_csr_mip) & ~r_isr_on;

    //=========================================================================
    
    reg  [15:0] r_csr_rdata;
    
    wire [15:0] w_csr_mie = { 4'b0, r_csr_mie[2], 3'b0, r_csr_mie[1], 3'b0, r_csr_mie[0], 3'b0 };
    wire [15:0] w_csr_mip = { 4'b0, r_csr_mip[2], 3'b0, r_csr_mip[1], 3'b0, r_csr_mip[0], 3'b0 };
    
    always @ (posedge rst or posedge clk) begin : CSR_READ
    
        if (rst) begin
            r_csr_rdata <= 16'h0000;
        end
        else begin
            if (csr_rd) begin
                case ({ csr_idx, msw_sel })
                    // 0x304 : mie
                    7'b01_0100_0 : r_csr_rdata <= w_csr_mie[15:0];
                    // 0x344 : mip
                    7'b01_1100_0 : r_csr_rdata <= w_csr_mip[15:0];
                    // 0xC00, 0xB00 : cycle, mcycle
                    7'b10_0000_0 : r_csr_rdata <= r_csr_mcycle[15: 0];
                    7'b10_0000_1 : r_csr_rdata <= r_csr_mcycle[31:16];
                    // 0xC80, 0xB80 : cycleh, mcycleh
                    7'b10_1000_0 : r_csr_rdata <= r_csr_mcycle[47:32];
                    7'b10_1000_1 : r_csr_rdata <= r_csr_mcycle[63:48];
                    default      : r_csr_rdata <= 16'h0000;
                endcase
            end
            else begin
                r_csr_rdata <= 16'h0000;
            end
        end
    end
    
    assign csr_rdata = r_csr_rdata;
    
endmodule

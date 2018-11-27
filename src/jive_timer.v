module jive_timer
(
    input          rst,
    input          clk,
    
    input          csel,
    input          rden,
    input          wren,
    input   [15:2] addr,
    input    [3:0] bena,
    input   [31:0] wdata,
    output  [31:0] rdata,
    output         dtack,
    
    input          rtc_in,
    output         tmr_int
);

    //=========================================================================
    
    reg [63:0] r_mtime;
    reg [63:0] r_mtimecmp;
    reg        r_tmr_int;

    always @(posedge rst or posedge clk) begin : TIMER_WR_REGS
        reg [2:0] v_rtc_cc;
        reg [3:1] v_inc;
    
        if (rst) begin
            r_mtime    <= 64'h00000000_00000000;
            r_mtimecmp <= 64'hFFFFFFFF_FFFFFFFF;
            r_tmr_int  <= 1'b0;
            v_rtc_cc   <= 3'b000;
            v_inc      <= 3'b000;
        end
        else begin
            if (csel & wren) begin
                case ({ addr[15:14], addr[2] })
                    // 0x4000
                    3'b010 : begin
                        r_mtimecmp[31: 0] <= wdata;
                    end
                    // 0x4004
                    3'b011 : begin
                        r_mtimecmp[63:32] <= wdata;
                    end
                    // 0xC000
                    3'b110 : begin
                        r_mtime[31: 0]    <= wdata;
                    end
                    // 0xC004
                    3'b111 : begin
                        r_mtime[63:32]    <= wdata;
                    end
                    default : ;
                endcase
            end
            else if (^v_rtc_cc[2:1]) begin
                r_mtime <= r_mtime + 64'd1;
                /*
                                 r_mtime[15: 0] <= r_mtime[15: 0] + 16'd1;
                if ( v_inc[  1]) r_mtime[31:16] <= r_mtime[31:16] + 16'd1;
                if (&v_inc[2:1]) r_mtime[47:32] <= r_mtime[47:32] + 16'd1;
                if (&v_inc[3:1]) r_mtime[63:48] <= r_mtime[63:48] + 16'd1;
                */
            end
            
            r_tmr_int <= (r_mtime > r_mtimecmp) ? 1'b1 : 1'b0;
            
            /*
            v_inc[1] <= (r_mtime[15: 0] == 16'hFFFF) ? 1'b1 : 1'b0;
            v_inc[2] <= (r_mtime[31:16] == 16'hFFFF) ? 1'b1 : 1'b0;
            v_inc[3] <= (r_mtime[47:32] == 16'hFFFF) ? 1'b1 : 1'b0;
            */
            
            v_rtc_cc <= { v_rtc_cc[1:0], rtc_in };
        end
    end
    
    assign tmr_int = r_tmr_int;

    //=========================================================================
    
    reg [31:0] r_rdata;
    reg        r_dtack;
    
    always @(posedge rst or posedge clk) begin : TIMER_RD_REGS
    
        if (rst) begin
            r_rdata <= 32'h00000000;
            r_dtack <= 1'b0;
        end
        else begin
            if (csel & rden) begin
                case ({ addr[15:14], addr[2] })
                    // 0x4000
                    3'b010 : begin
                        r_rdata <= r_mtimecmp[31: 0];
                    end
                    // 0x4004
                    3'b011 : begin
                        r_rdata <= r_mtimecmp[63:32];
                    end
                    // 0xC000
                    3'b110 : begin
                        r_rdata <= r_mtime[31: 0];
                    end
                    // 0xC004
                    3'b111 : begin
                        r_rdata <= r_mtime[63:32];
                    end
                    default : begin
                        r_rdata <= 32'h00000000;
                    end
                endcase
            end
            else begin
                r_rdata <= 32'h00000000;
            end
            r_dtack <= csel & rden;
        end
    end
    
    assign rdata = r_rdata;
    assign dtack = r_dtack | csel & wren;
    
    //=========================================================================
    
endmodule

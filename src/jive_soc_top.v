module jive_soc_top
(
    input             clk,      // 46B (#35) : 12 MHz clock input
    `ifdef verilator3
    // Instruction fetch
    output            i_rd_ack,
    output     [31:0] i_address,
    output     [31:0] i_rddata,
    // Data read/write
    output            d_rd_ack,
    output            d_wr_ack,
    output     [31:0] d_address,
    output      [3:0] d_byteena,
    output     [31:0] d_rddata,
    output     [31:0] d_wrdata,
    // Register write-back
    output            wb_ena,
    output      [4:0] wb_idx,
    output     [31:0] wb_data,
    `endif
    //
    input       [4:1] dip_sw,   // 49A (#43), 44B (#34), 36B (#25), 37A (#23)
    //
    input             uart_rxd, // 39A (#26)
    output            uart_txd, // 43A (#32)
    input             uart_cts, // 42B (#31)
    output            uart_rts, // 38B (#27)
    //
    output            spi_ss_n, // 35B (#16)
    output            spi_sclk, // 34A (#15)
    output            spi_mosi, // 33B (#17)
    input             spi_miso  // 32A (#14)
);

    //=========================================================================

    reg  [3:0] r_rst_ctr;
    wire       rst;
    
    initial begin
        r_rst_ctr = 4'd0;
    end
    
    always @ (posedge clk) begin : RESET_GEN
    
        if (!r_rst_ctr[3]) begin
            r_rst_ctr <= r_rst_ctr + 4'd1;
        end
    end
    
    assign rst = ~r_rst_ctr[3];
    
    //=========================================================================
    
    wire w_rtc_clk;
    reg  r_rtc_ena;
    
    always @ (posedge rst or posedge clk) begin
        
        if (rst) begin
            r_rtc_ena <= 1'b0;
        end
        else begin
            // Enable RTC when running application SW
            if (w_addr_p0[31] & w_fetch_p0) begin
                r_rtc_ena <= 1'b1;
            end
        end
    end

    LSOSC U_low_freq_osc
    (
        `ifdef verilator3
        ._clk    (clk),
        `endif
        .CLKLFPU (1'b1),
        .CLKLFEN (r_rtc_ena),
        .CLKLF   (w_rtc_clk)
    );

    //=========================================================================
    
    reg        r_ram_dtack_p1;
    wire       w_dtack_p01;
    wire       w_fetch_p0;
    wire       w_rden_p0;
    wire       w_wren_p0;
    
    always @ (posedge clk) begin : DTACK_GEN_P1
    
        r_ram_dtack_p1 <= (w_fetch_p0 | w_rden_p0 | w_wren_p0) & w_addr_p0[31];
    end
    
    assign w_dtack_p01 = r_ram_dtack_p1 | w_boot_dtack_p1 | w_uart_dtack_p1;
    
    wire  [3:0] w_bena_p0;
    wire [31:0] w_addr_p0;
    wire [31:0] w_wdata_p0;
    wire [31:0] w_rdata_p1;
    
    wire        w_ext_int = 1'b0;
    wire        w_tmr_int;
    
    jive_cpu_top
    #(
        `ifdef verilator3
        .RESET_PC (32'h80000000) // For running compliance tests
        `else
        .RESET_PC (32'h00000000) // For using the UART/SREC bootloader
        `endif
    )
    DUT_jive_cpu_top
    (
        .rst      (rst),
        .clk      (clk),
        
        .fetch    (w_fetch_p0),
        .rden     (w_rden_p0),
        .wren     (w_wren_p0),
        .bena     (w_bena_p0),
        .addr     (w_addr_p0),
        .wdata    (w_wdata_p0),
        .rdata    (w_rdata_p1),
        .dtack    (w_dtack_p01),
        
        .ext_int  (w_ext_int),
        .tmr_int  (w_tmr_int)
    );

    //=========================================================================
    // UART/SREC BOOT ROM (0x00000000 - 0x000003FF)
    //=========================================================================
    
    wire        w_boot_csel_p0 = ({ w_addr_p0[31], w_addr_p0[17:16] } == 3'b000) ? 1'b1 : 1'b0;
    wire [31:0] w_boot_rdata_p1;
    wire        w_boot_dtack_p1;
    
    `ifdef verilator3
    jive_bootrom
    #(
        .INIT_FILE        ("../../cpu_jive/mem/uart_boot.mem"),
        .INIT_FILE_FORMAT ("HEX")
    )
    U_boot_rom
    (
        .clk      (clk),
        .clk_en   (1'b1),
        
        .csel     (w_boot_csel_p0),
        .rden     (w_rden_p0 | w_fetch_p0),
        
        .addr     (w_addr_p0[9:2]),
        .rdata    (w_boot_rdata_p1),
        .dtack    (w_boot_dtack_p1)
    );
    `else
    reg r_boot_dtack_p1;
    
    always @ (posedge clk) begin
        r_boot_dtack_p1 <= (w_rden_p0 | w_fetch_p0) & w_boot_csel_p0;
    end
    
    assign w_boot_dtack_p1 = r_boot_dtack_p1;
    
    jive_bootrom U_boot_rom
    (
        .clk_i     (clk),
        .clk_en_i  (1'b1),
        .addr_i    (w_addr_p0[9:2]),
        .wr_en_i   (1'b0),
        .wr_data_i (32'h00000000),
        .rd_data_o (w_boot_rdata_p1)
    );
    `endif
    
    //=========================================================================
    // MACHINE TIMER (0x00010000 - 0x0001FFFF)
    //=========================================================================
    
    wire        w_timer_csel_p0 = ({ w_addr_p0[31], w_addr_p0[17:16] } == 3'b001) ? 1'b1 : 1'b0;
    wire [31:0] w_timer_rdata_p1;
    wire        w_timer_dtack_p1;
    
    jive_timer U_timer
    (
        .rst      (rst),
        .clk      (clk),

        .csel     (w_timer_csel_p0),
        .rden     (w_rden_p0),
        .wren     (w_wren_p0),
        .addr     (w_addr_p0[15:2]),
        .bena     (w_bena_p0),
        .wdata    (w_wdata_p0),
        .rdata    (w_timer_rdata_p1),
        .dtack    (w_timer_dtack_p1),
        
        .rtc_in   (w_rtc_clk),
        .tmr_int  (w_tmr_int)
    );
    
    //=========================================================================
    // SIMPLE UART RT/TX (0x00020000 - 0x00020003)
    //=========================================================================
    
    wire        w_uart_csel_p0 = ({ w_addr_p0[31], w_addr_p0[17:16] } == 3'b010) ? 1'b1 : 1'b0;
    wire [31:0] w_uart_rdata_p1;
    wire        w_uart_dtack_p1;
    
    jive_uart
    #(
        `ifdef verilator3
        .BAUD_RATE (100)
        `else
        .BAUD_RATE (625) // 19200 bauds @ 12 MHz
        `endif
    )
    U_uart
    (
        .rst      (rst),
        .clk      (clk),

        .csel     (w_uart_csel_p0),
        .rden     (w_rden_p0),
        .wren     (w_wren_p0),
        .bena     (w_bena_p0),
        .wdata    (w_wdata_p0),
        .rdata    (w_uart_rdata_p1),
        .dtack    (w_uart_dtack_p1),

        .uart_txd (uart_txd),
        .uart_rxd (uart_rxd)
    );
    
    //=========================================================================
    // 64 KB RAM (0x80000000 - 0x8000FFFF)
    //=========================================================================
    
    wire [31:0] w_ram_rdata_p1;
    
    SP256K
    `ifdef verilator3
    #(
        .HIWORD   (1)
    )
    `endif
    U_spram_hi
    (
        .STDBY    (1'b0),
        .SLEEP    (1'b0),
        .PWROFF_N (1'b1),
        .CK       (clk),
        .CS       (w_addr_p0[31]),
        .WE       (w_wren_p0),
        .MASKWE   ({ w_bena_p0[3],
                     w_bena_p0[3],
                     w_bena_p0[2],
                     w_bena_p0[2] }),
        .AD       (w_addr_p0[15:2]),
        .DI       (w_wdata_p0[31:16]),
        .DO       (w_ram_rdata_p1[31:16])
    );
    
    SP256K
    `ifdef verilator3
    #(
        .HIWORD     (0)
    )
    `endif
    U_spram_lo
    (
        .STDBY    (1'b0),
        .SLEEP    (1'b0),
        .PWROFF_N (1'b1),
        .CK       (clk),
        .CS       (w_addr_p0[31]),
        .WE       (w_wren_p0),
        .MASKWE   ({ w_bena_p0[1],
                     w_bena_p0[1],
                     w_bena_p0[0],
                     w_bena_p0[0] }),
        .AD       (w_addr_p0[15:2]),
        .DI       (w_wdata_p0[15:0]),
        .DO       (w_ram_rdata_p1[15:0])
    );
    
    assign w_rdata_p1 = (w_addr_p0[31]) ? w_ram_rdata_p1
                      : (|w_addr_p0[17:16]) ? w_uart_rdata_p1 | w_timer_rdata_p1
                      : w_boot_rdata_p1;
    
    `ifdef verilator3
    // Instruction fetch
    assign i_rd_ack  = w_fetch_p0 & (r_ram_dtack_p1 | w_boot_dtack_p1);
    assign i_address = w_addr_p0;
    assign i_rddata  = w_rdata_p1;
    // Data read/write
    assign d_rd_ack  = w_rden_p0 & (r_ram_dtack_p1 | w_boot_dtack_p1 | w_timer_dtack_p1 | w_uart_dtack_p1);
    assign d_wr_ack  = w_wren_p0;
    assign d_address = w_addr_p0;
    assign d_byteena = w_bena_p0;
    assign d_rddata  = w_rdata_p1;
    assign d_wrdata  = w_wdata_p0;
    // Register write-back
    assign wb_ena    = DUT_jive_cpu_top.w_tb_wb_ena;
    assign wb_idx    = DUT_jive_cpu_top.w_rd_idx_d;
    assign wb_data   = DUT_jive_cpu_top.w_tb_wb_data;
    `endif

endmodule
module jive_uart
(
    input         rst,
    input         clk,
    
    input         csel,
    input         rden,
    input         wren,
    input   [3:0] bena,
    input  [31:0] wdata,
    output [31:0] rdata,
    output        dtack,
    
    output        uart_txd,
    input         uart_rxd
);
    parameter BAUD_RATE = 2500; // 19200 bauds @ 48 MHz

    //=========================================================================
    // Registers read
    //=========================================================================
    
    reg [7:0] r_rdata;
    reg       r_dtack;
    
    always @(posedge rst or posedge clk) begin : UART_RD_REGS
    
        if (rst) begin
            r_rdata <= 8'h00;
            r_dtack <= 1'b0;
        end
        else begin
            r_rdata <= (csel & rden & bena[0]) ? r_rx_data : 8'h00;
            r_dtack <= csel & (rden & r_rx_rdy | wren & r_tx_rdy) & bena[0];
        end
    end
    
    assign rdata = { 24'h00_00_00, r_rdata };
    assign dtack = r_dtack;
    
    //=========================================================================
    // Re-sampling flip-flops
    //=========================================================================
    
    reg [2:0] r_uart_rxd_cc; // 3-stage re-sampling register

    always@(posedge rst or posedge clk) begin : RX_INPUT
    
        if (rst) begin
            r_uart_rxd_cc <= 3'b111;
        end
        else begin
            r_uart_rxd_cc <= { r_uart_rxd_cc[1:0], uart_rxd };
        end
    end
    
    //=========================================================================
    // Baud rate generators
    //=========================================================================
    
    reg       r_rx_ena;
    reg       r_tx_ena;

    always@(posedge rst or posedge clk) begin : RX_TX_BAUD_RATE
        reg [11:0] v_rx_cnt;
        reg [11:0] v_tx_cnt;

        if (rst) begin
            r_rx_ena <= 1'b0;
            r_tx_ena <= 1'b0;
            v_rx_cnt <= BAUD_RATE[11:0];
            v_tx_cnt <= BAUD_RATE[11:0];
        end
        else begin
            // Receiver
            if (^r_uart_rxd_cc[2:1]) begin
                v_rx_cnt <= { 1'b0, BAUD_RATE[11:1] };
                r_rx_ena <= 1'b0;
            end
            else begin
                if (v_rx_cnt[11:1] == 11'd0) begin
                    v_rx_cnt <= BAUD_RATE[11:0];
                    r_rx_ena <= 1'b1;
                end
                else begin
                    v_rx_cnt <= v_rx_cnt - 12'd1;
                    r_rx_ena <= 1'b0;
                end
            end
            
            // Transmitter
            if ((v_tx_cnt[11:1] == 11'd0) || (csel & wren & bena[0] & r_tx_rdy)) begin
                v_tx_cnt <= BAUD_RATE[11:0];
                r_tx_ena <= 1'b1;
            end
            else begin
                v_tx_cnt <= v_tx_cnt - 12'd1;
                r_tx_ena <= 1'b0;
            end
        end
    end

    //=========================================================================
    // UART receiver state machine
    //=========================================================================
    
    localparam
        FSM_RX_IDLE = 0,
        FSM_RX_DATA = 1,
        FSM_RX_STOP = 2;

    reg [2:0] r_rx_fsm;   // Receiver state machine
    reg [7:0] r_rx_shift; // Received data
    reg [7:0] r_rx_data;  // Received data
    reg       r_rx_vld;   // Received data valid
    reg       r_rx_rdy;   // Received data valid

    always@(posedge rst or posedge clk) begin : RX_FSM
        reg [2:0] v_data_cnt;
        reg       v_rxd_d;

        if (rst) begin
            v_data_cnt <= 3'd0;
            v_rxd_d    <= 1'b1;

            r_rx_fsm   <= 3'b000;
            r_rx_fsm[FSM_RX_IDLE] <= 1'b1;
            r_rx_shift <= 8'hFF;
            r_rx_data  <= 8'h00;
            r_rx_vld   <= 1'b0;
            r_rx_rdy   <= 1'b0;
        end
        else begin
            if (r_rx_ena) begin
                r_rx_fsm <= 3'b000;
                
                case(1'b1)
                    r_rx_fsm[FSM_RX_IDLE] : begin
                        v_data_cnt <= 3'd0;
                        r_rx_vld   <= 1'b0;
                
                        // 1 -> 0 transition : start bit
                        if (~r_uart_rxd_cc[2] & v_rxd_d) begin
                            r_rx_fsm[FSM_RX_DATA] <= 1'b1;
                        end
                        else begin
                            r_rx_fsm[FSM_RX_IDLE] <= 1'b1;
                        end
                    end
                
                    r_rx_fsm[FSM_RX_DATA] : begin
                        r_rx_shift <= { r_uart_rxd_cc[2], r_rx_shift[7:1] };
                
                        if (v_data_cnt == 3'd7) begin
                            r_rx_fsm[FSM_RX_STOP] <= 1'b1;
                        end
                        else begin
                            v_data_cnt <= v_data_cnt + 3'd1;
                            r_rx_fsm[FSM_RX_DATA] <= 1'b1;
                        end
                    end
                
                    r_rx_fsm[FSM_RX_STOP] : begin
                        // 0 -> 1 transition : stop bit
                        if (r_uart_rxd_cc[2] & ~v_rxd_d) begin
                            r_rx_fsm[FSM_RX_IDLE] <= 1'b1;
                        end
                        else begin
                            r_rx_fsm[FSM_RX_STOP] <= 1'b1;
                        end
                        r_rx_vld <= r_uart_rxd_cc[2] & ~v_rxd_d;
                    end
                endcase
                v_rxd_d <= r_uart_rxd_cc[2];
            end
            if (r_rx_vld & r_rx_ena) begin
                r_rx_data <= r_rx_shift;
                r_rx_rdy  <= 1'b1;
            end
            else if (csel & rden & bena[0] & r_dtack) begin
                r_rx_rdy  <= 1'b0;
            end
        end
    end
    
    //=========================================================================
    // 8N1 byte transmit
    //=========================================================================    
    
    `ifdef verilator3
    integer _uart_fh_out;
    
    initial begin
        _uart_fh_out = $fopen("uart_tx.log", "w");
        if (_uart_fh_out == 0) begin
            $display("File uart_tx.log open error %d\n", _uart_fh_out);
            $finish;
        end
    end
    `endif
    
    reg  [10:0] r_tx_data;  // Transmitted data, 8N1 format
    reg         r_tx_rdy;   // Transmitter is ready

    always@(posedge rst or posedge clk) begin : TX_BUFFER

        if (rst) begin
            r_tx_data <= { 1'b1, 8'h52, 2'b01 }; // 'R'
            r_tx_rdy  <= 1'b0;
        end
        else begin
            if (r_tx_ena) begin
                if (r_tx_rdy) begin
                    if (csel & wren & bena[0]) begin
                        // Testbench output
                        `ifdef verilator3
                        $fwrite(_uart_fh_out, "%c", wdata[7:0]);
                        `endif
                        // Load shift register :
                        // Stop(1) | Byte | Start(0) | Idle (1)
                        r_tx_data <= { 1'b1, wdata[7:0], 2'b01 };
                    end
                end
                else begin
                    // Shift one bit out
                    r_tx_data <= { 1'b0, r_tx_data[10:1] };
                end
            end
            r_tx_rdy <= (r_tx_data[10:1] == 10'b0_00000000_0) ? 1'b1 : 1'b0;
        end
    end
    
    assign uart_txd = r_tx_data[0];
    
endmodule

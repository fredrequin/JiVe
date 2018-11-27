module EBR_B
(
    // Write port
    input         WCLK,
    input         WCLKE,
    input         WE,
    input         WADDR10, WADDR9, WADDR8, WADDR7, WADDR6, WADDR5, WADDR4, WADDR3, WADDR2, WADDR1, WADDR0,
    input         MASK_N15, MASK_N14, MASK_N13, MASK_N12, MASK_N11, MASK_N10, MASK_N9, MASK_N8,
    input         MASK_N7,  MASK_N6,  MASK_N5,  MASK_N4,  MASK_N3,  MASK_N2,  MASK_N1, MASK_N0,
    input         WDATA15, WDATA14, WDATA13, WDATA12, WDATA11, WDATA10, WDATA9, WDATA8,
    input         WDATA7,  WDATA6,  WDATA5,  WDATA4,  WDATA3,  WDATA2,  WDATA1, WDATA0,
    // Read port
    input         RCLK,
    input         RCLKE,
    input         RE,
    input         RADDR10, RADDR9, RADDR8, RADDR7, RADDR6, RADDR5, RADDR4, RADDR3, RADDR2, RADDR1, RADDR0,
    output        RDATA15, RDATA14, RDATA13, RDATA12, RDATA11, RDATA10, RDATA9, RDATA8,
    output        RDATA7,  RDATA6,  RDATA5,  RDATA4,  RDATA3,  RDATA2,  RDATA1, RDATA0
);
    parameter INIT_0 = 256'h0;
    parameter INIT_1 = 256'h0;
    parameter INIT_2 = 256'h0;
    parameter INIT_3 = 256'h0;
    parameter INIT_4 = 256'h0;
    parameter INIT_5 = 256'h0;
    parameter INIT_6 = 256'h0;
    parameter INIT_7 = 256'h0;
    parameter INIT_8 = 256'h0;
    parameter INIT_9 = 256'h0;
    parameter INIT_A = 256'h0;
    parameter INIT_B = 256'h0;
    parameter INIT_C = 256'h0;
    parameter INIT_D = 256'h0;
    parameter INIT_E = 256'h0;
    parameter INIT_F = 256'h0;
    parameter DATA_WIDTH_R = 16;
    parameter DATA_WIDTH_W = 16;
    
    wire  [7:0] w_waddr = { WADDR7, WADDR6, WADDR5, WADDR4, WADDR3, WADDR2, WADDR1, WADDR0 };
    wire [15:0] w_wdata = { WDATA15, WDATA14, WDATA13, WDATA12, WDATA11, WDATA10, WDATA9, WDATA8,
                            WDATA7,  WDATA6,  WDATA5,  WDATA4,  WDATA3,  WDATA2,  WDATA1, WDATA0 };
    wire [15:0] w_wmask = { MASK_N15, MASK_N14, MASK_N13, MASK_N12, MASK_N11, MASK_N10, MASK_N9, MASK_N8,
                            MASK_N7,  MASK_N6,  MASK_N5,  MASK_N4,  MASK_N3,  MASK_N2,  MASK_N1, MASK_N0 };
    wire  [7:0] w_raddr = { RADDR7, RADDR6, RADDR5, RADDR4, RADDR3, RADDR2, RADDR1, RADDR0 };
    
    /////////////////////////////////
    // MEMORY BLOCK INITIALIZATION //
    /////////////////////////////////
    
    reg [15:0] r_ram_blk [0:255];
    
    initial begin : SBRAM_INIT
        reg [255:0] v_tmp [0:15];
        integer i;
        
        v_tmp[4'h0] = INIT_0;
        v_tmp[4'h1] = INIT_1;
        v_tmp[4'h2] = INIT_2;
        v_tmp[4'h3] = INIT_3;
        v_tmp[4'h4] = INIT_4;
        v_tmp[4'h5] = INIT_5;
        v_tmp[4'h6] = INIT_6;
        v_tmp[4'h7] = INIT_7;
        v_tmp[4'h8] = INIT_8;
        v_tmp[4'h9] = INIT_9;
        v_tmp[4'hA] = INIT_A;
        v_tmp[4'hB] = INIT_B;
        v_tmp[4'hC] = INIT_C;
        v_tmp[4'hD] = INIT_D;
        v_tmp[4'hE] = INIT_E;
        v_tmp[4'hF] = INIT_F;
        
        for (i = 0; i < 256; i = i + 16) begin
            r_ram_blk[{ 4'h0, i[7:4] }] = v_tmp[4'h0][15:0];
            r_ram_blk[{ 4'h1, i[7:4] }] = v_tmp[4'h1][15:0];
            r_ram_blk[{ 4'h2, i[7:4] }] = v_tmp[4'h2][15:0];
            r_ram_blk[{ 4'h3, i[7:4] }] = v_tmp[4'h3][15:0];
            r_ram_blk[{ 4'h4, i[7:4] }] = v_tmp[4'h4][15:0];
            r_ram_blk[{ 4'h5, i[7:4] }] = v_tmp[4'h5][15:0];
            r_ram_blk[{ 4'h6, i[7:4] }] = v_tmp[4'h6][15:0];
            r_ram_blk[{ 4'h7, i[7:4] }] = v_tmp[4'h7][15:0];
            r_ram_blk[{ 4'h8, i[7:4] }] = v_tmp[4'h8][15:0];
            r_ram_blk[{ 4'h9, i[7:4] }] = v_tmp[4'h9][15:0];
            r_ram_blk[{ 4'hA, i[7:4] }] = v_tmp[4'hA][15:0];
            r_ram_blk[{ 4'hB, i[7:4] }] = v_tmp[4'hB][15:0];
            r_ram_blk[{ 4'hC, i[7:4] }] = v_tmp[4'hC][15:0];
            r_ram_blk[{ 4'hD, i[7:4] }] = v_tmp[4'hD][15:0];
            r_ram_blk[{ 4'hE, i[7:4] }] = v_tmp[4'hE][15:0];
            r_ram_blk[{ 4'hF, i[7:4] }] = v_tmp[4'hF][15:0];
            
            v_tmp[4'h0] = v_tmp[4'h0] >> 16;
            v_tmp[4'h1] = v_tmp[4'h1] >> 16;
            v_tmp[4'h2] = v_tmp[4'h2] >> 16;
            v_tmp[4'h3] = v_tmp[4'h3] >> 16;
            v_tmp[4'h4] = v_tmp[4'h4] >> 16;
            v_tmp[4'h5] = v_tmp[4'h5] >> 16;
            v_tmp[4'h6] = v_tmp[4'h6] >> 16;
            v_tmp[4'h7] = v_tmp[4'h7] >> 16;
            v_tmp[4'h8] = v_tmp[4'h8] >> 16;
            v_tmp[4'h9] = v_tmp[4'h9] >> 16;
            v_tmp[4'hA] = v_tmp[4'hA] >> 16;
            v_tmp[4'hB] = v_tmp[4'hB] >> 16;
            v_tmp[4'hC] = v_tmp[4'hC] >> 16;
            v_tmp[4'hD] = v_tmp[4'hD] >> 16;
            v_tmp[4'hE] = v_tmp[4'hE] >> 16;
            v_tmp[4'hF] = v_tmp[4'hF] >> 16;
        end
    end

    ////////////////
    // WRITE PORT //
    ////////////////
    
    always@(posedge WCLK) begin : WRITE_PORT
        integer i;
    
        if (WCLKE & WE) begin
            for (i = 0; i < 16; i = i + 1) begin
                if (w_wmask[i]) begin
                    r_ram_blk[w_waddr][i] <= w_wdata[i];
                end
            end
        end
    end
    
    ///////////////
    // READ PORT //
    ///////////////
    
    reg [15:0] r_rdata_p1;
    
    always@(posedge RCLK) begin : READ_PORT
    
        if (RCLKE & RE) begin
            r_rdata_p1 <= r_ram_blk[w_raddr];
        end
    end
    
    assign RDATA15 = r_rdata_p1[15];
    assign RDATA14 = r_rdata_p1[14];
    assign RDATA13 = r_rdata_p1[13];
    assign RDATA12 = r_rdata_p1[12];
    assign RDATA11 = r_rdata_p1[11];
    assign RDATA10 = r_rdata_p1[10];
    assign RDATA9  = r_rdata_p1[9];
    assign RDATA8  = r_rdata_p1[8];
    assign RDATA7  = r_rdata_p1[7];
    assign RDATA6  = r_rdata_p1[6];
    assign RDATA5  = r_rdata_p1[5];
    assign RDATA4  = r_rdata_p1[4];
    assign RDATA3  = r_rdata_p1[3];
    assign RDATA2  = r_rdata_p1[2];
    assign RDATA1  = r_rdata_p1[1];
    assign RDATA0  = r_rdata_p1[0];
    
endmodule

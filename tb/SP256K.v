module SP256K
(
    input         STDBY,
    input         SLEEP,
    input         PWROFF_N,
    
    input         CK,
    input         CS,
    
    input         WE,
    input   [3:0] MASKWE,
    input  [13:0] AD,
    input  [15:0] DI,
    output [15:0] DO
);
    parameter HIWORD = 0;

    /////////////////////////////////
    // MEMORY BLOCK INITIALIZATION //
    /////////////////////////////////
    
    import "DPI-C" function int spram_init(input int index);
    
    reg [3:0] r_ram_blk_0 [0:16383];
    reg [3:0] r_ram_blk_1 [0:16383];
    reg [3:0] r_ram_blk_2 [0:16383];
    reg [3:0] r_ram_blk_3 [0:16383];
    
    initial begin : SPRAM_INIT
        int i;
        int tmp;
        
        for (i = 0; i < 16384; i = i + 1) begin
            tmp = spram_init(i);
            r_ram_blk_3[i] = (HIWORD[0]) ? tmp[31:28] : tmp[15:12];
            r_ram_blk_2[i] = (HIWORD[0]) ? tmp[27:24] : tmp[11: 8];
            r_ram_blk_1[i] = (HIWORD[0]) ? tmp[23:20] : tmp[ 7: 4];
            r_ram_blk_0[i] = (HIWORD[0]) ? tmp[19:16] : tmp[ 3: 0];
        end
    end

    ////////////////
    // WRITE PORT //
    ////////////////
    
    always@(posedge CK) begin : WRITE_PORT
    
        if (CS & WE) begin
            if (MASKWE[3]) r_ram_blk_3[AD] <= DI[15:12];
            if (MASKWE[2]) r_ram_blk_2[AD] <= DI[11: 8];
            if (MASKWE[1]) r_ram_blk_1[AD] <= DI[ 7: 4];
            if (MASKWE[0]) r_ram_blk_0[AD] <= DI[ 3: 0];
        end
    end
    
    ///////////////
    // READ PORT //
    ///////////////
    
    reg [15:0] r_dataout_p1;
    
    always@(posedge CK) begin : READ_PORT
    
        if (CS) begin
            r_dataout_p1[15:12] <= r_ram_blk_3[AD];
            r_dataout_p1[11: 8] <= r_ram_blk_2[AD];
            r_dataout_p1[ 7: 4] <= r_ram_blk_1[AD];
            r_dataout_p1[ 3: 0] <= r_ram_blk_0[AD];
        end
    end
    
    assign DO = r_dataout_p1;
    
endmodule

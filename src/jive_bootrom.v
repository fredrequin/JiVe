module jive_bootrom
(
    input         clk,
    input         clk_en,
    
    input         csel,
    input         rden,
    
    input   [7:0] addr,
    output [31:0] rdata,
    output        dtack
);
    parameter INIT_FILE        = "NONE";
    parameter INIT_FILE_FORMAT = "HEX";

    //=========================================================================
    
    reg [31:0] r_rom_blk [0:255];

    initial begin : ROM_INIT
        
        `ifdef verilator3
        r_rom_blk[8'h00] = 32'h00000093;
        r_rom_blk[8'h01] = 32'h00000113;
        r_rom_blk[8'h02] = 32'h00000193;
        r_rom_blk[8'h03] = 32'h00000213;
        r_rom_blk[8'h04] = 32'h00000293;
        r_rom_blk[8'h05] = 32'h00000313;
        r_rom_blk[8'h06] = 32'h00000393;
        r_rom_blk[8'h07] = 32'h00000413;
        r_rom_blk[8'h08] = 32'h00000493;
        r_rom_blk[8'h09] = 32'h00000513;
        r_rom_blk[8'h0A] = 32'h00000593;
        r_rom_blk[8'h0B] = 32'h00000613;
        r_rom_blk[8'h0C] = 32'h00000693;
        r_rom_blk[8'h0D] = 32'h00000713;
        r_rom_blk[8'h0E] = 32'h00000793;
        r_rom_blk[8'h0F] = 32'h00000813;
        r_rom_blk[8'h10] = 32'h00000893;
        r_rom_blk[8'h11] = 32'h00000913;
        r_rom_blk[8'h12] = 32'h00000993;
        r_rom_blk[8'h13] = 32'h00000A13;
        r_rom_blk[8'h14] = 32'h00000A93;
        r_rom_blk[8'h15] = 32'h00000B13;
        r_rom_blk[8'h16] = 32'h00000B93;
        r_rom_blk[8'h17] = 32'h00000C13;
        r_rom_blk[8'h18] = 32'h00000C93;
        r_rom_blk[8'h19] = 32'h00000D13;
        r_rom_blk[8'h1A] = 32'h00000D93;
        r_rom_blk[8'h1B] = 32'h00000E13;
        r_rom_blk[8'h1C] = 32'h00000E93;
        r_rom_blk[8'h1D] = 32'h00000F13;
        r_rom_blk[8'h1E] = 32'h00000F93;
        r_rom_blk[8'h1F] = 32'h80010117;
        r_rom_blk[8'h20] = 32'hF8010113;
        r_rom_blk[8'h21] = 32'h80000D17;
        r_rom_blk[8'h22] = 32'hF7CD0D13;
        r_rom_blk[8'h23] = 32'h80000D97;
        r_rom_blk[8'h24] = 32'hF74D8D93;
        r_rom_blk[8'h25] = 32'h01BD5863;
        r_rom_blk[8'h26] = 32'h000D2023;
        r_rom_blk[8'h27] = 32'h004D0D13;
        r_rom_blk[8'h28] = 32'hFFADDCE3;
        r_rom_blk[8'h29] = 32'h00000513;
        r_rom_blk[8'h2A] = 32'h00000593;
        r_rom_blk[8'h2B] = 32'h044000EF;
        r_rom_blk[8'h2C] = 32'h0000006F;
        r_rom_blk[8'h2D] = 32'h00050067;
        r_rom_blk[8'h2E] = 32'h00000793;
        r_rom_blk[8'h2F] = 32'h00010637;
        r_rom_blk[8'h30] = 32'h01000593;
        r_rom_blk[8'h31] = 32'h00062683;
        r_rom_blk[8'h32] = 32'hFFF50513;
        r_rom_blk[8'h33] = 32'h00479793;
        r_rom_blk[8'h34] = 32'hFD068713;
        r_rom_blk[8'h35] = 32'h00E5F463;
        r_rom_blk[8'h36] = 32'hFC968713;
        r_rom_blk[8'h37] = 32'h00F77713;
        r_rom_blk[8'h38] = 32'h00F767B3;
        r_rom_blk[8'h39] = 32'hFE0510E3;
        r_rom_blk[8'h3A] = 32'h00078513;
        r_rom_blk[8'h3B] = 32'h00008067;
        r_rom_blk[8'h3C] = 32'hFD010113;
        r_rom_blk[8'h3D] = 32'h02912223;
        r_rom_blk[8'h3E] = 32'h01412C23;
        r_rom_blk[8'h3F] = 32'h01512A23;
        r_rom_blk[8'h40] = 32'h01612823;
        r_rom_blk[8'h41] = 32'h01712623;
        r_rom_blk[8'h42] = 32'h01812423;
        r_rom_blk[8'h43] = 32'h02112623;
        r_rom_blk[8'h44] = 32'h02812423;
        r_rom_blk[8'h45] = 32'h03212023;
        r_rom_blk[8'h46] = 32'h01312E23;
        r_rom_blk[8'h47] = 32'h01912223;
        r_rom_blk[8'h48] = 32'h01A12023;
        r_rom_blk[8'h49] = 32'h000107B7;
        r_rom_blk[8'h4A] = 32'h04200713;
        r_rom_blk[8'h4B] = 32'h00E7A023;
        r_rom_blk[8'h4C] = 32'h000104B7;
        r_rom_blk[8'h4D] = 32'h05300A93;
        r_rom_blk[8'h4E] = 32'h00900B13;
        r_rom_blk[8'h4F] = 32'h00100A13;
        r_rom_blk[8'h50] = 32'h80010BB7;
        r_rom_blk[8'h51] = 32'h03000C13;
        r_rom_blk[8'h52] = 32'h0004A783;
        r_rom_blk[8'h53] = 32'h03579663;
        r_rom_blk[8'h54] = 32'h0004A983;
        r_rom_blk[8'h55] = 32'hFD098793;
        r_rom_blk[8'h56] = 32'h02FB6063;
        r_rom_blk[8'h57] = 32'h00FA17B3;
        r_rom_blk[8'h58] = 32'h2237F713;
        r_rom_blk[8'h59] = 32'h04071C63;
        r_rom_blk[8'h5A] = 32'h0887F713;
        r_rom_blk[8'h5B] = 32'h10071263;
        r_rom_blk[8'h5C] = 32'h1047F793;
        r_rom_blk[8'h5D] = 32'h0C079C63;
        r_rom_blk[8'h5E] = 32'h02812403;
        r_rom_blk[8'h5F] = 32'h02C12083;
        r_rom_blk[8'h60] = 32'h02412483;
        r_rom_blk[8'h61] = 32'h02012903;
        r_rom_blk[8'h62] = 32'h01C12983;
        r_rom_blk[8'h63] = 32'h01812A03;
        r_rom_blk[8'h64] = 32'h01412A83;
        r_rom_blk[8'h65] = 32'h01012B03;
        r_rom_blk[8'h66] = 32'h00C12B83;
        r_rom_blk[8'h67] = 32'h00812C03;
        r_rom_blk[8'h68] = 32'h00412C83;
        r_rom_blk[8'h69] = 32'h00012D03;
        r_rom_blk[8'h6A] = 32'h000107B7;
        r_rom_blk[8'h6B] = 32'h02100713;
        r_rom_blk[8'h6C] = 32'h00E7A023;
        r_rom_blk[8'h6D] = 32'h03010113;
        r_rom_blk[8'h6E] = 32'hEF9FF06F;
        r_rom_blk[8'h6F] = 32'h00200513;
        r_rom_blk[8'h70] = 32'hEF9FF0EF;
        r_rom_blk[8'h71] = 32'h00050413;
        r_rom_blk[8'h72] = 32'hFFE50913;
        r_rom_blk[8'h73] = 32'h00400513;
        r_rom_blk[8'h74] = 32'hEE9FF0EF;
        r_rom_blk[8'h75] = 32'h00850433;
        r_rom_blk[8'h76] = 32'h00855C93;
        r_rom_blk[8'h77] = 32'h008C8CB3;
        r_rom_blk[8'h78] = 32'h0A055C63;
        r_rom_blk[8'h79] = 32'h012507B3;
        r_rom_blk[8'h7A] = 32'hF8FBE8E3;
        r_rom_blk[8'h7B] = 32'h00050413;
        r_rom_blk[8'h7C] = 32'hFCF98D13;
        r_rom_blk[8'h7D] = 32'h00200513;
        r_rom_blk[8'h7E] = 32'h0B2A6463;
        r_rom_blk[8'h7F] = 32'hEBDFF0EF;
        r_rom_blk[8'h80] = 32'h00AC8433;
        r_rom_blk[8'h81] = 32'h0FF47413;
        r_rom_blk[8'h82] = 32'h0FF00793;
        r_rom_blk[8'h83] = 32'hF6F416E3;
        r_rom_blk[8'h84] = 32'h0004A703;
        r_rom_blk[8'h85] = 32'h00D00793;
        r_rom_blk[8'h86] = 32'hF6F710E3;
        r_rom_blk[8'h87] = 32'h0004A783;
        r_rom_blk[8'h88] = 32'h00A00693;
        r_rom_blk[8'h89] = 32'hF4D79AE3;
        r_rom_blk[8'h8A] = 32'h02E00693;
        r_rom_blk[8'h8B] = 32'h00D4A023;
        r_rom_blk[8'h8C] = 32'h03600693;
        r_rom_blk[8'h8D] = 32'hF136FAE3;
        r_rom_blk[8'h8E] = 32'h00E4A023;
        r_rom_blk[8'h8F] = 32'h00F4A023;
        r_rom_blk[8'h90] = 32'h80000537;
        r_rom_blk[8'h91] = 32'hE71FF0EF;
        r_rom_blk[8'h92] = 32'hF31FF06F;
        r_rom_blk[8'h93] = 32'h00200513;
        r_rom_blk[8'h94] = 32'hE69FF0EF;
        r_rom_blk[8'h95] = 32'h00050C93;
        r_rom_blk[8'h96] = 32'hFFD50913;
        r_rom_blk[8'h97] = 32'h00600513;
        r_rom_blk[8'h98] = 32'hE59FF0EF;
        r_rom_blk[8'h99] = 32'h01055413;
        r_rom_blk[8'h9A] = 32'h01940433;
        r_rom_blk[8'h9B] = 32'hF69FF06F;
        r_rom_blk[8'h9C] = 32'h00200513;
        r_rom_blk[8'h9D] = 32'hE45FF0EF;
        r_rom_blk[8'h9E] = 32'h00050C93;
        r_rom_blk[8'h9F] = 32'hFFC50913;
        r_rom_blk[8'hA0] = 32'h00800513;
        r_rom_blk[8'hA1] = 32'hE35FF0EF;
        r_rom_blk[8'hA2] = 32'h01855413;
        r_rom_blk[8'hA3] = 32'h01055793;
        r_rom_blk[8'hA4] = 32'h00F40433;
        r_rom_blk[8'hA5] = 32'hFD5FF06F;
        r_rom_blk[8'hA6] = 32'hF4050AE3;
        r_rom_blk[8'hA7] = 32'hEDDFF06F;
        r_rom_blk[8'hA8] = 32'hE19FF0EF;
        r_rom_blk[8'hA9] = 32'h00200793;
        r_rom_blk[8'hAA] = 32'h00AC8CB3;
        r_rom_blk[8'hAB] = 32'hFFF90913;
        r_rom_blk[8'hAC] = 32'h01A7E863;
        r_rom_blk[8'hAD] = 32'h00A40023;
        r_rom_blk[8'hAE] = 32'h00140413;
        r_rom_blk[8'hAF] = 32'hF39FF06F;
        r_rom_blk[8'hB0] = 32'hF3899AE3;
        r_rom_blk[8'hB1] = 32'h0FF57513;
        r_rom_blk[8'hB2] = 32'h00A4A023;
        r_rom_blk[8'hB3] = 32'hF29FF06F;
        r_rom_blk[8'hB4] = 32'h00000000;
        r_rom_blk[8'hB5] = 32'h00000000;
        r_rom_blk[8'hB6] = 32'h00000000;
        r_rom_blk[8'hB7] = 32'h00000000;
        r_rom_blk[8'hB8] = 32'h00000000;
        r_rom_blk[8'hB9] = 32'h00000000;
        r_rom_blk[8'hBA] = 32'h00000000;
        r_rom_blk[8'hBB] = 32'h00000000;
        r_rom_blk[8'hBC] = 32'h00000000;
        r_rom_blk[8'hBD] = 32'h00000000;
        r_rom_blk[8'hBE] = 32'h00000000;
        r_rom_blk[8'hBF] = 32'h00000000;
        `else
        integer i;
        
        if (INIT_FILE == "NONE") begin
            for (i = 0; i < 256; i = i + 1) begin
                r_rom_blk[i] = 32'h00000000;
            end
        end
        else begin
            if (INIT_FILE_FORMAT == "HEX") begin
                $readmemh(INIT_FILE, r_rom_blk);
            end
            else begin
                $readmemb(INIT_FILE, r_rom_blk);
            end           
        end
        `endif
    end

    //=========================================================================
    
    reg [31:0] r_rom_rdata_p1;
    reg        r_rom_dtack_p1;
    
    always @ (posedge clk) begin : ROM_READ_P1
    
        if (clk_en) begin
            r_rom_rdata_p1 <= r_rom_blk[addr];
            r_rom_dtack_p1 <= csel & rden;
        end
    end
    
    assign rdata = r_rom_rdata_p1;
    assign dtack = r_rom_dtack_p1;
    
    //=========================================================================
    
endmodule

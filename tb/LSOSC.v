module LSOSC
(
    `ifdef verilator3
    input  _clk,
    `endif
    input  CLKLFPU,
    input  CLKLFEN,
    output CLKLF
);

    integer _ctr;
    
    initial begin
        _ctr = 0;
    end
    
    always @ (posedge _clk) begin
    
        if (!CLKLFPU) begin
            _ctr <= 0;
        end
        else begin
            _ctr <= _ctr + 1;
        end
    end
    
    assign CLKLF = _ctr[10] & CLKLFEN;

endmodule

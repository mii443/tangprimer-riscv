module MEMORY(
    input clock,

    input [31:0] raddr,
    input [31:0] iaddr,
    input wen,
    input [31:0] wdata,
    
    output [31:0] inst,
    output [31:0] rdata
);

    reg [7:0] mem [32:0];
    
    reg [31:0] reg_raddr;
    
    integer i;
    initial begin
        for (i=0;i<64;i=i+1) mem[i] <= 0;
        mem[0] <= 8'b00000000;
        mem[1] <= 8'b00100000;
        mem[2] <= 8'b10100010;
        mem[3] <= 8'b00100011;

        mem[0] <= 8'b00000000;
        mem[1] <= 8'b00100000;
        mem[2] <= 8'b10100010;
        mem[3] <= 8'b00100011;
        reg_raddr <= 32'b0;
    end

    always @(posedge clock) begin
        if (wen == 1'b1) begin
            mem[raddr] = wdata[0 +:8];
            mem[raddr+1] = wdata[8 +:8];
            mem[raddr+2] = wdata[16 +:8];
            mem[raddr+3] = wdata[24 +:8];
        end
    end

    assign inst = {
        mem[iaddr+0],
        mem[iaddr+1],
        mem[iaddr+2],
        mem[iaddr+3]
    };

    assign rdata = {
        mem[raddr+0],
        mem[raddr+1],
        mem[raddr+2],
        mem[raddr+3]
    };

endmodule
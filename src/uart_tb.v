module memory_tb;

    parameter RATE = 1;

    initial begin
        $dumpfile("tb_memory.vcd");
        $dumpvars(3, memory_tb);

        # (10000) $finish;
    end

    reg clk = 0;
    always #(RATE) clk = !clk;
    wire LED;
    wire TX;

    TOP top(
        .clock(clk),
        .LED(LED),
        .tx(TX)
    );

endmodule
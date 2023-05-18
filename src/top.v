module TOP(
    input clock,
    output LED,
    output tx
);

    wire tx_busy;
    wire tx_start;
    wire [7:0] tx_data;

    UART uart0(
        .clock(clock),
        .tx(tx),
        .tx_busy(tx_busy),
        .start(tx_start),
        .data_in(tx_data),
        .LED(LED)
    );

    wire [31:0] inst;
    wire [31:0] rdata;
    wire [31:0] raddr;
    wire [31:0] iaddr;
    wire [31:0] wdata;
    wire wen;
    MEMORY mem0(
        .clock(clock),
        .raddr(raddr),
        .iaddr(iaddr),
        .wen(wen),
        .wdata(wdata),
        .inst(inst),
        .rdata(rdata)
    );

    CORE core0(
        .clock(clock),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .raddr(raddr),
        .iaddr(iaddr),
        .wen(wen),
        .wdata(wdata),
        .inst(inst),
        .rdata(rdata)
    );
/*
    localparam MEM_WRITE = 0;
    localparam MEM_READ = 1;
    localparam MEM_IDLE = 2;

    localparam WAIT_TIME = 200000;
    reg [31:0] clock_count;
    reg [7:0] send_count;
    reg [3:0] state;
    wire [4 * 8:0] str = "test";
    initial begin
        clock_count = WAIT_TIME;
        send_count = 0;
        state = MEM_WRITE;
        tx_start = 1'b0;
        tx_data = 8'b0;
    end

    always @(posedge clock) begin
        if (clock_count == WAIT_TIME) begin

            case (state)
                MEM_WRITE: begin
                    raddr <= 32'b0;
                    wdata <= "C";
                    wen <= 1'b1;
                    state <= MEM_READ;
                end

                MEM_READ: begin
                    wen <= 1'b0;
                    raddr <= 32'b0;
                    if (tx_busy == 1'b0) begin
                        tx_data <= rdata[0 +:8];
                        tx_start <= 1'b1;
                    end
                    state <= MEM_IDLE;
                end

                MEM_IDLE:
                    state <= MEM_WRITE;
            endcase

            clock_count <= 0;
        end else begin
            clock_count <= clock_count + 1;
            tx_start <= 1'b1;
        end
    end*/

endmodule
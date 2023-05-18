module UART(
    input clock,

    input [7:0] data_in,
    input start,

    output tx_busy,
    output tx,
    output LED
);

    // UART Clock
    localparam FPGA_FREQ = 27; // MHz
    localparam UART_FREQ = 115200;
    localparam TX_CLOCK_COUNT_MAX = FPGA_FREQ * 1000000 / UART_FREQ - 1;

    reg [31:0] clock_count;

    reg led_flag;
    assign LED = led_flag;

    wire tx_clock = (clock_count == 0);

    initial begin
        clock_count = 0;
    end

    always @(posedge clock) begin
        if (clock_count == TX_CLOCK_COUNT_MAX) begin
            clock_count <= 0;
            led_flag <= ~led_flag;
        end else begin
            clock_count <= clock_count + 1;
        end
    end


    // State Machine
    localparam S_IDLE = 0;
    localparam S_START = 1;
    localparam S_SEND = 2;
    localparam S_P = 3;
    localparam S_END = 4;

    reg [4:0] state;
    reg [3:0] send_count;

    reg tx_reg;
    reg [7:0] data;
    reg [7:0] local_in;
    reg local_start;

    assign tx = tx_reg;

    always @(posedge clock) begin
        local_in <= data_in;
        local_start <= start;
    end

    assign tx_busy = (state != S_IDLE);

    initial begin
        state = S_IDLE;
        send_count = 0;
        tx_reg = 1'b1;
    end

    always @(posedge clock) begin
        case (state)
            S_IDLE:
                if (tx_clock) begin
                    if (local_start) begin
                        tx_reg <= 1'b1;
                        state <= S_START;
                    end else begin
                        tx_reg <= 1'b1;
                        state <= S_IDLE;
                    end
                end

            S_START: 
                if (tx_clock) begin
                    tx_reg <= 1'b0;
                    data <= local_in;
                    send_count <= 0;
                    state <= S_SEND;
                end else begin
                    tx_reg <= 1'b0;
                    state <= S_START;
                end

            S_SEND:
                if (tx_clock) begin
                    tx_reg <= data[send_count];
                    if (send_count == 3'd7) begin
                        state <= S_P;
                    end else begin
                        send_count <= send_count + 1;
                        state <= S_SEND;
                    end
                end else begin
                    tx_reg <= data[send_count];
                    state <= S_SEND;
                end

            S_P:
                if (tx_clock) begin
                    tx_reg <= 1'b1;
                    state <= S_END;
                end else begin
                    tx_reg <= 1'b1;
                    state <= S_P;
                end

            S_END:
                if (tx_clock) begin
                    tx_reg <= 1'b1;
                    state <= S_IDLE;
                end else begin
                    tx_reg <= 1'b1;
                    state <= S_END;
                end
        endcase
    end

endmodule
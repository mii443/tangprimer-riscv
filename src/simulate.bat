iverilog -o tb_memory.o uart_tb.v top.v core.v memory.v uart.v
vvp tb_memory.o
gtkwave tb_memory.vcd
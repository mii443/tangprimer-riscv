`include "defs.vh"

module CORE(
    input clock,

// UART
    output tx_start,
    output [7:0] tx_data,

// Memory
    output [31:0] raddr,
    output [31:0] iaddr,
    output wen,
    output [31:0] wdata,
    input [31:0] inst,
    input [31:0] rdata
);

    reg [31:0] register [31:0];
    reg [31:0] REGISTER_TEST;

    reg [7:0] reg_tx_data;
    reg reg_tx_start;

    reg [31:0] pc;
    reg [31:0] pc_p4;
    reg [31:0] reg_inst;
    reg [31:0] reg_iaddr;
    reg [31:0] reg_raddr;
    reg [31:0] reg_wdata;
    reg reg_wen;

    reg [31:0] reg_wb_data;
    reg reg_wb_wen;

    reg [6:0] opcode;
    reg [4:0] rd;
    reg [2:0] funct3;
    reg [4:0] rs1;
    reg [4:0] rs2;
    reg [6:0] funct7;

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    reg [11:0] i_imm;
    wire [31:0] i_imm_sext;
    reg [11:0] s_imm;
    wire [31:0] s_imm_sext;
    reg [12:0] b_imm;
    reg [19:0] u_imm;
    wire [31:0] u_imm_sext;
    reg [20:0] j_imm;

    reg [31:0] alu_out;

    localparam ST_IF = 0;
    localparam ST_ID = 1;
    localparam ST_EX = 2;
    localparam ST_ACCESS = 3;
    localparam ST_WB = 4;
    reg [3:0] stage;

    integer i;
    initial begin
        for (i=0;i<32;i=i+1) register[i] <= 31'b0;
        register[0] <= 32'b00000000000000000000000000000000;
        register[1] <= 32'b00000000000000000000000000000000;
        register[2] <= 32'b00000000000000000000000000000000;
    
        reg_wb_data = 0;
        reg_wb_wen = 0;

        pc = 0;
        reg_inst = 0;
        reg_iaddr = 0;
        reg_raddr = 0;
        reg_wdata = 0;
        reg_wen = 0;
        alu_out = 0;
        stage = ST_IF;
    end

    always @(posedge clock) begin
        case (stage)
            ST_IF: begin
                reg_tx_start <= 1;
                reg_tx_data <= rdata[31:24];
                REGISTER_TEST <= register[4][31:0];
                reg_inst <= inst;
                pc_p4 <= pc + 4;

                stage <= ST_ID;
            end

            ST_ID: begin
                opcode = reg_inst[0+:7];
                rd = reg_inst[7+:5];
                funct3 = reg_inst[12+:3];
                rs1 <= reg_inst[19:15];
                rs2 <= reg_inst[24:20];
                funct7 = reg_inst[25+:7];

                i_imm <= reg_inst[20+:12];
                s_imm <= { reg_inst[31:25], reg_inst[11:7] };
                b_imm = { reg_inst[25+:7], reg_inst[7+:5] };
                u_imm = reg_inst[31:12];
                j_imm = {{12{reg_inst[31]}}, reg_inst[19:12], reg_inst[20], reg_inst[30:25], reg_inst[24:21], 1'b0};

                stage <= ST_EX;
            end

            ST_EX: begin
                if ((reg_inst & `MASK_OP_SW) == `OP_SW)
                    alu_out = rs1_data + s_imm_sext;
                if ((reg_inst & `MASK_OP_LW) == `OP_LW)
                    alu_out = rs1_data + i_imm_sext;
                if ((reg_inst & `MASK_OP_LUI) == `OP_LUI) begin
                    reg_wb_data[31:12] = u_imm[31:12];
                    reg_wb_wen = 1;
                end
                if ((reg_inst & `MASK_OP_ADDI) == `OP_ADDI) begin
                    reg_wb_data = rs1_data + i_imm_sext;
                    reg_wb_wen = 1;
                end
                if ((reg_inst & `MASK_OP_AUIPC) == `OP_AUIPC) begin
                    pc_p4 <= pc_p4 + (u_imm_sext << 12);
                    reg_wb_data <= pc_p4 + (u_imm_sext << 12);
                    reg_wb_wen = 1;
                end
                if ((reg_inst & `MASK_OP_JAL) == `OP_JAL) begin
                    reg_wb_data <= pc + 4;
                    reg_wb_wen = 1;
                    pc_p4 <= pc_p4 + j_imm;
                end
                if ((reg_inst & `MASK_OP_JALR) == `OP_JALR) begin
                    reg_wb_data <= pc + 4;
                    reg_wb_wen = 1;
                    pc_p4 <= (rs1_data + i_imm_sext) & 1'b0;
                end
                if ((reg_inst & `MASK_OP_BEQ) == `OP_BEQ) begin
                    if (rs1_data == rs2_data) begin
                        
                    end
                end

                stage <= ST_ACCESS;
            end

            ST_ACCESS: begin
                reg_raddr = alu_out;
                reg_wen = opcode == `OP_SW;
                reg_wdata = rs2_data;

                stage <= ST_WB;
            end

            ST_WB: begin

                if (opcode == `OP_LW)
                    register[rd] <= rdata;
                if (reg_wb_wen == 1)
                    register[rd] <= reg_wb_data;

                reg_wb_wen = 0;
                pc = pc_p4;
                alu_out = 0;
                reg_wen = 0;
                reg_iaddr = pc_p4;

                stage <= ST_IF;
            end
        endcase
    end

    assign rs1_data = register[rs1];
    assign rs2_data = register[rs2];

    assign i_imm_sext = { {20{i_imm[11]}}, i_imm[10:0] };
    assign s_imm_sext = { {20{s_imm[11]}}, s_imm[10:0] };
    assign u_imm_sext = { {12{u_imm[19]}}, u_imm[18:0] };

    assign tx_start = reg_tx_start;
    assign tx_data = reg_tx_data;

    assign iaddr = reg_iaddr;
    assign raddr = reg_raddr;
    assign wdata = reg_wdata;
    assign wen = reg_wen;

endmodule
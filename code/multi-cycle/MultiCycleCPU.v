`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Class: Fundamentals of Digital Logic and Processor
// Designer: Shulin Zeng
//
// Create Date: 2021/04/30
// Design Name: MultiCycleCPU
// Module Name: MultiCycleCPU
// Project Name: Multi-cycle-cpu
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module MultiCycleCPU (reset,
                      clk);
    //Input Clock Signals
    input reset;
    input clk;
    
    //--------------Your code below-----------------------
    
    // Controller
    reg [5:0] OpCode;
    reg [4:0] Rs;
    reg [4:0] Rt;
    reg [4:0] Rd;
    reg [4:0] Shamt;
    reg [5:0] Funct;
    reg [1:0] PCSrc;
    reg [3:0] ALUOp;
    reg [15:0] Immediate;
    reg [26:0] Address_j;
    
    wire PCWrite;
    reg PCWrite_with_cond;
    wire Branch;
    wire RegWrite;
    wire IorD;
    wire IRWrite;
    wire [1:0] RegDst;
    wire MemRead;
    wire MemWrite;
    wire [1:0] MemtoReg;
    wire ALUSrc1;
    wire ALUSrc2;
    wire ExtOp;
    wire LuiOp;
    
    Controller controller(
    .reset(reset),
    .clk(clk),
    .OpCode(OpCode),
    .Funct(Funct),
    .PCWrite(PCWrite),
    .PCWriteCond(PCWriteCond),
    .IorD(IorD),
    .IRWrite(IRWrite),
    .PCSrc(PCSrc),
    .Branch(Branch),
    .RegWrite(RegWrite),
    .RegDst(RegDst),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .MemtoReg(MemtoReg),
    .ALUSrcA(ALUSrc1),
    .ALUSrcB(ALUSrc2),
    .ALUOp(ALUOp),
    .ExtOp(ExtOp),
    .LuiOp(LuiOp)
    );
    
    // PC
    reg [31:0] PC_i;
    wire [31:0] PC_o;
    PC pc(
    .reset(reset),
    .clk(clk),
    .PCWrite(PCWrite_with_cond),
    .PC_i(PC_i),
    .PC_o(PC_o)
    );
    
    reg [31:0] Address;
    wire [31:0] Write_data;
    wire [31:0] Mem_data;
    wire [31:0] ALUOut;
    wire [31:0] ALUOut_register_data;
    
    // * Mux of choose Data or Instruction in memory
    always @(*) begin
        if (IorD == 1'b0) begin // load instruction
            Address[31:0] <= PC_o[31:0];
        end
        else begin
            Address[31:0] <= ALUOut_register_data[31:0];
        end
    end
    
    // memory
    InstAndDataMemory instanddatamemory(
    .reset(reset),
    .clk(clk),
    .Address(Address),
    .Write_data(Write_data),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .Mem_data(Mem_data)
    );
    
    // instruction register
    InstReg instreg(
    .reset(reset),
    .clk(clk),
    .IRWrite(IRWrite),
    .Instruction(Mem_data),
    .OpCode(OpCode),
    .rs(Rs),
    .rt(Rt),
    .rd(Rd),
    .Shamt(Shamt),
    .Funct(Funct)
    );

    always @(*) begin
        Immediate[15:0] <= {Rd[5:0], Shamt[4:0], Funct[5:0]};
        Address_j[26:0] <= {Rt[4:0], Rs[4:0], Immediate[15:0]};
    end
    
    // memory data register
    wire [31:0] Data;
    RegTemp regtemp(
    .reset(reset),
    .clk(clk),
    .Data_i(Mem_data),
    .Data_o(Data)
    );
    
    // * Mux of reg source
    wire [31:0] Read_data1, Read_data2;
    reg [4:0] Read_register1, Read_register2, Write_register;
    always @(*) begin
        case(RegDst)
            2'b00:begin
                Write_register <= Rt;
            end
            
            2'b01:begin
                Write_register <= Rd;
            end
            
            default:begin
                Write_register <= 5'b11111; // ra
            end
        endcase
    end
    
    // * Mux of write data source
    reg [31:0] Write_register_data;
    always @(*) begin
        case(MemtoReg)
            1'b0:begin
                Write_register_data[31:0] <= Data[31:0];
            end
            
            1'b1:begin
                Write_register_data[31:0] <= ALUOut[31:0];
            end
        endcase
    end
    
    wire [31:0] ImmExtOut;
    wire [31:0] ImmExtShift;
    
    // immediate extension
    ImmProcess immprocess(
    .ExtOp(ExtOp),
    .LuiOp(LuOp),
    .Immediate(Immediate),
    .ImmExtOut(ImmExtOut),
    .ImmExtShift(ImmExtShift)
    );
    
    
    // register file
    RegisterFile registerfile(
    .reset(reset),
    .clk(clk),
    .Read_register1(Read_register1),
    .Read_register2(Read_register2),
    .Write_register(Write_register),
    .Write_data(Write_register_data),
    .Read_data1(Read_data1),
    .Read_data2(Read_data2)
    );
    
    //? register of Read Data1(A) and Read Data2(B)
    wire [31:0] Read_register_data1;
    wire [31:0] Read_register_data2;
    RegTemp Read_data_1_Register(reset, clk, Read_data1, Read_register_data1);
    RegTemp Read_data_2_Register(reset, clk, Read_data2, Read_data2_register);

    // ALU controller
    wire [4:0] ALUConf;
    wire Sign;
    ALUControl aluControl(
    .ALUOp(ALUOp),
    .Funct(Funct),
    .ALUConf(ALUConf),
    .Sign(Sign)
    );

    reg [31:0] in1;
    reg [31:0] in2;

    // * Mux of ALU in1
    always @(*) begin
        case(ALUSrc1)
            2'b00:begin // use PC
                in1 <= PC_o;
            end 

            2'b01:begin // use Read_register_data1
                in1 <= Read_register_data1;
            end

            2'b10:begin // use shamt
                in1 <= Shamt;
            end

            default:begin
                in1 <= Read_register_data1;
            end

        endcase
    end

    // * Mux of ALU in2
    always @(*) begin
        case(ALUSrc2)
            2'b00:begin
                in2 <= Read_register_data2; // use Read_register_data1
            end

            2'b01:begin
                in2 <= 32'h4; // PC <= PC + 4
            end

            2'b10:begin
                in2 <= ImmExtOut; // imm without shift
            end

            2'b11:begin
                in2 <= ImmExtShift; // imm after shift
            end

            default:begin
                in2 <= Read_register_data2;
            end

        endcase
    end
    
    // ALU
    wire Zero;
    ALU ALU(
        .ALUConf(ALUConf),
        .Sign(Sign),
        .in1(in1),
        .in2(in2),
        .Zero(Zero),
        .Result(ALUOut)
    );

    //? register of ALUOut
    RegTemp ALU_Register(
        reset, clk, ALUOut, ALUOut_register_data
    );


    // * Mux of PC
    // TODO do not understand the logic
    always @(*) begin
        case(PCSrc)
        2'b00:begin // from ALU(include PC+4 and jr&jalr)
            PC_i[31:0] <= ALUOut[31:0];
        end

        2'b01:begin // beq
            PC_i[31:0] <= ALUOut_register_data[31:0];
        end

        2'b10:begin // j & jal
            PC_i[31:0] <= {PC_o[31:28],Address_j,2'b00};
        end

        default:begin
            PC_i[31:0] <= ALUOut_register_data[31:0];
        end

        endcase
    end

    // control signal of PC
    always @(*) begin
        if((Zero && PCWriteCond)||PCWrite)begin
            PCWrite_with_cond <= 1;
        end
        else begin
            PCWrite_with_cond <= 0;
        end
    end

    
    //--------------Your code above-----------------------
endmodule

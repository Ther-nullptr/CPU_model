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
    wire [5:0] OpCode;
    wire [4:0] Rs;
    wire [4:0] Rt;
    wire [4:0] Rd;
    wire [4:0] Shamt;
    wire [5:0] Funct;
    wire [1:0] PCSrc;
    wire [3:0] ALUOp;
    wire [15:0] Immediate;
    wire [26:0] Address_j;
    
    wire PCWrite;
    wire PCWrite_with_cond;
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
    wire [31:0] PC_i;
    wire [31:0] PC_o;
    PC pc(
    .reset(reset),
    .clk(clk),
    .PCWrite(PCWrite_with_cond),
    .PC_i(PC_i),
    .PC_o(PC_o)
    );
    
    wire [31:0] Address;
    wire [31:0] Write_data;
    wire [31:0] Mem_data;
    wire [31:0] ALUOut;
    wire [31:0] ALUOut_register_data;
    
    // * Mux of choose Data or Instruction in memory
    assign Address[31:0] =
        (IorD == 1'b0)? PC_o[31:0] : 
        ALUOut_register_data[31:0];
    
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

    
    assign Immediate[15:0] = {Rd[5:0], Shamt[4:0], Funct[5:0]};
    assign Address_j[26:0] = {Rt[4:0], Rs[4:0], Immediate[15:0]};
    
    // memory data register
    wire [31:0] Data;
    RegTemp regtemp(
    .reset(reset),
    .clk(clk),
    .Data_i(Mem_data),
    .Data_o(Data)
    );
    
    // * Mux of wire source
    wire [31:0] Read_data1, Read_data2;
    wire [4:0] Read_register1, Read_register2, Write_register;

    assign Write_register = 
        (RegDst == 2'b00)? Rt:
        (RegDst == 2'b01)? Rd:
        5'b11111;
    
    // * Mux of write data source
    wire [31:0] Write_register_data;
    assign Write_register_data = 
        (MemtoReg == 1'b0)? Data:
        ALUOut;
    
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

    wire [31:0] in1;
    wire [31:0] in2;

    // * Mux of ALU in1
    assign in1 = 
        (ALUSrc1 == 2'b00)? PC_o:
        (ALUSrc1 == 2'b10)? Shamt:
        Read_register_data1;

    // * Mux of ALU in2
    assign in2 = 
        (ALUSrc2 == 2'b00)? Read_register_data2:
        (ALUSrc2 == 2'b01)? 32'h4:
        (ALUSrc2 == 2'b10)? ImmExtOut:
        ImmExtShift;
    
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
    assign PC_i = 
        (PCSrc == 2'b00)? ALUOut:
        (PCSrc == 2'b01)? ALUOut_register_data:
        {PC_o[31:28],Address_j,2'b00};

    // generate control signal of PC
    assign PCWrite_with_cond = 
        ((Zero && PCWriteCond)||PCWrite)? 1'b1:
        1'b0;
    
    //--------------Your code above-----------------------
endmodule

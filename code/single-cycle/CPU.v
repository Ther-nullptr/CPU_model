module CPU(reset,
           clk);
    input reset, clk;
    
    //--------------Your code below-----------------------
    
    // PC
    reg [31:0] PC_i;
    wire [31:0] PC_o;
    PC pc(
        .reset(reset),
        .clk(clk),
        .PC_i(PC_i),
        .PC_o(PC_o)
        );
    // TODO: PC_Write useful in single cycle?

    // instruction memory
    wire [31:0] Instruction;
    InstructionMemory instructionmemory(
        .Address(PC_o),
        .Instruction(Instruction)
    );

    // select the instruction type
    reg [5:0] OpCode;
    reg [4:0] Rs;
    reg [4:0] Rt;
    reg [4:0] Rd;
    reg [4:0] Shamt;
    reg [5:0] Funct;
    reg [15:0] Immediate;
    reg [26:0] Address;
    always @(*) begin
        OpCode <= Instruction[31:26];
        case(OpCode)
            6'b000000:begin  // R
                Rs <= Instruction[25:21];
                Rt <= Instruction[20:16];
                Rd <= Instruction[15:11];
                Shamt <= Instruction[10:6];
                Funct <= Instruction[5:0];
            end

            6'b0001x:begin
                Rs <= Instruction[25:21];
                Rt <= Instruction[20:16];
                Immediate <= Instruction[15:0];
            end

            default:begin
                Address <= Instruction[25:0];
            end
            
        endcase
    end

    // controller
    wire [1:0] PCSrc;
    wire Branch;
    wire RegWrite;
    wire [1:0] RegDst;
    wire MemRead;
    wire MemWrite;
    wire [1:0] MemtoReg;
    wire ALUSrc1;
    wire ALUSrc2;
    wire ExtOp;
    wire LuOp;
    Control control(
        .OpCode(OpCode),
        .Funct(Funct),
        .PCSrc(PCSrc),
        .Branch(Branch),
        .RegWrite(RegWrite),
        .RegDst(RegDst),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        .ALUSrc1(ALUSrc1),
        .ALUSrc2(ALUSrc2),
        .ExtOp(ExtOp),
        .LuOp(LuOp)
        );
    
    // * Mux of PC
    // ! the adder of PC(PC <= PC + 4)
    // ! the adder of PC(PC <= PC + 4 + {SignExt(imm16),2b00})
    wire Zero;
    wire [31:0] ImmExtOut;
    wire [31:0] ImmExtShift;
    wire [31:0] Read_data1, Read_data2;
    always @(*) begin
        PC_i <= PC_o + 4; // add 4 first
        case(PCSrc)
            2'b00:begin
                if(Branch & Zero) begin
                    PC_i <= PC_i + ImmExtShift; 
                end
                else begin
                    PC_i <= PC_i;
                end
            end

            2'b01: begin // j or jal
                PC_i <= {PC_i[31:28], Instruction[26:0], 2'b00};
            end

            2'b10: begin
                PC_i <= Read_data1;
            end

            default: begin
                PC_i <= PC_i;
            end
        endcase
    end
    
    // * Mux of reg source
    reg [4:0] Read_register1, Read_register2, Write_register;
    reg [31:0] Write_data_register;
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

    // register file
    RegisterFile registerfile(
        .reset(reset),
        .clk(clk),
        .Read_register1(Read_register1),
        .Read_register2(Read_register2),
        .Write_register(Write_register),
        .Write_data(Write_data_register),
        .Read_data1(Read_data1),
        .Read_data2(Read_data2)
    );
    
    // immediate extension
    // ! it can directly generate the imm32 and left shift it
    ImmProcess immprocess(
        .ExtOp(ExtOp),
        .LuiOp(LuOp),
        .Immediate(Immediate),
        .ImmExtOut(ImmExtOut),
        .ImmExtShift(ImmExtShift)
    );
    
    
    // * Mux of imm or reg
    reg [31:0] in1;
    reg [31:0] in2;
    always @(*) begin
        case(ALUSrc1)
            2'b0:begin
                in1 <= Read_data1;
            end

            2'b1:begin
                in1 <= Shamt; // load the shamt
            end
        endcase

        case(ALUSrc2)
            2'b0:begin
                in2 <= Read_data2;
            end

            2'b1:begin
                in2 <= ImmExtOut;
            end
        endcase
    end
    
    // ALU controller
    wire [4:0] ALUCtrl;
    wire Sign;
    ALUControl alucontrol(
        .OpCode(OpCode),
        .Funct(Funct),
        .ALUCtrl(ALUCtrl),
        .Sign(Sign)
    );
    
    // ALU
    wire [31:0] Out;
    
    ALU alu(
        .ALUCtrl(ALUCtrl),
        .in1(in1),
        .in2(in2),
        .Sign(Sign),
        .out(Out),
        .zero(Zero)
    );
    
    // data memory
    wire [31:0] Read_data;
    DataMemory datamemory(
        .reset(reset),
        .clk(clk),
        .Address(Out),
        .Write_data(Read_data2),
        .Read_data(Read_data),
        .MemRead(MemRead),
        .MemWrite(MemWrite)
    );
    
    // * Mux of ALU or mem
    always @(*) begin
        case(MemtoReg) 
            1'b0: begin
                Write_data_register <= Out;
            end
            1'b1: begin
                Write_data_register <= Read_data;
            end
        endcase
    end
    
    //--------------Your code above-----------------------
    
endmodule
    

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Class: Fundamentals of Digital Logic and Processor
// Designer: Shulin Zeng, Shang Yang
//
// Create Date: 2021/04/30
// Design Name: MultiCycleCPU
// Module Name: Controller
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


module Controller(reset,
                  clk,
                  OpCode,
                  Funct,
                  PCWrite,
                  PCWriteCond,
                  IorD,
                  MemWrite,
                  MemRead,
                  IRWrite,
                  MemtoReg,
                  RegDst,
                  RegWrite,
                  ExtOp,
                  LuiOp,
                  ALUSrcA,
                  ALUSrcB,
                  ALUOp,
                  PCSource);
    //Input Clock Signals
    input reset;
    input clk;
    //Input Signals
    input  [5:0] OpCode;
    input  [5:0] Funct;
    //Output Control Signals
    output reg PCWrite;
    output reg PCWriteCond;
    output reg IorD;
    output reg MemWrite;
    output reg MemRead;
    output reg IRWrite;
    output reg [1:0] MemtoReg;
    output reg [1:0] RegDst;
    output reg RegWrite;
    output reg ExtOp;
    output reg LuiOp;
    output reg [1:0] ALUSrcA;
    output reg [1:0] ALUSrcB;
    output reg [3:0] ALUOp;
    output reg [1:0] PCSource;
    
    reg [2:0] state; //current state
    reg [2:0] next_state; //next_state
    parameter sIF = 3'b0 ,sID = 3'b1;
    
    //--------------Your code below-----------------------
    initial begin
        ALUOp <= 3'b000;
    end
    
    always @(posedge reset or posedge clk)
    begin
        if (reset)
        begin
            state       <= 3'b0;
            next_state  <= 3'b0;
            PCWrite     <= 1'b0;
            PCWriteCond <= 1'b0;
            IorD        <= 1'b0;
            MemWrite    <= 1'b0;
            MemRead     <= 1'b0;
            IRWrite     <= 1'b0;
            MemtoReg    <= 2'b00;
            RegDst      <= 2'b0;
            RegWrite    <= 1'b0;
            ExtOp       <= 1'b0;
            LuiOp       <= 1'b0;
            ALUSrcA     <= 2'b0;
            ALUSrcB     <= 2'b0;
            PCSource    <= 2'b0;
        end
        else
        begin
            if (next_state == sIF)
            begin
                
                state      <= next_state;
                next_state <= next_state + 3'b1;
                
                MemRead  <= 1'b1;
                IRWrite  <= 1'b1;
                PCWrite  <= 1'b1;
                PCSource <= 2'b00;
                ALUSrcA  <= 2'b00;
                IorD     <= 1'b0;
                ALUSrcB  <= 2'b01;
                
                PCWriteCond <= 1'b0;
                MemWrite    <= 1'b0;
                MemtoReg    <= 2'b00;
                RegDst      <= 2'b0;
                RegWrite    <= 1'b0;
                ExtOp       <= 1'b0;
                LuiOp       <= 1'b0;
            end
            
            else if (next_state == sID)
            begin
            state      <= next_state;
            next_state <= next_state + 3'b1;
            ALUSrcA    <= 2'b00;
            ALUSrcB    <= 2'b11;
            ExtOp      <= 1'b1;
            
            PCWrite     <= 1'b0;
            PCWriteCond <= 1'b0;
            IorD        <= 1'b0;
            MemWrite    <= 1'b0;
            MemRead     <= 1'b0;
            IRWrite     <= 1'b0;
            MemtoReg    <= 2'b00;
            RegDst      <= 2'b0;
            RegWrite    <= 1'b0;
            LuiOp       <= 1'b0;
            PCSource    <= 2'b0;
        end
        else if (next_state == 3'd2)
        begin
        state <= next_state;
        case(OpCode)
            6'h00: //* R type
            begin
                ALUSrcA <= (Funct == 6'h00 || Funct == 6'h02 || Funct == 6'h03) ? 2'b10 : 2'b01;
                ALUSrcB <= 2'b00;
                case(Funct)
                    6'h08: //* jr
                    begin
                        PCSource   <= 2'b00;
                        PCWrite    <= 1'b1;
                        next_state <= sIF;
                    end
                    6'h09: //* jalr
                    begin
                        PCSource   <= 2'b00;
                        PCWrite    <= 1'b1;
                        next_state <= sIF;
                        
                        RegDst   <= 2'b01;
                        MemtoReg <= 2'b10;
                        RegWrite <= 1'b1;
                    end
                    default:
                    begin
                        next_state <= next_state + 3'b1;
                    end
                endcase
            end
            6'h23,6'h2b,6'h0f,6'h08,6'h09,6'h0c,6'h0b,6'h0a: //* simple I type
            begin
                ALUSrcA <= 2'b01;
                ALUSrcB <= 2'b10;
                ExtOp   <= ((OpCode == 6'h0c)? 0 : 1);
                LuiOp   <= ((OpCode == 6'h0f)? 1 : 0);
                next_state <= next_state +3'b1;
            end
            6'h04: //* beq
            begin
                PCWriteCond <= 1'b1;
                ALUSrcA     <= 2'b01;
                ALUSrcB     <= 2'b00;
                PCSource    <= 2'b01;
                next_state  <= sIF;
            end
            6'h02: //* j
            begin
                PCWrite    <= 1'b1;
                PCSource   <= 2'b10;
                next_state <= sIF;
            end
            6'h03: //* jal
            begin
                PCWrite  <= 1'b1;
                PCSource <= 2'b10;
                RegDst   <= 2'b10;
                MemtoReg <= 2'b10;
                RegWrite <= 1'b1;
                
                next_state <= sIF;
            end
            default:
            begin
                next_state <= sIF;
            end
        endcase
    end
    else if (next_state == 3'd3)
    begin
    state <= next_state;
    case(OpCode)
        6'h00: //* R type
        begin
            RegWrite   <= 1'b1;
            RegDst     <= 2'b01;
            MemtoReg   <= 2'b01;
            next_state <= sIF;
        end
        6'h2b: //* sw
        begin
            MemWrite   <= 1'b1;
            IorD       <= 1'b1;
            next_state <= sIF;
        end
        6'h08,6'h09,6'h0c,6'h0b,6'h0a,6'h0f: //* simple I type
        begin
            RegWrite   <= 1'b1;
            RegDst     <= 2'b00;
            MemtoReg   <= 2'b01;
            next_state <= sIF;
        end
        6'h23: //* lw
        begin
            MemRead    <= 1'b1;
            IorD       <= 1'b1;
            IRWrite    <= 1'b0;
            next_state <= next_state +3'b001;
        end
        default:
        begin
            next_state <= sIF;
        end
    endcase
    
    end
    else if (next_state == 3'd4)
    begin
    state <= next_state;
    case(OpCode)
        6'h23: //* lw
        begin
            RegWrite   <= 1'b1;
            RegDst     <= 2'b00;
            MemtoReg   <= 2'b00;
            next_state <= sIF;
        end
        default:
        begin
            next_state <= sIF;
        end
    endcase
    end
    end
    end
    
    
    //--------------Your code below-----------------------
    //ALUOp
    parameter I1_op    = 3'b000; // I type: lw,sw
    parameter I2_op    = 3'b001; // I type: beq
    parameter R_op     = 3'b010; // R type
    parameter and_op   = 3'b011; // andi
    parameter slt_op   = 3'b100; // slti, sltiu
    parameter addiu_op = 3'b101;
    always @(*) begin
        ALUOp[3] <= OpCode[0]; // we can find that the opcode of unsigned instructions(I type) is odd
        if (state == sIF || state == sID) begin // the first two stages, ALUOp is set as 0
            ALUOp[2:0] <= I1_op;
        end
        else begin
            case(OpCode)
                6'h00:begin // R type
                    ALUOp[2:0] <= R_op;
                end
                6'h04:begin // beq
                    ALUOp[2:0] <= I2_op;
                end
                6'h0c:begin // andi
                    ALUOp[2:0] <= and_op;
                end
                6'h0a:begin // slti
                    ALUOp[2:0] <= slt_op;
                end
                6'h0b:begin // sltiu
                    ALUOp[2:0] <= slt_op;
                end
                6'h09:begin // addiu
                    ALUOp[2:0] <= addiu_op;
                end
                default:begin
                    ALUOp[2:0] <= I1_op;
                end
            endcase
        end
    end
    
    //--------------Your code above-----------------------
    
endmodule

`timescale 1ns / 1ps
module Control(OpCode,
               Funct,
               PCSrc,
               Branch,
               RegWrite,
               RegDst,
               MemRead,
               MemWrite,
               MemtoReg,
               ALUSrc1,
               ALUSrc2,
               ExtOp,
               LuOp);
    input [5:0] OpCode;
    input [5:0] Funct;
    output reg [1:0] PCSrc;
    output reg Branch;
    output reg RegWrite;
    output reg [1:0] RegDst;
    output reg MemRead;
    output reg MemWrite;
    output reg [1:0] MemtoReg;
    output reg ALUSrc1;
    output reg ALUSrc2;
    output reg ExtOp;
    output reg LuOp;
    
    // Your code below
    
    // MIPS Opcodes
    parameter lw_op  = 6'h23; // load word(I)
    parameter sw_op  = 6'h2b; // save word(I)
    parameter lui_op = 6'h0f; // load upper 16 bits of immediate(I)
    
    parameter add_op   = 6'h00; // add(R)
    parameter addu_op  = 6'h00; // add unsigned #! u(R)
    parameter sub_op   = 6'h00; // sub(R)
    parameter subu_op  = 6'h00; // sub unsigned #! u(R)
    parameter addi_op  = 6'h08; // add immediate(I)
    parameter addiu_op = 6'h09; // add immediate unsigned #! u(I)
    
    parameter and_op   = 6'h00; // and(R)
    parameter or_op    = 6'h00; // or(R)
    parameter xor_op   = 6'h00; // xor(R)
    parameter nor_op   = 6'h00; // nor(R)
    parameter andi_op  = 6'h0c; // and immediate(I)
    parameter sll_op   = 6'h00; // shift left logical(R)
    parameter srl_op   = 6'h00; // shift right logical(R)
    parameter sra_op   = 6'h00; // shift right algorithm(R)
    parameter slt_op   = 6'h00; // set on less than(R)
    parameter sltu_op  = 6'h00; // set on less than unsigned #! u(R)
    parameter slti_op  = 6'h0a; // set on less than immediate(I)
    parameter sltiu_op = 6'h0b; // set on less than immediate unsigned #! u(I)
    
    parameter beq_op  = 6'h04; // branch equal(I)
    parameter j_op    = 6'h02; // jump(J)
    parameter jal_op  = 6'h03; // jump and link(J)
    parameter jr_op   = 6'h00; // jump register(R)
    parameter jalr_op = 6'h00; // (R)
    
    parameter R_op = 6'h00; // represent for all R-types
    
    initial begin
        PCSrc    <= 0;
        Branch   <= 0;
        RegWrite <= 0;
        RegDst   <= 0;
        MemRead  <= 0;
        MemWrite <= 0;
        MemtoReg <= 0;
        ALUSrc1  <= 0;
        ALUSrc2  <= 0;
        ExtOp    <= 0;
        LuOp     <= 0;
    end
    
    always @(*) begin
        // PCSrc
        case(OpCode)
            j_op: begin // all the R type
                PCSrc <= 2'b01;
            end
            
            jal_op: begin
                PCSrc <= 2'b01;
            end
            
            jr_op: begin
                PCSrc <= 2'b10;
            end
            
            jalr_op: begin
                PCSrc <= 2'b10;
            end
            
            default: begin
                PCSrc <= 2'b00;
            end
        endcase
        
        // Branch
        case(OpCode)
            beq_op:begin
                Branch <= 1'b1;
            end
            
            j_op: begin // all the R type
                PCSrc <= 1'bx;
            end
            
            jal_op: begin
                PCSrc <= 1'bx;
            end
            
            jr_op: begin
                PCSrc <= 1'bx;
            end
            
            jalr_op: begin
                PCSrc <= 1'bx;
            end
            
            default:begin
                PCSrc <= 1'b0;
            end
        endcase
        
        // RegWrite
        case(OpCode)
            sw_op:begin
                RegWrite <= 0;
            end
            
            beq_op:begin
                RegWrite <= 0;
            end
            
            j_op:begin
                RegWrite <= 0;
            end
            
            jr_op:begin
                RegWrite <= 0;
            end
            
            default:begin
                RegWrite <= 1;
            end
        endcase
        
        // RegDst
        case(OpCode)
            R_op:begin
                RegDst <= 2'b01;
            end
            
            jal_op:begin
                RegDst <= 2'b10;
            end
            
            jalr_op:begin
                RegDst <= 2'b10;
            end
            
            j_op:begin
                RegDst <= 2'bxx;
            end
            
            jr_op:begin
                RegDst <= 2'bxx;
            end
            
            sw_op:begin
                RegDst <= 2'bxx;
            end
            
            beq_op:begin
                RegDst <= 2'bxx;
            end
            
            default:begin
                RegDst <= 2'b00;
            end
        endcase
        
        // MemRead
        case(OpCode)
            lw_op:begin
                MemRead <= 1;
            end
            
            default:begin
                MemRead <= 0;
            end
        endcase
        
        // MemWrite
        case(OpCode)
            sw_op:begin
                MemRead <= 1;
            end
            
            default:begin
                MemRead <= 0;
            end
        endcase
        
        // MemtoReg
        case(OpCode)
            lw_op:begin
                MemtoReg <= 2'b01;
            end
            
            jal_op:begin
                MemtoReg <= 2'b01;
            end
            
            jalr_op:begin
                MemtoReg <= 2'b01;
            end
            
            sw_op:begin
                MemtoReg <= 2'b01;
            end
            
            beq_op:begin
                MemtoReg <= 2'b01;
            end
            
            j_op:begin
                MemtoReg <= 2'b01;
            end
            
            jr_op:begin
                MemtoReg <= 2'b01;
            end
        endcase
        
        // ALUSrc1
        case(OpCode)
            sll_op:begin
                ALUSrc1 <= 1;
            end

            srl_op:begin
                ALUSrc1 <= 1;
            end

            sra_op:begin
                ALUSrc1 <= 1;
            end

            default:begin
                ALUSrc1 <= 0;
            end
        endcase

        // ALUSrc2
        case(OpCode)
            R_op:begin
                ALUSrc2 <= 1;
            end

            default:begin
                ALUSrc2 <= 0;
            end
        endcase

        // ExtOp
        case(OpCode)
            andi_op:begin
                ExtOp <= 0;
            end
            
            default:begin
                ExtOp <= 1;
            end
        endcase

        // LuOp
        case(OpCode)
            lui_op:begin
                LuOp <= 1;
            end

            default:begin
                LuOp <= 0;
            end
        endcase
    end
    // Your code above
endmodule

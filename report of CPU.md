# 处理器第二次大作业

## 单周期CPU

### 控制器模块设计

| Ins.     | PCSrc[1:0] | Branch | RegWrite | RegDst[1:0] | MemRead | MemWrite | MemtoReg[1:0] | ALUSrc1 | ALUSrc2 | ExtOp | LUOp |
| -------- | ---------- | ------ | -------- | ----------- | ------- | -------- | ------------- | ------- | ------- | ----- | ---- |
| lw(I)    | 00         | 0      | 1        | 00          | 1       | 0        | 01            | 0       | 1       | 1     | 0    |
| sw(I)    | 00         | 0      | 0        | XX          | 0       | 1        | XX            | 0       | 1       | 1     | 0    |
| lui(i)   | 00         | 0      | 1        | 00          | 0       | 0        | 11            | 0       | 1       | x     | 1    |
| add(R)   | 00         | 0      | 1        | 01          | 0       | 0        | 00            | 0       | 0       | x     | x    |
| addu(R)  | 00         | 0      | 1        | 01          | 0       | 0        | 00            | 0       | 0       | x     | x    |
| sub(R)   | 00         | 0      | 1        | 01          | 0       | 0        | 00            | 0       | 0       | x     | x    |
| subu(R)  | 00         | 0      | 1        | 01          | 0       | 0        | 00            | 0       | 0       | x     | x    |
| addi(I)  | 00         | 0      | 1        | 00          | 0       | 0        | 00            | 0       | 1       | 1     | 0    |
| addiu(I) | 00         | 0      | 1        | 00          | 0       | 0        | 00            | 0       | 1       | 1     | 0    |
| and(R)   | 00         | 0      | 1        | 01          | 0       | 0        | 00            | 0       | 0       | x     | x    |
| or(R)    | 00         | 0      | 1        | 01          | 0       | 0        | 00            | 0       | 0       | x     | x    |
| xor(R)   | 00         | 0      | 1        | 01          | 0       | 0        | 00            | 0       | 0       | x     | x    |
| nor(R)   | 00         | 0      | 1        | 01          | 0       | 0        | 00            | 0       | 0       | x     | x    |
| andi(I)  | 00         | 0      | 1        | 00          | 0       | 0        | 00            | 0       | 1       | 0     | 0    |
| sll(R)   | 00         | 0      | 1        | 01          | 0       | 0        | 00            | 1       | 0       | x     | x    |
| srl(R)   | 00         | 0      | 1        | 01          | 0       | 0        | 00            | 1       | 0       | x     | x    |
| sra(R)   | 00         | 0      | 1        | 01          | 0       | 0        | 00            | 1       | 0       | x     | x    |
| slt(R)   | 00         | 0      | 1        | 01          | 0       | 0        | 00            | 0       | 0       | x     | x    |
| sltu(R)  | 00         | 0      | 1        | 01          | 0       | 0        | 00            | 0       | 0       | x     | x    |
| slti(I)  | 00         | 0      | 1        | 00          | 0       | 0        | 00            | 0       | 1       | 1     | 0    |
| sltiu(I) | 00         | 0      | 1        | 00          | 0       | 0        | 00            | 0       | 1       | 1     | 0    |
| beq(I)   | 00         | 1      | 0        | XX          | 0       | 0        | XX            | 0       | 0       | 1     | 0    |
| j(J)     | 01         | x      | 0        | XX          | 0       | 0        | XX            | 0       | x       | x     | x    |
| jal(J)   | 01         | x      | 1        | 10          | 0       | 0        | 10            | 0       | x       | x     | x    |
| jr(R)    | 10         | x      | 0        | XX          | 0       | 0        | XX            | 0       | x       | x     | x    |
| jalr(R)  | 10         | x      | 1        | 10          | 0       | 0        | 10            | 0       | x       | x     | x    |

> 各控制信号的简要分析：
>
> 1. PCSrc：
>    * 若为00，则`PC <= PC + 4`。此时如果`Branch & Zero`为1，则PC <= PC + 4 + {SignExt[imm16], 2b00};
>    * 若为01，则`PC <= {(PC + 4)[31:28],imm,00}`，即PC来源于立即数操作。
>    * 若为10，则PC需要从寄存器中读取。
> 2. Branch：是否为分支操作。
> 3. RegWrite：是否需要将结果写入寄存器。
> 4. RegDst：
>    * 若为00，则写入`$rt`。
>    * 若为01，则写入`$rd`。
>    * 若为10，则写入`$ra`，即将`PC+4`的地址写入寄存器`$ra`方便跳转。
> 5. MemRead：是否需要从数据存储器中读取数据。
> 6. MemWrite：是否需要从数据存储器中写入数据。
> 7. MemtoReg：
>    * 若为00，则寄存器的数据来源为ALU。
>    * 若为01，则寄存器的数据来源为数据存储器。
>    * 若为10，则寄存器的数据来源为`PC+4`。
>    * 若为11，则寄存器的数据来源为立即数扩展单元。
> 8. ALUSrc1：
>    * 若为0，则ALU in1的数据来源为寄存器。
>    * 若为1，则ALU in1的数据来源为shamt（即指令的[10:6]位）。
> 9. ALUSrc2：
>    * 若为0，则ALU in2的数据来源为寄存器。
>    * 若为1，则ALU in2的数据来源为符号扩展后的立即数。
> 10. ExtOp：是否进行符号位扩展。
> 11. LUop：是否进行lui操作。

### 数据通路设计

数据通路中所包含的多路选择器：

![image-20220524190110408](C:\Users\86181\AppData\Roaming\Typora\typora-user-images\image-20220524190110408.png)

1. PC更新值的mux，根据`PCSrc`的值选择新的PC来源于`PC+4`，分支地址，跳转地址还是寄存器。

```verilog
assign PC_i = 
        (PCSrc == 2'b01) ? {PC_default_next[31:28], Address, 2'b00} :
        (PCSrc == 2'b10) ? Read_data1 :
        (Branch & Zero) ? PC_default_next + ImmExtShift:
        PC_default_next;
```

2. 寄存器堆中写寄存器的mux，根据`regDst`的值选择写寄存器为`Rt`、`Rd`还是`Ra`。

```verilog
assign Write_register = 
        (regDst == 2'b00) ? Rt :
        (regDst == 2'b01) ? Rd :
        5'b11111;
```

3. ALU第一个操作数的mux，根据`ALUSrc1`的值选择该操作数为寄存器读取值还是shamt。

```verilog
assign in1 = 
        (ALUSrc1 == 1'b0) ? Read_data1 :
        Shamt;
```

4. ALU第二个操作数的mux，根据`ALUSrc2`的值选择该操作数为寄存器读取值还是立即数扩展值。

```verilog
assign in2 = 
        (ALUSrc2 == 1'b0) ? Read_data2 :
        ImmExtOut;
```

5. 控制写入数据的mux，根据`Memtoreg`的值选择写入寄存器的值来源于ALU输出，数据存储器，自增后的PC还是立即数扩展单元。

```verilog
assign Write_register_data = 
        (Memtoreg == 2'b00) ? Out :
        (Memtoreg == 2'b01) ? Read_data :
        (Memtoreg == 2'b10) ? PC_default_next :
        (Memtoreg == 2'b11) ? ImmExtOut
        Out;
```

### 汇编程序分析

该汇编代码的计算过程如下图注释所示：

```assembly
 addi $a0, $zero, 12123 # a0 = 12123
 addiu $a1, $zero, -12345 # a1 = -12345 
 sll $a2, $a1, 16 # a2 = (a1 << 16) = -809041920
 sra $a3, $a2, 16 # a3 = (a2 >> 16)(algorithm) = -12345
 beq $a3, $a1, L1 # a3 = a1, jump
 lui $a0, 22222
L1: 
 add $t0, $a2, $a0 # t0 = -809041920 + 12123 = -809029797
 sra $t1, $t0, 8 # t1 = (t0 >> 8)(algorithm) = -3160273
 addi $t2, $zero, -12123 # t2 = -12123
 slt $v0, $a0, $t2 # a0 > t2, v0 = 0
 sltu $v1, $a0, $t2 # a0 < (unsigned)t2, v1 = 1
Loop: 
 j Loop # stop at here
```

`$a0($4)`:12123; `$a1($5)`:-12345; `$a2($6)`:-809041920; `$a3($7)`:-12345; `$t0($8)`:-809029797; `$t1($9)`:-3160273; `$t2($10)`:-12123; `$v0($2)`:0; `$v1($3)`:1

仿真结果如下：

<img src="C:\Users\86181\AppData\Roaming\Typora\typora-user-images\image-20220523172045005.png" alt="image-20220523172045005" style="zoom:150%;" />

可以看到，所有寄存器的值都符合预期，单周期CPU设计正确。

## 多周期CPU

### 状态机控制器

多周期CPU状态转移图（大图见附件中的`status machine.pdf`）：

![image-20220524211352746](C:\Users\86181\AppData\Roaming\Typora\typora-user-images\image-20220524211352746.png)

多周期CPU有一些控制信号与单周期CPU不同，将**不同**的控制信号列举如下：

> 1. PCSrc： # TODO
>    * 若为00，则`PC <= PC+4`。
>    * 若为01，则`PC <= PC + 4 + {SignExt[imm16], 2b00}`(beq)。
>    * 若为10，则`PC <= {(PC + 4)[31:28],imm,00}`(j or jal)。
>    * 若为11，则`PC`来源于寄存器(jr or jalr)。
> 2. Branch：多周期CPU中省去了branch信号。
> 3. MemtoReg：
>    * 若为00，则寄存器的数据来源为数据存储器。
>    * 若为01，则寄存器的数据来源为ALU。
>    * 若为10，则寄存器的数据来源为`PC`（此时的PC已经自增过4，所以不需要再加4）。
> 4. ALUSrc1：#
>    * 若为00，则ALU in1的数据来源为PC。
>    * 若为01，则ALU in1的数据来源为寄存器。
>    * 若为10，则ALU in1的数据来源为shamt（即指令的[10:6]位）。
> 5. ALUSrc2：
>    * 若为00，则ALU in2的数据来源为寄存器（用于R型指令）。
>    * 若为01，则ALU in2的数据来源为4（用于PC的自增）。
>    * 若为10，则ALU in2的数据来源为符号扩展后的立即数（用于一般I型指令）。
>    * 若为11，则ALU in2的数据来源为符号扩展并移位的立即数（用于跳转）。
> 6. PCWrite：
>    * 若为0，则无法写入PC。
>    * 若为1，则可以写入PC（仅在IF阶段和执行j，jr，jal，jalr四个跳转指令时使用）。
> 7. PCWriteCond：在执行beq指令时为1，此时若ALU输出为0，则也可更新PC。
> 8. IorD：
>    * 若为0，则在存储器中访问指令地址。
>    * 若为1，则在存储器中访问数据地址。
> 9. IRWrite：若为1则将memory中的指令写入instruction register。

### ALU控制逻辑与功能实现

#### Controller

观察MIPS中的指令，可以发现以下规律：对于I型指令，如果该指令为执行无符号运算（或者我们不关心其是否有符号还是无符号），则其OpCode为奇数；反之为偶数。所以我们将`ALUOp[3:0]`冗余的高位与指令的符号相关联：

```verilog
ALUOp[3] <= OpCode[0];
```

在IF阶段和ID阶段，ALUOp为0；而在其余的阶段，若指令为R type，则ALUOp为010，否则根据OpCode决定ALUOp：

```verilog
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
                default:begin
                    ALUOp[2:0] <= I1_op;
                end
            endcase
        end
    end
```

#### ALUControl

在ALUControl模块中，输入为控制模块产生的`ALUOp`字段和指令中的`Funct`字段，输出为`ALUConf`（决定ALU所执行的计算类型）和`Sign`（进行有符号计算还是无符号计算）。

在ALUControl模块中，我们可以用如下逻辑控制`Sign`的生成（分R type和I type讨论）：

```verilog
// step 1: to decide the signed & unsigned
    // I type
    
    always @(*) begin
        case(ALUOp[3])
            1'b0:Sign <= 1;
            1'b1:Sign <= 0;
        endcase
    end
    
    // R type
    always @(*) begin
        if (ALUOp[2:0] == 3'b010) begin
            case(Funct)
                addu_fun: Sign <= 0;
                subu_fun: Sign <= 0;
                sltu_fun: Sign <= 0;
                default: Sign  <= 1;
            endcase
        end
    end
    
```

之后根据ALUOp和Funct综合生成`ALUConf`：

```verilog
// step 2: generate ALUConf according to Funct
    always @(*) begin
        if (ALUOp == 3'b010) begin // R type, decide the ALUConf by Funct
            case(Funct)
                add_fun:ALUConf  <= add_ctrl;
                addu_fun:ALUConf <= add_ctrl;
                sub_fun:ALUConf  <= sub_ctrl;
                subu_fun:ALUConf <= sub_ctrl;
                
                and_fun:ALUConf <= and_ctrl;
                or_fun:ALUConf  <= or_ctrl;
                xor_fun:ALUConf <= xor_ctrl;
                nor_fun:ALUConf <= nor_ctrl;
                
                slt_fun:ALUConf  <= slt_ctrl;
                sltu_fun:ALUConf <= slt_ctrl;
                sll_fun:ALUConf  <= sll_ctrl;
                srl_fun:ALUConf  <= srl_ctrl;
                sra_fun:ALUConf  <= sra_ctrl;
            endcase
        end
        else if (ALUOp == 3'b000) // use add
            ALUConf <= add_ctrl;
        else if (ALUOp == 3'b001) // use sub
            ALUConf <= sub_ctrl;
        else if (ALUOp == 3'b011) // use and
            ALUConf <= and_ctrl;
        else if (ALUOp == 3'b100) // use slt
            ALUConf <= slt_ctrl;
        else
            ALUConf <= add_ctrl;
    end
    
```

#### ALU

根据`ALUControl`模块生成的`ALUConf`字段进行不同的运算：

```verilog
always @(*) begin
        case(ALUConf)
            and_ctrl: Result <= in1 & in2;
            or_ctrl: Result  <= in1 | in2;
            add_ctrl: Result <= in1 + in2;
            sub_ctrl: Result <= in1 - in2;
            slt_ctrl: begin
                if (Sign) begin //signed
                    case({in1[31],in2[31]}) // to compare according to the sign bit
                        2'b01: Result <= 0;
                        2'b10: Result <= 1;
                        2'b00: Result <= (in1<in2);
                        2'b11: Result <= (in1[30:0]<in2[30:0]);
                    endcase
                end
                else // unsigned
                Result <= (in1 < in2);
            end
            nor_ctrl: Result <= ~(in1 | in2);
            xor_ctrl: Result <= (in1 ^ in2);
            sll_ctrl: Result <= (in2 << in1);
            srl_ctrl: Result <= (in2 >> in1);
            // important!! if you want to add shamt options, you should load the last 16 bits and get the shamt[10:6]
            sra_ctrl: Result <= ({{32{in2[31]}}, in2} >> in1); // the highst bit is always same as signal-bit
            // when it comes to unsigned numbers, sra_ctrl may get wrong answers
            // see: https://chortle.ccsu.edu/AssemblyTutorial/Chapter-14/ass14_14.html
            default: Result <= 0;
        endcase
    end
```

与单周期CPU的不同点：

1. 单周期CPU的ALUOp由ALUControl模块生成，而多周期CPU的ALUOp由Controller模块生成。
2. 多周期CPU的ALU模块除了执行数据运算外，还执行PC自增、PC跳转等运算。

### 数据通路

#### MUX

1. 选择指令还是数据的mux，根据`IorD`的值来决定输入的是指令地址还是数据地址。

   ```verilog
   assign Address = 
       (IorD == 1'b0)? PC_o :
       ALUOut_register_data;
   ```

2. 选择写寄存器的mux，根据`regDst`的值选择写寄存器为`Rt`、`Rd`还是`Ra`。

   ```verilog
   assign Write_register = 
       (RegDst == 2'b00)? Rt:
       (RegDst == 2'b01)? Rd:
       5'b11111; // $ra
   ```

3. 控制写入数据的mux，根据`Memtoreg`的值选择写入寄存器的值来源于ALU输出，数据存储器，自增后的PC还是立即数扩展单元。

   ```verilog
   assign Write_register_data = 
        (MemtoReg == 2'b00)? Data:
        (MemtoReg == 2'b01)? ALUOut_register_data:
        (MemtoReg == 2'b10)? PC_o:
        (MemtoReg == 2'b11)? ImmExtOut:
        Data;
   ```

4. ALU第一个操作数的mux，根据`ALUSrc1`的值选择该操作数为寄存器读取值、shamt还是PC。

   ```verilog
   assign in1 = 
       (ALUSrc1 == 2'b00)? PC_o:
       (ALUSrc1 == 2'b10)? Shamt:
       Read_register_data1;
   ```

5. ALU第二个操作数的mux，根据`ALUSrc2`的值选择该操作数为寄存器读取值、常数值4、符号扩展后的立即数还是移位后的立即数。

   ```verilog
   assign in2 = 
       (ALUSrc2 == 2'b00)? Read_register_data2:
       (ALUSrc2 == 2'b01)? 32'h4:
       (ALUSrc2 == 2'b10)? ImmExtOut:
       ImmExtShift;
   ```

6. 选择PC来源的mux，根据`PCSrc`的值选择PC来自ALU输出、ALU寄存器输出、跳转值还是寄存器。

   ```verilog
   assign PC_i = 
       (PCSrc == 2'b00)? ALUOut:
       (PCSrc == 2'b01)? ALUOut_register_data:
       (PCSrc == 2'b10)? {PC_o[31:28],Address_j,2'b00}:
       Read_register_data1;
   ```

#### Register

1. Instruction Register，用于临时存放指令，供后续步骤使用

```verilog
// instruction register
    InstReg Instreg(
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
```

2. Memory Data Register，用于临时存放从寄存器中读取的数据，供后续步骤使用

```verilog
RegTemp Memory_data_register(
    .reset(reset),
    .clk(clk),
    .Data_i(Mem_data),
    .Data_o(Data)
    );
```

3. 寄存器'A'和'B'，用于存放寄存器堆中读取的数据

```verilog
RegTemp Read_data_1_Register(.reset(reset), .clk(clk), .Data_i(Read_data1), .Data_o(Read_register_data1));
RegTemp Read_data_2_Register(.reset(reset), .clk(clk), .Data_i(Read_data2), .Data_o(Read_register_data2));
```

4. ALUOut寄存器，用于存放ALU的输出结果

```verilog
RegTemp ALU_register(
    reset, clk, ALUOut, ALUOut_register_data
    );
```

### 功能验证

仿真结果如下：

![image-20220523221248226](C:\Users\86181\AppData\Roaming\Typora\typora-user-images\image-20220523221248226.png)

可以看到，仿真结果正确。

## MIPS 单周期和多周期 CPU 的性能对比

### 汇编程序分析

#### 功能

功能：计算$2\times(1+2+...+n)$的值。

label的作用：

* `Loop` 使得程序陷入死循环，无法退出。
* `sum` 控制程序当`$a0>=1`时，递归调用函数。
* `L1` 实现累加逻辑。

注释和机器码如下图所示：

```assembly
 addi $a0, $zero, 5 # a0 = 0 + 5
    # {6'h08, 5'd0, 5'd4, 16'h5}
 xor $v0, $zero, $zero # v0 = 0 ^ 0 = 0
    # {6'h00, 5'd0, 5'd0, 5'd2, 5'd0, 6'h26}
 jal sum # call sum function
    # {6'h03, 26'h4}
Loop:
 beq $zero, $zero, Loop
    # {6'h04, 5'd0, 5'd0, 16'hffff}
sum:
 addi $sp, $sp, -8 # decrement stack pointer
    # {6'h08, 5'd29, 5'd29, 16'hfff8}
 sw $ra, 4($sp) # store return address
    # {6'h2b, 5'd29, 5'd31, 16'h4}
 sw $a0, 0($sp) # store a0
    # {6'h2b, 5'd29, 5'd4, 16'h0}
 slti $t0, $a0, 1 # t0 = (a0 < 1) ? 1 : 0
    # {6'h0a, 5'd4, 5'd8, 16'h1}
 beq $t0, $zero, L1 # if t0 == 0, jump to L1
    # {6'h04, 5'h8, 5'h0, 16'h2}
 addi $sp, $sp, 8 # increment stack pointer
    # {6'h08, 5'd29, 5'd29, 16'h0008}
 jr $ra # return from function
    # {6'h0, 5'd31, 15'h0, 6'h08}
L1:
 add $v0, $a0, $v0 # v0 = a0 + v0
    # {6'h00, 5'd4, 5'd2, 5'd2, 5'd0, 6'h20}
 addi $a0, $a0, -1 # a0 = a0 - 1
    # {6'h08, 5'd4, 5'd4, 16'hffff}
 jal sum # call sum function
    # {6'h03, 26'h4}
 lw $a0, 0($sp) # load a0
    # {6'h23, 5'd29, 5'd4, 16'h0}
 lw $ra, 4($sp) # load return address
    # {6'h23, 5'd29, 5'd31, 16'h4}
 addi $sp, $sp, 8 # increment stack pointer
    # {6'h08, 5'd29, 5'd29, 16'h8}
 add $v0, $a0, $v0 # v0 = a0 + v0
    # {6'h00, 5'd8, 5'd4, 5'd4, 5'd0, 6'h20}
 jr $ra  # return from function
    # {6'h0, 5'd31, 15'h0, 6'h08}
```

#### 仿真结果

计算完毕后各个寄存器中的值：

`$a0($4)`:5, `$v0($2)`:30, `$t0($8)`:1

注释如上图所示。

单周期CPU仿真结果如下：

![image-20220525184454515](C:\Users\86181\AppData\Roaming\Typora\typora-user-images\image-20220525184454515.png)

可以看到，所有寄存器的值都符合预期，单周期CPU设计正确。

多周期CPU仿真结果如下：

![image-20220524094157709](C:\Users\86181\AppData\Roaming\Typora\typora-user-images\image-20220524094157709.png)

可以看到，所有寄存器的值都符合预期，多周期CPU设计正确。

### 资源与性能对比

#### 单周期CPU

* 资源消耗

  ![image-20220525195833745](C:\Users\86181\AppData\Roaming\Typora\typora-user-images\image-20220525195833745.png)

  ![image-20220525195855736](C:\Users\86181\AppData\Roaming\Typora\typora-user-images\image-20220525195855736.png)

* 时序性能

  时序约束文件如下，即clk周期为20ns（频率50MHz）：

  ```tcl
  create_clock -period 20.000 -name CLK -waveform {0.000 10.000} [get_ports clk]
  ```

  ![image-20220525200340003](C:\Users\86181\AppData\Roaming\Typora\typora-user-images\image-20220525200340003.png)

  最低路径延时：$t_{min}=T-WNS=15.327ns$

  最高时钟频率：$f_{max}=\frac{1}{t_{min}}=65.2MHz$

#### 多周期CPU

* 资源消耗

![image-20220525202122436](C:\Users\86181\AppData\Roaming\Typora\typora-user-images\image-20220525202122436.png)

![image-20220525202147196](C:\Users\86181\AppData\Roaming\Typora\typora-user-images\image-20220525202147196.png)

* 时序性能

  时序约束文件如下，即clk周期为20ns（频率50MHz）：

  ```tcl
  create_clock -period 20.000 -name CLK -waveform {0.000 10.000} [get_ports clk]
  ```

  ![image-20220525202502878](C:\Users\86181\AppData\Roaming\Typora\typora-user-images\image-20220525202502878.png)

    最低路径延时：$t_{min}=T-WNS=10.432ns$

    最高时钟频率：$f_{max}=\frac{1}{t_{min}}=95.9MHz$

对比可以发现，多周期CPU的资源消耗略多于单周期CPU，但最高时钟频率变大。

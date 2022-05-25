	addi $a0, $zero, 5 # a0 = 0 + 5
    # {6'h08, 5'd0, 5'd4, 16'ha}
	xor $v0, $zero, $zero # v0 = 0 ^ 0 = 0
    # {6'h00, 5'd0, 5'd0, 5'd0, 5'd0, 6'h26}
	jal sum # call sum function
    # {6'h03, 26'h4}
Loop:
	beq $zero, $zero, Loop
    # {6'h04, 5'h0, 5'h0, 16'h3}
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
    # {6'h04, 5'h8, 5'h0, 16'h11}
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
    # {6'h08, 5'd29, 5'd29, 16'h0008}
	add $v0, $a0, $v0 # v0 = a0 + v0
    # {6'h00, 5'd8, 5'd4, 5'd4, 5'd0, 6'h20}
	jr $ra  # return from function
    # {6'h0, 5'd31, 15'h0, 6'h08}

@ This ARM Assembler code should implement a matching function, for use in the MasterMind program, as
@ described in the CW2 specification. It should produce as output 2 numbers, the first for the
@ exact matches (peg of right colour and in right position) and approximate matches (peg of right
@ color but not in right position). Make sure to count each peg just once!
	
@ Example (first sequence is secret, second sequence is guess):
@ 1 2 1
@ 3 1 3 ==> 0 1
@ You can return the result as a pointer to two numbers, or two values
@ encoded within one number
@
@ -----------------------------------------------------------------------------

.text
@ this is the matching fct that should be called from the C part of the CW	
.global         matches
@ use the name `main` here, for standalone testing of the assembler code
@ when integrating this code into `master-mind.c`, choose a different name
@ otw there will be a clash with the main function in the C code
.global         main
main2: 
	LDR  R2, =secret	@ pointer to secret sequence
	LDR  R3, =guess		@ pointer to guess sequence

	@ you probably need to initialise more values here

	@ ... COMPLETE THE CODE BY ADDING YOUR CODE HERE, you should use sub-routines to structure your code
	MOV R0, R2
	MOV R1, R3
	BL matches

exit:	@MOV	 R0, R4		@ load result to output register
	MOV 	 R7, #1		@ load system call code
	SWI 	 0		@ return this value

@ -----------------------------------------------------------------------------
@ sub-routines

@ this is the matching fct that should be callable from C	
matches:			@ Input: R0, R1 ... ptr to int arrays to match ; Output: R0 ... exact matches (10s) and approx matches (1s) of base COLORS
	@ COMPLETE THE CODE HERE
	PUSH {R4-R11, LR}
	MOV R9, R0 @ Copy seq 1 for inner loop
	MOV R4, #0 @ Exact matches
	MOV R5, #0 @ Approx matches
	MOV R11, #0 @ Counter for loop
	MOV R10, #0 @ Counter for inner loop
	B exact_loop

exact_loop:
	@ Check if the end of the array is reached
	CMP R11, #LEN
	BEQ exact_end

	@ Check if the two values are equal
	LDR R6, [R0] @ Sequence 1 element
	LDR R7, [R1] @ Sequence 2 element
	CMP R6, R7
	BNE exact_next @ If not equal, go to next

	@ If equal, increment exact matches and mark values
	ADD R4, #1
	MOV R6, #NAN1
	MOV R7, #NAN2

	@ Store marked values
	STR R6, [R0]
	STR R7, [R1]

exact_next:
	@ Increment pointers and count to next val
	ADD R11, #1
	ADD R0, #4
	ADD R1, #4
	B exact_loop @ Go to next iteration

exact_end:
	@reset pointers and count
	SUB R0, #12
	SUB R1, #12
	MOV R11, #0

approx_loop:
	@ Check if the end of the array is reached
	CMP R11, #LEN
	BEQ approx_end

	@check if the value in R1 is marked
	LDR R6, [R0] @ Sequence 1 element
	LDR R7, [R1] @ Sequence 2 element

	CMP R7, #NAN1
	BEQ approx_next
	CMP R7, #NAN2
	BEQ approx_next
	B approx_inner_loop
	
approx_inner_loop:
	@ Check if the end of the array is reached
	CMP R10, #LEN
	BEQ approx_inner_end

	LDR R8, [R9] @ Load element
	@ Check if elements are equal
	CMP R8, R7
	BNE approx_inner_next

	@ If equal, increment approx matches and mark value
	ADD R5, #1
	MOV R8, #NAN2

	STR R8, [R9] @ Store marked value
	B approx_inner_end @ Break out of loop

approx_inner_next:
	@ Increment pointers and count to next val
	ADD R10, #1
	ADD R9, #4
	B approx_inner_loop @ Go to next iteration

approx_inner_end:
	@ Reset pointers and count
	LSL R10, #2
	SUB R9, R10
	MOV R10, #0
	B approx_next

approx_next:
	@ Increment pointers and count to next val
	ADD R11, #1
	ADD R0, #4
	ADD R1, #4
	B approx_loop @ Go to next iteration

approx_end:
	@ Reset pointers and count
	SUB R0, #12
	SUB R1, #12
	MOV R11, #0

	@ Store exact and approx matches in R0
	LDR R0, =result
	STR R4, [R0]
	ADD R0, #4
	STR R5, [R0]
	LDR R0, =result

	POP {R4-R11, LR}
	BX LR @ Return value to c code

@ show the sequence in R0, use a call to printf in libc to do the printing, a useful function when debugging 
showseq: 			@ Input: R0 = pointer to a sequence of 3 int values to show
	@ COMPLETE THE CODE HERE (OPTIONAL)
	
	
@ =============================================================================

.data

@ constants about the basic setup of the game: length of sequence and number of colors	
.equ LEN, 3
.equ COL, 3
.equ NAN1, 8
.equ NAN2, 9

@ a format string for printf that can be used in showseq
f4str: .asciz "Seq:    %d %d %d\n"

@ a memory location, initialised as 0, you may need this in the matching fct
n: .word 0x00

result: .skip 8 @ 4 bytes for each int
	
@ INPUT DATA for the matching function
.align 4
secret: .word 1 
	.word 2 
	.word 1 

.align 4
guess:	.word 3 
	.word 1 
	.word 3 

@ Not strictly necessary, but can be used to test the result	
@ Expect Answer: 0 1
.align 4
expect: .byte 0
	.byte 1

.align 4
secret1: .word 1 
	 .word 2 
	 .word 3 

.align 4
guess1:	.word 1 
	.word 1 
	.word 2 

@ Not strictly necessary, but can be used to test the result	
@ Expect Answer: 1 1
.align 4
expect1: .byte 1
	 .byte 1

.align 4
secret2: .word 2 
	 .word 3
	 .word 2 

.align 4
guess2:	.word 3 
	.word 3 
	.word 1 

@ Not strictly necessary, but can be used to test the result	
@ Expect Answer: 1 0
.align 4
expect2: .byte 1
	 .byte 0


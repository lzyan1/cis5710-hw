        .section .data
input_string:   .asciz "Hello world!"

        # tohost/fromhost are data locations used by Spike
        .align 8
tohost: .byte 0
        .align 8
fromhost: .byte 0

        
        .section .text
        .globl _start
_start:
        # Load the address of the input string into a0
        la a0, input_string

        # Your code here!
loop:
        lbu t0, 0(a0)
        beqz t0, end_program
        
        li t1, 0x61
        bltu t0, t1, skip
        li t1, 0x7B
        bgeu t0, t1, skip

        addi t0, t0, -32
        sb t0, 0(a0)
skip:
        addi a0, a0, 1
        j loop
end_program:
        # jump here when you're done
        j end_program


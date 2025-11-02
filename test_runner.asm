# ================== test_runner.asm ==================
# Automated tests for the bisection procedure.
        .include "io_macros.inc"
        .globl main
        .extern bisect_root

        .data
hdr:    .asciz "== Automated tests ==\n"
fmt1:   .asciz "Case: ["
comma:  .asciz ", "
closeb: .asciz "] eps="
res:    .asciz " -> root="
iters:  .asciz " iters="
nl:     .asciz "\n"

cases:
        .double 1.0, 3.0, 1.0e-3
        .double 1.0, 3.0, 1.0e-5
        .double 1.0, 3.0, 1.0e-8
        .double 2.0, 2.5, 1.0e-6
        .double -10.0, 10.0, 1.0e-4

        .text
main:
        addi sp, sp, -32
        sd   ra, 24(sp)

        la a0, hdr

        la t0, cases
        li t1, 5

loop:
        beqz t1, done
        fld fa0, 0(t0)        # a
        fld fa1, 8(t0)        # b
        fld fa2, 16(t0)       # eps

        la a0, fmt1
        jal ra, print_double          # a in fa0
        la a0, comma
        fmv.d fa0, fa1
        jal ra, print_double
        la a0, closeb
        fmv.d fa0, fa2
        jal ra, print_double

        addi sp, sp, -4
        mv   a0, sp
        jal  ra, bisect_root  # -> root in fa0

        la a0, res
        jal ra, print_double
        la a0, iters
        lw a0, 0(sp)
        jal ra, print_int
        la a0, nl
        addi sp, sp, 4

        addi t0, t0, 24
        addi t1, t1, -1
        j loop

done:
        ld ra, 24(sp)
        addi sp, sp, 32
        li a0, 0
        ret

# ------------------- IO procedures (RARS syscalls) -------------------
print_str:
        li a7, 4
        ecall
        ret

print_int:
        li a7, 1
        ecall
        ret

print_double:
        li a7, 3
        ecall
        ret

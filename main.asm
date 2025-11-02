# ================== main.asm (RARS 1.6, RV32I + D) ==================
# Task 33: Root of x^3 - 0.5x^2 + 0.2x - 4 = 0 by bisection.
        .include "io_macros.inc"

        .globl  main

        .data
prompt_eps:  .asciz "Enter epsilon in [1e-3;1e-8]: "
prompt_a:    .asciz "Enter a (e.g., 1): "
prompt_b:    .asciz "Enter b (e.g., 3): "
warn_fix:    .asciz "Interval is not a bracket. Auto-fixing...\n"
using_br:    .asciz "Using bracket: ["
comma:       .asciz ", "
closeb:      .asciz "]\n"
res_root:    .asciz "Root ~= "
res_iters:   .asciz "  iterations = "
res_resid:   .asciz "  |f(root)| = "
bad_eps:     .asciz "Epsilon out of range; clamped to allowed bounds.\n"
nl:          .asciz "\n"
dbg_fa:      .asciz "  f(a) = "
dbg_fb:      .asciz "  f(b) = "

        .align 3
A:      .space 8        # double a
B:      .space 8        # double b
EPS:    .space 8        # double eps
iters:  .space 4        # int
FA:     .space 8        # double f(a)
FB:     .space 8        # double f(b)

        .align 3
d0:     .double 0.0
d1e_8:  .double 1.0e-8
d1e_3:  .double 1.0e-3
dhalf:  .double 0.5

        .text
main:
        addi sp, sp, -64
        sw   ra, 60(sp)
        sw   s0, 56(sp)
        addi s0, sp, 64

# --- read epsilon ---
        PRINT_STR prompt_eps
        jal  ra, read_double       # -> fa0
        la t3, EPS
        fsd fa0, 0(t3)

        # clamp to [1e-8, 1e-3]
        la t3, EPS
        fld ft2, 0(t3)               # eps
        la t0, d1e_8
        fld ft0, 0(t0)
        la t1, d1e_3
        fld ft1, 0(t1)

        flt.d t2, ft2, ft0     # eps < 1e-8 ?
        beqz  t2, L_eps_low_ok
        PRINT_STR bad_eps
        fmv.d ft2, ft0
L_eps_low_ok:
        flt.d t2, ft1, ft2     # 1e-3 < eps ?
        beqz  t2, L_eps_high_ok
        PRINT_STR bad_eps
        fmv.d ft2, ft1
L_eps_high_ok:
        la t3, EPS
        fsd ft2, 0(t3)

# --- read a, then b ---
        PRINT_STR prompt_a
        jal  ra, read_double
        la t3, A
        fsd fa0, 0(t3)
        PRINT_STR prompt_b
        jal  ra, read_double
        la t3, B
        fsd fa0, 0(t3)


# --- validate sign change ---
        # load A, compute f(a) -> FA
        la     t3, A
        fld    ft6, 0(t3)
        fmv.d  fa0, ft6
        jal    ra, f_eval
        la     t3, FA
        fsd    fa0, 0(t3)

        # load B, compute f(b) -> FB
        la     t3, B
        fld    ft7, 0(t3)
        fmv.d  fa0, ft7
        jal    ra, f_eval
        la     t3, FB
        fsd    fa0, 0(t3)

        # debug print
        PRINT_STR dbg_fa
        la     t3, FA
        fld    fa0, 0(t3)
        PRINT_DOUBLE
        PRINT_STR nl
        PRINT_STR dbg_fb
        la     t3, FB
        fld    fa0, 0(t3)
        PRINT_DOUBLE
        PRINT_STR nl

        # product test
        la     t3, FA
        fld    ft2, 0(t3)
        la     t3, FB
        fld    ft3, 0(t3)
        fmul.d ft5, ft2, ft3
        la     t0, d0
        fld    ft4, 0(t0)         # 0.0
        flt.d  t6, ft5, ft4       # (f(a)*f(b)) < 0 ?
        bnez   t6, L_have_br

        PRINT_STR warn_fix
        la     a0, A              # reuse A,B as out slots
        la     a1, B
        la     t3, A
        fld    fa0, 0(t3)         # guess a
        la     t3, B
        fld    fa1, 0(t3)         # guess b
        jal    ra, find_bracket   # writes *A,*B

        # reload A,B
        la     t3, A
        fld    ft6, 0(t3)
        la     t3, B
        fld    ft7, 0(t3)

        # show new bracket
        PRINT_STR using_br
        fmv.d  fa0, ft6
        PRINT_DOUBLE
        PRINT_STR comma
        fmv.d  fa0, ft7
        PRINT_DOUBLE
        PRINT_STR closeb

        # recompute f(a), f(b) into FA/FB
        fmv.d fa0, ft6
        jal   ra, f_eval
        la    t3, FA
        fsd   fa0, 0(t3)
        fmv.d fa0, ft7
        jal   ra, f_eval
        la    t3, FB
        fsd   fa0, 0(t3)
        PRINT_STR dbg_fa
        la    t3, FA
        fld   fa0, 0(t3)
        PRINT_DOUBLE
        PRINT_STR nl
        PRINT_STR dbg_fb
        la    t3, FB
        fld   fa0, 0(t3)
        PRINT_DOUBLE
        PRINT_STR nl

L_have_br:

        # show final bracket
        PRINT_STR using_br
        fmv.d  fa0, ft6
        PRINT_DOUBLE
        PRINT_STR comma
        fmv.d  fa0, ft7
        PRINT_DOUBLE
        PRINT_STR closeb

# --- run bisection ---
        la t3, A
        fld fa0, 0(t3)
        la t3, B
        fld fa1, 0(t3)
        la t3, EPS
        fld fa2, 0(t3)
        la     a0, iters
        jal    ra, bisect_root    # -> fa0 root

        PRINT_STR res_root
        PRINT_DOUBLE
        PRINT_STR res_iters
        la t3, iters
        lw a0, 0(t3)
        PRINT_INT

        # Residual |f(root)|
        fmv.d  fa1, fa0            # keep root in fa1
        fmv.d  fa0, fa1
        jal    ra, f_eval          # fa0 = f(root)
        la     t0, d0
        fld    ft0, 0(t0)
        flt.d  t1, fa0, ft0
        beqz   t1, L_abs_ok
        fneg.d fa0, fa0
L_abs_ok:
        PRINT_STR res_resid
        PRINT_DOUBLE
        PRINT_STR nl

        # Exit cleanly
        li   a7, 10
        ecall

# ------------------- IO procedures (RARS syscalls) -------------------
print_str:
        li a7, 4
        ecall
        ret

print_int:
        li a7, 1
        ecall
        ret

read_double:
        li a7, 7
        ecall
        ret

print_double:
        li a7, 3
        ecall
        ret
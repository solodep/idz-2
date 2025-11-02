# ================== math_utils.asm (RARS 1.6, RV32I + D) ==================
# f(x), bracket search, bisection core

        .globl f_eval
        .globl find_bracket
        .globl bisect_root

        .data
        .align 3
d_half:   .double 0.5
d_pt2:    .double 0.2
d_four:   .double 4.0
d_zero:   .double 0.0
d_ten:    .double 10.0
d_neg10:  .double -10.0
d_step:   .double 0.5

        .text

# Trampoline in case this file is run directly
start:    j   main

# double f_eval(double x): x^3 - 0.5x^2 + 0.2x - 4
f_eval:
        addi sp, sp, -16
        sw   ra, 12(sp)
        sw   s0, 8(sp)
        addi s0, sp, 16

        fmv.d ft0, fa0          # x
        fmul.d ft1, ft0, ft0    # x^2
        fmul.d ft2, ft1, ft0    # x^3

        la    t0, d_half
        fld   ft3, 0(t0)        # 0.5
        fmul.d ft3, ft3, ft1    # 0.5 x^2

        la    t0, d_pt2
        fld   ft4, 0(t0)        # 0.2
        fmul.d ft4, ft4, ft0    # 0.2 x

        fsub.d ft5, ft2, ft3
        fadd.d ft5, ft5, ft4

        la    t0, d_four
        fld   ft6, 0(t0)
        fneg.d ft6, ft6          # -4
        fadd.d fa0, ft5, ft6     # result

        lw   ra, 12(sp)
        lw   s0, 8(sp)
        addi sp, sp, 16
        ret

# void find_bracket(double a_guess, double b_guess, double* outA, double* outB)
find_bracket:
        addi sp, sp, -48
        sw   ra, 44(sp)
        sw   s0, 40(sp)
        sw   s1, 36(sp)
        sw   s2, 32(sp)
        addi s0, sp, 48

        mv   s1, a0     # &outA
        mv   s2, a1     # &outB

        # ensure a<=b
        flt.d t0, fa1, fa0
        beqz  t0, FB_chk
        fmv.d ft0, fa0
        fmv.d fa0, fa1
        fmv.d fa1, ft0

FB_chk:
        
# check sign change for [fa0, fa1]
        fmv.d ft0, fa0      # a
        fmv.d ft1, fa1      # b
        fmv.d fa0, ft0
        jal   ra, f_eval
        fmv.d ft2, fa0      # f(a)
        fmv.d fa0, ft1
        jal   ra, f_eval
        fmv.d ft3, fa0      # f(b)

        # product sign test
        fmul.d ft5, ft2, ft3
        la    t1, d_zero
        fld   ft4, 0(t1)
        flt.d t6, ft5, ft4
        beqz  t6, FB_scan


        fsd  ft0, 0(s1)
        fsd  ft1, 0(s2)
        j    FB_done

FB_scan:
        # scan [-10;10] with step 0.5
        la   t0, d_neg10
        fld  ft0, 0(t0)      # cur
        la   t1, d_ten
        fld  ft1, 0(t1)      # ten
        la   t2, d_step
        fld  ft2, 0(t2)      # step

FB_loop:
        flt.d t0, ft1, ft0   # if ten < cur -> end
        bnez  t0, FB_fallback

        fmv.d ft3, ft0
        fadd.d ft4, ft0, ft2

        fmv.d fa0, ft3
        jal   ra, f_eval
        fmv.d ft5, fa0
        fmv.d fa0, ft4
        jal   ra, f_eval
        fmv.d ft6, fa0

        la    t3, d_zero
        fld   ft7, 0(t3)
        flt.d t3, ft5, ft7
        flt.d t4, ft7, ft5
        flt.d t5, ft6, ft7
        flt.d t6, ft7, ft6
        and   t3, t3, t6
        and   t4, t4, t5
        or    t3, t3, t4
        beqz  t3, FB_next

        fsd  ft3, 0(s1)
        fsd  ft4, 0(s2)
        j    FB_done

FB_next:
        fadd.d ft0, ft0, ft2
        j     FB_loop

FB_fallback:
        # fallback [-10;10]
        la   t0, d_neg10
        fld  ft0, 0(t0)
        la   t1, d_ten
        fld  ft1, 0(t1)
        fsd  ft0, 0(s1)
        fsd  ft1, 0(s2)

FB_done:
        lw   ra, 44(sp)
        lw   s0, 40(sp)
        lw   s1, 36(sp)
        lw   s2, 32(sp)
        addi sp, sp, 48
        ret

# double bisect_root(double a, double b, double eps, int* iters)
bisect_root:
        addi sp, sp, -64
        sw   ra, 60(sp)
        sw   s0, 56(sp)
        sw   s1, 52(sp)
        sw   s2, 48(sp)
        addi s0, sp, 64

        mv   s1, a0           # &iters
        li   s2, 0            # iter counter
        li   t0, 300          # max iters

        # locals: save a,b,eps
        fsd  fa0, -8(s0)
        fsd  fa1, -16(s0)
        fsd  fa2, -24(s0)

L_bisect_loop:
        # half = (b-a)/2
        fld  ft0, -8(s0)      # a
        fld  ft1, -16(s0)     # b
        fld  ft2, -24(s0)     # eps

        fsub.d ft3, ft1, ft0
        la   t1, d_half
        fld  ft4, 0(t1)
        fmul.d ft5, ft3, ft4  # half

        flt.d t1, ft2, ft5    # eps < half ?
        beqz  t1, L_bisect_done

        # m = (a+b)/2
        fadd.d ft6, ft0, ft1
        fmul.d ft6, ft6, ft4

        # fm = f(m), fa = f(a)
        fmv.d  fa0, ft6
        jal    ra, f_eval
        fmv.d  ft7, fa0       # fm

        fmv.d  fa0, ft0
        jal    ra, f_eval
        fmv.d  fa1, fa0       # fa

        la     t2, d_zero
        fld    fa2, 0(t2)
        flt.d  t2, fa1, fa2   # fa<0
        flt.d  t3, fa2, fa1   # fa>0
        flt.d  t4, ft7, fa2   # fm<0
        flt.d  t5, fa2, ft7   # fm>0
        and    t6, t2, t5
        and    a2, t3, t4
        or     t6, t6, a2
        beqz   t6, L_set_left
        fsd    ft6, -16(s0)   # b = m
        j      L_iter

L_set_left:
        fsd    ft6, -8(s0)    # a = m

L_iter:
        addi   s2, s2, 1
        blt    s2, t0, L_bisect_loop

L_bisect_done:
        # result = (a+b)/2
        fld  ft0, -8(s0)
        fld  ft1, -16(s0)
        fadd.d ft2, ft0, ft1
        la   t1, d_half
        fld  ft3, 0(t1)
        fmul.d fa0, ft2, ft3

        sw   s2, 0(s1)
        lw   ra, 60(sp)
        lw   s0, 56(sp)
        lw   s1, 52(sp)
        lw   s2, 48(sp)
        addi sp, sp, 64
        ret
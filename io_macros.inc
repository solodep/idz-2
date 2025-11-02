# ================== io_macros.inc ==================
# Real, useful macros for RARS (tested syntax: .macro ... %param)
# These macros call small IO procedures (print_str/print_int/read_double/print_double)
# which must be present in the including translation unit.
#
# Usage examples:
#   PRINT_STR prompt_eps
#   READ_DOUBLE fa2
#   PRINT_DOUBLE
#   PRINT_INT

.macro PRINT_STR %label
    la a0, %label
    jal ra, print_str
.end_macro

.macro PRINT_INT
    jal ra, print_int
.end_macro

.macro READ_DOUBLE %fd
    jal ra, read_double
    fmv.d %fd, fa0
.end_macro

.macro PRINT_DOUBLE
    jal ra, print_double
.end_macro

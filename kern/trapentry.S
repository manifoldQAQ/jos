/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)                      \
    .globl name;        /* define global symbol for 'name' */   \
    .type name, @function;  /* symbol type is function */       \
    .align 2;       /* align function definition */     \
    name:           /* function starts here */      \
    pushl $(num);                           \
    jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)                 \
    .globl name;                          \
    .type name, @function;                      \
    .align 2;                           \
    name:                               \
    pushl $0;                           \
    pushl $(num);                           \
    jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 *        Description                       Interrupt     Error Code
 *        Divide error                       0            No
 *        Debug exceptions                   1            No
 *        Breakpoint                         3            No
 *        Overflow                           4            No
 *        Bounds check                       5            No
 *        Invalid opcode                     6            No
 *        Coprocessor not available          7            No
 *        System error                       8            Yes (always 0)
 *        Coprocessor Segment Overrun        9            No
 *        Invalid TSS                       10            Yes
 *        Segment not present               11            Yes
 *        Stack exception                   12            Yes
 *        General protection fault          13            Yes
 *        Page fault                        14            Yes
 *        Coprocessor error                 16            No
 */
TRAPHANDLER_NOEC(T_DIVIDE_ENTRY, T_DIVIDE)          // 0: divide error
TRAPHANDLER_NOEC(T_DEBUG_ENTRY, T_DEBUG)            // 1: debug exception
TRAPHANDLER_NOEC(T_NMI_ENTRY, T_NMI)                     // 2: non-maskable interrupt
TRAPHANDLER_NOEC(T_BRKPT_ENTRY, T_BRKPT)            // 3: breakpoint
TRAPHANDLER_NOEC(T_OFLOW_ENTRY, T_OFLOW)            // 4: overflow
TRAPHANDLER_NOEC(T_BOUND_ENTRY, T_BOUND)            // 5: bound check
TRAPHANDLER_NOEC(T_ILLOP_ENTRY, T_ILLOP)            // 6: invalid op
TRAPHANDLER_NOEC(T_DEVICE_ENTRY, T_DEVICE)          // 7: illegal device
TRAPHANDLER(T_DBLFLT_ENTRY, T_DBLFLT)               // 8: double fault
/* TRAPHANDLER_NOEC(T_COPROC_ENTRY, T_COPROC) */    // 9: reserved coproc
TRAPHANDLER(T_TSS_ENTRY, T_TSS)                     // 10: invalid tss
TRAPHANDLER(T_SEGNP_ENTRY, T_SEGNP)                 // 11: segment not present
TRAPHANDLER(T_STACK_ENTRY, T_STACK)                 // 12: stack exception
TRAPHANDLER(T_GPFLT_ENTRY, T_GPFLT)                 // 13: general protection fault
TRAPHANDLER(T_PGFLT_ENTRY, T_PGFLT)                 // 14: page fault
/* TRAPHANDLER_NOEC(T_RES_ENTRY, T_RES) */          // 15: reserved
TRAPHANDLER_NOEC(T_FPERR_ENTRY, T_FPERR)            // 16: floating point error
TRAPHANDLER_NOEC(T_ALIGN_ENTRY, T_ALIGN)            // 17: alignment check
TRAPHANDLER_NOEC(T_MCHK_ENTRY, T_MCHK)              // 18: machine check
TRAPHANDLER_NOEC(T_SIMDERR_ENTRY, T_SIMDERR)        // 19: SIMD FP error
TRAPHANDLER_NOEC(T_SYSCALL_ENTRY, T_SYSCALL)        // 48: syscall


/*
 * Lab 3: Your code here for _alltraps
 * now that we are done with tf_trapno & ti_err, proceed to the upper part
 * of struct Trapframe
 */
_alltraps:
    pushw $0
    pushw %ds
    pushw $0
    pushw %es
    pushal
    # cannot directly modify ds/es, use ax as a workaround
    # since we have used pushal, it's fine to use ax
    movw $(GD_KD), %ax
    movw %ax, %ds
    movw %ax, %es
    pushl %esp
    call trap

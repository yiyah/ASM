#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "tty.h"
#include "proto.h"

/**
  * @brief  Let the function enter an infinite loop
  * @param  func_name: which function enters an infinite loop
  * @retval None
  */
PUBLIC void spin(char * func_name)
{
    printl("\nspinning in %s ...\n", func_name);
    while (1) {}
}

/**
  * @brief  Invoked by assert().
  *         assert failed in ring0~1 will cause the system to go down,
  *         block user process in ring2~3.
  * @param  exp       The failure expression itself.
  * @param  file      __FILE__
  * @param  base_file __BASE_FILE__
  * @param  line      __LINE__
  * @retval None
  */
PUBLIC void assertion_failure(char *exp, char *file, char *base_file, int line)
{
    printl("%c  assert(%s) failed: file: %s, base_file: %s, ln%d",
           MAG_CH_ASSERT,
           exp, file, base_file, line);

    /**
     * If assertion fails in a TASK, the system will halt before
     * printl() returns. If it happens in a USER PROC, printl() will
     * return like a common routine and arrive here. 
     * @see sys_printx()
     * 
     * We use a forever loop to prevent the proc from going on:
     */
    spin("assertion_failure()");

    /* should never arrive here */
        __asm__ __volatile__("ud2");
}

/**
  * @brief  Only use in ring0 or ring1, it will hang the system.
  *         (user process should not hang the system)
  *         When using this function, a critical error must have occurred.
  * @param  fmt     Format control string
  * @param  ...     a variadic list
  * @retval None
  */
PUBLIC void panic(const char *fmt, ...)
{
    int i;
    char buf[256];

    /* 4 is the size of fmt in the stack */
    va_list arg = (va_list)((char*)&fmt + 4);

    i = vsprintf(buf, fmt, arg);

    printl("%c !!panic!! %s", MAG_CH_PANIC, buf);

    /* should never arrive here */
    __asm__ __volatile__("ud2");
}

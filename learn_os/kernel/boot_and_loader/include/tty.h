#ifndef __TTY_H_
#define __TTY_H_

#define TTY_IN_BYTES    256     /* TTY input queue size */

/* TTY */
typedef struct s_tty
{
    u32     in_buf[TTY_IN_BYTES];   /* TTY input buffer */
    u32*    p_inbuf_head;           /* point to the next free byte in the buffer */
    u32*    p_inbuf_tail;           /* point to the key which need to deal */
    int     inbuf_count;            /* how much has been filled in the buffer */

    struct s_console* p_console;
}TTY;


#endif

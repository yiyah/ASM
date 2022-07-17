#ifndef __KEYBOARD_H_
#define __KEYBOARD_H_

#define KB_IN_BYTES 32  /* size of keyboard input buffer */

typedef struct s_kb {
    char* p_head;
    char* p_tail;
    int   count;
    char  buf[KB_IN_BYTES];
}KB_INPUT;

#endif

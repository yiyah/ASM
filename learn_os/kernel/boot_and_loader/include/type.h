#ifndef __TYPE_H_
#define __TYPE_H_

typedef unsigned char       u8;
typedef unsigned short      u16;
typedef unsigned int        u32;

typedef void (*int_handler) ();
typedef void (*task_f) ();
typedef void (*irq_handler) (u32 irq);
typedef void* system_call;

#endif /* __TYPE_H_ */

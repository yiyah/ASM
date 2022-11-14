#ifndef __PROTO_H_
#define __PROTO_H_


/* string.asm */
/**
 * `phys_copy' and `phys_set' are used only in the kernel, where segments
 * are all flat (based on 0). In the meanwhile, currently linear address
 * space is mapped to the identical physical address space. Therefore,
 * a `physical copy' will be as same as a common copy, so does `phys_set'.
 */
#define phys_copy   memcpy
#define phys_set    memset
PUBLIC void* memcpy(void* pDst, void* pSrc, int iSize);
PUBLIC void memset(void* p_dst, u8 ch, u32 size);
PUBLIC char* strcpy(char* p_dst, char* p_src);
PUBLIC int strlen(char* p_str);

/* kliba.asm */
PUBLIC void disp_str(char* pszInfo);
PUBLIC void disp_color_str(char* pszInfo, u8 color);
PUBLIC void out_byte(u16 port, u8 value);
PUBLIC u8   in_byte(u16 port);
PUBLIC void port_read(u16 port, void* buf, int n);
PUBLIC void port_write(u16 port, void* buf, int n);
PUBLIC void disable_irq(u32 irq);
PUBLIC void enable_irq(u32 irq);
PUBLIC void enable_int();
PUBLIC void disable_int();

/* syscall.asm */
int sendrec(int function, int src_dest, MESSAGE* msg);
void printx(char* s);

/* kernel.asm */
PUBLIC void restart();
PUBLIC void sys_call();

/* kernel/hd.c */
PUBLIC void task_hd();
PUBLIC void hd_handler(int irq);

/* i8259.c */
PUBLIC void init_8259A();
PUBLIC void spurious_irq(int irq);
PUBLIC void put_irq_handler(int irq, irq_handler handler);

/* protect.c */
PUBLIC void init_prot();

/* klib.c */
PUBLIC void ctoh(char* str ,char num);
PUBLIC void itoh(char* str ,int num);
PUBLIC void disp_hex_oneByte(u8 hex);
PUBLIC void disp_hex_fourByte(u32 hex);
PUBLIC void delay(u16 timef);
PUBLIC void ClearScreen();

/* main.c */
extern PROCESS* p_proc_ready;
extern PUBLIC PROCESS proc_tables[NR_TASKS+NR_PROCS];

/* start.c */
extern PUBLIC TSS tss;
extern PUBLIC DESCRIPTOR gdt[GDT_DESC_NUM];
extern PUBLIC GATE idt[IDT_DESC_NUM];

/* main.c */
PUBLIC int get_ticks();
void TestA();
void TestB();
void TestC();

/* clock.c */
PUBLIC void clock_handler(u32 irq);
PUBLIC void init_clock();
PUBLIC void milli_delay(u32 milli_sec);

/* process.c */
PUBLIC void schedule();
PUBLIC int sys_sendrec(int function, int src_dest, MESSAGE* m, struct s_proc* p);
PUBLIC int send_recv(int function, int src_dest, MESSAGE* msg);
PUBLIC int ldt_seg_linear(PROCESS* p, int idx);
PUBLIC void* va2la(int pid, void* va);
PUBLIC void reset_msg(MESSAGE* p);
PUBLIC void inform_int(int task_nr);
PUBLIC void dump_proc(struct s_proc* p);
PUBLIC void dump_msg(const char * title, MESSAGE* m);

/* keyboard.c */
PUBLIC void init_keyboard();
PUBLIC void keyboard_read();

/* systask.c */
PUBLIC void task_sys();

/* tty.c */
PUBLIC void task_tty();
PUBLIC void in_process(TTY* p_tty, u32 key);
PUBLIC int sys_printx(int _unused1, int _unused2, char* s, struct s_proc* p_proc);

/* printf.c */
PUBLIC  int     printf(const char* fmt, ...);
#define printl  printf

/* vsprintf.c */
PUBLIC int vsprintf(char *buf, const char *fmt, va_list args);
PUBLIC int sprintf(char *buf, const char *fmt, ...);

/* misc.c */
PUBLIC void spin(char * func_name);
PUBLIC void panic(const char *fmt, ...);

/* fs/main.c */
PUBLIC void task_fs();

#endif

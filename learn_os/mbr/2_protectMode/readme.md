# Real mode

## Abbreviate

GDT: Global Description Table
GDTR: Global Description Table Register
LDT: Local Description Table

## Steps for enter protect mode

step1: Prepare the GDT

step2: Prepare the selector

step3: Init the GDT(descriptor)

step4: Calculate the segment base address of GDT and load GDTR(lgdt)

step5: Close the interruption(cli)

step6: Open the address line A20(bit 1 in 0x92 port) and set the flag of protect mode(bit 0 in cr0)

step7: Enter protect mode

## How back to real mode form protect mode?

Let us make clear the operation.

First, you need to figure out a way to refresh the cache register when you are in protect mode. So you must jump to 16 bits code **for refresh cs** (major is it's segment limit is 0xFFFF and can r/w) and reload a normal decsciptor to refresh ds, es, fs, gs and ss.(normal is segment attribute can r/w)

Second, clear the PE flag and turn off the A20.Then go back to DOS.

OK. We make a step as fllow:

* step1: You need to consider you must jump to 16 bits code to refresh the regester in protect mode.

    so, you must prepare the 16 bit segment, descriptor(normal, 16bit). And then clear PE flag.

* step2: Now you can jump to real mode when you clear flag.

  But where you jump? Where is the address of real mode's code?

  The one way know the address is when you are in real mode at first. So you need to prepare the address when you in real mode.

  ```asm
  ; you can jump when just know the segment
  jmp     0:LABEL_REAL_ENTRY
  ; and the jmp instruction like fllow
  ; so you can change the segment in real mode like
  mov   [LABEL_GO_BACK_TO_REAL+3], ax
  ```

  |BYTE 1|BYTE 2 BYTE 3|BYTE4 BYTE 5|
  |---|---|---|
  |OEAH|OFFSET|SEGMENT|

* step3: Close the A20 , open interruption and refresh the ds, es, ss and sp.

  You also save the sp before you jump in protect mode.

  And back to DOS.

  ```ASM
  mov   ax, 0x4c00
  int   21h         ; DOS
  ```

## LDT

* How to use LDT?

  * step1: prepare LDT (include descriptor, selector)

  * step2: prepare the code that will jump.(what the LDT describe)

  * step3: add label, selector about LDT to GDT.(because find LDT through GDT)

  * step4: init the descriptor of LDT in real mode as usal.

  * step5: jump to the code whcih LDT describe before using lldt to load LDT.

## GATE

* How to use call gate?

    * step1: add descriptor, selector and code as usual. (Where you want to jump)

    * step2: add descriptor, selector about GATE.

## Ring 3

* How to go to ring 3?

    * step1: add descriptor, selector and code as usual. (Where you want to jump)

    * step2: add stack for ring 3. (include it's selector)

    * step3: modify the DPL if you maybe access some segment.

    * step4: push ss, sp, cs, ip and then retf.

* How back to ring 1 from ring 3?

    Modify the descriptor and selector of GATE. (make CPL, RPL <= DPL_G)

## Page mechanism

1. Let's make clear that how to start using page mechanism.

    * First, we should let **cr3**(also name PDBR, Page-Directory Base Regester) point to the base address of **page directory table**.

    * Secondly, set the flag of PG in **cr0**(bit 31).

2. How to use page mechanism? And prepare what?

    * step1: Determines the address of the page directory table and page table.

    * step2: Add descriptor, selector of page directory table and page table. (Because we need to fill them in protect mode)

    * step3: Initialize the PDE and PTE. (page directory/table entry)

    * step4: Load base address of PDE to cr3 and set PG flag.

3. How to benefit from paging?

    Now we can use page mechanism and make linear addresses and physical addresses correspond one-to-one. But it has not changed much, it's similar to previous program.

    Now we show a way to get benefit from it!

    Let us look the following code. What can you find?

    ```asm
    call    SelFlatC:ProcPagingDemo
    call    PageSwitch
    call    SelFlatC:ProcPagingDemo
    ```

    If we don't know anything about paging. We would think the program call the same function and their result is no difference. But unexpectedly, they are difference from each other.

    * Let's think about it. (12_dos_benefit_from_page.asm)

        `ProcPagingDemo` is an address 0x301000. It call another address 0x401000 here.

        Now we have `function_1` in 0x401000 and `function_2` in 0x501000. The `ProcPagingDemo` will call `function_1` at first, because linear address 0x401000 is correspond to phycical address 0x401000.

        But now we map the linear address 0x401000 to physical address 0x501000 by `PageSwitch`. Then, the `ProcPagingDemo` will call `function_2`.

    * How to coding?

        * step1: Add `ProcPagingDemo`, `function_1` and `function_2` in respectively address.

        * step2: Setup paging. First map the linear address to the same physical address. (This step is easy, just like usual.)

        * step3: **The key step.** Except setup paging as usual, we should map linear address 0x401000 to physical address 0x501000. How to do that?

            Think about how linear address translate to physical address. The bit_22 to bit_31 are used to determine which **PDE**. The bit_12 to bit_21 are used to determine which **PTE**. The bit_0 to bit_11 are used to add with physical page top address.

            * So we can find PDE by using `shr linear_addr, 22`

            * find PTE by using

                ```asm
                mov     eax, linear_addr
                shr     eax, 12
                and     eax, 0x3FF      ;0x3FF is use 10 bits to clear other bits
                ```

            We should make clear that we just know which PDE and PTE to use. But we have no idea where they save. Let's go on considering how to find PDE. Ohh, got it! The cr3 is point to the base address of page directory table.

            So we should find PDE base on the first PDE address.

            And now we know which PDE and PTE used, we should calculate their physical address. Note that the PDE interval is 4K Bytes and the PTE interval is 4 Bytes.

## Summary

1. What should prepare for LDT/GDT?

    * The descriptor table

    * The selector

    * Where the descriptor describe? It may be code, data or stack, make this.

    if using LDT, it just need to add the descriptor and selector again.

## RESULT

1. 1_EnterProtectMode.asm

    ![看不到图片是科学问题](https://raw.githubusercontent.com/yiyah/Picture_Material/master/20220105231546.png)

2. 3_dos_AccessHighAddress.asm

    ![看不到图片是科学问题](https://raw.githubusercontent.com/yiyah/Picture_Material/master/20220213224852.png)

3. 9_dos_getMemory.asm

    This is value in memory. So the right way to read is little-endian.(4 Bytes)

    ![看不到图片是科学问题](https://raw.githubusercontent.com/yiyah/Picture_Material/master/20220309221843.png)

4. 11_dos_page_less.asm

    It is similar as 10_dos_page.asm.

    ![看不到图片是科学问题](https://raw.githubusercontent.com/yiyah/Picture_Material/master/20220313000144.png)

    What are different form them?

    We can see that the page_less only have 8 PDE. (The base address of Page Directory Table is 0x200000)

    ![看不到图片是科学问题](https://raw.githubusercontent.com/yiyah/Picture_Material/master/20220313000733.png)

## NOTE

1. es and gs

   I found that it will occur error wile using es in DOS.
   I don't know why.

2. problem of call

    I have no idea that why I get something wrong while using `call DispStr` at the file 8_dos_ring3_To_ring1.asm.

    In the end I realized how stupid I was.

    Fuck! I am so stupid that I made such a low-level mistake.

    At first, I also think it may need a long call.

    But I forget the function of DispStr is not using retf. So I got mistake also. I didn't know anything about it at that time. Damn it!

    Handsome as I am, fix this problem in commit a42cd78.

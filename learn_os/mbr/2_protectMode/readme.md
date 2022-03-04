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

step6: Open the address line A20 and set the flag of protect mode(cr0)

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
  mov	[LABEL_GO_BACK_TO_REAL+3], ax
  ```

  |BYTE 1|BYTE 2 BYTE 3|BYTE4 BYTE 5|
  |---|---|---|
  |OEAH|OFFSET|SEGMENT|

* step3: Close the A20 , open interruption and refresh the ds, es, ss and sp.

  You also save the sp before you jump in protect mode.

  And back to DOS.

  ```ASM
  mov	ax, 0x4c00
  int	21h		    ; DOS
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

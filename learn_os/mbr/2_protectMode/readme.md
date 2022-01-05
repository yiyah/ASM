# Real mode

## Abbreviate

GDT: Global Description Table
GDTR: Global Description Table Register

## steps for enter real mode

step1: Prepare the GDT

step2: Prepare the selector

step3: Init the GDT(descriptor)

step4: Calculate the segment base address of GDT and load GDTR(lgdt)

step5: Close the interruption(cli)

step6: Open the address line A20 and set the flag of protect mode(cr0)

step7: Enter protect mode

## the result of 1_EnterRealMode.asm

![看不到图片是科学问题](https://raw.githubusercontent.com/yiyah/Picture_Material/master/20220105231546.png)
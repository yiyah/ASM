# boot

We had knowed how to enter protect mode and use page mechanism.

But we can only use 512 bytes in MBR. This is a very small space.

Because a kernel definitely exceed 512 bytes. And how we solve this problem?

In this section, we want to use this follow to resolve it.

`boot --> loader --> kernel`

1. boot (MBR): Mainly responsible for copying the loader to memory and handing control to it

2. loader: Mainly responsible for copying the kernel to memory, enter protect mode and handing control to kernel.

## FAT12

Q: How can we read sector from disk?

A: Use int 13H

    ```shell
    1. reset disk
        ah = 0x0                al = drive letter (floppya = 0)
    
    2. read sector
        ah = 0x02               al = read how many sector
        ch = cylinder number    cl = start sector number
        dh = head number        dl = drive letter (floppya = 0)
        es:bx = data buffer (data go where)
    ```

## Reference

1. [bios内存分布详解](https://blog.csdn.net/u013961718/article/details/53506127)

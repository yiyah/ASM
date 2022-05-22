# boot

We had knowed how to enter protect mode and use page mechanism.

But we can only use 512 bytes in MBR. This is a very small space.

Because a kernel definitely exceed 512 bytes. And how we solve this problem?

In this section, we want to use this follow to resolve it.

`boot --> loader --> kernel`

1. boot (MBR): Mainly responsible for copying the loader to memory and handing control to it

2. loader: Mainly responsible for copying the kernel to memory, enter protect mode and handing control to kernel.

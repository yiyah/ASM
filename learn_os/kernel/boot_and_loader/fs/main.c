#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "tty.h"
#include "console.h"
#include "proto.h"
#include "global.h"


/**
  * @brief  <Ring 1> The main loop of TASK FS.
  */
PUBLIC void task_fs()
{
    printl("Task FS begins.\n");

    /* open the device: hard disk */
    MESSAGE driver_msg;
    driver_msg.type = DEV_OPEN;
    send_recv(BOTH, TASK_HD, &driver_msg);

    spin("FS");
}

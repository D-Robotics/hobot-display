#include <stdio.h>
#include "lt8618_ioctl.h"
#include <string.h>
#include <unistd.h>

int main()
{
    unsigned int connected = 0;

    int ret = -1;
    lt8618_ioctl_init();
    lt8618_get_hdmi_connected(&connected);
    lt8618_ioctl_deinit();

    if(connected == 1)
        printf("1");
    else
        printf("0");

    return 0;
}
#include <stdio.h>
#include "lt8618_ioctl.h"
#include <string.h>
#include <unistd.h>

int main()
{
    hdmi_timing_t hdmi_timing;

    int ret = -1;
    lt8618_ioctl_init();
    ret = lt8618_get_edid_resolution_ratio((hdmi_timing_t *)&hdmi_timing);
    lt8618_ioctl_deinit();

    return ret;
}
#include "lt8618_ioctl.h"
#define LT8618_IO_MAGIC 'F'

#define LT8618_IOW(num, dtype) _IOW(LT8618_IO_MAGIC, num, dtype)
#define LT8618_IOR(num, dtype) _IOR(LT8618_IO_MAGIC, num, dtype)
#define LT8618_IOWR(num, dtype) _IOWR(LT8618_IO_MAGIC, num, dtype)
#define LT8618_IO(num) _IO(LT8618_IO_MAGIC, num)

#define LT8618_SET_RESOLUTION_RATIO LT8618_IOW(101, hobot_hdmi_sync_t)
#define LT8618_GET_EDID_RESOLUTION_RATIO LT8618_IOR(100, hobot_hdmi_sync_t)
#define LT8618_GET_EDID_RAW LT8618_IOR(103, edid_raw_t)
#define LT8618_SET_EDID_TIMING LT8618_IOW(102, hdmi_timing_t)
#define LT8618_GET_HDMI_CONNECTED LT8618_IOR(106, unsigned int)

#define LT8618_DEC      "/dev/lt8618_ioctl"

static int lt8618_fd = -1;

int lt8618_ioctl_init(void)
{
    lt8618_fd = open(LT8618_DEC, O_RDWR);
    if (lt8618_fd < 0) {
        printf("open device %s failed\n", LT8618_DEC);
        return -1;
    }

    return 0;
}

int lt8618_ioctl_deinit(void)
{
    if (lt8618_fd > 0) {
        close(lt8618_fd);
    }
    
    return 0;
}

int lt8618_set_resolution_ratio(hobot_hdmi_sync_t * sync)
{
    if (lt8618_fd < 0) {
        printf("device not open\n");
    }
    printf("auto:%d\n",sync->auto_detect);
    
    if (ioctl(lt8618_fd, LT8618_SET_RESOLUTION_RATIO, &sync) < 0) {
       printf("LT8618_SET_RESOLUTION_RATIO failed\n");
       return -1;
    }

    return 0;
}

int lt8618_get_edid_resolution_ratio(hobot_hdmi_sync_t * sync)
{
    if (lt8618_fd < 0) {
        printf("device not open\n");
    }
    if (ioctl(lt8618_fd, LT8618_GET_EDID_RESOLUTION_RATIO, sync) < 0) {
       //printf("LT8618_GET_EDID_RESOLUTION_RATIO failed\n");
       return -1;
    }
    return 0;
}

int lt8618_set_hdmi_timing(hdmi_timing_t* sync)
{
    if (lt8618_fd < 0) {
        printf("device not open\n");
    }
    if (ioctl(lt8618_fd, LT8618_SET_EDID_TIMING, sync) < 0) {
       //printf("LT8618_GET_EDID_RESOLUTION_RATIO failed\n");
       return -1;
    }
    return 0;
}

int lt8618_get_edid_data(edid_raw_t* edid)
{
    if (lt8618_fd < 0) {
        printf("device not open\n");
    }
    if (ioctl(lt8618_fd, LT8618_GET_EDID_RAW, edid) < 0) {
       //printf("LT8618_GET_EDID_RESOLUTION_RATIO failed\n");
       return -1;
    }
    return 0;
}

int lt8618_get_hdmi_connected(unsigned int* connected)
{
    if (lt8618_fd < 0) {
        printf("device not open\n");
    }
    if (ioctl(lt8618_fd, LT8618_GET_HDMI_CONNECTED, connected) < 0) {
       printf("LT8618_GET_HDMI_CONNECTED failed\n");
       return -1;
    }
    return 0;
}

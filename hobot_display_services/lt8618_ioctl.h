#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>

#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/stat.h>

#ifndef _HOBOT_LT8618_H_
#define _HOBOT_LT8618_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef struct hdmi_timing
{
	int auto_detect;
	int hfp;
	int hs;
	int hbp;
	int hact;
	int htotal;
	int vfp;
	int vs;
	int vbp;
	int vact;
	int vtotal;
	int vic;
	int pic_ratio;
	int clk;

} hdmi_timing_t;

typedef struct hobot_hdmi_sync {
	int auto_detect;
	int hfp;
	int hs;
	int hbp;
	int hact;
	int htotal;
	int vfp;
	int vs;
	int vbp;
	int vact;
	int vtotal;
	int vic;
	int pic_ratio;
	int clk;
} hobot_hdmi_sync_t;

typedef enum {
	_HDMI_480P60_ = 0,
	_HDMI_576P50_,

	_HDMI_720P60_,
	_HDMI_720P50_,
	_HDMI_720P30_,
	_HDMI_720P25_,

	_HDMI_1080P60_,
	_HDMI_1080P50_,
	_HDMI_1080P30_,
	_HDMI_1080P25_,

	_HDMI_1080i60_,
	_HDMI_1080i50_,

	_HDMI_4K30_,

	_HDMI_800x600P60_,
	_HDMI_1024x768P60_,
	_HDMI_1024x600_,
	_HDMI_800x480_,
}LT8618_Resolution_Ratio;

typedef struct edid_raw
{
	int block_num;
	unsigned char edid_data[256];
	unsigned char edid_data2[256];
} edid_raw_t;

int lt8618_ioctl_init(void);

int lt8618_ioctl_deinit(void);

int lt8618_set_resolution_ratio(hobot_hdmi_sync_t *ratio);

int lt8618_get_edid_resolution_ratio(hobot_hdmi_sync_t * sync);

int lt8618_set_hdmi_timing(hdmi_timing_t* sync);

int lt8618_get_edid_data(edid_raw_t* edid);

int lt8618_get_hdmi_connected(unsigned int* connected);

#ifdef __cplusplus
}
#endif

#endif
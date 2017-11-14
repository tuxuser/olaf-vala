#ifndef _LAFSTRUCTS_H
#define _LAFSTRUCTS_H

#include <stdint.h>

#pragma pack(push, 1)
typedef struct _PHONEINFO
{
    uint8_t ResponseHeader[3];      

    uint32_t Finished;            // 0x00
    uint8_t ModelName[0xA];       // 0x04
    uint8_t SoftwareVersion[0x1E];// 0x0E
    uint8_t SubVersion;           // 0x2C
    uint8_t SerialNumber[0x14];   // 0x2D
    uint16_t BatteryLevel;        // 0x41
    uint8_t PhoneType[0xA];       // 0x43
    uint8_t OSVersion[0xA];       // 0x4D
    uint8_t PhoneNumber[0xF];     // 0x57
    uint8_t CurrentMode;          // 0x66
    uint8_t PreventUpgrade;       // 0x67
    uint8_t Reserved[0x2B];       // 0x68
} PHONEINFO;                      // size 0x96 (incl ResponseHeader)

typedef struct _LAF_PROPERTIES
{
    uint16_t BlobSize;				// 0x000
    uint8_t Reserved[0xE];			// 0x002
    uint8_t DownloadType;				// 0x010
    uint8_t Reserved2[0x10];			// 0x011
    uint32_t DownloadSpeedFloat;		// 0x021
    uint32_t Reserved3;				// 0x025
    uint8_t DownloadSwVersion[0x108];	// 0x029
    uint8_t ModelName[0x1E];			// 0x131
    uint8_t DeviceSwVersion[0x100];	// 0x14f
    uint8_t DeviceFactoryVersion[0x150];// 0x24f
    uint8_t BootloaderVersion[0x28];	// 0x39f
    uint8_t Imei[0x14];				// 0x3c7
    uint8_t Pid[0x1E];				// 0x3db
    uint8_t DownloadCable[0xA];		// 0x3f9
    uint8_t UsbVersion[0x14];			// 0x403
    uint8_t HardwareRevision[0x14];	// 0x417
    uint32_t BatteryLevel;			// 0x42b
    uint8_t SecureDevice;				// 0x42f
    uint8_t DeviceBuildType[0xA];		// 0x430
    uint8_t ChipsetPlatform[0x14];	// 0x43a
    uint8_t TargetOperator[0x14];		// 0x44e
    uint8_t TargetCountry[0x86];		// 0x462
    uint8_t LafSwVersion[0x14];		// 0x4e8
    uint32_t ApFactoryResetStatus;	// 0x4fc
    uint32_t CpFactoryResetStatus;	// 0x500
    uint32_t IsDownloadNotFinish;		// 0x504
    uint32_t Qem;						// 0x508
    uint8_t Reserved4[0x1C];			// 0x50C
    uint8_t DeviceFactoryOutVersion[0x100];// 0x528
    uint8_t CupssSwFv[0x100];			// 0x628
    uint32_t IsOneBinaryDualPlan;		// 0x728
    uint32_t MemorySize;				// 0x72C
    uint8_t MemoryID[4];				// 0x730
    uint8_t Reserved5[0x3D4];			// 0x734
} LAF_PROPERTIES;					// size 0xB08

#pragma pack(pop)

#endif
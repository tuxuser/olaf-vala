[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "lafstructs.h")]
namespace Vapi.LafStructs
{
    /*
     * Workaround due to missing packed attribute in vala
     */

    [CCode(cname = "PHONEINFO")]
    public struct PhoneInfoStruct
    {
        uint8 ResponseHeader[3];

        uint32 Finished;            // 0x00
        uint8 ModelName[0xA];       // 0x04
        uint8 SoftwareVersion[0x1E];// 0x0E
        uint8 SubVersion;           // 0x2C
        uint8 SerialNumber[0x14];   // 0x2D
        uint16 BatteryLevel;        // 0x41
        uint8 PhoneType[0xA];       // 0x43
        uint8 OSVersion[0xA];       // 0x4D
        uint8 PhoneNumber[0xF];     // 0x57
        uint8 CurrentMode;          // 0x66
        uint8 PreventUpgrade;       // 0x67
        uint8 Reserved[0x2B];       // 0x68
    }                               // size 0x96 (incl ResponseHeader)

    [CCode(cname = "LAF_PROPERTIES")]
    public struct LafPropertiesStruct
    {
        uint16 BlobSize;				// 0x000
        uint8 Reserved[0xE];			// 0x002
        uint8 DownloadType;				// 0x010
        uint8 Reserved2[0x10];			// 0x011
        uint32 DownloadSpeedFloat;		// 0x021
        uint32 Reserved3;				// 0x025
        uint8 DownloadSwVersion[0x108];	// 0x029
        uint8 ModelName[0x1E];			// 0x131
        uint8 DeviceSwVersion[0x100];	// 0x14f
        uint8 DeviceFactoryVersion[0x150];// 0x24f
        uint8 BootloaderVersion[0x28];	// 0x39f
        uint8 Imei[0x14];				// 0x3c7
        uint8 Pid[0x1E];				// 0x3db
        uint8 DownloadCable[0xA];		// 0x3f9
        uint8 UsbVersion[0x14];			// 0x403
        uint8 HardwareRevision[0x14];	// 0x417
        uint32 BatteryLevel;			// 0x42b
        uint8 SecureDevice;				// 0x42f
        uint8 DeviceBuildType[0xA];		// 0x430
        uint8 ChipsetPlatform[0x14];	// 0x43a
        uint8 TargetOperator[0x14];		// 0x44e
        uint8 TargetCountry[0x86];		// 0x462
        uint8 LafSwVersion[0x14];		// 0x4e8
        uint32 ApFactoryResetStatus;	// 0x4fc
        uint32 CpFactoryResetStatus;	// 0x500
        uint32 IsDownloadNotFinish;		// 0x504
        uint32 Qem;						// 0x508
        uint8 Reserved4[0x1C];			// 0x50C
        uint8 DeviceFactoryOutVersion[0x100];// 0x528
        uint8 CupssSwFv[0x100];			// 0x628
        uint32 IsOneBinaryDualPlan;		// 0x728
        uint32 MemorySize;				// 0x72C
        uint8 MemoryID[4];				// 0x730
        uint8 Reserved5[0x3D4];			// 0x734
    }									// size 0xB08
}
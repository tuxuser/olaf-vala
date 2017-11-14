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
}
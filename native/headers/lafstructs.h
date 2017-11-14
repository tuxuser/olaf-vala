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
#pragma pack(pop)

#endif
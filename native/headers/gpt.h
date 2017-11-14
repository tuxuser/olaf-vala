#ifndef _GPT_H
#define _GPT_H

#include <stdint.h>

#pragma pack(push, 1)
typedef struct _GPT_HEADER
{
    uint8_t Signature[8];     // 00
    uint32_t Version;         // 08
    uint32_t Headersize;      // 12
    uint32_t HeaderCrc32;     // 16
    uint32_t Reserved;        // 20
    uint64_t CurrentLBA;      // 24
    uint64_t BackupLBA;       // 32
    uint64_t FirstUsableLBA;  // 40
    uint64_t LastUsableLBA;   // 48
    uint8_t DiskGUID[16];     // 56
    uint64_t FirstEntryLba;   // 72
    uint32_t NumOfEntries;    // 80
    uint32_t SizeOfEntry;     // 84
    uint32_t EntriesCRC32;    // 88
    uint8_t Reserved2[420];   // 92
} GPT_HEADER;               // size 512

typedef struct _GPT_PARTITION
{
    uint8_t PartitionGUID[16];    // 0
    uint8_t UniqueGUID[16];       // 16
    uint64_t StartLBA;            // 32
    uint64_t EndLBA;              // 40
    uint64_t Attributes;          // 48
    uint8_t PartitionName[72];    // 56
} GPT_PARTITION;                // size 128

typedef struct _MBR_PARTITION
{
    uint8_t Status;       // 0
    uint8_t StartChs[3];  // 1
    uint8_t Type;         // 4
    uint8_t EndChs[3];    // 5
    uint32_t StartLBA;    // 8
    uint32_t LBASize;     // 12
} MBR_PARTITION;        // size 16

typedef struct _MASTER_BOOT_RECORD
{
    uint8_t Bootcode[440];        // 0
    uint32_t DiskSignature;       // 440
    uint16_t Empty;               // 444
    MBR_PARTITION Partition[4];  // 446
    uint16_t MBRSignature;        // 510
} MASTER_BOOT_RECORD; // size 512

typedef struct _PARTITION_TABLE
{
    MASTER_BOOT_RECORD mbr;       // 0
    GPT_HEADER gptHeader;        // 512
} PARTITION_TABLE;              // size 1024
#pragma pack(pop)

#endif
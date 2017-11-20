#ifndef _KDZSTRUCTS_H
#define _KDZSTRUCTS_H

#include <stdint.h>

#pragma pack(push, 1)
typedef struct _DZ_CHUNK {
	uint32_t Magic;
	char SliceName[32];	/* name of the slice ("partition") */
	char FileName[64];	/* name of this chunk */
	uint32_t TargetSize;	/* size of target area */
	uint32_t DataSize;	/* amount of compressed data in chunk */
	uint8_t MD5[16];		/* MD5 of uncompressed data */
	uint32_t TargetAddr;	/* first block to write */
	uint32_t TrimCount;	/* blocks to TRIM before writing */
	uint32_t Device;	/* flash device Id */
	uint32_t CRC32;		/* CRC32 of uncompressed data */
	uint8_t Padding[372];
} DZ_CHUNK;

typedef struct _DZ_HEADER {
	uint32_t Magic;
	uint32_t MajorVersion;		/* format major version */
	uint32_t MinorVersion;		/* format minor version */
	uint32_t Reserved0;	/* patch level? */
	char Device[32];	/* device name */
	char Version[144];	/* "factoryversion" */
	uint32_t ChunkCount;	/* number of chunks */
	uint8_t MD5[16];		/* MD5 of chunk headers */
	uint32_t Unknown0;
	uint32_t Reserved1;
	uint16_t Reserved4;
	uint8_t Unknown1[16];
	char Unknown2[50];	/* A##-M##-C##-U##-0 ? */
	char BuildType[20];	/* "user"? */
	uint8_t Unknown3[4];
	char AndroidVersion[10]; /* Android version */
	char OldDateCode[10];	/* anti-rollback? */
	uint32_t FeatureYesNo[45]; //Y - N? - last is FF FF FF FF
} DZ_HEADER;

typedef struct _KDZ_ENTRY {
	char FileName[256];
	uint64_t FileSize;
	uint64_t FileOffset;
} KDZ_ENTRY; //0x110

typedef struct _KDZ_HEADER {
	uint32_t HeaderSize;
	uint32_t Unknown;
	//KDZ_ENTRY Files[];
} KDZ_HEADER;

#pragma pack(pop)

#endif
[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "kdzstructs.h")]
namespace Vapi.KdzStructs
{
    /*
     * Workaround due to missing packed attribute in vala
     */

    [CCode(cname = "DZ_CHUNK")]
    struct DzChunk {
        uint32 Magic;
        char SliceName[32];	/* name of the slice ("partition") */
        char FileName[64];	/* name of this chunk */
        uint32 TargetSize;	/* size of target area */
        uint32 DataSize;	/* amount of compressed data in chunk */
        uint8 MD5[16];		/* MD5 of uncompressed data */
        uint32 TargetAddr;	/* first block to write */
        uint32 TrimCount;	/* blocks to TRIM before writing */
        uint32 Device;	/* flash device Id */
        uint32 CRC32;		/* CRC32 of uncompressed data */
        char Padding[372];
    }
    
    [CCode(cname = "DZ_HEADER")]
    struct DzHeader {
        uint32 Magic;
        uint32 MajorVersion;		/* format major version */
        uint32 MinorVersion;		/* format minor version */
        uint32 Reserved0;	/* patch level? */
        char Device[32];	/* device name */
        char Version[144];	/* "factoryversion" */
        uint32 ChunkCount;	/* number of chunks */
        uint8 MD5[16];		/* MD5 of chunk headers */
        uint32 Unknown0;
        uint32 Reserved1;
        uint16 Reserved4;
        uint8 Unknown1[16];
        char Unknown2[50];	/* A##-M##-C##-U##-0 ? */
        char BuildType[20];	/* "user"? */
        uint8 Unknown3[4];
        char AndroidVersion[10]; /* Android version */
        char OldDateCode[10];	/* anti-rollback? */
        uint32 FeatureYesNo[45]; //Y - N? - last is FF FF FF FF
    }
    
    [CCode(cname = "KDZ_ENTRY")]
    struct KdzEntry {
        char FileName[256];
        uint64 FileSize;
        uint64 FileOffset;
    }
    
    [CCode(cname = "KDZ_HEADER")]
    struct KdzHeader {
        uint32 HeaderSize;
        uint32 Unknown;
        //KdzEntry Files[];
    }
}
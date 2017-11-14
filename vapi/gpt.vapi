[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "gpt.h")]
namespace Vapi.Gpt
{
    /*
     * Workaround due to missing packed attribute in vala
     */

    [CCode(cname = "GPT_HEADER")]
    public struct GptHeader
    {
        uint8 Signature[8];     // 00
        uint32 Version;         // 08
        uint32 Headersize;      // 12
        uint32 HeaderCrc32;     // 16
        uint32 Reserved;        // 20
        uint64 CurrentLBA;      // 24
        uint64 BackupLBA;       // 32
        uint64 FirstUsableLBA;  // 40
        uint64 LastUsableLBA;   // 48
        uint8 DiskGUID[16];     // 56
        uint64 FirstEntryLba;   // 72
        uint32 NumOfEntries;    // 80
        uint32 SizeOfEntry;     // 84
        uint32 EntriesCRC32;    // 88
        uint8 Reserved2[420];   // 92
    } // size 512

    [CCode(cname = "GPT_PARTITION")]
    public struct GptPartition
    {
        uint8 PartitionGUID[16];    // 0
        uint8 UniqueGUID[16];       // 16
        uint64 StartLBA;            // 32
        uint64 EndLBA;              // 40
        uint64 Attributes;          // 48
        uint16 PartitionName[36];    // 56
    } // size 128

    [CCode(cname = "MBR_PARTITION")]
    public struct MBRPartition
    {
        uint8 Status;       // 0
        uint8 StartChs[3];  // 1
        uint8 Type;         // 4
        uint8 EndChs[3];    // 5
        uint32 StartLBA;    // 8
        uint32 LBASize;     // 12
    } // size 16

    [CCode(cname = "MASTER_BOOT_RECORD")]
    public struct MasterBootRecord
    {
        uint8 Bootcode[440];        // 0
        uint32 DiskSignature;       // 440
        uint16 Empty;               // 444
        MBRPartition Partition[4];  // 446
        uint16 MBRSignature;        // 510
    } // size 512

    [CCode(cname = "PARTITION_TABLE")]
    public struct PartitionTable
    {
        MasterBootRecord mbr;       // 0
        GptHeader gptHeader;        // 512
    } // size 1024
}
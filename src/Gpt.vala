namespace Olaf
{
    struct GPTHeader
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

    struct GPTPartition
    {
        uint8 PartitionGUID[16];    // 0
        uint8 UniqueGUID[16];       // 16
        uint64 StartLBA;            // 32
        uint64 EndLBA;              // 40
        uint64 Attributes;          // 48
        uint8 PartitionName[72];    // 56
    } // size 128

    struct MBRPartition
    {
        uint8 Status;       // 0
        uint8 StartChs[3];  // 1
        uint8 Type;         // 4
        uint8 EndChs[3];    // 5
        uint32 StartLBA;    // 8
        uint32 LBASize;     // 12
    } // size 16

    struct MasterBootRecord
    {
        uint8 Bootcode[440];        // 0
        uint32 DiskSignature;       // 440
        uint16 Empty;               // 444
        MBRPartition Partition[4];  // 446
        uint16 MBRSignature;        // 510
    } // size 512

    struct PartitionTable
    {
        MasterBootRecord mbr;       // 0
        GPTHeader gptHeader;        // 512
    } // size 1024

    public class GPTParser
    {
        private uint8[] table;
        public GPTParser(uint8[] gptTable)
        {
            assert(sizeof(MBRPartition) == 16);
            assert(sizeof(GPTPartition) == 128);
            assert(sizeof(MasterBootRecord) == 512);
            assert(sizeof(GPTHeader) == 512);
            assert(sizeof(PartitionTable) == 1024);
            this.table = gptTable;
        }

        public void Parse()
        {
            PartitionTable* partTable = (PartitionTable*)this.table;
            stdout.printf("gpt has %u NumOfEntries\n", partTable->gptHeader.NumOfEntries);
            return;
            for (int i = 0; i < partTable->gptHeader.NumOfEntries - 1; i++)
            {
                GPTPartition* partitions = (GPTPartition*)&this.table[sizeof(PartitionTable)];
                stdout.printf("%d: %s\n", i,(string)partitions[i].PartitionName);
                Util.hexdump(partitions[i].PartitionName);
            }
        }
    }
}

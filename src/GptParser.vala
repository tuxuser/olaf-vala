using Vapi.Gpt;

namespace Olaf
{
    public class GPTParser
    {
        private uint8[] table;
        public GPTParser(uint8[] gptTable)
        {
            assert(sizeof(MBRPartition) == 16);
            assert(sizeof(GptPartition) == 128);
            assert(sizeof(MasterBootRecord) == 512);
            assert(sizeof(GptHeader) == 512);
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
                GptPartition* partitions = (GptPartition*)&this.table[sizeof(PartitionTable)];
                stdout.printf("%d: %s\n", i,(string)partitions[i].PartitionName);
                Util.hexdump(partitions[i].PartitionName);
            }
        }
    }
}

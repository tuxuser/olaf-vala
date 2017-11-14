using Vapi.Gpt;

namespace Olaf.Structure
{
    public class GPTPartitionTable
    {
        private PartitionTable partitionTable;
        private GptPartition[] Partitions;

        public bool Valid { get; private set; }

        public GPTPartitionTable(uint8[] data)
        {
            assert(sizeof(MBRPartition) == 16);
            assert(sizeof(GptPartition) == 128);
            assert(sizeof(MasterBootRecord) == 512);
            assert(sizeof(GptHeader) == 512);
            assert(sizeof(PartitionTable) == 1024);
            this.Valid = false;

            if (data.length < sizeof(PartitionTable))
            {
                stderr.printf("Invalid GPT partitiontable data\n");
                return;
            }
            Memory.copy(&this.partitionTable, data, sizeof(PartitionTable));
            uint partitionEntryCount = this.partitionTable.gptHeader.NumOfEntries;
            stdout.printf("Found %u GPT partitions\n", partitionEntryCount);

            ulong datasizePartitionEntries = data.length - sizeof(PartitionTable);
            ulong expectSize = sizeof(GptPartition) * partitionEntryCount;
            if (datasizePartitionEntries < expectSize)
            {
                stderr.printf("Insufficient data for GPT partition entries\n");
                return;
            }
            this.Partitions = new GptPartition[partitionEntryCount];
            Memory.copy(this.Partitions, &data[sizeof(PartitionTable)], expectSize);
            this.Valid = true;
        }

        public uint GetPartitionCount()
        {
            return this.Partitions.length;
        }

        public void PrintPartition(uint index)
        {
            if (index > GetPartitionCount())
            {
                stderr.printf("Requested partition %u out of bounds\n", index);
                return;
            }
            stdout.printf("Partition %u: %s\n",
                        index, (string)this.Partitions[index].PartitionName);
        }
    }
}

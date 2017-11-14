using Vapi.Gpt;

namespace Olaf.Structure
{
    public class GPTPartitionTable
    {
        public static uint GPT_TABLE_LENGTH = 0x4400;

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

        public GptHeader GetHeader()
        {
            return this.partitionTable.gptHeader;
        }

        public GptPartition? GetPartition(uint index)
        {
            if (index > GetPartitionCount())
            {
                stderr.printf("Requested partition %u out of bounds\n", index);
                return null;
            }

            return this.Partitions[index];
        }

        public string to_string()
        {
            GptHeader header = this.partitionTable.gptHeader;
            StringBuilder builder = new StringBuilder();
            builder.append("::: GPT Header :::\n");
            builder.append_printf("Signature: %s\n", (string)header.Signature);
            builder.append_printf("Version: 0x%04x\n", header.Version);
            builder.append_printf("HeaderSize: 0x%04x\n", header.Headersize);
            builder.append_printf("HeaderCRC32: 0x%04x\n", header.HeaderCrc32);
            builder.append_printf("Reserved: 0x%04x\n", header.Reserved);
            builder.append_printf("CurrentLBA: 0x%08llx\n", header.CurrentLBA);
            builder.append_printf("BackupLBA: 0x%08llx\n", header.BackupLBA);
            builder.append_printf("FirstUsableLBA: 0x%08llx\n", header.FirstUsableLBA);
            builder.append_printf("LastUsableLBA: 0x%08llx\n", header.LastUsableLBA);
            //builder.append_printf("DiskGUID: %s\n", header.DiskGUID.to_string());
            builder.append_printf("FirstEntryLBA: 0x%08llx\n", header.FirstEntryLba);
            builder.append_printf("NumOfEntries: 0x%04x\n", header.NumOfEntries);
            builder.append_printf("SizeOfEntry: 0x%04x\n", header.SizeOfEntry);
            builder.append_printf("EntriesCRC32: 0x%04x\n", header.EntriesCRC32);
            builder.append("\n");
            builder.append("::: GPT Partitions :::\n");
            for (int i=0; i < GetPartitionCount(); i++)
            {
                GptPartition part = GetPartition(i);
                string name = Util.UInt16ToString(part.PartitionName);
                builder.append_printf("Partition %u) %s LBA:0x%08llx-0x%08llx\tAttrs: 0x%08llx\n",
                                                i, name, part.StartLBA, part.EndLBA, part.Attributes);
            }
            return builder.str;
        }

    }
}

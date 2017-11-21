using Vapi.KdzStructs;

namespace Olaf.Structure
{
    public class Kdz
    {
        private const uint32 DZ_FILE_MAGIC = 0x74189632;
        private const uint32 DZ_CHUNK_MAGIC = 0x78951230;

        private Posix.FILE? File;

        private KdzHeader Header;
        private KdzEntry[] KdzEntries;

        private DzHeader DzFile;
        private DzChunk[] DzChunks;

        private string DzFilename;
        private ulong DzOffset;

        public Kdz(string filePath)
        {
            this.File = Posix.FILE.open(filePath, "rb");
            if (this.File == null)
            {
                stderr.printf("Failed to open file \"%s\"\n", filePath);
                return;
            }

            this.Header = new KdzHeader();
            // Read Header fields first
            this.File.read(&this.Header, sizeof(KdzHeader), 1);

            // Read the contained kdz entries
            ulong length = (this.Header.HeaderSize - sizeof(KdzHeader));
            this.KdzEntries = new KdzEntry[length / sizeof(KdzEntry)];
            for (int i = 0; i < this.KdzEntries.length; i++)
            {
                this.File.read(&this.KdzEntries[i], sizeof(KdzEntry), 1);
                // Check for last-entry-marker
                if (this.KdzEntries[i].FileName[0] == 0x3)
                { // Resize array
                    stdout.printf("KDZ contains %i files\n", i + 1);
                    this.KdzEntries.resize(i + 1);
                    break;
                }
            }

            // Search the DZ file
            this.DzOffset = 0;
            foreach(KdzEntry entry in this.KdzEntries)
            {
                if(((string)entry.FileName).ascii_down().has_suffix(".dz"))
                {
                    stdout.printf("Found DZ File: %s\n", (string)entry.FileName);
                    this.DzOffset = (ulong)entry.FileOffset;
                    this.DzFilename = (string)entry.FileName;
                }
            }

            if (this.DzOffset == 0)
            {
                stderr.printf("No DZ File found!\n");
                return;
            }
            
            // Read the DZ file
            this.File.seek((long)this.DzOffset, Posix.FILE.SEEK_SET);
            this.DzFile = new DzHeader();
            this.File.read(&this.DzFile, sizeof(DzHeader), 1);
            // Check DZ file magic
            if (this.DzFile.Magic != DZ_FILE_MAGIC)
            {
                stderr.printf("Invalid MAGIC for inner DZ file\n");
                return;
            }
            else if (this.DzFile.MajorVersion != 2 || this.DzFile.MinorVersion != 1)
            {
                stderr.printf("Unsupported DZ file version: %u.%u\n",
                            this.DzFile.MajorVersion, this.DzFile.MinorVersion);
                stderr.printf("Only supporting v2.1 for now...\n");
                return;
            }

            // Read DZ chunks
            this.DzChunks = new DzChunk[this.DzFile.ChunkCount];
            for (int i = 0; i < this.DzFile.ChunkCount; i++)
            {
                this.File.read(&this.DzChunks[i], sizeof(DzChunk), 1);
                if (this.DzChunks[i].Magic != DZ_CHUNK_MAGIC)
                {
                    stderr.printf("DZ Chunk has invalid magic!\n");
                    return;
                }
                // Forward to next chunk, skipping the chunk data
                this.File.seek(this.DzChunks[i].DataSize, Posix.FILE.SEEK_CUR);
            }
            this.File.rewind();
        }

        public void Extract(string destinationFilePath)
        {
            uint8[] buf;
            string destination = "";
            foreach(KdzEntry kdzEntry in this.KdzEntries)
            {
                destination = Path.build_path(Path.DIR_SEPARATOR_S, destinationFilePath, (string)kdzEntry.FileName);
                Posix.FILE? f = Posix.FILE.open(destination, "wb");
                if (f == null)
                {
                    stderr.printf("Failed to open file \"%s\" for writing!\n", destination);
                    return;
                }
                stdout.printf("* Extracting KDZ file: \"%s\"\n", (string)kdzEntry.FileName);
                buf = new uint8[(ulong)kdzEntry.FileSize];
                this.File.seek((long)kdzEntry.FileOffset, Posix.FILE.SEEK_SET);
                this.File.read(buf, (size_t)kdzEntry.FileSize, 1);
                f.write(buf, (size_t)kdzEntry.FileSize, 1);
            }

            // Set to first DZ data blob
            long offset = (long)(this.DzOffset + sizeof(DzHeader) + sizeof(DzChunk));
            foreach(DzChunk dzChunk in this.DzChunks)
            {
                destination = Path.build_path(Path.DIR_SEPARATOR_S, destinationFilePath, (string)dzChunk.FileName);
                Posix.FILE? f = Posix.FILE.open(destination, "wb");
                if (f == null)
                {
                    stderr.printf("Failed to open file \"%s\" for writing!\n", destination);
                    return;
                }
                stdout.printf("* Extracting DZ file: \"%s\"\n", (string)dzChunk.FileName);
                buf = new uint8[dzChunk.DataSize];
                this.File.seek(offset, Posix.FILE.SEEK_SET);
                this.File.read(buf, dzChunk.DataSize, 1);
                f.write(buf, (size_t)dzChunk.DataSize, 1);
                // Forward to next data blob
                offset += (long)(dzChunk.DataSize + sizeof(DzChunk));
            }
        }

        public string to_string()
        {
            StringBuilder builder = new StringBuilder();

            builder.append("::: KDZ Header :::\n");
            builder.append_printf("HeaderSize: 0x%04x\n", this.Header.HeaderSize);
            builder.append_printf("Unknown: 0x%04x\n", this.Header.Unknown);
            builder.append("\n");
            
            builder.append("::: KDZ Entries :::\n");
            builder.append_printf("Count: %lu\n", this.KdzEntries.length);
            for (int i = 0; i < this.KdzEntries.length; i++)
            {
                builder.append_printf("Filename: %s | FileSize: 0x%llx | FileOffset: 0x%llx\n",
                                                            (string)this.KdzEntries[i].FileName,
                                                            this.KdzEntries[i].FileSize,
                                                            this.KdzEntries[i].FileOffset);
            }
            builder.append("\n");

            builder.append("::: DZ File :::\n");
            builder.append_printf("Magic: 0x%x\n", this.DzFile.Magic);
            builder.append_printf("Version: %u.%u\n",
                            this.DzFile.MajorVersion, this.DzFile.MinorVersion);
            builder.append_printf("Reserved0: 0x%x\n", this.DzFile.Reserved0);
            builder.append_printf("Device: %s\n", (string)this.DzFile.Device);
            builder.append_printf("Version: %s\n", (string)this.DzFile.Version);
            builder.append_printf("ChunkCount: %u\n", this.DzFile.ChunkCount);
            //builder.append_printf("MD5: %s\n", (string)this.DzFile.MD5);
            builder.append_printf("Unknown0: 0x%x\n", this.DzFile.Unknown0);
            builder.append_printf("Reserved1: 0x%x\n", this.DzFile.Reserved1);
            builder.append_printf("Reserved4: 0x%x\n", this.DzFile.Reserved4);
            //builder.append_printf("Unknown1: %s\n", (string)this.DzFile.Unknown1);
            builder.append_printf("Unknown2: %s\n", (string)this.DzFile.Unknown2);
            builder.append_printf("BuildType: %s\n", (string)this.DzFile.BuildType);
            //builder.append_printf("Unknown3: %s\n", (string)this.DzFile.Unknown3);
            builder.append_printf("AndroidVersion: %s\n", (string)this.DzFile.AndroidVersion);
            builder.append_printf("OldDateCode: %s\n", (string)this.DzFile.OldDateCode);
            //builder.append_printf("\n", this.DzFile.FeatureYesNo);
            builder.append("\n");

            builder.append("::: DZ Chunks :::\n");
            builder.append_printf("Count: %u\n", this.DzChunks.length);
            for (int i = 0; i < this.DzChunks.length; i++)
            {
                builder.append_printf("File %i:\n", i);
                builder.append_printf("Magic: 0x%x\n", this.DzChunks[i].Magic);
                builder.append_printf("SliceName: %s\n", (string)this.DzChunks[i].SliceName);
                builder.append_printf("FileName: %s\n", (string)this.DzChunks[i].FileName);
                builder.append_printf("TargetSize: 0x%x\n", this.DzChunks[i].TargetSize);
                builder.append_printf("DataSize: 0x%x\n", this.DzChunks[i].DataSize);
                //builder.append_printf("MD5: %s\n", this.DzChunks[i].MD5);
                builder.append_printf("TargetAddress: 0x%x\n", this.DzChunks[i].TargetAddr);
                builder.append_printf("TrimCount: 0x%x\n", this.DzChunks[i].TrimCount);
                builder.append_printf("Device: 0x%x\n", this.DzChunks[i].Device);
                builder.append_printf("CRC32: 0x%x\n", this.DzChunks[i].CRC32);
                //builder.append_printf("Padding: %s\n", this.DzChunks[i].Padding);
                builder.append("\n");
            }

            return builder.str;
        }
    }
}
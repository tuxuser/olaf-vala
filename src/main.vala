using GLib;
using Olaf.Packet;
using Olaf.Structure;

namespace Olaf
{
	public class Program
	{
		private static void InitializeMaps()
		{
			stdout.printf("Initializing maps - yes, vala has its quirks\n");
			Packet.AtCommandMap.init();
			Packet.LAFCommandMap.init();
		}

		private static Communication.LGDevice? ChooseDevice(List<Communication.LGDevice?> devices)
		{
			int index = 0, choice = 0, deviceCount = (int)devices.length();

			if (deviceCount == 1)
				// Auto connect
				return devices.nth_data(0);

			devices.foreach ((entry) => {
				stdout.printf("%i) %s\n",++index, entry.to_string());
			});
			
			stdout.printf("Choose device: ");
			stdin.scanf("%d", out choice);

			--choice;
			if (choice < 0 || choice > deviceCount)
				// Invalid choice
				return null;

			return devices.nth_data(choice);
		}

		private static void ShowUsage()
		{
			stdout.printf("\tpull [remote file path] [local file path]\n");
			stdout.printf("\tdump [partition name] [local destination file]\n");
			stdout.printf("\tflash [partition name] [local source file]\n");
			stdout.printf("\tshell - Execute an interactive shell session\n");
			stdout.printf("\tinfo - Show phone / LAF info\n");
			stdout.printf("\tgpt - Show GPT partition table of LAF device\n");
			stdout.printf("\treboot - Reboot the device\n");
			stdout.printf("\tpoweroff - Power off the device\n");
			stdout.printf("\thelp - Show this listing right here\n");
		}

		// TODO: This will overflow if filesize is over 2GB
		private static void LoadFile(string filePath, out uint8[] outData)
		{
			Posix.FILE f = Posix.FILE.open(filePath, "rb");
			f.seek(0, Posix.FILE.SEEK_END);
			long filesize = f.tell();
			f.seek(0, Posix.FILE.SEEK_SET);
			outData = new uint8[filesize];
			f.read(outData, filesize, 1);
		}

		private static void SaveFile(string filePath, uint8[] inData)
		{
			Posix.FILE f = Posix.FILE.open(filePath, "wb");
			f.write(inData, inData.length, 1);
			f.flush();
		}

		private static void ShowPhoneInfo(LAFProtocol protocol)
		{
			Structure.PhoneInfo phoneInfo;
			protocol.GetPhoneInfo(out phoneInfo);
			stdout.printf(phoneInfo.to_string());
		}

		private static void ShowLafProps(LAFProtocol protocol)
		{
			Structure.LAFProperties props;
			if (protocol.GetLafProperties(out props) != 0)
			{
				stderr.printf("Failed to get LAF properties\n");
				return;
			}
			stdout.printf(props.to_string());
		}

		private static void RunCmdShell(LAFProtocol protocol)
		{
			while(true)
			{
				stdout.printf("#LAF>");
				string? input = stdin.read_line();
				stdout.printf("\n");
				if (input != null && input.length > 1)
				{
					if (input == "exit")
						break;
					string reply;
					if(protocol.SendCmdExec(input, out reply) == 0)
						stdout.printf(reply);
					stdout.printf("\n");
				}
			}
		}

		private static GPTPartitionTable? GetGptPartitionTable(LAFProtocol protocol)
		{
			Structure.GPTPartitionTable partTable;
			if (protocol.GetPartitionTable(out partTable) != 0)
			{
				stderr.printf("Failed to get partition table\n");
				return null;
			}
			return partTable;
		}

		private static void PullFile(LAFProtocol protocol, string remotePath, string localDestinationPath)
		{
			uint8[] readData;
			protocol.ReadFile(remotePath, out readData);
			SaveFile(localDestinationPath, readData);
		}

		private static void ReadPartition(LAFProtocol protocol, string partitionName, string destPath)
		{
			// Write 10MB chunks to file
			const uint CHUNK_SIZE = 10 * 1024 * 1024;

			Posix.FILE localFileHandle = Posix.FILE.open(destPath, "wb");
			if (localFileHandle == null)
			{
				stderr.printf("Failed to open file \"%s\" for writing\n", destPath);
				return;
			}

			GPTPartitionTable? table = GetGptPartitionTable(protocol);
			if (table == null)
			{
				stderr.printf("Failed to get partition table\n");
				return;
			}

			Vapi.Gpt.GptPartition? part = table.GetPartitionByName(partitionName);
			if (part == null)
			{
				stderr.printf("Failed to get partition \"%s\"\n", partitionName);
				return;
			}

			uint remoteFileHandle;
			if (protocol.SendOpen("", out remoteFileHandle) != 0)
			{
				stderr.printf("Failed to open remote file handle\n");
				return;
			}

			uint64 offset = part.StartLBA * 512;
			uint64 endOffset = part.EndLBA * 512;
			uint64 readSize = 0;
			uint8[] readData;
			while (offset < endOffset)
			{
				readSize = (endOffset - offset) > CHUNK_SIZE ? CHUNK_SIZE : (endOffset - offset);
				protocol.ReadData(remoteFileHandle, offset, readSize, out readData);
				localFileHandle.write(readData, (size_t)readSize, 1);
				offset += readSize;
			}

			if (protocol.SendClose(remoteFileHandle) != 0)
			{
				stderr.printf("Failed to close remote file handle\n");
				return;
			}

			stdout.printf("Reading partition finished!\n");
		}

		private static void WritePartition(LAFProtocol protocol, string partitionName, string sourcePath)
		{
			// Read 10MB chunks from file
			const uint CHUNK_SIZE = 10 * 1024 * 1024;

			long fileSize;
			Posix.FILE localFileHandle = Posix.FILE.open(sourcePath, "rb");
			if (localFileHandle == null)
			{
				stderr.printf("Failed to open file \"%s\" for reading\n", sourcePath);
				return;
			}
			localFileHandle.seek(0, Posix.FILE.SEEK_END);
			fileSize = localFileHandle.tell();
			localFileHandle.seek(0, Posix.FILE.SEEK_SET);

			GPTPartitionTable? table = GetGptPartitionTable(protocol);
			if (table == null)
			{
				stderr.printf("Failed to get partition table\n");
				return;
			}

			Vapi.Gpt.GptPartition? part = table.GetPartitionByName(partitionName);
			if (part == null)
			{
				stderr.printf("Failed to get partition \"%s\"\n", partitionName);
				return;
			}
			
			if (fileSize > ((part.EndLBA - part.StartLBA) * 512))
			{
				stderr.printf("File to write is bigger than partition...\n");
				return;
			}

			uint remoteFileHandle;
			if (protocol.SendOpen("", out remoteFileHandle) != 0)
			{
				stderr.printf("Failed to open remote file handle\n");
				return;
			}

			protocol.SendErase(remoteFileHandle,
								(uint)part.StartLBA,
								(uint)(part.EndLBA-part.StartLBA));

			uint64 offset = part.StartLBA * 512;
			uint64 endOffset = offset + fileSize;
			uint64 writeSize = 0;
			uint8[] writeData = new uint8[CHUNK_SIZE];
			while (offset < endOffset)
			{
				if ((endOffset - offset) < CHUNK_SIZE)
					writeData.resize((int)(endOffset - offset));

				localFileHandle.read(writeData, (size_t)writeData.length, 1);
				protocol.WriteData(remoteFileHandle, offset, writeData);				
				offset += writeData.length;
			}

			if (protocol.SendClose(remoteFileHandle) != 0)
			{
				stderr.printf("Failed to close remote file handle\n");
				return;
			}
			stdout.printf("Writing partition finished!\n");
		}

		public static int main(string[] args)
		{
			// Disable stdout/stderr buffering
			Posix.setvbuf(Posix.stdout, null, Posix.BufferMode.Unbuffered, 0);
			Posix.setvbuf(Posix.stderr, null, Posix.BufferMode.Unbuffered, 0);

			stdout.printf("Hello from OLAF - [O]pen LG [LAF]\n");

			InitializeMaps();
			Communication.BaseEnumerator enumerator;
	#if WIN32 || MINGW
			debug("Windows -> Choosing serial communication\n");
			enumerator = new Communication.SerialEnumerator();
	#else
			debug("Unix -> Choosing usb communication\n");
			enumerator = new Communication.UsbEnumerator();
	#endif

			List<Communication.LGDevice?> devices;
			int devCount = enumerator.GetDevices(out devices);
			if (devCount <= 0)
			{
				stdout.printf("No LG devices found! Bye!\n");
				return 1;
			}
			stdout.printf("Found %i devices:\n", devCount);

			Communication.LGDevice selectedDevice = ChooseDevice(devices);
			if(selectedDevice == null)
			{
				stdout.printf("Invalid choice, Bye!\n");
				return 2;
			}

			if (!selectedDevice.Open())
			{
				stderr.printf("Opening the device failed!\n");
				return 1;
			}
			
			LAFProtocol protocol = new LAFProtocol(selectedDevice);		
			protocol.SendUnlock();

			if (args.length < 2)
			{
				stderr.printf("No arguments provided!\n");
				ShowUsage();
				return 3;
			}
			string command = args[1];
			switch (command)
			{
				case "pull":
					if (args.length < 4)
					{
						stderr.printf("pull: Missing remote path and/or local destination\n");
						ShowUsage();
						break;
					}
					PullFile(protocol, args[2], args[3]);
					break;
				case "dump":
					if (args.length < 4)
					{
						stderr.printf("dump: Missing partition name and/or destination filepath\n");
						ShowUsage();
						break;
					}
					ReadPartition(protocol, args[2], args[3]);
					break;
				case "flash":
					if (args.length < 4)
					{
						stderr.printf("flash: Missing partition name and/or source filepath\n");
						ShowUsage();
						break;
					}
					WritePartition(protocol, args[2], args[3]);
					break;
				case "shell":
					RunCmdShell(protocol);
					break;
				case "info":
					ShowPhoneInfo(protocol);
					ShowLafProps(protocol);
					break;
				case "gpt":
					GPTPartitionTable table = GetGptPartitionTable(protocol);
					if (table != null)
						stdout.printf(table.to_string());
					else
						stderr.printf("Failed to get partition table\n");
					break;
				case "reboot":
					protocol.SendReboot();
					break;
				case "poweroff":
					protocol.SendPoweroff();
					break;
				case "help":
					ShowUsage();
					break;
				default:
					error("Command \"%s\" is unknown. Try \"help\" !\n", command);
					break;
			}

			/*
			Vapi.Gpt.GptPartition? partition = partTable.GetPartitionByName("nvdata");
			if (partition == null)
				return 4;
			else
				stdout.printf("Found partition!\n");
			*/
			return 0;
		}
	}
}

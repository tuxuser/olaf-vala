using GLib;
using Olaf.Packet;

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
					protocol.SendCmdExec(input, out reply);
					stdout.printf(reply + "\n");
				}
			}
		}

		private static void ShowGptPartitionTable(LAFProtocol protocol)
		{
			Structure.GPTPartitionTable partTable;
			if (protocol.GetPartitionTable(out partTable) != 0)
			{
				stderr.printf("Failed to get partition table\n");
				return;
			}
			stdout.printf(partTable.to_string());
		}

		private static void PullFile(LAFProtocol protocol, string remotePath, string localDestinationPath)
		{
			uint8[] readData;
			protocol.ReadFile(remotePath, out readData);
			SaveFile(localDestinationPath, readData);
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
					error("Sorry, not yet implemented\n");
					break;
				case "flash":
					error("Sorry, not yet implemented\n");
					break;
				case "shell":
					RunCmdShell(protocol);
					break;
				case "info":
					ShowPhoneInfo(protocol);
					ShowLafProps(protocol);
					break;
				case "gpt":
					ShowGptPartitionTable(protocol);
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

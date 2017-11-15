using Olaf.Communication;
using Olaf.Packet;
using Olaf.Structure;

namespace Olaf
{
    public class LAFProtocol
    {
        // https://github.com/Lekensteyn/lglaf/blob/master/protocol.md
        public const uint VERSION = 0x01000004;

        private LGDevice Device;
        public LAFProtocol(LGDevice device)
        {
            this.Device = device;
        }

        private int Send(LAFPacket packet)
        {
            return this.Device.SendPacket(packet);
        }

        private int Receive(out LAFPacket packet)
        {
            LAFPacket tmp;
            int ret = this.Device.ReceivePacket(out tmp);
            if (ret != 0){
                stderr.printf("Failed to receive...\n");
                return -1;
            }
            else if (tmp.Header.CmdName == LAFCommand.RESPONSE_FAIL.to_uint())
            {
                LAFError error = (LAFError)tmp.Header.Arg1;
                stderr.printf("Command FAILED! ErrorCode: 0x%04x (%s)\n",
                                                    error, error.to_string());
                return -2;
            }
            else if (tmp.Header.CmdName != ~tmp.Header.CmdInvert)
            {
                stderr.printf("Inverted Command does not match..\n");
                return -3;
            }
            else if (!tmp.VerifyCrc())
            {
                stderr.printf("CRC checksum does not match...\n");
                return -4;
            }

            packet = tmp;
            return 0;
        }

        private int SendAndReceive(LAFPacket inPacket, out LAFPacket outPacket, string desc)
        {
            if (Send(inPacket) != 0)
            {
                stderr.printf("Failed to send %s request\n", desc);
                return -1;
            }
            if (Receive(out outPacket) != 0)
            {
                stderr.printf("Failed to get %s response\n", desc);
                return -2;
            }
            return 0;
        }
            
        public int SendCentMeter(uint mode)
        {
            LAFPacket response = new LAFPacket.Empty();
            LAFPacket challenge = new LAFPacket.WithEnum(LAFCommand.KILO_CHALLENGE, LAFSubCommand.KILOCENT_CHALLENGE);
            if(SendAndReceive(challenge, out response, "KILO CENT") != 0)
            {
                return -1;
            }

            // Calculate response
            unowned uint8[] challengeBytes = (uint8[])response.Header.Arg2;
            challengeBytes.length = 4;
            uint8[] encryptedBody = new Crypto().EncryptMeterResponse(challengeBytes);

            // Build response
            challenge = new LAFPacket.WithEnum(LAFCommand.KILO_CHALLENGE, LAFSubCommand.KILOMETER_CHALLENGE, 0, mode);
            challenge.SetBody(encryptedBody);

            if(SendAndReceive(challenge, out response, "KILO METER") != 0)
            {
                return -1;
            }

            return 0;
        }
        
        public int SendHello()
        {
            LAFPacket response = new LAFPacket.Empty();
            LAFPacket request = new LAFPacket.WithMainCmdEnum(LAFCommand.HELLO, LAFProtocol.VERSION, 0, 0, 1);
            if(SendAndReceive(request, out response, "HELLO") != 0)
            {
                return -1;
            }
            else if(response.Header.Arg1 != request.Header.Arg1)
            {
                stderr.printf("HELO: Received Protocol version does not match sent versio!\n");
                return -2;
            }

            return 0;
        }

        public int SendReboot()
        {
            LAFPacket response = new LAFPacket.Empty();
            LAFPacket request = new LAFPacket.WithEnum(LAFCommand.CONTROL, LAFSubCommand.CONTROL_REBOOT_OS);
            if(SendAndReceive(request, out response, "CTRL REBOOT") != 0)
            {
                return -1;
            }
            return 0;
        }

        public int SendPoweroff()
        {
            LAFPacket response = new LAFPacket.Empty();
            LAFPacket request = new LAFPacket.WithEnum(LAFCommand.CONTROL, LAFSubCommand.CONTROL_POWER_OFF);
            if(SendAndReceive(request, out response, "CTRL POWEROFF") != 0)
            {
                return -1;
            }
            return 0;
        }

        public int SendCmdExec(string psexec, out string cmdReply)
        {
            if (SendCentMeter(2) != 0)
            {
                stderr.printf("SendCmdExec: Failed CENT METER challenge!\n");
                return -1;
            }

            LAFPacket response = new LAFPacket.Empty();
            LAFPacket request = new LAFPacket.WithMainCmdEnum(LAFCommand.EXECUTE);
            request.SetBodyFromString(psexec);

            if(SendAndReceive(request, out response, "EXEC") != 0)
            {
                int i;
                //return -1;
            }
            cmdReply = (string)response.Body;
            return 0;
        }

        public int SendOpen(string filePath, out uint fileHandle)
        {
            if (SendCentMeter(2) != 0)
            {
                stderr.printf("SendOpen: Failed CENT METER challenge!\n");
                return -1;
            }

            LAFPacket response = new LAFPacket.Empty();
            LAFPacket request = new LAFPacket.WithMainCmdEnum(LAFCommand.OPEN);
            request.SetBodyFromString(filePath);

            if(SendAndReceive(request, out response, "OPEN") != 0)
            {
                return -1;
            }

            fileHandle = response.Header.Arg1;
            return 0;
        }

        // offset in blocks: size of 512bytes
        public int SendRead(uint fileHandle, uint offset, uint length, out uint8[] outData)
        {
            LAFPacket response = new LAFPacket.Empty();
            LAFPacket request = new LAFPacket.WithMainCmdEnum(LAFCommand.READ,
                                                                fileHandle,
                                                                offset,
                                                                length,
                                                                SeekMode.SET);
            if(SendAndReceive(request, out response, "READ") != 0)
            {
                return -1;
            }
            outData = response.Body;
            return 0;
        }

        public int SendWrite(uint fileHandle, uint offset, uint8[] inData)
        {
            LAFPacket response = new LAFPacket.Empty();
            LAFPacket request = new LAFPacket.WithMainCmdEnum(LAFCommand.WRITE,
                                                              fileHandle,
                                                              offset);
            request.SetBody(inData);
            if(SendAndReceive(request, out response, "WRTE") != 0)
            {
                return -1;
            }
            return 0;
        }

        public int SendClose(uint fileHandle)
        {
            LAFPacket response = new LAFPacket.Empty();
            LAFPacket request = new LAFPacket.WithMainCmdEnum(LAFCommand.CLOSE,
                                                              fileHandle);
            if(SendAndReceive(request, out response, "CLSE") != 0)
            {
                return -1;
            }
            return 0;
        }

        public int SendUnlink(string filePath)
        {
            LAFPacket response = new LAFPacket.Empty();
            LAFPacket request = new LAFPacket.WithMainCmdEnum(LAFCommand.UNLINK);
            if(SendAndReceive(request, out response, "UNLK") != 0)
            {
                return -1;
            }
            return 0;
        }

        public int GetLafProperties(out LAFProperties properties)
        {
            LAFPacket response = new LAFPacket.Empty();
            LAFPacket request = new LAFPacket.WithEnum(LAFCommand.INFO,
                                                       LAFSubCommand.INFO_GET_PROPS);
            // Request needs body of fixed size
            uint8[] emptyBody = new uint8[LAFProperties.LAF_PROPERTIES_LENGTH];
            // + that fixed size as uint16 at the beginning of body
            *(ushort*)emptyBody = (ushort)LAFProperties.LAF_PROPERTIES_LENGTH;
            request.SetBody(emptyBody);

            if(SendAndReceive(request, out response, "INFO GPRO") != 0)
            {
                return -1;
            }
            properties = new LAFProperties(response.Body);
            return 0;
        }

        public int SendUnlock()
        {
            int ret = 0;
            stdout.printf("Sending USB interface ?unlock?\n");
            uint8[] req = {0xEF, 0x00, 0x16, 0x65, 0x7E};
            uint8[] res = new uint8[7];

            ret = this.Device.Write(req);
            assert(ret == 0);
            ret = this.Device.Read(res);
            assert(ret == 0);
            stdout.printf("?Unlock? response:\n");
            Util.hexdump(res);

            return 0;
        }

        public int GetPartitionTable(out GPTPartitionTable partitionTable)
        {
            int ret = 0;
            uint fileHandle;
            // "" fallsback to "/dev/block/mmcblk0"
            ret = SendOpen("", out fileHandle);
            assert(ret == 0);
            uint8[] data = new uint8[GPTPartitionTable.GPT_TABLE_LENGTH];
            SendRead(fileHandle, 0, data.length, out data);
            assert(ret == 0);
            partitionTable = new GPTPartitionTable(data);
            return 0;
        }

        public int GetPhoneInfo(out PhoneInfo phoneInfo)
        {
            int ret = 0;
            uint8[] response = new uint8[PhoneInfo.PHONEINFO_RESPONSE_LEN];
            ret = this.Device.Write(PhoneInfo.PHONEINFO_CMD);
            assert(ret == 0);
            ret = this.Device.Read(response);
            assert(ret == 0);
            phoneInfo = new PhoneInfo(response);

            return 0;
        }

        public int GetFilesizeFromDevice(string deviceFilePath, out int fileSize)
        {
            int ret;
            string reply;
            ret = SendCmdExec("ls -l " + deviceFilePath, out reply);
            assert(ret == 0);
            if (reply == null || reply.length == 0)
            {
                stderr.printf("File \"%s\" not found!\n", deviceFilePath);
                return 1;
            }

            // Replace multiple whitespaces with a single one
            // original line ex. "-rwxr-x--- root     root        10048 1970-01-01 00:00 testfile"
			reply  = /(\s+)/.replace (reply, -1, 0, " ");
            string[] columns = reply.split(" ");
            fileSize = columns[3].to_int();
            if (fileSize == 0)
            {
                stderr.printf("FileSize: 0, either invalid file or parsing gone wrong\n");
                return 2;
            }
            return 0;
        }

        public int ReadFile(string deviceFilePath, out uint8[] outData)
        {
            int ret;
            int fileSize;
            ret = GetFilesizeFromDevice(deviceFilePath, out fileSize);
            assert(ret == 0);
            
            uint fileHandle = 0;
            ret = SendOpen(deviceFilePath, out fileHandle);
            assert(ret == 0);

            // Reserve output buffer
            outData = new uint8[fileSize];
            
            int offset = 0;
            int position = 0;
            int readSize = 0;
            uint8[] readData;
            while (offset < fileSize)
            {
                if ((position + 512) > fileSize)
                    readSize = fileSize - position;
                else
                    readSize = 512;
                ret = SendRead(fileHandle, offset, readSize, out readData);
                assert(ret == 0);
                Memory.copy(&outData[position], readData, readSize);
                position += readSize;
                offset++;
            }
            ret = SendClose(fileHandle);
            assert(ret == 0);
            stdout.printf("Read %i bytes from %s\n", outData.length, deviceFilePath);
            stdout.printf((string)outData);
            return 0;
        }
        public int WriteFile(string deviceFilePath, uint8[] inData)
        {
            return 0;
        }
        public int DeleteFile(string deviceFilePath)
        {
            int ret;
            int fileSize = 0;
            ret = GetFilesizeFromDevice(deviceFilePath, out fileSize);
            assert(ret == 0);
            if(fileSize == 0)
            {
                stderr.printf("File %s does not seem to exist\n", deviceFilePath);
                return 1;
            }
            ret = SendUnlink(deviceFilePath);
            assert(ret == 0);

            return 0;
        }
    }
}
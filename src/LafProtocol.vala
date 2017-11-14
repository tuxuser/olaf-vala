using Olaf.Communication;
using Olaf.Packet;

namespace Olaf
{
    public class LAFProtocol
    {
        // https://github.com/Lekensteyn/lglaf/blob/master/protocol.md
        public const uint VERSION = 0x01000004;
        public const uint GPT_TABLE_LENGTH = 0x4400;

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
                stderr.printf("Command FAILED! ErrorCode: 0x%04x\n", tmp.Header.Arg1);
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

        public int SendCmdExec(string psexec)
        {
            if (SendCentMeter(2) != 0)
            {
                stderr.printf("SendCmdExec failed CENT METER challenge!\n");
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
            return 0;
        }

        public int SendOpen(string filePath, out int fileHandle)
        {
            if (SendCentMeter(2) != 0)
            {
                stderr.printf("SendCmdExec failed CENT METER challenge!\n");
                return -1;
            }

            LAFPacket response = new LAFPacket.Empty();
            LAFPacket request = new LAFPacket.WithMainCmdEnum(LAFCommand.OPEN);
            request.SetBodyFromString(filePath);

            if(SendAndReceive(request, out response, "OPEN") != 0)
            {
                return -1;
            }

            fileHandle = (int)response.Header.Arg1;
            return 0;
        }

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

        public int SendGetInfo(out DeviceProperties properties)
        {
            LAFPacket response = new LAFPacket.Empty();
            LAFPacket request = new LAFPacket.WithEnum(LAFCommand.INFO,
                                                       LAFSubCommand.INFO_GET_PROPS);
            // Request needs body of fixed size
            uint8[] emptyBody = new uint8[BodySize.INFO_PROPERTIES];
            // + that fixed size as uint16 at the beginning of body
            *(ushort*)emptyBody = (ushort)BodySize.INFO_PROPERTIES;
            request.SetBody(emptyBody);

            if(SendAndReceive(request, out response, "INFO GPRO") != 0)
            {
                return -1;
            }
            properties = new DeviceProperties(response.Body);
            return 0;
        }

        public int GetPartitionTable(out uint8[] partitionTable)
        {
            int ret = 0;
            int fileHandle;
            uint8[] table;
            // "" fallsback to "/dev/block/mmcblk0"
            ret = SendOpen("", out fileHandle);
            assert(ret == 0);
            SendRead(fileHandle, 0, GPT_TABLE_LENGTH, out partitionTable);
            assert(ret == 0);
            return 0;
        }
    }
}
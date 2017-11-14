using Olaf.Communication;

namespace Olaf
{
    public class ATProtocol
    {
        private static const uint8 COMMAND_TERMINATOR = 0x0D;
        private LGDevice Device;
        public ATProtocol(LGDevice device)
        {
            this.Device = device;
        }

        private int SendCommand(Packet.ATCommand cmd, string extensionData = "")
        {
            uint8[] command = new uint8[1]; // Convert ATCommand to bytes
            uint8[] data = extensionData.to_ascii().data;

            uint8[] packet = new uint8[command.length + data.length + 1];
            Memory.copy(packet, command, command.length);
            Memory.copy(&packet[command.length], data, data.length);
            packet[packet.length] = COMMAND_TERMINATOR;

            return this.Device.Write(packet);
        }

        private int ReceiveReply(out string reply)
        {
            return 0;
        }
    }
}
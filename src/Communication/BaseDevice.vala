using Olaf.Packet;

namespace Olaf.Communication
{
    public enum InterfaceType
    {
        USB,
        SERIAL;

        public string to_string()
        {
            switch(this)
            {
                case USB:
                    return "USB";
                case SERIAL:
                    return "SERIAL";
                default:
                    assert_not_reached();
            }
        }
    }

    public enum ProtocolType
    {
        MODEM,
        LAF,
        UNDEFINED;

        public string to_string()
        {
            switch(this)
            {
                case MODEM:
                    return "LG MODEM";
                case LAF:
                    return "LG LAF";
                case UNDEFINED:
                    return "LG UNDEFINED";
                default:
                    assert_not_reached();
            }
        }
    }

    public abstract class LGDevice
    {
        public InterfaceType Interface { get; internal set; }
        public ProtocolType Protocol { get; internal set; }

        public LGDevice(InterfaceType interface, ProtocolType protocol)
        {
            this.Interface = interface;
            this.Protocol = protocol;
        }

        public abstract bool Open();
        public abstract void Close();
        public abstract int Read(uint8[] outData);
        public abstract int Write(uint8[] inData);

        public int SendPacket(LAFPacket packet)
        {
            uint8[] data = packet.Serialize();
            stdout.printf(":::Outgoing Packet:::\n");
            stdout.printf(packet.to_string());
            if (packet.Header.BodyLength > 0)
            {
                stdout.printf(":::Body:::\n");
                Util.hexdump(packet.Body);
            }
            stdout.printf("\n");
            return Write(data);
        }

        public int ReceivePacket(out LAFPacket outPacket)
        {
            uint8[] header = new uint8[sizeof(LAF_PACKET_HDR)];
            int ret = Read(header);
            if (ret != 0)
            {
                return ret;
            }

            outPacket = new LAFPacket.Empty();
            outPacket.Deserialize(header);
            stdout.printf(":::Incoming Packet:::\n");
            stdout.printf(outPacket.to_string());

            if (outPacket.Header.BodyLength > 0)
            {
                uint8[] body = new uint8[outPacket.Header.BodyLength];
                ret = Read(body);
                if (ret != 0)
                {
                    stderr.printf("Failed to read body from packet\n");
                    return ret;
                }
                outPacket.SetBody(body);
                stdout.printf(":::Body:::\n");
                Util.hexdump(outPacket.Body);
            }
            stdout.printf("\n");
            return 0;
        }

        public virtual string to_string()
        {
            return "Protocol: %s, Interface: %s".printf(
                this.Protocol.to_string(), this.Interface.to_string()
            );
        }
    }

    public abstract class BaseEnumerator
    {
        public abstract int GetDevices(out List<LGDevice?> outDevices);
    }
}
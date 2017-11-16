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
            debug(":::Outgoing Packet:::\n");
            debug(packet.to_string());
            if (packet.Header.BodyLength > 0)
            {
                debug(":::Body:::\n");
                //Util.hexdump(packet.Body);
            }
            debug("\n");
            return Write(data);
        }

        public int ReceivePacket(out LAFPacket outPacket)
        {
            uint8[] buffer;
            /*
             * USB: Read all at once
             * Serial: Read chunked, first header, then body
             */
            if (this.Interface == InterfaceType.USB)
                buffer = new uint8[16*1024];
            else
                buffer = new uint8[sizeof(LAF_PACKET_HDR)];

            int ret = Read(buffer);
            if (ret != 0)
            {
                debug("Failed to read data of size: %i\n", buffer.length);
                return ret;
            }

            outPacket = new LAFPacket.Empty();
            outPacket.Deserialize(buffer);
            debug(":::Incoming Packet:::\n");
            debug(outPacket.to_string());

            if (outPacket.Header.BodyLength > 0)
            {
                uint8[] body;
                if (this.Interface == InterfaceType.USB)
                {
                    // Read from original buffer
                    body = new uint8[outPacket.Header.BodyLength];
                    Memory.copy(body, &buffer[sizeof(LAF_PACKET_HDR)], outPacket.Header.BodyLength);
                }
                else // Serial
                {
                    // Read a new chunk from device
                    body = new uint8[outPacket.Header.BodyLength];
                    ret = Read(body);
                    if (ret != 0)
                    {
                        debug("Failed to read body from serial\n");
                        return ret;
                    }
                }
                outPacket.SetBody(body);
                debug(":::Body:::\n");
                //Util.hexdump(outPacket.Body);
            }

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
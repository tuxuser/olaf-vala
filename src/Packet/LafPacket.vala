using GLib;
using Vapi.Builtins;

namespace Olaf.Packet
{
    public class LAFPacket
    {
        public LAF_PACKET_HDR Header;
        public uint8[] Body;

        public LAFPacket(uint32 cmd, uint arg1 = 0, uint arg2 = 0, uint arg3 = 0, uint arg4 = 0)
        {
            Memory.@set((void*)&Header, 0, sizeof(LAF_PACKET_HDR));
            Header.CmdName = cmd;
            Header.Arg1 = arg1;
            Header.Arg2 = arg2;
            Header.Arg3 = arg3;
            Header.Arg4 = arg4;
        }

        public LAFPacket.WithMainCmdEnum(LAFCommand cmd, uint arg1 = 0, uint arg2 = 0, uint arg3 = 0, uint arg4 = 0)
        {
            this(cmd.to_uint(),
                arg1,
                arg2,
                arg3,
                arg4
            );
        }

        public LAFPacket.WithEnum(LAFCommand cmd, LAFSubCommand subcmd, uint arg2 = 0, uint arg3 = 0, uint arg4 = 0)
        {
            this(cmd.to_uint(),
                 subcmd.to_uint(),
                 arg2,
                 arg3,
                 arg4
            );
        }

        public LAFPacket.Empty()
        {
            this(0, 0, 0, 0, 0);
        }

        public void SetBody(uint8[] body)
        {
            Body = body;
        }

        public void SetBodyFromString(string body)
        {
            // +1 as NULL-terminator
            uint8[] tmp = new uint8[body.length + 1];
            Memory.copy(tmp, body.to_ascii().data, body.length);
            Body = tmp;
        }

        public void Deserialize(uint8[] data)
        {
            Memory.copy((void*)&Header, data, sizeof(LAF_PACKET_HDR));
            // TODO: BodyLen / bswap32 / read body
            if (Header.BodyLength > 0 &&
                data.length >= (sizeof(LAF_PACKET_HDR) + Header.BodyLength))
            {
                Body = new uint8[Header.BodyLength];
                Memory.copy(Body, (void*)&data[sizeof(LAF_PACKET_HDR)], Header.BodyLength);
            }
        }

        public uint8[] Serialize()
        {
            Header.BodyLength = Body.length;
            Header.CmdInvert = ~Header.CmdName;
            Header.Crc = 0;
            uint8[] data = new uint8[sizeof(LAF_PACKET_HDR) + Body.length];

            Memory.copy(data, (void*)&Header, sizeof(LAF_PACKET_HDR));
            if (Body.length > 0)
            {
                Memory.copy(&data[sizeof(LAF_PACKET_HDR)], Body, Body.length);
            }
            // Calculate hash
            Header.Crc = Util.Crc16Lsb(data);
            // Overwrite header with correct Crc field
            Memory.copy(data, (void*)&Header, sizeof(LAF_PACKET_HDR));
            return data;
        }

        public bool VerifyCrc()
        {
            ushort crc = Header.Crc;
            Header.Crc = 0;

            uint8[] data = new uint8[sizeof(LAF_PACKET_HDR) + Body.length];
            
            Memory.copy(data, (void*)&Header, sizeof(LAF_PACKET_HDR));
            if (Body.length > 0)
            {
                Memory.copy(&data[sizeof(LAF_PACKET_HDR)], Body, Body.length);
            }
            return (Util.Crc16Lsb(data) == crc);
        }

        public string to_string()
        {
            StringBuilder sb = new StringBuilder();
            sb.append_printf(":::HEADER:::\n");
            sb.append_printf("CmdName: %s\n", Util.UintToCmd(Header.CmdName));
            sb.append_printf("Arg1: 0x%04x (%s)\n", Header.Arg1, Util.UintToCmd(Header.Arg1));
            sb.append_printf("Arg2: 0x%04x (%u)\n", Header.Arg2, Header.Arg2);
            sb.append_printf("Arg3: 0x%04x (%u)\n", Header.Arg3, Header.Arg3);
            sb.append_printf("Arg4: 0x%04x (%u)\n", Header.Arg4, Header.Arg4);
            sb.append_printf("BodyLength: 0x%04x (%u)\n", Header.BodyLength, Header.BodyLength);
            sb.append_printf("Crc: 0x%04x\n", Header.Crc);
            sb.append_printf("Unused: 0x%04x\n", Header.Unused);
            sb.append_printf("CmdInvert: 0x%04x (Valid: %s)\n", Header.CmdInvert, 
                                            (Header.CmdName == ~Header.CmdInvert) ? "YES" : "NO");
            return sb.str;
        }
    }

    public struct LAF_PACKET_HDR {
        uint CmdName; // BE
        uint Arg1; // BE for CENT/METR/other words, LE for values
        uint Arg2;
        uint Arg3;
        uint Arg4;
        uint BodyLength; // LE
        ushort Crc; // LE
        ushort Unused;
        uint CmdInvert; // BE
    }
}
namespace Olaf
{
    public class Util
    {
        public static string UintToCmd(uint cmd)
        {
            string tmp = "B00B";
            *(uint*)tmp = (uint)cmd;
            return tmp;
        }

        public static uint CmdToUint(uint8[] cmd)
        {
            if (cmd.length != 4)
            {
                stderr.printf("Cmd length != 4\n");
                return 0;
            }
            // bitshifting ftw
            return (uint)(cmd[0] | cmd[1] << 8 | cmd[2] << 16 | cmd[3] << 24);
        }

        public static string UInt16ToString(uint16[] array)
        {
            unichar c;
            StringBuilder builder = new StringBuilder();
            for (int i = 0; i < array.length; i++) {
                c = ((string)array).get_char(i);
                if(c.iscntrl())
                    continue;
                builder.append_unichar(c);
            }
            return builder.str;
        }

        // Source: https://github.com/Lekensteyn/lglaf/blob/master/lglaf.py#L127
        public static ushort Crc16Lsb(uint8[] data)
        {
            uint8 byte = 0;
            ushort crc = 0xFFFF;  
            for (int i = 0; i < data.length; i++)
            {
                byte = data[i];
                crc ^= byte;

                for (int bits = 0; bits < 8; bits++)
                {
                    if ((crc & 1) == 1)
                        crc = (crc >> 1) ^ 0x8408;
                    else
                        crc >>= 1;
                }
            }
            return crc ^ 0xFFFF;
        }

        // Source: https://gist.github.com/phako/96b36b5070beaf7eee27
        public static void hexdump (uint8[] data) {
            var builder = new StringBuilder.sized(16);
            var i = 0;
    
            foreach (var c in data) {
                if (i % 16 == 0) {
                    print ("%08x | ", i);
                }
                i++;
                print ("%02x ", c);
                if (((char) c).isprint ()) {
                    builder.append_c ((char) c);
                } else {
                    builder.append (".");
                }
                if (i % 16 == 0) {
                    print ("| %s\n", builder.str);
                    builder.erase ();
                }
            }
    
            if (i % 16 != 0) {
                print ("%s| %s\n", string.nfill ((16 - (i % 16)) * 3, ' '), builder.str);
            }
    
        }
    }
}
using LibSerialPort;

namespace Olaf.Communication
{
    public class SerialDevice : LGDevice
    {
        private LibSerialPort.Port? Port;
        private string Name;
        private string Description;
        public SerialDevice(ProtocolType proto, string name, string description)
        {
            base(InterfaceType.SERIAL, proto);
            this.Name = name;
            this.Description = description;
        }

        public override bool Open()
        {
            Return ret;
            LibSerialPort.Port port;
            ret = LibSerialPort.Port.new_by_name(this.Name, out this.Port);
            if (ret != Return.OK)
            {
                stderr.printf("Failed to get port by name: %s\n", this.Name);
                stderr.printf("Error: %s\n", ret.to_string());
                return false;
            }

            ret = this.Port.open(OpenMode.READ_WRITE);
            if (ret != Return.OK)
            {
                stderr.printf("Failed to open port: %s\n", this.Name);
                stderr.printf("Error: %s\n", ret.to_string());
                return false;
            }

            stdout.printf("Connected to %s\n", this.to_string());
            debug(GetConfig());
            return true;
        }

        public override void Close()
        {
            Return ret = this.Port.close();
            if (ret != Return.OK)
                stderr.printf("Failed to close device\n");
        }

        public override int Read(uint8[] outData)
        {
            Return ret = this.Port.blocking_read(outData, 2000);
            if(ret != outData.length)
            {
                stderr.printf("Read failed, Error: %s\n", ret.to_string());
                return 1;
            }
            return 0;
        }

        public override int Write(uint8[] inData)
        {
            Return ret = this.Port.blocking_write(inData, 2000);
            if(ret != inData.length)
            {
                stderr.printf("Write failed, Error: %s\n", ret.to_string());
                return 1;
            }
            return 0;
        }

        private string GetConfig()
        {
            Return ret;
            LibSerialPort.Config config;
            LibSerialPort.Config.new(out config);
            if ((ret = this.Port.get_config(config)) != Return.OK)
            {
                error("Failed to get serial port config\n");
                error("LibSerialPort Error: %s\n", ret.to_string());
                return "<GETTING SERIAL PORT CONFIG FAILED>\n\n";
            }

            int baudrate = 0, bits = 0, stopbits = 0;
            config.get_baudrate(out baudrate);
            config.get_bits(out bits);
            config.get_stopbits(out stopbits);

            StringBuilder builder = new StringBuilder();
            builder.append_printf("::: SERIAL PORT CONFIG :::\n");
            builder.append_printf("Baudrate: %i\n", baudrate);
            builder.append_printf("Bits: %i\n", bits);
            builder.append_printf("Stopbits: %i\n\n", stopbits);
            return builder.str;
        }

        public override string to_string()
        {
            return "%s %s (Port: %s)".printf(base.to_string(), this.Description, this.Name);
        }
    }

    public class SerialEnumerator : BaseEnumerator
    {
        private static const string LAFString = "LGE Mobile USB Serial Port";
        private static const string ModemString = "LGE Mobile USB Modem";

        public override int GetDevices(out List<LGDevice?> outDevices)
        {
            outDevices = new List<LGDevice?>();
            LibSerialPort.Port[]? ports = LibSerialPort.Port.enum();
            if (ports == null)
                return 0;

			for (int i = 0; i < ports.length; i++)
            {	
                unowned string name = ports[i].name();
                unowned string description = ports[i].get_description();
                if (description.contains(SerialEnumerator.LAFString))
                    outDevices.append(new SerialDevice(ProtocolType.LAF, name, description));
                else if (description.contains(SerialEnumerator.ModemString))
                    outDevices.append(new SerialDevice(ProtocolType.MODEM, name, description));
                else if (description.contains("LG ") || name.contains("LGE "))
                    outDevices.append(new SerialDevice(ProtocolType.UNDEFINED, name, description));
            }

            return (int)outDevices.length();
        }
    }
}
using Vapi.LafStructs;

namespace Olaf.Structure
{
    public class PhoneInfo
    {
        public static const uint8[] PHONEINFO_CMD = {0xEF, 0xA0, 0x1C, 0xC0, 0x7E};
        public static uint PHONEINFO_RESPONSE_LEN = 0x96;

        private PhoneInfoStruct phoneInfo;

        public PhoneInfo(uint8[] data)
        {
            assert(sizeof(PhoneInfoStruct) == PHONEINFO_RESPONSE_LEN);

            if (data.length < PHONEINFO_RESPONSE_LEN)
            {
                stderr.printf("Invalid PhoneInfo data\n");
                return;
            }
            Memory.copy(&this.phoneInfo, data, PHONEINFO_RESPONSE_LEN);
        }

        public string to_string()
        {
            StringBuilder builder = new StringBuilder();
            uint16 batteryLevel = this.phoneInfo.BatteryLevel;
            builder.append("::: PHONEINFO :::\n");
            builder.append_printf("Not Finished? %04x\n", this.phoneInfo.Finished);
            builder.append_printf("Model Name: %s\n", (string)this.phoneInfo.ModelName);
            builder.append_printf("Software Version: %s\n", (string)this.phoneInfo.SoftwareVersion);
            builder.append_printf("Sub Version: %u\n", this.phoneInfo.SubVersion);
            builder.append_printf("Serial: %s\n", (string)this.phoneInfo.SerialNumber);
            builder.append_printf("BatteryLevel: %u / %u\n", (batteryLevel & 0xFF), (batteryLevel & 0xFF00) >> 8);
            builder.append_printf("Phone Type: %s\n", (string)this.phoneInfo.PhoneType);
            builder.append_printf("OS Version: %s\n", (string)this.phoneInfo.OSVersion);
            builder.append_printf("Phone Number: %s\n", (string)this.phoneInfo.PhoneNumber);
            builder.append_printf("Current Mode: %u\n", this.phoneInfo.CurrentMode);
            builder.append_printf("Prevent Upgrade: %u\n", this.phoneInfo.PreventUpgrade);
            builder.append("\n\n");
            return builder.str;
        }
    }
}
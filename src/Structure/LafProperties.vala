using Vapi.LafStructs;

namespace Olaf.Structure
{
    public class LAFProperties
    {
		public static uint LAF_PROPERTIES_LENGTH = 0xB08;
		private LafPropertiesStruct lafProperties;

        public LAFProperties(uint8[] data)
        {			
            assert(sizeof(LafPropertiesStruct) == LAF_PROPERTIES_LENGTH);
			if (data.length < LAF_PROPERTIES_LENGTH)
			{
				stderr.printf("Invalid LAF Properties data\n");
				return;
			}
			Memory.copy(&this.lafProperties, data, LAF_PROPERTIES_LENGTH);
        }
		
		public string to_string()
		{
			LafPropertiesStruct props = this.lafProperties;
			StringBuilder sb = new StringBuilder();
			sb.append("::: LAF Properties :::\n");
			sb.append_printf("Blobsize: 0x%x\n", props.BlobSize);
			sb.append_printf("DownloadType: 0x%x\n", props.DownloadType);
			sb.append_printf("DownloadSpeed: %f\n", props.DownloadSpeedFloat);
			sb.append_printf("DownloadSwVersion: %s\n", (string)props.DownloadSwVersion);
			sb.append_printf("ModelName: %s\n", (string)props.ModelName);
			sb.append_printf("DeviceSwVersion: %s\n", (string)props.DeviceSwVersion);
			sb.append_printf("DeviceFactoryVersion: %s\n", (string)props.DeviceFactoryVersion);
			sb.append_printf("BootloaderVersion: %s\n", (string)props.BootloaderVersion);
			sb.append_printf("IMEI: %s\n", (string)props.Imei);
			sb.append_printf("PID: %s\n", 	(string)props.Pid);
			sb.append_printf("DownloadCable: %s\n", (string)props.DownloadCable);
			sb.append_printf("USB Version: %s\n", (string)props.UsbVersion);
			sb.append_printf("Hardware Revision: %s\n", (string)props.HardwareRevision);
			sb.append_printf("BatteryLevel: %x\n", props.BatteryLevel);
			sb.append_printf("SecureDevice: %c\n", props.SecureDevice);
			sb.append_printf("DeviceBuildType: %s\n", (string)props.DeviceBuildType);
			sb.append_printf("ChipsetPlatform: %s\n", (string)props.ChipsetPlatform);
			sb.append_printf("TargetOperator: %s\n", (string)props.TargetOperator);
			sb.append_printf("TargetCountry: %s\n", (string)props.TargetCountry);
			sb.append_printf("LafSwVersion: %s\n", (string)props.LafSwVersion);
			sb.append_printf("ApFactoryResetStatus: 0x%x\n", props.ApFactoryResetStatus);
			sb.append_printf("CpFactoryResetStatus: 0x%x\n", props.CpFactoryResetStatus);
			sb.append_printf("IsDownloadNotFinish: 0x%x\n", props.IsDownloadNotFinish);
			sb.append_printf("QEM: 0x%x\n", props.Qem);
			sb.append_printf("DeviceFactoryOutVersion: %s\n", (string)props.DeviceFactoryOutVersion);
			sb.append_printf("CupssSwFv: %s\n", (string)props.CupssSwFv);
			sb.append_printf("IsOneBinaryDualPlan: 0x%x\n", props.IsOneBinaryDualPlan);
			sb.append_printf("MemorySize: 0x%x\n", props.MemorySize);
			sb.append_printf("MemoryID: %s\n", (string)props.MemoryID);
			sb.append("\n\n");
			return sb.str;
		}
    }
}
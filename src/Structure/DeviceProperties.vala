using Gee;

namespace Olaf.Structure
{
	[SimpleType]
    public enum DeviceProperty
    {
        DownloadCable,
        BatteryLevel,
        DownloadType,
        DownloadSpeed,
        UsbVersion,
        HardwareRevision,
        DownloadSwVersion,
        DeviceSwVersion,
        SecureDevice,
        LafSwVersion,
        DeviceFactoryVersion,
        DeviceFactoryOutVersion,
        Pid,
        Imei,
        ModelName,
        DeviceBuildType,
        ChipsetPlatform,
        TargetOperator,
        TargetCountry,
        ApFactoryResetStatus,
        CpFactoryResetStatus,
        IsDownloadNotFinish,
        Qem,
        CupssSwFv,
        IsOneBinaryDualPlan,
        MemorySize,
        MemoryID,
        BootloaderVersion;
		
		public string GetName()
		{
			string tmp = this.to_string();
			return tmp.substring(tmp.last_index_of("_") + 1);
		}
    }
	
	public interface IStringable {
		public abstract string to_string();
	}

    public abstract class Field<T> : IStringable
    {
        public T value;
		private int offset;

        public Field(int offset)
        {
            this.offset = offset;
        }

        public int GetOffset()
        {
            return this.offset;
        }

        public virtual bool Parse(uint8[] Data)
		{			
			value = (T)&Data[this.offset];
			return true;
		}
		
		public string to_string(){
			return "UNKNOWN";
		}
    }
	
	public class StringField : Field<string>
	{
		public StringField(int offset)
        {
			base(offset);
        }
		
		public string to_string(){
			return this.value;
		}
	}
	
	public class IntField : Field<uint>
	{
		public IntField(int offset)
        {
			base(offset);
        }
		
		public string to_string(){
			return this.value.to_string();
		}
	}
	
	public class CharField : Field<uchar>
	{
		public CharField(int offset)
        {
			base(offset);
        }
		
		public string to_string(){
			return this.value.to_string();
		}
	}

    public class DeviceProperties
    {
        private uint8[] Data;
        private HashMap <DeviceProperty?, Field?> propertyMap;

        public DeviceProperties(uint8[] data)
        {
            Data = data;
            propertyMap = new HashMap<DeviceProperty?, Field?>();
            propertyMap.set(DeviceProperty.DownloadCable, new StringField(0x3f9));
			propertyMap.set(DeviceProperty.BatteryLevel, new IntField(0x42b));
			propertyMap.set(DeviceProperty.DownloadType, new CharField(0x10));
			propertyMap.set(DeviceProperty.DownloadSpeed, new IntField(0x21));
			propertyMap.set(DeviceProperty.UsbVersion, new StringField(0x403));
			propertyMap.set(DeviceProperty.HardwareRevision, new StringField(0x417));
			propertyMap.set(DeviceProperty.DownloadSwVersion, new StringField(0x029));
			propertyMap.set(DeviceProperty.DeviceSwVersion, new StringField(0x14f));
			propertyMap.set(DeviceProperty.SecureDevice, new CharField(0x42f));
			propertyMap.set(DeviceProperty.LafSwVersion, new StringField(0x4e8));
			propertyMap.set(DeviceProperty.DeviceFactoryVersion, new StringField(0x24f));
			propertyMap.set(DeviceProperty.DeviceFactoryOutVersion, new StringField(0x528));
			propertyMap.set(DeviceProperty.Pid, new StringField(0x3db));
			propertyMap.set(DeviceProperty.Imei, new StringField(0x3c7));
			propertyMap.set(DeviceProperty.ModelName, new StringField(0x131));
			propertyMap.set(DeviceProperty.DeviceBuildType, new StringField(0x430));
			propertyMap.set(DeviceProperty.ChipsetPlatform, new StringField(0x43a));
			propertyMap.set(DeviceProperty.TargetOperator, new StringField(0x44e));
			propertyMap.set(DeviceProperty.TargetCountry, new StringField(0x462));
			propertyMap.set(DeviceProperty.ApFactoryResetStatus, new IntField(0x4fc));
			propertyMap.set(DeviceProperty.CpFactoryResetStatus, new IntField(0x500));
			propertyMap.set(DeviceProperty.IsDownloadNotFinish, new IntField(0x504));
			propertyMap.set(DeviceProperty.Qem, new IntField(0x508));
			propertyMap.set(DeviceProperty.CupssSwFv, new StringField(0x628));
			propertyMap.set(DeviceProperty.IsOneBinaryDualPlan, new IntField(0x728));
			propertyMap.set(DeviceProperty.MemorySize, new IntField(0x72c));
			propertyMap.set(DeviceProperty.MemoryID, new StringField(0x730));
			propertyMap.set(DeviceProperty.BootloaderVersion, new StringField(0x39f));
        }

        public Field GetProperty(DeviceProperty property)
        {
            Field f = propertyMap.get(property);
            if(!f.Parse(Data)){
				stderr.printf("0x%x contains invalid data\n", f.GetOffset());
			}
            return f;
        }
		
		public string to_string()
		{
			StringBuilder sb = new StringBuilder();
			foreach (Map.Entry<DeviceProperty?, Field?> entry in propertyMap.entries)
			{
				entry.value.Parse(Data);
				string value;
				if (entry.value is IntField)
					value = ((IntField)entry.value).to_string();
				else if (entry.value is CharField)
					value = ((CharField)entry.value).to_string();
				else if (entry.value is StringField)
					value = ((StringField)entry.value).to_string();
				else
					value = "(FAILED TO PARSE)";

				
				sb.append_printf("%s: %s\n", entry.key.GetName(), value);				
			}
			return sb.str;
		}
    }
}
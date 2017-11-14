using GLib;
using LibUSB;

namespace Olaf.Communication
{
    public class UsbDevice : LGDevice
    {
        private static const int TRANSFER_TIMEOUT = 3000;
        private LibUSB.DeviceHandle? Handle;
        private LibUSB.Device Device;

        private uint8 ConfigurationNum;
        private uint8 InterfaceNum;
        private uint8 EpIN;
        private uint8 EpOUT;

        public UsbDevice(ProtocolType proto, LibUSB.Device device,
                         uint8 configurationNum, uint8 interfaceNum,
                         uint8 epIn, uint8 epOut)
        {
            base(InterfaceType.USB, proto);
            this.Device = device;
            this.ConfigurationNum = configurationNum;
            this.InterfaceNum = interfaceNum;
            this.EpIN = epIn;
            this.EpOUT = epOut;
        }

        public override bool Open()
        {
            LibUSB.Error result = 0;
            if ((result = (LibUSB.Error)this.Device.open(out this.Handle)) != LibUSB.Error.SUCCESS)
            {
                stderr.printf("Opening devicehandle failed! Error: %s\n", result.to_string());
                return false;
            }
            stdout.printf("Connected to %s\n", this.to_string());

            int currentConfig = -1;            
            if ((result = (LibUSB.Error)this.Handle.get_configuration(out currentConfig)) != LibUSB.Error.SUCCESS)
            {
                stderr.printf("Getting configuration from device failed! Error: %s\n", result.to_string());
                return false;
            }

            if (currentConfig != this.ConfigurationNum)
            {
                stdout.printf("Setting configuration: Current: %i -> Target: %i\n", currentConfig, this.ConfigurationNum);
                if ((result = (LibUSB.Error)this.Handle.set_configuration(this.ConfigurationNum)) != LibUSB.Error.SUCCESS)
                {
                    stderr.printf("Setting configuration failed! Error: %s\n", result.to_string());
                    return false;
                }
            }
            
            ConfigDescriptor confDesc = null;
            /* Seems like a 0-indexed configurationNum is needed */
            this.Device.get_config_descriptor(this.ConfigurationNum - 1, out confDesc);
            for (int infNum = 0; infNum < confDesc.bNumInterfaces; infNum++)
            {
                unowned InterfaceDescriptor intfDesc = confDesc.interface[infNum].altsetting[0];
                if (this.Handle.kernel_driver_active(infNum) > 0)
                {
                    stdout.printf("Detaching kernel driver for interface: %i\n", infNum);
                    result = (LibUSB.Error)this.Handle.detach_kernel_driver(infNum);
                    if (result != LibUSB.Error.SUCCESS)
                        stderr.printf("Detaching kernel driver failed! Error: %s\n", result.to_string());
                }
                if (infNum != this.InterfaceNum)
                    continue;
                if ((result = (LibUSB.Error)this.Handle.claim_interface(this.InterfaceNum)) != LibUSB.Error.SUCCESS)
                {
                    stderr.printf("Failed to claim interface %i! Error: %s\n", this.InterfaceNum, result.to_string());
                    return false;
                }
            }

            return true;
        }

        public override void Close()
        {
        }

        public override int Read(uint8[] outData)
        {
            int transferred;
            LibUSB.Error result = (LibUSB.Error)this.Handle.bulk_transfer(this.EpIN, outData, out transferred, TRANSFER_TIMEOUT);
            if (result != LibUSB.Error.SUCCESS)
            {
                stderr.printf("Reading failed, Error: %s, transferred: %i\n", result.to_string(), transferred);
                return 1;
            }
            return 0;
        }

        public override int Write(uint8[] inData)
        { 
            int transferred;
            LibUSB.Error result = (LibUSB.Error)this.Handle.bulk_transfer(this.EpOUT, inData, out transferred, TRANSFER_TIMEOUT);
            if (result != LibUSB.Error.SUCCESS || transferred != inData.length)
            {
                stderr.printf("Writing failed, Error: %s, transferred: %i\n", result.to_string(), transferred);
                return 1;
            }
            return 0;
        }

        public override string to_string()
        {
            return "%s - EP IN: 0x%02X, EP OUT: 0x%02X".printf(base.to_string(), this.EpIN, this.EpOUT);
        }
    }

	public struct UsbInterface
	{
		public uint8 InterfaceClass;
		public uint8 InterfaceSubClass;
		public uint8 InterfaceProtocol;
		public uint8 NumEndpoints;
		
		public bool Match(InterfaceDescriptor inf)
		{
			return (inf.bInterfaceClass == this.InterfaceClass &&
				inf.bInterfaceSubClass == this.InterfaceSubClass &&
				inf.bInterfaceProtocol == this.InterfaceProtocol &&
				inf.bNumEndpoints == this.NumEndpoints);
		}
	}
	
    public class UsbEnumerator : BaseEnumerator
    {
        private LibUSB.Context context;
        private static const int LG_VENDOR_ID = 0x1004;
		private static UsbInterface LafDevice = UsbInterface(){
			InterfaceClass = 255,
			InterfaceSubClass = 255,
			InterfaceProtocol = 255,
			NumEndpoints = 2
		};
		public static UsbInterface ModemDevice = UsbInterface(){
			InterfaceClass = 2,
			InterfaceSubClass = 2,
			InterfaceProtocol = 1,
			NumEndpoints = 1
        };

        public UsbEnumerator()
        {
            LibUSB.Context.init(out this.context);
        }

        public override int GetDevices(out List<LGDevice?> outDevices)
        {
            Device[] devs;
            ProtocolType protocolType;
            context.get_device_list(out devs);

            outDevices = new List<UsbDevice?>();
            for(int i = 0; devs[i] != null; i++)
            {
                Device dev = devs[i];
                DeviceDescriptor desc = DeviceDescriptor(dev);
                if (desc.idVendor != LG_VENDOR_ID)
                    continue;

                for (uint8 confNum = 0; confNum < desc.bNumConfigurations; confNum++)
                {
                    ConfigDescriptor confDesc = null;
                    dev.get_config_descriptor(confNum, out confDesc);
                    for (uint8 infNum = 0; infNum < confDesc.bNumInterfaces; infNum++)
                    {
                        for (int altNum = 0; altNum < confDesc.interface[infNum].altsetting.length; altNum++)
                        {
                            unowned InterfaceDescriptor interface = confDesc.interface[infNum].altsetting[altNum];
                            if (LafDevice.Match(interface))
                                protocolType = ProtocolType.LAF;
                            else if (ModemDevice.Match(interface))
                                protocolType = ProtocolType.MODEM;
                            else
                                continue;

                            // Gather endpoints
                            uint8 epIN = 0, epOUT = 0;
                            for (int epNum = 0; epNum < interface.bNumEndpoints; epNum++)
                            {
                                unowned EndpointDescriptor endpoint = interface.endpoint[epNum];
                                if ((endpoint.bEndpointAddress & EndpointDirection.IN) != 0)
                                    epIN = endpoint.bEndpointAddress;
                                else
                                    epOUT = endpoint.bEndpointAddress;
                            }
                            // Construct the container class
                            UsbDevice usbdev = new UsbDevice(protocolType, dev,
                                                    confDesc.bConfigurationValue,
                                                    interface.bInterfaceNumber,
                                                    epIN, epOUT);
                            outDevices.append(usbdev);
                        }
                    }
                }
            }

            return (int)outDevices.length();
        }
    }
}

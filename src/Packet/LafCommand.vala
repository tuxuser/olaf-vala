using Gee;

namespace Olaf.Packet
{
    public enum BodySize
    {
        KILO_METER = 0x10,
        INFO_PROPERTIES = 0xB08
    }

    public enum SeekMode
    {
        SET,
        CURRENT,
        END,
        DATA
    }

    // https://github.com/Lekensteyn/lglaf/blob/master/protocol.md
    public enum LAFCommand
    {
        HELLO,              // HELLO
        RESPONSE_FAIL,      // Response from host on Error
        CONTROL,            // Control request (reboot, poweroff)
        KILO_CHALLENGE,     // Unlock Challenge
        INFO,               // Request device properties
        OPEN,               // Open filehandle on host
        READ,               // Read opened filehandle
        WRITE,              // Write opened filehandle
        ERASE,              // Erase block
        UNLINK,             // Delete file
        CLOSE,              // Close filehandle
        EXECUTE,            // Execute shell command
        SNIF,               // Sniff image download?
        FUSE,               // Get or set efuses
        /* New */
        RESERVED,           // Reserved
        IOCTL,              // IOCTL
        MISC,               // Set system variable ?
        DIFF,
        WRITE_ZERO,         // Write zero / Zero partition?
        SIGN,               // Sign partition?
        CALCULATE_CHECKSUM, // Calculate checksum - of what?
        OPCODE,             // Write OpCode
        SET_EMMC_BOOT_PART, // Set eMMC boot partition
        SET_UFS_BOOT_LUN,   // Set UFS Boot LUN
        MOD_BOOTPART_TABLE, // Manipulate Bootpartitiontable
        CHECK;              // Data checksum

        public uint to_uint()
        {
            return Util.CmdToUint(this.to_bytes());
        }

        public uint8[] to_bytes()
        {
            return this.to_string().to_ascii().data;
        }

        public string to_string()
        {
            return LAFCommandMap.command.get(this);
        }
    }

    public enum LAFSubCommand
    {
        CONTROL_REBOOT_OS,
        CONTROL_POWER_OFF,

        KILOCENT_CHALLENGE,
        KILOMETER_CHALLENGE,

        INFO_GET_PROPS,
        INFO_SET_PROPS,

        SNIF_REQUEST,
        SNIF_OPEN,
        SNIF_WRITE,
        SNIF_CLOSE,
        SNIF_STATUS,
        SNIF_IDDD,

        OPCM_CHEK,
        OPCM_WRITE,
        MISC_WRITE,
        FUSE_GET,
        FUSE_SET,
        CHCK_TSUM,
        CHCK_CLER,
        RESERVED_SDDD,
        RESERVED_IDDD,
        RESERVED_TDDD;

        public uint to_uint()
        {
            return Util.CmdToUint(this.to_bytes());
        }

        public uint8[] to_bytes()
        {
            return this.to_string().to_ascii().data;
        }

        public string to_string()
        {
            return LAFCommandMap.subcommand.get(this);
        }
    }

    public class LAFCommandMap
    {
        public static HashMap<LAFCommand, string> command;
        public static HashMap<LAFSubCommand, string> subcommand;
        public static void init()
        {
            command = new HashMap<LAFCommand, string>();
            command.set(LAFCommand.HELLO, "HELO");
            command.set(LAFCommand.RESPONSE_FAIL, "FAIL");
            command.set(LAFCommand.CONTROL, "CTRL");
            command.set(LAFCommand.KILO_CHALLENGE, "KILO");
            command.set(LAFCommand.INFO, "INFO");
            command.set(LAFCommand.OPEN, "OPEN");
            command.set(LAFCommand.READ, "READ");
            command.set(LAFCommand.WRITE, "WRTE");
            command.set(LAFCommand.ERASE, "ERSE");
            command.set(LAFCommand.UNLINK, "UNLK");
            command.set(LAFCommand.CLOSE, "CLSE");
            command.set(LAFCommand.EXECUTE, "EXEC");
            command.set(LAFCommand.SNIF, "SNIF");
            command.set(LAFCommand.FUSE, "FUSE");
            command.set(LAFCommand.RESERVED, "RSVD");
            command.set(LAFCommand.IOCTL, "IOCT");
            command.set(LAFCommand.MISC, "MISC");
            command.set(LAFCommand.DIFF, "DIFF");
            command.set(LAFCommand.WRITE_ZERO, "WRZR");
            command.set(LAFCommand.SIGN, "SIGN");
            command.set(LAFCommand.CALCULATE_CHECKSUM, "CRCC");
            command.set(LAFCommand.OPCODE, "OPCM");
            command.set(LAFCommand.SET_EMMC_BOOT_PART, "SEBP");
            command.set(LAFCommand.SET_UFS_BOOT_LUN, "SBLU");
            command.set(LAFCommand.MOD_BOOTPART_TABLE, "MBPT");
            command.set(LAFCommand.CHECK, "CHCK");

            subcommand = new HashMap<LAFSubCommand, string>();
            subcommand.set(LAFSubCommand.CONTROL_REBOOT_OS, "ONRS");
            subcommand.set(LAFSubCommand.CONTROL_POWER_OFF, "POFF");
            subcommand.set(LAFSubCommand.KILOCENT_CHALLENGE, "CENT");
            subcommand.set(LAFSubCommand.KILOMETER_CHALLENGE, "METR");
            subcommand.set(LAFSubCommand.INFO_GET_PROPS, "GPRO");
            subcommand.set(LAFSubCommand.INFO_SET_PROPS, "SPRO");
            subcommand.set(LAFSubCommand.SNIF_REQUEST, "REQS");
            subcommand.set(LAFSubCommand.SNIF_OPEN, "OPEN");
            subcommand.set(LAFSubCommand.SNIF_WRITE, "WRTE");
            subcommand.set(LAFSubCommand.SNIF_CLOSE, "CLSE");
            subcommand.set(LAFSubCommand.SNIF_STATUS, "STUS");
            subcommand.set(LAFSubCommand.SNIF_IDDD, "IDDD");
            subcommand.set(LAFSubCommand.OPCM_CHEK, "CHEK");
            subcommand.set(LAFSubCommand.OPCM_WRITE, "WRTE");
            subcommand.set(LAFSubCommand.MISC_WRITE, "WRTE");
            subcommand.set(LAFSubCommand.FUSE_GET, "GFUS");
            subcommand.set(LAFSubCommand.FUSE_SET, "SFRS");
            subcommand.set(LAFSubCommand.CHCK_TSUM, "TSUM");
            subcommand.set(LAFSubCommand.CHCK_CLER, "CLER");
            subcommand.set(LAFSubCommand.RESERVED_SDDD, "SDDD");
            subcommand.set(LAFSubCommand.RESERVED_IDDD, "IDDD");
            subcommand.set(LAFSubCommand.RESERVED_TDDD, "TDDD");
        }
    }
}
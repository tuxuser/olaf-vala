using Gee;

namespace Olaf.Packet
{
    public enum ATCommand
    {
        /* LG specific commands */
        ONECMD,

        FBOOT,
        FACTORY_RESET_STATUS,   // AT%%FRSTSTATUS=%d
        
        CHECK_FOTA_PACKAGE,     // AT%%CHECKFOTAPACKAGE=%s
        START_FOTA_PACKAGE,     // AT%%STARTFOTAPACKAGE=am start -a com.lge.lgfota.permission.ACTION_GOTA_LGUP_UPDATE
        HIDDEN_MENU_STATUS,
        HIDDEN_MENU_DISABLE,
        HIDDEN_MENU_ENABLE,     // AT%%HMEXT=<*8*hex*>

        RESTART,
        DOWNLOAD_MODE,
        DIAG_MODE,              // AT$DIAG=0 (alternative: nv_write NV_LG_FW_DIAG_ENABLE_I {0})

        SPC_UNLOCK,             // AT%SPCUNLOCK=000000
        /* General commands */
        SW_VERSION,
        SW_FW_VERSION,
        INFO,
        IMEI,
        DEVICE_MODEL;

        public uint8[] to_bytes()
        {
            return this.to_string().to_ascii().data;
        }

        public string to_string()
        {
            return AtCommandMap.command.get(this);
        }
    }

    public class AtCommandMap
    {
        public static HashMap<ATCommand, string> command;
        public static void init()
        {
            command = new HashMap<ATCommand, string>();
            command.set(ATCommand.ONECMD, "AT%ONECMD");
            command.set(ATCommand.FBOOT, "AT%FBOOT");
            command.set(ATCommand.FACTORY_RESET_STATUS, "AT%FRSTSTATUS=");
            command.set(ATCommand.CHECK_FOTA_PACKAGE, "AT%%CHECKFOTAPACKAGE=");
            command.set(ATCommand.START_FOTA_PACKAGE, "AT%%STARTFOTAPACKAGE=");
            command.set(ATCommand.HIDDEN_MENU_STATUS, "AT%%HMEXT?");
            command.set(ATCommand.HIDDEN_MENU_DISABLE, "AT%%HMEXT=0");
            command.set(ATCommand.HIDDEN_MENU_ENABLE, "AT%%HMEXT=");
            command.set(ATCommand.RESTART, "AT%RESTART");
            command.set(ATCommand.DOWNLOAD_MODE, "AT%DLOAD");
            command.set(ATCommand.DIAG_MODE, "AT$DIAG=");
            command.set(ATCommand.SPC_UNLOCK, "AT%SPCUNLOCK=");
            command.set(ATCommand.SW_VERSION, "AT%SWV");
            command.set(ATCommand.SW_FW_VERSION, "AT%SWFV");
            command.set(ATCommand.INFO, "AT%INFO");
            command.set(ATCommand.IMEI, "AT%IMEI");
            command.set(ATCommand.DEVICE_MODEL, "AT+GMM");
        }
    }
}
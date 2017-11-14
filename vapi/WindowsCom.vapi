[CCode(cprefix = "", lower_case_cprefix = "", cheader_filename = "comPort.h")]
namespace Vapi.WindowsCom {
    [Compact, CCode(free_function = "_vala_WindowsCom_dispose")]
    public class LGSerial {
        [CCode(cname = "openSerial")]
        public static bool open();

        [CCode(cname = "closeSerial")]
        public static void close();

        [CCode(cname = "writeSerial")]
        public static int write(uint8[] data);

        [CCode(cname = "readSerial")]
        public static int read(uint8[] data);

        /*
        [CCode(cname = "_vala_LGSerial_dispose")]
        private void dispose(){
            _close();
        }

        [CCode(cname = "_vala_LGSerial_new")]
        public LGSerial(){
            _open();
        }

        [CCode(cname = "_vala_LGSerial_read")]
        public int read(uint8[] data){
            return _read(data);
        }

        [CCode(cname = "_vala_LGSerial_write")]
        public int write(uint8[] data){
            return _write(data);
        }
         */
    }
}
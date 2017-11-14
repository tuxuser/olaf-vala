using GCrypt.Cipher;

namespace Olaf
{
    public class Crypto
    {
        private uint8[] Magic1 = {
            0x67, 0x6B, 0x72, 0x6C, 0x66, 0x67, 0x68, 0x73, 0x6D, 0x73, 0x64, 0x75, 0x66, 0x6A, 0x71, 0x6E,
            0x73, 0x64, 0x6D, 0x66, 0x74, 0x6B, 0x66, 0x6B, 0x64, 0x67, 0x6B, 0x71, 0x73, 0x6C, 0x65, 0x6B
        };
        // -----------magic2---------- "qndiakxxuiemdklseqid~a~niq,zjuxl" < seems to only be used in mfg/unfused devices
        private uint8[] Magic2 = {
            0x64, 0x71, 0x6F, 0x65, 0x76, 0x29, 0x6F, 0x68, 0x6E, 0x73, 0x57, 0x75, 0x5C, 0x62, 0x6B, 0x60,
            0x6F, 0x69, 0x69, 0x63, 0x6D, 0x5A, 0x5F, 0x6C, 0x70, 0x71, 0x65, 0x5C, 0x65, 0x61, 0x6C, 0x70
        };

        private void KeyTransform(uint8[] data, uint8[] centKey)
        {
            int i;
            uint8 *pbuf = data;
            for (i = 0; i < 8; i++)
            {
                pbuf[0] ^= centKey[3];
                pbuf[1] ^= centKey[2];
                pbuf[2] ^= centKey[1];
                pbuf[3] ^= centKey[0];
                pbuf += 4;
            }
        }

        private uint8[] Encrypt(uint8[] data, uint8[] key)
        {
            Cipher context;
            Cipher.open(out context, Algorithm.AES256, Mode.ECB, 0);

            context.set_key(key);

            uint8[] encrypted = new uint8[0x10];
            context.encrypt(encrypted, data);
            return encrypted;
        }

        public uint8[] EncryptMeterResponse(uint8[] challenge)
        {
            uint8[] buffer = new uint8[0x10];
            uint8[] keyBuf = new uint8[0x20];
            // copy over the magic static val
            Memory.copy(keyBuf, Magic2, keyBuf.length);
            // transform it with the CENT response bytes
            KeyTransform(keyBuf, challenge);
            // make the decrypted reply
            for (uint8 i = 0; i < 0x10; i++)
                buffer[i] = i & 0xFF;
           return Encrypt(buffer, keyBuf);
        }
    }
}

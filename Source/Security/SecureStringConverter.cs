using System.Security;
using System.Runtime.InteropServices;

namespace Carbon.Security
{
    public sealed class SecureStringConverter
    {
        public static byte[] ToBytes(SecureString secureString)
        {
            var unmanagedBytes = Marshal.SecureStringToGlobalAllocUnicode(secureString);
	        try
            {
	            byte[] bValue;
	            unsafe
                {
                    var byteArray = (byte*)unmanagedBytes.ToPointer();

                    bValue = new byte[secureString.Length * 2];

                    for (var i = 0; i < bValue.Length; ++i)
                    {
                        bValue[i] = *byteArray++;
                    }
                }
                return bValue;
            }
            finally
            {
                Marshal.ZeroFreeGlobalAllocUnicode(unmanagedBytes);
            }

        }
    }
}

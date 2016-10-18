using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;

namespace Carbon.Security
{
    public sealed class SecureStringConverter
    {
        public static byte[] toBytes(System.Security.SecureString pass)
        {
            IntPtr unmanagedBytes = Marshal.SecureStringToGlobalAllocUnicode(pass);
            byte[] bValue = null;
            try
            {
                unsafe
                {
                    byte* byteArray = (byte*)unmanagedBytes.ToPointer();

                    bValue = new byte[pass.Length * 2];

                    for (int i = 0; i < bValue.Length; ++i)
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

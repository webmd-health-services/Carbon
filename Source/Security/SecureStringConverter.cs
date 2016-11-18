// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//   
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

using System.Security;
using System.Runtime.InteropServices;
using System.Text;

namespace Carbon.Security
{
    public sealed class SecureStringConverter
    {
        public static byte[] ToBytes(SecureString secureString)
        {
            var pUnicodeBytes = Marshal.SecureStringToGlobalAllocUnicode(secureString);
	        try
            {
	            byte[] unicodeBytes = new byte[secureString.Length * 2]; ;
                try
                {
                    unsafe
                    {
                        var byteArray = (byte*)pUnicodeBytes.ToPointer();

    
                        for (var i = 0; i < unicodeBytes.Length; ++i)
                        {
                            unicodeBytes[i] = *byteArray++;
                        }
                    }

                    return Encoding.Convert(Encoding.Unicode, Encoding.UTF8, unicodeBytes, 0, unicodeBytes.Length);
                }
                finally
                {
                    System.Array.Clear(unicodeBytes, 0, unicodeBytes.Length);
                }
            }
            finally
            {
                Marshal.ZeroFreeGlobalAllocUnicode(pUnicodeBytes);
            }

        }
    }
}

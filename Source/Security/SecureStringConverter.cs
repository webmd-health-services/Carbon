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

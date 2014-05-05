// Copyright 2012 Aaron Jensen
//   
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

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.ServiceProcess;
using System.Text;

namespace Carbon
{
    public sealed class AdvApi32
    {

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool QueryServiceObjectSecurity(SafeHandle serviceHandle, SecurityInfos secInfo,
                                                              byte[] lpSecDesrBuf, uint bufSize, out uint bufSizeNeeded);

        // http://msdn.microsoft.com/en-us/library/cc231199.aspx
        private static readonly Dictionary<int, string> QueryServiceObjectSecurityReturnCodes =
            new Dictionary<int, string>
                {
                    { Win32ErrorCodes.ACCESS_DENIED, "Access denied. The specified handle was not opened with READ_CONTROL access, or the calling process is not the owner of the object." },
                    { Win32ErrorCodes.INVALID_HANDLE, "Invalid handle. The specified handle is not valid."},
                    { Win32ErrorCodes.INVALID_PARAMETER, "Invalid Parameter. The specified security information is not valid." },
                    { Win32ErrorCodes.INVALID_FLAGS, "Invalid flags." }
                };

        public static byte[] GetServiceSecurityDescriptor(string serviceName)
        {
            var sc = new ServiceController(serviceName);
            var sdBytes = new byte[0];
            uint bufSizeNeeded;
            var ok = QueryServiceObjectSecurity(sc.ServiceHandle,
                                                SecurityInfos.DiscretionaryAcl,
                                                sdBytes,
                                                0,
                                                out bufSizeNeeded);
            if (!ok)
            {
                var errorCode = Marshal.GetLastWin32Error();
                if (errorCode == Win32ErrorCodes.INSUFFICIENT_BUFFER)
                {
                    // expected; now we know bufsize
                    sdBytes = new byte[bufSizeNeeded];
                    ok = QueryServiceObjectSecurity(sc.ServiceHandle,
                                                    SecurityInfos.DiscretionaryAcl,
                                                    sdBytes,
                                                    bufSizeNeeded,
                                                    out bufSizeNeeded);
                }
            }
            HandleWin32Bool(ok, QueryServiceObjectSecurityReturnCodes);

            return sdBytes;
        }


        // ReSharper disable InconsistentNaming
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool SetServiceObjectSecurity(SafeHandle serviceHandle, SecurityInfos secInfos, byte[] lpSecDesrBuf);
        // ReSharper restore InconsistentNaming

        private static readonly Dictionary<int,string> SetServiceObjectSecurityReturnCodes  = new Dictionary<int, string>
                    {
                        { Win32ErrorCodes.ACCESS_DENIED, "Access denied. The specified handle was not opened with the required access, or the calling process is not the owner of the object." },
                        { Win32ErrorCodes.INVALID_HANDLE, "Invalid handle. The specified handle is not valid." },
                        { Win32ErrorCodes.INVALID_PARAMETER, "Invalid Parameter. The specified security information or security descriptor is not valid." },
                        { Win32ErrorCodes.SERVICE_MARKED_FOR_DELETE, "Service marked for delete. The specified service has been marked for deletion." }
                    };

        public static void SetServiceSecurityDescriptor(string serviceName, byte[] sdBytes)
        {
            var sc = new ServiceController(serviceName);
            var ok = SetServiceObjectSecurity(sc.ServiceHandle, SecurityInfos.DiscretionaryAcl, sdBytes);
            HandleWin32Bool(ok, SetServiceObjectSecurityReturnCodes);
        }

        private static void HandleWin32Bool(bool ok, IDictionary<int, string> errorMessageMap )
        {
            if (ok) return;

            var errorCode = Marshal.GetLastWin32Error();
            if( errorMessageMap.ContainsKey(errorCode) )
            {
                throw new Win32Exception(errorCode, errorMessageMap[errorCode]);
            }
            throw new Win32Exception(errorCode);
        }

        #region ResolveAccountName

        [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        internal static extern bool LookupAccountName(
            string lpSystemName,
            string lpAccountName,
            [MarshalAs(UnmanagedType.LPArray)] byte[] Sid,
            ref uint cbSid,
            StringBuilder ReferencedDomainName,
            ref uint cchReferencedDomainName,
            out IdentityType peUse);

        [DllImport("advapi32", CharSet = CharSet.Auto, SetLastError = true)]
        internal static extern bool ConvertSidToStringSid(
            [MarshalAs(UnmanagedType.LPArray)] byte[] pSID,
            out IntPtr ptrSid);

        #endregion
    }
}

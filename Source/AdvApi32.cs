using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.ServiceProcess;

namespace Carbon
{
    public sealed class AdvApi32
    {
        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool QueryServiceObjectSecurity(SafeHandle serviceHandle, SecurityInfos secInfo,
                                                              byte[] lpSecDesrBuf, uint bufSize, out uint bufSizeNeeded);

        private static readonly Dictionary<int, string> QueryServiceObjectSecurityReturnCodes =
            new Dictionary<int, string>
                {
                    { Win32ErrorCodes.ACCESS_DENIED, "Access denied. The specified handle was not opened with READ_CONTROL access, or the calling process is not the owner of the object." },
                    { Win32ErrorCodes.INVALID_HANDLE, "Invalid handle. The specified handle is not valid."},
                    { Win32ErrorCodes.INVALID_PARAMETER, "Invalid Parameter. The specified security information is not valid." }
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
    }
}

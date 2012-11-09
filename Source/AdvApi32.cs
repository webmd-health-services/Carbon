using System;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.ServiceProcess;

namespace Carbon
{
    public sealed class AdvApi32
    {
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool QueryServiceObjectSecurity(SafeHandle serviceHandle, SecurityInfos secInfo, byte[] lpSecDesrBuf, uint bufSize, out uint bufSizeNeeded);

        public static byte[] GetServiceSecurityDescriptor(string serviceName)
        {
            var sc = new ServiceController(serviceName);
            var psd = new byte[0];
            uint bufSizeNeeded;
            var ok = QueryServiceObjectSecurity(sc.ServiceHandle, SecurityInfos.DiscretionaryAcl, psd, 0, out bufSizeNeeded);
            if (!ok)
            {
                int err = Marshal.GetLastWin32Error();
                if (err == 122) // ERROR_INSUFFICIENT_BUFFER
                {
                    // expected; now we know bufsize
                    psd = new byte[bufSizeNeeded];
                    ok = QueryServiceObjectSecurity(sc.ServiceHandle, SecurityInfos.DiscretionaryAcl, psd, bufSizeNeeded, out bufSizeNeeded);
                }
                else
                {
                    throw new ApplicationException("error calling QueryServiceObjectSecurity() to get DACL for SeaweedService: error code=" + err);
                }
            }
            if (!ok)
                throw new ApplicationException("error calling QueryServiceObjectSecurity(2) to get DACL for SeaweedService: error code=" + Marshal.GetLastWin32Error());

            return psd;
        }

    }
}

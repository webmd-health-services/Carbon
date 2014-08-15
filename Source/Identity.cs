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
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using Carbon.Win32;

namespace Carbon
{
    public sealed class Identity
    {
		// ReSharper disable InconsistentNaming
		[DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern bool LookupAccountName(
			string lpSystemName,
			string lpAccountName,
			[MarshalAs(UnmanagedType.LPArray)] byte[] Sid,
			ref uint cbSid,
			StringBuilder ReferencedDomainName,
			ref uint cchReferencedDomainName,
			out IdentityType peUse);

		[DllImport("advapi32", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern bool ConvertSidToStringSid(
			[MarshalAs(UnmanagedType.LPArray)] byte[] pSID,
			out IntPtr ptrSid);

		[DllImport("kernel32.dll")]
		private static extern IntPtr LocalFree(IntPtr hMem);
		// ReSharper restore InconsistentNaming

		private Identity(string domain, string name, SecurityIdentifier sid, IdentityType type)
        {
            Domain = domain;
            Name = name;
            Sid = sid;
            Type = type;
        }

        public string Domain { get; private set; }

        public string FullName
        {
            get
            {
                return (string.IsNullOrEmpty(Domain)) 
                    ? Name 
                    : string.Format("{0}\\{1}", Domain, Name);
            }
        }

        public string Name { get; private set; }

        public SecurityIdentifier Sid { get; private set; }

        public IdentityType Type { get; private set; }

        public override bool Equals(object obj)
        {
            if (obj == null || typeof (Identity) != obj.GetType())
            {
                return false;
            }

            return Sid.Equals(((Identity) obj).Sid);
        }

        public override int GetHashCode()
        {
            return Sid.GetHashCode();
        }

        public override string ToString()
        {
            return FullName;
        }

        public static Identity FindByName(string name)
        {
            byte[] rawSid = null;
            uint cbSid = 0;
            var referencedDomainName = new StringBuilder();
            var cchReferencedDomainName = (uint) referencedDomainName.Capacity;
            IdentityType sidUse;

	        if (name.StartsWith(".\\"))
	        {
		        name = string.Format("{0}{1}", Environment.MachineName, name.Substring(1));
			}

	        if (name.Equals("LocalSystem", StringComparison.InvariantCultureIgnoreCase))
	        {
		        name = "NT AUTHORITY\\SYSTEM";
	        }

            int err;
            if (LookupAccountName(null, name, rawSid, ref cbSid, referencedDomainName, ref cchReferencedDomainName, out sidUse))
            {
                throw new Win32Exception();
            }

            err = Marshal.GetLastWin32Error();
            if (err == Win32ErrorCodes.InsufficientBuffer || err == Win32ErrorCodes.InvalidFlags)
            {
                rawSid = new byte[cbSid];
                referencedDomainName.EnsureCapacity((int) cchReferencedDomainName);
                if (!LookupAccountName(null, name, rawSid, ref cbSid, referencedDomainName, ref cchReferencedDomainName, out sidUse))
                {
                    throw new Win32Exception();
                }
            }
            else if (err == Win32ErrorCodes.NoneMapped)
            {
                // Couldn't find the account.
                return null;
            }
            else
            {
                throw new Win32Exception();
            }

            IntPtr ptrSid;
            if (!ConvertSidToStringSid(rawSid, out ptrSid))
            {
                throw new Win32Exception();
            }

            var sid = new SecurityIdentifier(rawSid, 0);
            LocalFree(ptrSid);
            var ntAccount = sid.Translate(typeof (NTAccount));
            var domainName = referencedDomainName.ToString();
            var accountName = ntAccount.Value;
            if (!string.IsNullOrEmpty(domainName))
            {
                var domainPrefix = string.Format("{0}\\", domainName);
                if (accountName.StartsWith(domainPrefix))
                {
                    accountName = accountName.Replace(domainPrefix, "");
                }
            }
            return new Identity(domainName, accountName, sid, sidUse);
        }
    }
}

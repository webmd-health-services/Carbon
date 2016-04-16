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
		[DllImport("advapi32", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern bool ConvertSidToStringSid(
			[MarshalAs(UnmanagedType.LPArray)] byte[] pSID,
			out IntPtr ptrSid);

		[DllImport("kernel32.dll")]
		private static extern IntPtr LocalFree(IntPtr hMem);

		[DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern bool LookupAccountName(
            string lpSystemName,
            string lpAccountName,
            [MarshalAs(UnmanagedType.LPArray)] byte[] Sid,
            ref uint cbSid,
            StringBuilder referencedDomainName,
            ref uint cchReferencedDomainName,
            out IdentityType peUse);

        [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        static extern bool LookupAccountSid(
          string lpSystemName,
          [MarshalAs(UnmanagedType.LPArray)] byte[] Sid,
          StringBuilder lpName,
          ref uint cchName,
          StringBuilder referencedDomainName,
          ref uint cchReferencedDomainName,
          out IdentityType peUse);
        
		[DllImport("NetApi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern int NetLocalGroupAddMembers(
			string servername, //server name 
			string groupname, //group name 
			UInt32 level, //info level 
			ref LOCALGROUP_MEMBERS_INFO_0 buf, //Group info structure 
			UInt32 totalentries //number of entries 
			);

		[DllImport("NetApi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern int NetLocalGroupDelMembers(
			string servername, //server name 
			string groupname, //group name 
			UInt32 level, //info level 
			ref LOCALGROUP_MEMBERS_INFO_0 buf, //Group info structure 
			UInt32 totalentries //number of entries 
			);

		[DllImport("NetAPI32.dll", CharSet = CharSet.Unicode)]
		private extern static int NetLocalGroupGetMembers(
			[MarshalAs(UnmanagedType.LPWStr)] string servername,
			[MarshalAs(UnmanagedType.LPWStr)] string localgroupname,
			int level,
			out IntPtr bufptr,
			int prefmaxlen,
			out int entriesread,
			out int totalentries,
			IntPtr resume_handle);

		[DllImport("Netapi32.dll", SetLastError = true)]
		private static extern int NetApiBufferFree(IntPtr buffer);

		[StructLayout(LayoutKind.Sequential)]
		private struct LOCALGROUP_MEMBERS_INFO_0
		{
			[MarshalAs(UnmanagedType.SysInt)]
			public IntPtr pSID;

		}
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

		public void AddToLocalGroup(string groupName)
		{
			var sidBytes = new byte[Sid.BinaryLength];
			Sid.GetBinaryForm(sidBytes, 0);

			var info3 = new LOCALGROUP_MEMBERS_INFO_0
			{
				pSID = Marshal.AllocHGlobal(sidBytes.Length)
			};

			try
			{
				Marshal.Copy(sidBytes, 0, info3.pSID, sidBytes.Length);

				var result = NetLocalGroupAddMembers(null, groupName, 0, ref info3, 1);
				if (result == Win32ErrorCodes.NERR_Success || result == Win32ErrorCodes.MemberInAlias)
				{
					return;
				}

				throw new Win32Exception(result);
			}
			finally
			{
				Marshal.FreeHGlobal(info3.pSID);
			}
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
                var username = name.Substring(2);
                name = string.Format("{0}\\{1}", Environment.MachineName, username);
                var identity = FindByName(name);
                if (identity == null)
                {
                    name = string.Format("BUILTIN\\{0}", username);
                    identity = FindByName(name);
                }
                return identity;
            }

            if (name.Equals("LocalSystem", StringComparison.InvariantCultureIgnoreCase))
            {
                name = "NT AUTHORITY\\SYSTEM";
            }

	        if (LookupAccountName(null, name, rawSid, ref cbSid, referencedDomainName, ref cchReferencedDomainName, out sidUse))
            {
                throw new Win32Exception();
            }

            var err = Marshal.GetLastWin32Error();
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

        /// <summary>
        /// Searches for an identity by SID. If the SID is invalid, or the identity doesn't exist, null is returned.
        /// </summary>
        /// <param name="sid"></param>
        /// <returns>Null if the identity isn't found or the SID is invalid. Otherwise, a `Carbon.Identity` object.</returns>
        public static Identity FindBySid(SecurityIdentifier sid)
        {
            const int ok = 0;

            var sidBytes = new byte[sid.BinaryLength];
            sid.GetBinaryForm(sidBytes, 0);

            var name = new StringBuilder();
            var cchName = (uint) name.Capacity;
            var referencedDomainName = new StringBuilder();
            var cchReferencedDomainName = (uint) referencedDomainName.Capacity;
            IdentityType identityType;

            var err = ok;
            if ( !LookupAccountSid(null, sidBytes, name, ref cchName, referencedDomainName, ref cchReferencedDomainName, out identityType))
            {
                err = Marshal.GetLastWin32Error();
                if( err == Win32ErrorCodes.InsufficientBuffer )
                {
                    name.EnsureCapacity((int) cchName);
                    referencedDomainName.EnsureCapacity((int) cchReferencedDomainName);
	                err = ok;
                    if ( !LookupAccountSid(null, sidBytes, name, ref cchName, referencedDomainName, ref cchReferencedDomainName, out identityType))
                        err = Marshal.GetLastWin32Error();
                }
            }

            switch (err)
            {
                case ok:
                    return new Identity(referencedDomainName.ToString(), name.ToString(), sid, identityType);
				case Win32ErrorCodes.NoneMapped:
                    return null;
                default:
                    throw new Win32Exception(err, string.Format("Failed to lookup account SID for '{0}'.", sid));
            }

        }

		public override int GetHashCode()
		{
			return Sid.GetHashCode();
		}

		public bool IsMemberOfLocalGroup(string groupName)
		{
			int entriesRead;
			int totalEntries;
			var resume = IntPtr.Zero;
			IntPtr buffer;
			var result = NetLocalGroupGetMembers(null, groupName, 0, out buffer, -1, out entriesRead, out totalEntries, resume);
			try
			{
				if (result != Win32ErrorCodes.NERR_Success)
				{
					throw new Win32Exception(result);
				}

				if (entriesRead == 0)
				{
					return false;
				}

				var iter = buffer;
				for (var i = 0; i < entriesRead; i++)
				{
					var memberPtr = iter + (Marshal.SizeOf(typeof(LOCALGROUP_MEMBERS_INFO_0)) * i);
					var memberInfo = (LOCALGROUP_MEMBERS_INFO_0)Marshal.PtrToStructure(memberPtr, typeof(LOCALGROUP_MEMBERS_INFO_0));
					var sid = new SecurityIdentifier(memberInfo.pSID);
					if (sid.Value == Sid.Value)
					{
						return true;
					}
				}
			}
			finally
			{
				NetApiBufferFree(buffer);
			}
			return false;
		}

		public void RemoveFromLocalGroup(string groupName)
		{
			var sidBytes = new byte[Sid.BinaryLength];
			Sid.GetBinaryForm(sidBytes, 0);

			var info3 = new LOCALGROUP_MEMBERS_INFO_0
			{
				pSID = Marshal.AllocHGlobal(sidBytes.Length)
			};

			try
			{
				Marshal.Copy(sidBytes, 0, info3.pSID, sidBytes.Length);

				var result = NetLocalGroupDelMembers(null, groupName, 0, ref info3, 1);
				if (result == Win32ErrorCodes.NERR_Success || result == Win32ErrorCodes.MemberNotInAlias)
				{
					return;
				}

				throw new Win32Exception(result);
			}
			finally
			{
				Marshal.FreeHGlobal(info3.pSID);
			}
		}

		public override string ToString()
		{
			return FullName;
		}

	}
}


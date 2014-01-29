using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;

namespace Carbon
{
    public sealed class Identity
    {
        private Identity(string domain, string name, SecurityIdentifier sid, IdentityType type)
        {
            Domain = domain;
            Name = name;
            Sid = sid;
            Type = type;
        }

        public string Domain { get; private set; }

        public string FullName { get { return string.Format("{0}\\{1}", Domain, Name); } }

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

            int err;
            if (AdvApi32.LookupAccountName(null, name, rawSid, ref cbSid, referencedDomainName, ref cchReferencedDomainName, out sidUse))
            {
                throw new Win32Exception();
            }

            err = Marshal.GetLastWin32Error();
            if (err == Win32ErrorCodes.INSUFFICIENT_BUFFER || err == Win32ErrorCodes.INVALID_FLAGS)
            {
                rawSid = new byte[cbSid];
                referencedDomainName.EnsureCapacity((int) cchReferencedDomainName);
                if (!AdvApi32.LookupAccountName(null, name, rawSid, ref cbSid, referencedDomainName, ref cchReferencedDomainName, out sidUse))
                {
                    throw new Win32Exception();
                }
            }
            else if (err == Win32ErrorCodes.NONE_MAPPED)
            {
                // Couldn't find the account.
                return null;
            }
            else
            {
                throw new Win32Exception();
            }

            IntPtr ptrSid;
            if (!AdvApi32.ConvertSidToStringSid(rawSid, out ptrSid))
            {
                throw new Win32Exception();
            }

            var sid = new SecurityIdentifier(rawSid, 0);
            Kernel32.LocalFree(ptrSid);
            var ntAccount = sid.Translate(typeof (NTAccount));
            var domainName = referencedDomainName.ToString();
            var accountName = ntAccount.Value;
            var domainPrefix = string.Format("{0}\\", domainName);
            if (accountName.StartsWith(domainPrefix))
            {
                accountName = accountName.Replace(domainPrefix, "");
            }
            return new Identity(referencedDomainName.ToString(), accountName, sid, sidUse);
        }
    }
}

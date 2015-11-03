using System.Security.AccessControl;
using System.Security.Principal;

namespace Carbon.Security
{
	public sealed class HttpUrlAccessRule : AccessRule
	{
		public HttpUrlAccessRule(IdentityReference identity, HttpUrlAccessRights accessMask) 
			: base(identity, (int)accessMask, false, InheritanceFlags.None, PropagationFlags.None, AccessControlType.Allow)
		{
		}

		public HttpUrlAccessRights HttpUrlAccessRights { get { return (HttpUrlAccessRights) AccessMask; } }
	}
}

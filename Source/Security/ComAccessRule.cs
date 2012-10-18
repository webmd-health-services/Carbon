using System;
using System.Security.AccessControl;
using System.Security.Principal;

namespace Carbon.Security
{
	public sealed class ComAccessRule : AccessRule
	{
		public ComAccessRule(IdentityReference identity, ComAccessRights rights, AccessControlType type) 
			: base(identity, (int)rights, false,InheritanceFlags.None, PropagationFlags.None, type)
		{
			if( (rights & ComAccessRights.Execute) == 0 )
			{
				throw new ArgumentException("COM access rights must always have the Execute bit set.", "rights");
			}
			ComAccessRights = rights;
		}

		public ComAccessRights ComAccessRights { get; private set; }
	}
}

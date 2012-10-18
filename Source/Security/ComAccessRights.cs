using System;

namespace Carbon.Security
{
	[Flags]
	public enum ComAccessRights : uint
	{
		Execute = 1,
		ExecuteLocal = 2,
		ExecuteRemote = 4,
		ActivateLocal = 8,
		ActivateRemote = 16
	}
}

using System.Security.AccessControl;
using System.Security.Principal;

namespace Carbon.Security
{
	public sealed class ShareAccessRule : AccessRule
	{
		public ShareAccessRule(IdentityReference identity, ShareRights accessMask, AccessControlType type) : base(identity, (int)accessMask, false, InheritanceFlags.None, PropagationFlags.None, type)
		{
			ShareRights = accessMask;
		}

		public ShareRights ShareRights { get; private set; }

		public override bool Equals(object obj)
		{
			var rule = obj as ShareAccessRule;

			if (rule == null)
			{
				return false;
			}

			return rule.ShareRights == ShareRights &&
				   rule.IdentityReference == IdentityReference &&
				   rule.AccessControlType == AccessControlType;
		}

		public override int GetHashCode()
		{
			// http://stackoverflow.com/questions/263400/what-is-the-best-algorithm-for-an-overridden-system-object-gethashcode
			unchecked // Overflow is fine, just wrap
			{
				var hash = 17;
				// Suitable nullity checks etc, of course :)
				hash = hash * 23 + ShareRights.GetHashCode();
				hash = hash * 23 + IdentityReference.GetHashCode();
				hash = hash * 23 + AccessControlType.GetHashCode();
				return hash;
			}
		}
	}
}

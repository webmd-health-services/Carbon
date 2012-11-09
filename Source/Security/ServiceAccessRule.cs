using System.Security.AccessControl;
using System.Security.Principal;

namespace Carbon.Security
{
    public sealed class ServiceAccessRule : AccessRule
    {
        public ServiceAccessRule(IdentityReference identity, ServiceAccessRights rights, AccessControlType type) : 
            base(identity, (int)rights, false, InheritanceFlags.None, PropagationFlags.None, type)
        {
            ServiceAccessRights = rights;
        }

        public ServiceAccessRights ServiceAccessRights { get; private set; }

        // ReSharper disable CSharpWarnings::CS0659
        public override bool Equals(object obj)
        {
            var rule = obj as ServiceAccessRule;

            if (rule == null)
            {
                return false;
            }

            return rule.ServiceAccessRights == ServiceAccessRights &&
                   rule.IdentityReference == IdentityReference &&
                   rule.AccessControlType == AccessControlType;
        }
        // ReSharper restore CSharpWarnings::CS0659
    }
}
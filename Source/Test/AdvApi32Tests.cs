using NUnit.Framework;

namespace Carbon.Test
{
    [TestFixture]
    public sealed class AdvApi32Tests
    {
        [Test]
        public void ShouldGetPermissions()
        {
            AdvApi32.GetServiceSecurityDescriptor("CarbonGrantPrivilege");
        }
    }
}

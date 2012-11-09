using System.ComponentModel;
using NUnit.Framework;

namespace Carbon.Test.Lsa
{
    [TestFixture]
    public sealed class LsaTests
    {
        [Test]
        public void ShouldEnumerateLsaAccountRights()
        {
            Carbon.Lsa.GetPrivileges("aaron");
        }

        [Test]
        public void ShouldGrantPrivileges()
        {
            Carbon.Lsa.GrantPrivileges("aaron", new[] { "SeServiceLogonRight" });
            var privileges = Carbon.Lsa.GetPrivileges("aaron");
            Assert.That(privileges, Is.Not.Null);
            Assert.That(privileges, Contains.Item("SeServiceLogonRight"));
        }

        [Test]
        public void ShouldRevokePrivileges()
        {
            Carbon.Lsa.GrantPrivileges("aaron", new[] { "SeServiceLogonRight", "SeBackupPrivilege" });
            Carbon.Lsa.RevokePrivileges("aaron", new[] { "SeServiceLogonRight" });
            var privileges = Carbon.Lsa.GetPrivileges("aaron");
            Assert.That(privileges, Is.Not.Null);
            Assert.That(privileges, Contains.Item("SeBackupPrivilege"));
        }

        [Test]
        public void ShouldHandleNoPrivileges()
        {
            var privileges = Carbon.Lsa.GetPrivileges("aaron");
            Carbon.Lsa.RevokePrivileges("aaron", privileges);
            privileges = Carbon.Lsa.GetPrivileges("aaron");
            Assert.That(privileges, Is.Not.Null);
            Assert.That(privileges.Length, Is.EqualTo(0));
        }

        [Test]
        [ExpectedException(typeof(Win32Exception),ExpectedMessage = "No such privilege. Indicates a specified privilege does not exist.")]
        public void ShouldRejectUnknownPrivilege()
        {
            Carbon.Lsa.GrantPrivileges("aaron", new[] { "UnknownPrivilege" });
        }

    }
}

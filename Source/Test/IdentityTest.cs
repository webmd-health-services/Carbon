using System;
using NUnit.Framework;

namespace Carbon.Test
{
    [TestFixture]
    public sealed class IdentityTest
    {
        private Identity _identity;
        private string _name;

        [SetUp]
        public void Setup()
        {
            
        }

        [Test]
        public void ShouldResolveEveryone()
        {
            GivenIdentityName("EVERYONE");
            WhenResolvingIdentityName();
            ThenIdentityShouldBe(null, "Everyone");
        }

        [Test]
        public void ShouldResolveAdministrator()
        {
            GivenIdentityName("Administrator");
            WhenResolvingIdentityName();
            ThenIdentityShouldBe(Environment.GetEnvironmentVariable("COMPUTERNAME"), "Administrator");
        }

        [Test]
        public void ShouldResolveAdministrators()
        {
            GivenIdentityName("Administrators");
            WhenResolvingIdentityName();
            ThenIdentityShouldBe("BUILTIN", "Administrators");
        }

        [Test]
        public void ShouldResolve()
        {
            GivenIdentityName("NetworkService");
            WhenResolvingIdentityName();
            ThenIdentityShouldBe("NT AUTHORITY", "NETWORK SERVICE");
        }

        private void ThenIdentityShouldBe(string domain, string name)
        {
            Assert.That(_identity.Name, Is.EqualTo(name));
            if (string.IsNullOrEmpty(domain))
            {
                Assert.That(_identity.Domain, Is.Empty);
                Assert.That(_identity.FullName, Is.EqualTo(name));
            }
            else
            {
                Assert.That(_identity.FullName, Is.EqualTo(string.Format("{0}\\{1}", domain, name)));
            }
            Assert.That(_identity.Sid, Is.Not.Null);
        }

        private void WhenResolvingIdentityName()
        {
            _identity = Identity.FindByName(_name);
        }

        private void GivenIdentityName(string name)
        {
            _name = name;
        }
    }
}

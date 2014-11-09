// Copyright 2012 Aaron Jensen
//   
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
        [Ignore]
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

	    [Test]
        [Ignore]
	    public void ShouldResolveDotDomain()
	    {
		    GivenIdentityName(".\\Administrator");
			WhenResolvingIdentityName();
			ThenIdentityShouldBe(Environment.MachineName, "Administrator");
	    }

	    [Test]
	    public void ShouldResolveLocalSystem()
	    {
		    GivenIdentityName("localSYSTEM");
			WhenResolvingIdentityName();
			ThenIdentityShouldBe("NT AUTHORITY", "SYSTEM");
	    }

        private void ThenIdentityShouldBe(string domain, string name)
        {
			Assert.That(_identity, Is.Not.Null);
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

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
using System.DirectoryServices.AccountManagement;
using System.Security.Principal;
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
        [Ignore("Reason lost to the sands of time.")]
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
		public void ShouldResolveDotDomain()
		{
			var ctx = new PrincipalContext(ContextType.Machine);
			var query = new UserPrincipal(ctx);
			var searcher = new PrincipalSearcher(query);
			var users = searcher.FindAll();
			Assert.That(users, Is.Not.Null);
			var foundAUser = false;
			foreach (var user in users)
			{
				GivenIdentityName(string.Format(".\\{0}", user.SamAccountName));
				WhenResolvingIdentityName();
				ThenIdentityShouldBe(Environment.MachineName, user.SamAccountName);
				foundAUser = true;
			}
			Assert.That(foundAUser, Is.True);
		}

	    [Test]
	    public void ShouldResolveLocalSystem()
	    {
		    GivenIdentityName("localSYSTEM");
			WhenResolvingIdentityName();
			ThenIdentityShouldBe("NT AUTHORITY", "SYSTEM");
	    }

	    [Test]
	    public void ShouldResolveBySid()
	    {
		    var id = Identity.FindByName("BUILTIN\\Administrators");
		    var idBySid = Identity.FindBySid(id.Sid);
		    Assert.That(id, Is.EqualTo(idBySid));
	    }

	    [Test]
	    public void ShouldResolveUnknownSid()
	    {
		    var id = Identity.FindBySid(new SecurityIdentifier("S-1-5-21-2678556459-1010642102-471947008-1017"));
		    Assert.That(id, Is.Null);
	    }

	    [Test]
	    public void ShouldAddUserToGroup()
        {
            var groupName = "CIdentityTest";
            using (var ctx = new PrincipalContext(ContextType.Machine))
            {
                using (var group = GroupPrincipal.FindByIdentity(ctx, groupName))
                {
                    if (group == null)
                    {
                        using (var newGroup = new GroupPrincipal(ctx, groupName))
                        {
                            newGroup.Description = string.Format("Group created by {0} test fixture.", typeof(IdentityTest).FullName);
                            newGroup.Save();
                        }
                    }
                }

                try
                {
                    var id = Identity.FindByName(string.Format("{0}\\{1}", Environment.UserDomainName, Environment.UserName));
                    id.AddToLocalGroup(groupName);
                }
                finally
                {
                    using (var group = GroupPrincipal.FindByIdentity(ctx, "CIdentityTest"))
                        if( group != null )
                            group.Delete();
                }
            }
        }

        [Test]
	    public void ShouldFindUserInGroup()
	    {
			var id = Identity.FindByName(string.Format("{0}\\{1}", Environment.UserDomainName, Environment.UserName));
		    Assert.That(id.IsMemberOfLocalGroup("Administrators"), Is.True);
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

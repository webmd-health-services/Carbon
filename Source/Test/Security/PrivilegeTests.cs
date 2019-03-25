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
using System.ComponentModel;
using Carbon.Security;
using NUnit.Framework;

namespace Carbon.Test.Security
{
    [TestFixture]
    public sealed class LsaTests
    {
	    private string _identityName;

	    [SetUp]
	    public void SetUp()
	    {
		    _identityName = string.Format("{0}\\{1}", Environment.GetEnvironmentVariable("USERDOMAIN"), Environment.GetEnvironmentVariable("USERNAME"));
	    }
        [Test]
        public void ShouldEnumerateLsaAccountRights()
        {
            Privilege.GetPrivileges(_identityName);
        }

        [Test]
        public void ShouldGrantPrivileges()
        {
            Privilege.GrantPrivileges(_identityName, new[] { "SeServiceLogonRight" });
            var privileges = Privilege.GetPrivileges(_identityName);
            Assert.That(privileges, Is.Not.Null);
            Assert.That(privileges, Contains.Item("SeServiceLogonRight"));
        }

        [Test]
        public void ShouldRevokePrivileges()
        {
            Privilege.GrantPrivileges(_identityName, new[] { "SeServiceLogonRight", "SeBackupPrivilege" });
            Privilege.RevokePrivileges(_identityName, new[] { "SeServiceLogonRight" });
            var privileges = Privilege.GetPrivileges(_identityName);
            Assert.That(privileges, Is.Not.Null);
            Assert.That(privileges, Contains.Item("SeBackupPrivilege"));
        }

        [Test]
        public void ShouldHandleNoPrivileges()
        {
            var privileges = Privilege.GetPrivileges(_identityName);
            Privilege.RevokePrivileges(_identityName, privileges);
            privileges = Privilege.GetPrivileges(_identityName);
            Assert.That(privileges, Is.Not.Null);
            Assert.That(privileges.Length, Is.EqualTo(0));
        }

        [Test]
        public void ShouldRejectUnknownPrivilege()
        {
            Assert.Throws(Is.TypeOf<Win32Exception>()
                .And.Message.EqualTo("No such privilege. Indicates a specified privilege does not exist."),
                () => { Privilege.GrantPrivileges(_identityName, new[] { "UnknownPrivilege" }); });
        }

    }
}


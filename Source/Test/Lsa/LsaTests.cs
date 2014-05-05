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

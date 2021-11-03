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

using Carbon.Firewall;
using NUnit.Framework;
using System;
using System.Text;

namespace Carbon.Test.Firewall
{
	[TestFixture]
	public sealed class RuleTests
	{
		[Test]
		public void ShouldParseGroupingResourceInfo()
		{
			var resourceInfo = new[]
			{
				"Google Chrome",
				"@mqutil.dll,-6102",
				@"@%windir%\system32\inetsrv\iisres.dll,-30503",
				@"@%ProgramFiles%\Hyper-V\SnapInAbout.dll,-211",
				"@FirewallAPI.dll,-32752",
				"@FirewallAPI.dll,-28852",
				@"@C:\Windows\Microsoft.NET\Framework64\v4.0.30319\\ServiceModelEvents.dll,-2002",
				"@peerdistsh.dll,-9003",
			};

			foreach (var item in resourceInfo)
			{
				Rule.LoadIndirectString(item);
			}
		}

        [Test]
        public void ShouldConvertToCorrectEncoding()
        {
			var resourceSource = "@FirewallAPI.dll,-25257";
			var expectedString  = new StringBuilder(256);
			Rule.SHLoadIndirectString(resourceSource, expectedString, expectedString.Capacity, IntPtr.Zero);
            var result = Rule.LoadIndirectString(resourceSource);
            Assert.That(result, Is.EqualTo(expectedString.ToString()));
        }
    }
}

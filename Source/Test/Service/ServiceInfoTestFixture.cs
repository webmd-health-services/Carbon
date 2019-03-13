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
using System.ServiceProcess;
using Carbon.Service;
using NUnit.Framework;

namespace Carbon.Test.Service
{
	[TestFixture]
	public sealed class ServiceInfoTestFixture
	{

		[Test]
		public void ShouldGetServices()
		{
			foreach (var service in ServiceController.GetServices())
			{
				var info = new ServiceInfo(service.ServiceName, "");
				Console.WriteLine(info.Name);
				Console.WriteLine(string.Format("  DelayedAutoStart  {0}", info.DelayedAutoStart));
				Assert.That(info, Is.Not.Null);
			}
		}

		[Test]
		public void ShouldNotGetInvalidService()
		{
			Assert.Throws<Win32Exception>(() => { new ServiceInfo(Guid.NewGuid().ToString(), ""); });
		}

		[Test]
		public void ShouldSetDelayedAutoStart()
		{
			var info = new ServiceInfo("BITS");
			Assert.That(info, Is.Not.Null);
			Assert.That(info.DelayedAutoStart, Is.True);
		}
	}
}


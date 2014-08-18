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
using System.Diagnostics;
using System.IO;
using Carbon.Win32;
using NUnit.Framework;

namespace Carbon.Test.Win32
{
	[TestFixture]
	public sealed class HandleInfoTestFixture
	{
		[Test]
		public void ShouldGetFileSystemHandles()
		{
			var tempPath = string.Format("Carbon.dll-HandleInfoTestFixture-{0}", System.IO.Path.GetRandomFileName());
			tempPath = System.IO.Path.Combine(System.IO.Path.GetTempPath(), tempPath);

			var me = Process.GetCurrentProcess();

			// ReSharper disable once UnusedVariable
			using (var stream = File.OpenWrite(tempPath))
			{
				var startedAt = DateTime.Now;
				var handles = HandleInfo.GetFileSystemHandles();
				Console.WriteLine("Took {0}", (DateTime.Now - startedAt));
				Assert.That(handles, Is.Not.Null);
				var foundMyHandle = false;
				foreach (var handle in handles)
				{
					if (handle.Process.Id == me.Id && handle.Path == tempPath)
					{
						foundMyHandle = true;
						break;
					}
				}
				Assert.That(foundMyHandle, Is.True);
			}

			File.Delete(tempPath);
		}
	}
}

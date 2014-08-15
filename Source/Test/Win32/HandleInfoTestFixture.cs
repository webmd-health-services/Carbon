using System;
using System.Diagnostics;
using System.IO;
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

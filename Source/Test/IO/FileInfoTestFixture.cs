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
using System.IO;
using Carbon.IO;
using NUnit.Framework;
using CFileInfo = Carbon.IO.FileInfo;
using CFile = Carbon.IO.File;
using IOPath = System.IO.Path;
using IOFile = System.IO.File;

namespace Carbon.Test.IO
{
	[TestFixture]
	public sealed class FileInfoTestFixture
	{
		[Test]
		public void ShouldIgnoreFileInDirectoryThatDoesNotExist()
		{
            Assert.Throws<DirectoryNotFoundException>(() => { new CFileInfo("C:\\I\\do\\not\\exist.txt"); });
		}

		[Test]
		public void ShouldIgnoreFileThatDoesNotExist()
		{
            Assert.Throws<FileNotFoundException>(() =>
            {
                var path = IOPath.GetTempPath();
                path = IOPath.Combine(path, IOPath.GetRandomFileName());
                new CFileInfo(path);
            });
		}

		[Test]
		public void ShouldGetFileInfo()
		{
			var path = IOPath.GetTempPath();
			path = IOPath.Combine(path, IOPath.GetRandomFileName());
			var file = IOFile.Create(path);
			file.Close();
			try
			{
				var fileInfo = new CFileInfo(path);
				BY_HANDLE_FILE_INFORMATION kernelFileInfo;
				using (file = IOFile.Open(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
				{
					try
					{
						CFileInfo.GetFileInformationByHandle(file.SafeFileHandle, out kernelFileInfo);
					}
					finally
					{
						file.Close();
					}
				}

				Assert.That(fileInfo.LinkCount, Is.EqualTo(kernelFileInfo.NumberOfLinks), "LinkCount");
				Assert.That(fileInfo.VolumeSerialNumber, Is.EqualTo(kernelFileInfo.VolumeSerialNumber), "VolumeSerialNumber");

				UInt64 fileIndex = kernelFileInfo.FileIndexHigh;
				fileIndex = fileIndex << 32;
				fileIndex |= kernelFileInfo.FileIndexLow;

				Assert.That(fileInfo.FileIndex, Is.EqualTo(fileIndex), "FileIndex");

				fileIndex = fileInfo.FileIndex;
				var upperIndex = (uint)((fileIndex >> 32) & 0xffffffff);
				Assert.That(kernelFileInfo.FileIndexHigh, Is.EqualTo(upperIndex));

				var lowerIndex = (uint) (fileIndex & 0xffffffff);
				Assert.That(kernelFileInfo.FileIndexLow, Is.EqualTo(lowerIndex));
			}
			finally
			{
				IOFile.Delete(path);
			}
		}

		[Test]
		public void ShouldGetFileInfoWithMultipleHardLinks()
		{
			var path = IOPath.GetTempPath();
			path = IOPath.Combine(path, IOPath.GetRandomFileName());

			var file = IOFile.Create(path);
			file.Close();

			var linkPath = IOPath.GetTempPath();
			linkPath = IOPath.Combine(linkPath, IOPath.GetRandomFileName());

			CFile.CreateHardLink(linkPath, path);

			try
			{
				var fileInfo = new CFileInfo(path);
				Assert.That(fileInfo.LinkCount, Is.EqualTo(2), "LinkCount");
			}
			finally
			{
				IOFile.Delete(path);
				IOFile.Delete(linkPath);
			}
		}
	}
}

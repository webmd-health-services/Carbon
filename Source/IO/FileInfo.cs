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
using System.IO;
using System.Runtime.InteropServices;
#if CORECLR
using System.Runtime.InteropServices.ComTypes;
#endif
using Microsoft.Win32.SafeHandles;
using IOFile = System.IO.File;

namespace Carbon.IO
{
    [StructLayout(LayoutKind.Sequential)]
	// ReSharper disable once InconsistentNaming
	internal struct BY_HANDLE_FILE_INFORMATION
	{
		// ReSharper disable FieldCanBeMadeReadOnly.Local
		// ReSharper disable MemberCanBePrivate.Local
		public uint FileAttributes;
#pragma warning disable 618
		public FILETIME CreationTime;
		public FILETIME LastAccessTime;
		public FILETIME LastWriteTime;
#pragma warning restore 618
		public uint VolumeSerialNumber;
		public uint FileSizeHigh;
		public uint FileSizeLow;
		public uint NumberOfLinks;
		public uint FileIndexHigh;
		public uint FileIndexLow;
		// ReSharper restore FieldCanBeMadeReadOnly.Local
		// ReSharper restore MemberCanBePrivate.Local
	}
	
	public sealed class FileInfo
	{
        [DllImport("kernel32.dll", SetLastError = true)]
		internal static extern bool GetFileInformationByHandle(SafeFileHandle hFile, out BY_HANDLE_FILE_INFORMATION lpFileInformation);

        public FileInfo(string path)
		{
            BY_HANDLE_FILE_INFORMATION kernelFileInfo;
			bool result;
			using (var file = IOFile.Open(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
			{
				try
				{
					result = GetFileInformationByHandle(file.SafeFileHandle, out kernelFileInfo);
				}
				finally
				{
					file.Close();
				}
			}

			if (! result)
			{
				throw new Win32Exception();
			}

			LinkCount = kernelFileInfo.NumberOfLinks;
			VolumeSerialNumber = kernelFileInfo.VolumeSerialNumber;
			FileIndex = kernelFileInfo.FileIndexHigh;
			FileIndex = FileIndex << 32;
			FileIndex |= kernelFileInfo.FileIndexLow;
		}

		public UInt64 FileIndex { get; private set; }

		public uint LinkCount { get; private set; }

		public uint VolumeSerialNumber { get; private set; }
	}
}


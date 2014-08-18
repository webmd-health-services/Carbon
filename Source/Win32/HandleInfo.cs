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
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

namespace Carbon
{
	public sealed class HandleInfo
	{
		private static byte DirectoryObjectTypeNumber = 0;
		private static bool FoundDirectoryObjectTypeNumber = false;
		private static byte FileObjectTypeNumber = 0;
		private static bool FoundFileObjectTypeNumber = false;

		[DllImport("ntdll.dll")]
		private static extern NT_STATUS NtQueryObject(
			[In] IntPtr Handle,
			[In] OBJECT_INFORMATION_CLASS ObjectInformationClass,
			[In] IntPtr ObjectInformation,
			[In] int ObjectInformationLength,
			[Out] out int ReturnLength);

		[DllImport("ntdll.dll")]
		private static extern NT_STATUS NtQuerySystemInformation(
			[In] SYSTEM_INFORMATION_CLASS SystemInformationClass,
			[In] IntPtr SystemInformation,
			[In] int SystemInformationLength,
			[Out] out int ReturnLength);

		[DllImport("kernel32.dll", SetLastError = true)]
		private static extern IntPtr OpenProcess(
			[In] int dwDesiredAccess,
			[In, MarshalAs(UnmanagedType.Bool)] bool bInheritHandle,
			[In] int dwProcessId);

		[DllImport("kernel32.dll", SetLastError = true)]
		[return: MarshalAs(UnmanagedType.Bool)]
		private static extern bool DuplicateHandle(
			[In] IntPtr hSourceProcessHandle,
			[In] IntPtr hSourceHandle,
			[In] IntPtr hTargetProcessHandle,
			[Out] out IntPtr lpTargetHandle,
			[In] int dwDesiredAccess,
			[In, MarshalAs(UnmanagedType.Bool)] bool bInheritHandle,
			[In] int dwOptions);

		[DllImport("kernel32.dll", SetLastError = true)]
		private static extern uint QueryDosDevice(string lpDeviceName, StringBuilder lpTargetPath, int ucchMax);

		[DllImport("kernel32.dll", SetLastError = true)]
		[return: MarshalAs(UnmanagedType.Bool)]
		private static extern bool CloseHandle(IntPtr hObject);
		
		[StructLayout(LayoutKind.Sequential)]
		private struct SystemHandleEntry
		{
			public int OwnerProcessId;
			public byte ObjectTypeNumber;
			public byte Flags;
			public ushort Handle;
			public IntPtr Object;
			public int GrantedAccess;
		}

		private enum SYSTEM_INFORMATION_CLASS
		{
			SystemBasicInformation = 0,
			SystemPerformanceInformation = 2,
			SystemTimeOfDayInformation = 3,
			SystemProcessInformation = 5,
			SystemProcessorPerformanceInformation = 8,
			SystemHandleInformation = 16,
			SystemInterruptInformation = 23,
			SystemExceptionInformation = 33,
			SystemRegistryQuotaInformation = 37,
			SystemLookasideInformation = 45
		}

		private enum OBJECT_INFORMATION_CLASS
		{
			ObjectBasicInformation = 0,
			ObjectNameInformation = 1,
			ObjectTypeInformation = 2,
			ObjectAllTypesInformation = 3,
			ObjectHandleInformation = 4
		}

		private enum NT_STATUS
		{
			STATUS_SUCCESS = 0x00000000,
			STATUS_BUFFER_OVERFLOW = unchecked((int) 0x80000005L),
			STATUS_INFO_LENGTH_MISMATCH = unchecked((int) 0xC0000004L)
		}

		private HandleInfo(string path, Process process)
		{
			Path = path;
			Process = process;
		}

		public string Path { get; private set; }
		public Process Process { get; private set; }

		public static HandleInfo[] GetFileSystemHandles()
		{
			var handles = new List<HandleInfo>();
			var length = 32;
			var ptr = IntPtr.Zero;
			var processes = new Dictionary<int, Process>();
			try
			{
				while (true)
				{
					//Trace.WriteLine(string.Format("allocating {0} bytes of memory", length));
					ptr = Marshal.AllocHGlobal(length);
					int wantedLength;
					var result = NtQuerySystemInformation(SYSTEM_INFORMATION_CLASS.SystemHandleInformation, ptr, length, out wantedLength);

					if (result == NT_STATUS.STATUS_INFO_LENGTH_MISMATCH)
					{
					    length = wantedLength;
						Marshal.FreeHGlobal(ptr);
						ptr = IntPtr.Zero;
					}
					else if (result == NT_STATUS.STATUS_SUCCESS)
					{
						break;
					}
					else
					{
						throw (new Win32Exception());
					}
				}

				var handleCount = (int)Marshal.ReadInt64(ptr);
				if (IntPtr.Size == 4)
				{
					handleCount = Marshal.ReadInt32(ptr);
					//Trace.WriteLine(string.Format("32-bit ptr"));
				}

				long offset = IntPtr.Size;
				var systemHandleEntry = new SystemHandleEntry();
				var size = Marshal.SizeOf(systemHandleEntry);
				var numProcessed = 0;

				var remainder = (length - offset)%size;
				if (remainder != 0)
				{
					throw new ApplicationException(
						string.Format(
							"SystemHandleEntry structure size different than expected. Allocated {0} bytes of memory for {1} number of objects, at {2} bytes each, but it looks like we got an extra {3} bytes.",
							length, handleCount, size, remainder));
				}

				//Trace.WriteLine(string.Format("handleCount: {0}", handleCount));
				for (var i = 0; i < handleCount; i++, offset += size)
				{
					var fileHandle = (SystemHandleEntry) Marshal.PtrToStructure((IntPtr) ((long) ptr + offset), systemHandleEntry.GetType());
					numProcessed++;
					var typeNumber = fileHandle.ObjectTypeNumber;

					if (FoundFileObjectTypeNumber && FoundDirectoryObjectTypeNumber)
					{
						if (typeNumber != FileObjectTypeNumber && typeNumber != DirectoryObjectTypeNumber)
						{
							continue;
						}
					}

					var handle = GetHandle(fileHandle, processes);
					if (handle == null)
					{
						continue;
					}

					var fileExists = File.Exists(handle.Path);
					var dirExists = Directory.Exists(handle.Path);

					if (! fileExists && ! dirExists)
					{
						continue;
					}

					if( !FoundFileObjectTypeNumber && fileExists )
					{
						//Console.WriteLine("File object type number: {0}", typeNumber);
						FileObjectTypeNumber = typeNumber;
						FoundFileObjectTypeNumber = true;
					}

					if( !FoundDirectoryObjectTypeNumber && dirExists )
					{
						//Console.WriteLine("Directory object type number: {0}", typeNumber);
						DirectoryObjectTypeNumber = typeNumber;
						FoundDirectoryObjectTypeNumber = true;
					}
					handles.Add(handle);

				}
				//Trace.WriteLine(string.Format("numProcessed: {0}", numProcessed));
				return handles.ToArray();
			}
			finally
			{
				if (ptr != IntPtr.Zero)
				{
					Marshal.FreeHGlobal(ptr);
				}
			}
		}

		private static HandleInfo GetHandle(SystemHandleEntry systemHandleEntry, Dictionary<int, Process> processes)
		{
			if (systemHandleEntry.GrantedAccess == 0x0012019f || 
				systemHandleEntry.GrantedAccess == 0x00120189 ||
				systemHandleEntry.GrantedAccess == 0x120089)
			{
				return null;
			}

			var handleDuplicate = IntPtr.Zero;
			int ownerProcessId = systemHandleEntry.OwnerProcessId;
			var sourceProcessHandle = OpenProcess(0x40, true, ownerProcessId);
			try
			{
				if (!DuplicateHandle(sourceProcessHandle, (IntPtr) systemHandleEntry.Handle, Process.GetCurrentProcess().Handle, out handleDuplicate, 0, false, 2))
				{
					return null;
				}

				int length;
				NtQueryObject(handleDuplicate, OBJECT_INFORMATION_CLASS.ObjectNameInformation, IntPtr.Zero, 0, out length);

				var ptr = Marshal.AllocHGlobal(length);
				if (NtQueryObject(handleDuplicate, OBJECT_INFORMATION_CLASS.ObjectNameInformation, ptr, length, out length) != NT_STATUS.STATUS_SUCCESS)
				{
					return null;
				}

				var path = Marshal.PtrToStringUni((IntPtr) (((long) ptr + 2*IntPtr.Size)));
				path = ConvertToRegularFileName(path);
				if (!processes.ContainsKey(ownerProcessId))
				{
					processes[ownerProcessId] = Process.GetProcessById(ownerProcessId);
				}
				var process = processes[ownerProcessId];
				var handle = new HandleInfo(path, process);

				Marshal.FreeHGlobal(ptr);
				return handle;
			}
			finally
			{
				if (sourceProcessHandle != IntPtr.Zero)
				{
					CloseHandle(sourceProcessHandle);
				}

				if (handleDuplicate != IntPtr.Zero)
				{
					CloseHandle(handleDuplicate);
				}
			}
		}

		private static string ConvertToRegularFileName(string objectName)
		{

			foreach (var logicalDrive in DriveInfo.GetDrives())
			{
				if (logicalDrive.DriveType == DriveType.Network)
				{
					continue;
				}

				if( !logicalDrive.IsReady )
				{
					continue;
				}

				var targetPath = new StringBuilder();
				if (QueryDosDevice(logicalDrive.Name.Substring(0, 2), targetPath, 256) == 0)
				{
					return targetPath.ToString();
				}

				var targetPathString = targetPath.ToString();

				if (objectName.StartsWith(targetPathString))
				{
					objectName = objectName.Replace(targetPathString, logicalDrive.Name.Substring(0, 2));
					break;
				}
			}
			return objectName;
		}
	}
}

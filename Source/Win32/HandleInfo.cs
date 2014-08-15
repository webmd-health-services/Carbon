using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

namespace Carbon.Win32
{
	public sealed class HandleInfo
	{
		private static byte _directoryObjectTypeNumber;
		private static bool _foundDirectoryObjectTypeNumber;
		private static byte _fileObjectTypeNumber;
		private static bool _foundFileObjectTypeNumber;

		[DllImport("ntdll.dll")]
		private static extern NtStatus NtQueryObject(
			[In] IntPtr handle,
			[In] ObjectInformationClass objectInformationClass,
			[In] IntPtr objectInformation,
			[In] int objectInformationLength,
			[Out] out int returnLength);

		[DllImport("ntdll.dll")]
		private static extern NtStatus NtQuerySystemInformation(
			[In] SystemInformationClass systemInformationClass,
			[In] IntPtr systemInformation,
			[In] int systemInformationLength,
			[Out] out int returnLength);

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
			// ReSharper disable FieldCanBeMadeReadOnly.Local
			public int OwnerProcessId;
			public byte ObjectTypeNumber;
			public byte Flags;
			public ushort Handle;
			public IntPtr Object;
			public int GrantedAccess;
			// ReSharper restore FieldCanBeMadeReadOnly.Local
		}

		private enum SystemInformationClass
		{
			// ReSharper disable UnusedMember.Local
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
			// ReSharper restore UnusedMember.Local
		}

		private enum ObjectInformationClass
		{
			// ReSharper disable UnusedMember.Local
			ObjectBasicInformation = 0,
			ObjectNameInformation = 1,
			ObjectTypeInformation = 2,
			ObjectAllTypesInformation = 3,
			ObjectHandleInformation = 4
			// ReSharper restore UnusedMember.Local
		}

		private enum NtStatus
		{
			// ReSharper disable UnusedMember.Local
			StatusSuccess = 0x00000000,
			StatusBufferOverflow = unchecked((int) 0x80000005L),
			StatusInfoLengthMismatch = unchecked((int) 0xC0000004L)
			// ReSharper restore UnusedMember.Local
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
			var length = 0x10000;
			var ptr = IntPtr.Zero;
			var processes = new Dictionary<int, Process>();
			try
			{
				while (true)
				{
					ptr = Marshal.AllocHGlobal(length);
					int wantedLength;
					var systemHandleInformation = SystemInformationClass.SystemHandleInformation;
					var result = NtQuerySystemInformation(systemHandleInformation, ptr, length, out wantedLength);
					
					if (result == NtStatus.StatusInfoLengthMismatch)
					{
						length = Math.Max(length, wantedLength);
						Marshal.FreeHGlobal(ptr);
						ptr = IntPtr.Zero;
					}
					else if (result == NtStatus.StatusSuccess)
					{
						break;
					}
					else
					{
						throw (new Win32Exception());
					}
				}

				var handleCount = Marshal.ReadInt64(ptr);
				if (Marshal.SizeOf(typeof (IntPtr)) == 4)
				{
					handleCount = Marshal.ReadInt32(ptr);
				}

				var offset = IntPtr.Size;
				var systemHandleEntry = new SystemHandleEntry();
				var size = Marshal.SizeOf(systemHandleEntry);

				for (var i = 0; i < handleCount; i++, offset += size)
				{
					var fileHandle = (SystemHandleEntry) Marshal.PtrToStructure((IntPtr) ((long) ptr + offset), systemHandleEntry.GetType());
					var typeNumber = fileHandle.ObjectTypeNumber;

					if (_foundFileObjectTypeNumber && _foundDirectoryObjectTypeNumber)
					{
						if (typeNumber != _fileObjectTypeNumber && typeNumber != _directoryObjectTypeNumber)
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

					if( !_foundFileObjectTypeNumber && fileExists )
					{
						//Console.WriteLine("File object type number: {0}", typeNumber);
						_fileObjectTypeNumber = typeNumber;
						_foundFileObjectTypeNumber = true;
					}

					if( !_foundDirectoryObjectTypeNumber && dirExists )
					{
						//Console.WriteLine("Directory object type number: {0}", typeNumber);
						_directoryObjectTypeNumber = typeNumber;
						_foundDirectoryObjectTypeNumber = true;
					}
					handles.Add(handle);

				}
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
				NtQueryObject(handleDuplicate, ObjectInformationClass.ObjectNameInformation, IntPtr.Zero, 0, out length);

				var ptr = Marshal.AllocHGlobal(length);
				if (NtQueryObject(handleDuplicate, ObjectInformationClass.ObjectNameInformation, ptr, length, out length) != NtStatus.StatusSuccess)
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

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
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace Carbon.Service
{

	public sealed class ServiceInfo
	{
		public ServiceInfo(string name)
		{
			var databaseHandle = OpenSCManager(null, null, SC_MANAGER_ALL_ACCESS);
			if (databaseHandle == IntPtr.Zero)
			{
				throw new Win32Exception();
			}

			var serviceHandle = OpenService(databaseHandle, name, SERVICE_QUERY_CONFIG);
			if (serviceHandle == IntPtr.Zero)
			{
				throw new Win32Exception();
			}

			Name = name;
			SetServiceInfo(serviceHandle);
			SetDescription(serviceHandle);
			SetFailureActions(serviceHandle);

			CloseServiceHandle(databaseHandle);
			CloseServiceHandle(serviceHandle);

		}

		private void SetServiceInfo(IntPtr serviceHandle)
		{
			UInt32 dwBytesNeeded;

			// Allocate memory for struct.
			IntPtr ptr = Marshal.AllocHGlobal(4096);

			bool success = QueryServiceConfig(serviceHandle, ptr, 4096, out dwBytesNeeded);

			QUERY_SERVICE_CONFIG config = new QUERY_SERVICE_CONFIG();
			// Copy 
			Marshal.PtrToStructure(ptr, config);
			// Free memory for struct.
			Marshal.FreeHGlobal(ptr);

			UserName = config.lpServiceStartName.Trim('"');
			Path = config.lpBinaryPathName.Trim('"');
			ErrorControl = (ErrorControl) config.dwErrorControl;
			LoadOrderGroup = config.lpLoadOrderGroup;
			TagID = config.dwTagID;
			StartType = (StartType) config.dwStartType;
		}

		public string Description { get; private set; }
		public string FailureProgram { get; private set; }
		public ErrorControl ErrorControl { get; private set; }
		public FailureAction FirstFailure { get; private set; }
		public string LoadOrderGroup { get; private set; }
		public string Name { get; private set; }
		public string Path { get; private set; }
		public string RebootMessage { get; private set; }
		public uint ResetPeriod { get; private set; }

		public uint ResetPeriodDays
		{
			get
			{
				if (ResetPeriod == 0)
				{
					return 0;
				}
				return ResetPeriod/24/60/60;
			}
		}

		public uint RestartDelay { get; private set; }

		public uint RestartDelayMinutes
		{
			get { return ConvertToMinutes(RestartDelay); }
		}

		public uint RebootDelay { get; private set; }

		public uint RebootDelayMinutes
		{
			get { return ConvertToMinutes(RebootDelay); }
		}

		public FailureAction SecondFailure { get; private set; }
		public StartType StartType { get; private set; }
		public uint TagID { get; private set; }
		public FailureAction ThirdFailure { get; private set; }
		public string UserName { get; private set; }

		private uint ConvertToMinutes(uint restartDelay)
		{
			if (restartDelay == 0)
				return 0;

			return restartDelay / 1000 / 60;
		}

		private void SetDescription(IntPtr serviceHandle)
		{
			UInt32 dwBytesNeeded;

			// Determine the buffer size needed
			QueryServiceConfig2(serviceHandle, SERVICE_CONFIG_DESCRIPTION, IntPtr.Zero, 0, out dwBytesNeeded);
			var ptr = Marshal.AllocHGlobal((int) dwBytesNeeded);

			QueryServiceConfig2(serviceHandle, SERVICE_CONFIG_DESCRIPTION, ptr, dwBytesNeeded, out dwBytesNeeded);
			var descriptionStruct = new SERVICE_DESCRIPTION();
			Marshal.PtrToStructure(ptr, descriptionStruct);
			Marshal.FreeHGlobal(ptr);

			Description = descriptionStruct.lpDescription;
		}

		private void SetFailureActions(IntPtr serviceHandle)
		{
			UInt32 dwBytesNeeded;

			// Determine the buffer size needed
			bool success = QueryServiceConfig2(serviceHandle, SERVICE_CONFIG_FAILURE_ACTIONS, IntPtr.Zero, 0, out dwBytesNeeded);

			IntPtr ptr = Marshal.AllocHGlobal((int) dwBytesNeeded);
			success = QueryServiceConfig2(serviceHandle, SERVICE_CONFIG_FAILURE_ACTIONS, ptr, dwBytesNeeded, out dwBytesNeeded);
			SERVICE_FAILURE_ACTIONS failureActions = new SERVICE_FAILURE_ACTIONS();
			Marshal.PtrToStructure(ptr, failureActions);

			// Report it.
			ResetPeriod = (UInt32) failureActions.dwResetPeriod;

			int offset = 0;
			for (int i = 0; i < failureActions.cActions; i++)
			{
				var type = (FailureAction)Marshal.ReadInt32(failureActions.lpsaActions, offset);
				offset += sizeof(Int32);
				var delay = (UInt32)Marshal.ReadInt32(failureActions.lpsaActions, offset);
				offset += sizeof(Int32);

				if (i == 0)
				{
					FirstFailure = type;
				}
				else if(i == 1)
				{
					SecondFailure = type;
				}
				else if (i == 2)
				{
					ThirdFailure = type;
				}

				switch (type)
				{
					case( FailureAction.Reboot):
						RebootDelay = delay;
						break;
					case( FailureAction.Restart):
						RestartDelay = delay;
						break;
				}

			}

			Marshal.FreeHGlobal(ptr);
		}

		#region P/Invoke declarations

		[StructLayout(LayoutKind.Sequential)]
		private class SERVICE_DESCRIPTION
		{
			[MarshalAs(UnmanagedType.LPWStr)] public String lpDescription;
		}

		[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
		private class SERVICE_FAILURE_ACTIONS
		{
			public int dwResetPeriod;
			[MarshalAs(UnmanagedType.LPWStr)] public string lpRebootMsg;
			[MarshalAs(UnmanagedType.LPWStr)] public string lpCommand;
			public int cActions;
			public IntPtr lpsaActions;
		}

		[DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
		private static extern IntPtr OpenSCManager(String lpMachineName, String lpDatabaseName, UInt32 dwDesiredAccess);

		[DllImport("advapi32.dll", SetLastError = true)]
		[return: MarshalAs(UnmanagedType.Bool)]
		private static extern bool CloseServiceHandle(IntPtr hSCObject);
		
		[DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
		private static extern IntPtr OpenService(IntPtr hSCManager, String lpServiceName, UInt32 dwDesiredAccess);

		[DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "QueryServiceConfig2W")]
		private static extern Boolean QueryServiceConfig2(IntPtr hService, UInt32 dwInfoLevel, IntPtr buffer, UInt32 cbBufSize,
			out UInt32 pcbBytesNeeded);
	
		[DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
		private static extern Boolean QueryServiceConfig(IntPtr hService, IntPtr intPtrQueryConfig, UInt32 cbBufSize, out UInt32 pcbBytesNeeded);

		private const Int32 SC_MANAGER_ALL_ACCESS = 0x000F003F;
		private const Int32 SERVICE_QUERY_CONFIG = 0x00000001;
		private const UInt32 SERVICE_CONFIG_DESCRIPTION = 0x01;
		private const UInt32 SERVICE_CONFIG_FAILURE_ACTIONS = 0x02;

		[StructLayout(LayoutKind.Sequential)]
		private class QUERY_SERVICE_CONFIG
		{
			[MarshalAs(System.Runtime.InteropServices.UnmanagedType.U4)]
			public UInt32 dwServiceType;
			[MarshalAs(System.Runtime.InteropServices.UnmanagedType.U4)]
			public UInt32 dwStartType;
			[MarshalAs(System.Runtime.InteropServices.UnmanagedType.U4)]
			public UInt32 dwErrorControl;
			[MarshalAs(System.Runtime.InteropServices.UnmanagedType.LPWStr)]
			public String lpBinaryPathName;
			[MarshalAs(System.Runtime.InteropServices.UnmanagedType.LPWStr)]
			public String lpLoadOrderGroup;
			[MarshalAs(System.Runtime.InteropServices.UnmanagedType.U4)]
			public UInt32 dwTagID;
			[MarshalAs(System.Runtime.InteropServices.UnmanagedType.LPWStr)]
			public String lpDependencies;
			[MarshalAs(System.Runtime.InteropServices.UnmanagedType.LPWStr)]
			public String lpServiceStartName;
			[MarshalAs(System.Runtime.InteropServices.UnmanagedType.LPWStr)]
			public String lpDisplayName;
		};
		#endregion // P/Invoke declarations
	}
}

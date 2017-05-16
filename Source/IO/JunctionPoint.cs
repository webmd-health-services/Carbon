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
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;
using IOFile = System.IO.File;

namespace Carbon.IO
{
	/// <summary>
	/// Provides access to NTFS junction points in .Net.
	/// </summary>
	/// <remarks>Written by Jeff Brown.  Taken from http://www.codeproject.com/Articles/15633/Manipulating-NTFS-Junction-Points-in-NET </remarks>
	public static class JunctionPoint
	{
		/// <summary>
		/// The file or directory is not a reparse point.
		/// </summary>
		private const int ERROR_NOT_A_REPARSE_POINT = 4390;

		/// <summary>
		/// Command to set the reparse point data block.
		/// </summary>
		private const int FSCTL_SET_REPARSE_POINT = 0x000900A4;

		/// <summary>
		/// Command to get the reparse point data block.
		/// </summary>
		private const int FSCTL_GET_REPARSE_POINT = 0x000900A8;

		/// <summary>
		/// Command to delete the reparse point data base.
		/// </summary>
		private const int FSCTL_DELETE_REPARSE_POINT = 0x000900AC;

		/// <summary>
		/// Reparse point tag used to identify mount points and junction points.
		/// </summary>
		private const uint IO_REPARSE_TAG_MOUNT_POINT = 0xA0000003;

        /// <summary>
        /// Symbolic link tag used to identify symoblic links.
        /// </summary>
        internal const uint IO_SYMOBOLIC_LINK_TAG = 0xA000000C;
        
        /// <summary>
		/// This prefix indicates to NTFS that the path is to be treated as a non-interpreted
		/// path in the virtual file system.
		/// </summary>
		private const string NonInterpretedPathPrefix = @"\??\";

		[Flags]
		internal enum EFileAccess : uint
		{
			GenericRead = 0x80000000,
			GenericWrite = 0x40000000,
			GenericExecute = 0x20000000,
			GenericAll = 0x10000000,
		}

		[Flags]
		private enum EFileShare : uint
		{
			None = 0x00000000,
			Read = 0x00000001,
			Write = 0x00000002,
			Delete = 0x00000004,
		}

		private enum ECreationDisposition : uint
		{
			New = 1,
			CreateAlways = 2,
			OpenExisting = 3,
			OpenAlways = 4,
			TruncateExisting = 5,
		}

		[Flags]
		private enum EFileAttributes : uint
		{
			Readonly = 0x00000001,
			Hidden = 0x00000002,
			System = 0x00000004,
			Directory = 0x00000010,
			Archive = 0x00000020,
			Device = 0x00000040,
			Normal = 0x00000080,
			Temporary = 0x00000100,
			SparseFile = 0x00000200,
			ReparsePoint = 0x00000400,
			Compressed = 0x00000800,
			Offline = 0x00001000,
			NotContentIndexed = 0x00002000,
			Encrypted = 0x00004000,
			Write_Through = 0x80000000,
			Overlapped = 0x40000000,
			NoBuffering = 0x20000000,
			RandomAccess = 0x10000000,
			SequentialScan = 0x08000000,
			DeleteOnClose = 0x04000000,
			BackupSemantics = 0x02000000,
			PosixSemantics = 0x01000000,
			OpenReparsePoint = 0x00200000,
			OpenNoRecall = 0x00100000,
			FirstPipeInstance = 0x00080000
		}

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern bool DeviceIoControl(IntPtr hDevice, uint dwIoControlCode,
				IntPtr InBuffer, int nInBufferSize,
				IntPtr OutBuffer, int nOutBufferSize,
				out int pBytesReturned, IntPtr lpOverlapped);

	    /// <summary>
	    /// Creates a junction point from the specified directory to the specified target directory.
	    /// </summary>
	    /// <remarks>
	    /// Only works on NTFS.
	    /// </remarks>
	    /// <param name="junctionPoint">The junction point path</param>
	    /// <param name="targetDir">The target directory</param>
	    /// <param name="overwrite">If true overwrites an existing reparse point or empty directory</param>
	    /// <exception cref="IOException">Thrown when the junction point could not be created or when
	    /// an existing directory was found and <paramref name="overwrite" /> if false</exception>
	    public static void Create(string junctionPoint, string targetDir, bool overwrite)
	    {
	        targetDir = System.IO.Path.GetFullPath(targetDir);

	        if (!Directory.Exists(targetDir))
	            throw new IOException("Target path does not exist or is not a directory.");

	        if (Directory.Exists(junctionPoint))
	        {
	            if (!overwrite)
	                throw new IOException("Directory already exists and overwrite parameter is false.");
	        }
	        else
	        {
	            Directory.CreateDirectory(junctionPoint);
	        }

	        using (SafeFileHandle handle = ReparsePoint.OpenReparsePoint(junctionPoint, ReparsePoint.EFileAccess.GenericWrite))
			{
				byte[] targetDirBytes = Encoding.Unicode.GetBytes(NonInterpretedPathPrefix + System.IO.Path.GetFullPath(targetDir));

                var reparseDataBuffer = new ReparseData
                {
                    ReparseTag = IO_REPARSE_TAG_MOUNT_POINT,
                    ReparseDataLength = (ushort) (targetDirBytes.Length + 12),
                    SubstituteNameOffset = 0,
                    SubstituteNameLength = (ushort) targetDirBytes.Length,
                    PrintNameOffset = (ushort) (targetDirBytes.Length + 2),
                    PrintNameLength = 0,
                    PathBuffer = new byte[0x3ff0]
                };

			    Array.Copy(targetDirBytes, reparseDataBuffer.PathBuffer, targetDirBytes.Length);

				int inBufferSize = Marshal.SizeOf(reparseDataBuffer);
				IntPtr inBuffer = Marshal.AllocHGlobal(inBufferSize);

				try
				{
					Marshal.StructureToPtr(reparseDataBuffer, inBuffer, false);

					int bytesReturned;
					bool result = DeviceIoControl(handle.DangerousGetHandle(), FSCTL_SET_REPARSE_POINT,
							inBuffer, targetDirBytes.Length + 20, IntPtr.Zero, 0, out bytesReturned, IntPtr.Zero);

					if (!result)
						ThrowLastWin32Error("Unable to create junction point.");
				}
				finally
				{
					Marshal.FreeHGlobal(inBuffer);
				}
			}
		}


		/// <summary>
		/// Deletes a junction point at the specified source directory along with the directory itself.
		/// Does nothing if the junction point does not exist.
		/// </summary>
		/// <remarks>
		/// Only works on NTFS.
		/// </remarks>
		/// <param name="junctionPoint">The junction point path</param>
		public static void Delete(string junctionPoint)
		{
			if (!Directory.Exists(junctionPoint))
			{
				if (IOFile.Exists(junctionPoint))
					throw new IOException("Path is not a junction point.");

				return;
			}

			using (SafeFileHandle handle = ReparsePoint.OpenReparsePoint(junctionPoint, ReparsePoint.EFileAccess.GenericWrite))
			{
                var reparseDataBuffer = new ReparseData
                {
                    ReparseTag = IO_REPARSE_TAG_MOUNT_POINT,
                    ReparseDataLength = 0,
                    PathBuffer = new byte[0x3ff0]
                };

			    int inBufferSize = Marshal.SizeOf(reparseDataBuffer);
				IntPtr inBuffer = Marshal.AllocHGlobal(inBufferSize);
				try
				{
					Marshal.StructureToPtr(reparseDataBuffer, inBuffer, false);

					int bytesReturned;
					bool result = DeviceIoControl(handle.DangerousGetHandle(), FSCTL_DELETE_REPARSE_POINT,
							inBuffer, 8, IntPtr.Zero, 0, out bytesReturned, IntPtr.Zero);

					if (!result)
						ThrowLastWin32Error("Unable to delete junction point.");
				}
				finally
				{
					Marshal.FreeHGlobal(inBuffer);
				}

				try
				{
					Directory.Delete(junctionPoint);
				}
				catch (IOException ex)
				{
					throw new IOException("Unable to delete junction point.", ex);
				}
			}
		}

		/// <summary>
		/// Determines whether the specified path exists and refers to a junction point.
		/// </summary>
		/// <param name="path">The junction point path</param>
		/// <returns>True if the specified path represents a junction point</returns>
		/// <exception cref="IOException">Thrown if the specified path is invalid
		/// or some other error occurs</exception>
		public static bool Exists(string path)
		{
			if (!Directory.Exists(path))
				return false;

			var target = ReparsePoint.GetTarget(path);
			return target != null;
		}

		/// <summary>
		/// Gets the target of the specified junction point.
		/// </summary>
		/// <remarks>
		/// Only works on NTFS.
		/// </remarks>
		/// <param name="junctionPoint">The junction point path</param>
		/// <returns>The target of the junction point</returns>
		/// <exception cref="IOException">Thrown when the specified path does not
		/// exist, is invalid, is not a junction point, or some other error occurs</exception>
		public static string GetTarget(string junctionPoint)
		{
		    return ReparsePoint.GetTarget(junctionPoint);
		}

		private static void ThrowLastWin32Error(string message)
		{
			throw new IOException(message, Marshal.GetExceptionForHR(Marshal.GetHRForLastWin32Error()));
		}
	}
}


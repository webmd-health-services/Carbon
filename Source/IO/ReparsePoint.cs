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
    public static class ReparsePoint
    {
        /// <summary>
        /// The file or directory is not a reparse point.
        /// </summary>
        private const int ERROR_NOT_A_REPARSE_POINT = 4390;

        /// <summary>
        /// Command to get the reparse point data block.
        /// </summary>
        private const int FSCTL_GET_REPARSE_POINT = 0x000900A8;

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

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr CreateFile(
                string lpFileName,
                EFileAccess dwDesiredAccess,
                EFileShare dwShareMode,
                IntPtr lpSecurityAttributes,
                ECreationDisposition dwCreationDisposition,
                EFileAttributes dwFlagsAndAttributes,
                IntPtr hTemplateFile);

        internal static ReparseData? GetReparseData(SafeFileHandle handle)
        {
            int outBufferSize = Marshal.SizeOf(typeof(ReparseData));
            IntPtr outBuffer = Marshal.AllocHGlobal(outBufferSize);

            try
            {
                int bytesReturned;
                bool result = DeviceIoControl(handle.DangerousGetHandle(), FSCTL_GET_REPARSE_POINT,
                        IntPtr.Zero, 0, outBuffer, outBufferSize, out bytesReturned, IntPtr.Zero);

                if (!result)
                {
                    int error = Marshal.GetLastWin32Error();
                    if (error == ERROR_NOT_A_REPARSE_POINT)
                        return null;

                    ThrowLastWin32Error("Unable to get information about junction point.");
                }

                return (ReparseData)
                        Marshal.PtrToStructure(outBuffer, typeof(ReparseData));
            }
            finally
            {
                Marshal.FreeHGlobal(outBuffer);
            }
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
            using (SafeFileHandle handle = OpenReparsePoint(junctionPoint, EFileAccess.GenericRead))
            {
                string target = InternalGetTarget(handle);
                if (target == null)
                    return null;

                return target;
            }
        }

        private static string InternalGetTarget(SafeFileHandle handle)
        {
            var nullableReparseDataBuffer = GetReparseData(handle);
            if (nullableReparseDataBuffer == null)
                return null;

            var reparseDataBuffer = nullableReparseDataBuffer.Value;
            if (reparseDataBuffer.ReparseTag != IO_REPARSE_TAG_MOUNT_POINT &&
                reparseDataBuffer.ReparseTag != IO_SYMOBOLIC_LINK_TAG)
                return null;

            var offset = reparseDataBuffer.SubstituteNameOffset;
            var length = reparseDataBuffer.SubstituteNameLength;
            if (reparseDataBuffer.ReparseTag == IO_SYMOBOLIC_LINK_TAG)
            {
                // Offset should include the two NULL terminators that come before it in the buffer. Not sure why there are two.
                offset = (ushort)(reparseDataBuffer.PrintNameOffset + (sizeof(char) * 2));
                length = reparseDataBuffer.PrintNameLength;
            }

            string targetDir = Encoding.Unicode.GetString(reparseDataBuffer.PathBuffer, offset, length);

            if (targetDir.StartsWith(NonInterpretedPathPrefix))
                targetDir = targetDir.Substring(NonInterpretedPathPrefix.Length);

            return targetDir;
        }

        internal static SafeFileHandle OpenReparsePoint(string reparsePoint, EFileAccess accessMode)
        {
            var reparsePointHandle = new SafeFileHandle(CreateFile(reparsePoint, accessMode,
                    EFileShare.Read | EFileShare.Write | EFileShare.Delete,
                    IntPtr.Zero, ECreationDisposition.OpenExisting,
                    EFileAttributes.BackupSemantics | EFileAttributes.OpenReparsePoint, IntPtr.Zero), true);

            if (Marshal.GetLastWin32Error() != 0)
                ThrowLastWin32Error("Unable to open reparse point.");

            return reparsePointHandle;
        }

        private static void ThrowLastWin32Error(string message)
        {
            throw new IOException(message, Marshal.GetExceptionForHR(Marshal.GetHRForLastWin32Error()));
        }
    }
}


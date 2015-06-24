using System;
using System.Runtime.InteropServices;

namespace Carbon.IO
{
	public sealed class File
	{
		[DllImport("Kernel32.dll", CharSet = CharSet.Unicode)]
		static extern bool CreateHardLink(string lpFileName, string lpExistingFileName, IntPtr lpSecurityAttributes);

		public static void CreateHardLink(string path, string existingPath)
		{
			CreateHardLink(path, existingPath, IntPtr.Zero);
		}
	}
}

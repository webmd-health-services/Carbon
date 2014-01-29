using System;
using System.Runtime.InteropServices;

namespace Carbon
{
    public sealed class Kernel32
    {
        [DllImport("kernel32.dll")]
        public static extern IntPtr LocalFree(IntPtr hMem);
    }
}

using System.Runtime.InteropServices;

namespace Carbon.IO
{
    [StructLayout(LayoutKind.Sequential)]
    internal struct ReparseData
    {
        /// <summary>
        /// Reparse point tag. Must be a Microsoft reparse point tag.
        /// </summary>
        public uint ReparseTag;

        /// <summary>
        /// Size, in bytes, of the data after the Reserved member. This can be calculated by:
        /// (4 * sizeof(ushort)) + SubstituteNameLength + PrintNameLength + 
        /// (namesAreNullTerminated ? 2 * sizeof(char) : 0);
        /// </summary>
        public ushort ReparseDataLength;

        /// <summary>
        /// Reserved; do not use. 
        /// </summary>
        public ushort Reserved;

        /// <summary>
        /// Offset, in bytes, of the substitute name string in the PathBuffer array.
        /// </summary>
        public ushort SubstituteNameOffset;

        /// <summary>
        /// Length, in bytes, of the substitute name string. If this string is null-terminated,
        /// SubstituteNameLength does not include space for the null character.
        /// </summary>
        public ushort SubstituteNameLength;

        /// <summary>
        /// Offset, in bytes, of the print name string in the PathBuffer array.
        /// </summary>
        public ushort PrintNameOffset;

        /// <summary>
        /// Length, in bytes, of the print name string. If this string is null-terminated,
        /// PrintNameLength does not include space for the null character. 
        /// </summary>
        public ushort PrintNameLength;

        /// <summary>
        /// A buffer containing the unicode-encoded path string. The path string contains
        /// the substitute name string and print name string.
        /// </summary>
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 0x3FF0)]
        public byte[] PathBuffer;
    }
}

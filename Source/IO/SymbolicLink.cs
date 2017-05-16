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

using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
using IOFile = System.IO.File;
using IOPath = System.IO.Path;

namespace Carbon.IO
{
    public sealed class SymbolicLink
    {
        private enum SymbolicLinkType
        {
            File = 0x0,
            Directory = 0x1
        }

        [DllImport("kernel32.dll")]
        [return: MarshalAs(UnmanagedType.I1)]
        private static extern bool CreateSymbolicLink(string lpSymlinkFileName, string lpTargetFileName, SymbolicLinkType dwType);

        public static void Create(string path, string existingPath, bool isDirectory)
        {
            var typeFlags = SymbolicLinkType.File;
            if (isDirectory)
            {
                typeFlags = SymbolicLinkType.Directory;
            }

            CreateSymbolicLink(path, existingPath, typeFlags);
        }

        public static bool IsSymbolicLink(string path)
        {
            using (SafeFileHandle handle = ReparsePoint.OpenReparsePoint(path, ReparsePoint.EFileAccess.GenericRead))
            {
                var data = ReparsePoint.GetReparseData(handle);
                if (data == null)
                    return false;

                return (data.Value.ReparseTag == ReparsePoint.IO_SYMOBOLIC_LINK_TAG);
            }
        }

        public static string GetTargetPath(string path)
        {
            return ReparsePoint.GetTarget(path);
        }

    }
}

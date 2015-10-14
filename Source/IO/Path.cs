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

using System.IO;
using System.Runtime.InteropServices;
using System.Text;

namespace Carbon.IO
{
	public class Path
	{
		[DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
		public static extern uint GetLongPathName(
			string shortPath,
			StringBuilder sb,
			int buffer);

		[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
		public static extern uint GetShortPathName(
			string lpszLongPath,
			StringBuilder lpszShortPath,
			uint cchBuffer);

		[DllImport("shlwapi.dll", CharSet = CharSet.Auto)]
		public static extern bool PathRelativePathTo(
			[Out] StringBuilder pszPath,
			[In] string pszFrom,
			[In] FileAttributes dwAttrFrom,
			[In] string pszTo,
			[In] FileAttributes dwAttrTo
			);

    }
}


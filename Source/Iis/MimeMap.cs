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

namespace Carbon.Iis
{
	public sealed class MimeMap
	{
		public MimeMap(string fileExtension, string mimeType)
		{
			FileExtension = fileExtension;
			MimeType = mimeType;
		}

		public string FileExtension { get; private set; }

		public string MimeType { get; private set; }

		public override bool Equals(object obj)
		{
			var otherMimeMap = obj as MimeMap;

			if (otherMimeMap == null)
			{
				return false;
			}

			return FileExtension.Equals(otherMimeMap.FileExtension, StringComparison.InvariantCultureIgnoreCase) &&
			       MimeType.Equals(otherMimeMap.MimeType, StringComparison.InvariantCultureIgnoreCase);
		}

		public override int GetHashCode()
		{
			return ToString().ToLowerInvariant().GetHashCode();
		}

		public override string ToString()
		{
			return string.Format("{0} -> {1}", FileExtension, MimeType);
		}
	}
}


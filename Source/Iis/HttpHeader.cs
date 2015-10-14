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
	public sealed class HttpHeader 
	{
		public HttpHeader(string name, string value)
		{
			Name = name;
			Value = value;
		}

		public string Name { get; private set; }

		public string Value { get; private set; }

		public override bool Equals(object obj)
		{
			var otherHeader = obj as HttpHeader;

			if (otherHeader == null)
			{
				return false;
			}

			return Name.Equals(otherHeader.Name, StringComparison.InvariantCultureIgnoreCase) &&
			       Value.Equals(otherHeader.Value, StringComparison.InvariantCultureIgnoreCase);
		}

		public override int GetHashCode()
		{
			return ToString().ToLowerInvariant().GetHashCode();
		}

		public override string ToString()
		{
			return string.Format("{0}: {1}", Name, Value);
		}
	}
}


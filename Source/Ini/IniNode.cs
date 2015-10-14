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

namespace Carbon.Ini
{
    public sealed class IniNode
    {
        public IniNode(string section, string name, string value, int lineNumber)
        {
            Section = section;
            Name = name;
            Value = value;
            LineNumber = lineNumber;
        }

        public string FullName
        {
            get
            {
                if( String.IsNullOrEmpty(Section))
                {
                    return Name;
                }
                return string.Format("{0}.{1}", Section, Name);
            }
        }

        public int LineNumber { get; set; }
        public string Name { get; set; }
        public string Section { get; set; }
        public string Value { get; set; }
}
}


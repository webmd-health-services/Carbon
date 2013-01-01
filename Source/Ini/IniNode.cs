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

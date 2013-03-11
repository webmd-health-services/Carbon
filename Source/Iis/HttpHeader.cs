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

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
	}
}

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
	}
}

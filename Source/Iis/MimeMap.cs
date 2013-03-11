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

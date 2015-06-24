using System;
using System.Collections;

namespace Carbon.Msi
{
	public sealed class MsiInfo
	{
		public MsiInfo(string path, Hashtable properties)
		{
			if (String.IsNullOrEmpty(path))
			{
				throw new ArgumentException("Path must not be null or empty.", "path");
			}

			if (properties == null)
			{
				throw new ArgumentNullException("properties");
			}

			var requiredProperties = new[] {"Manufacturer", "ProductCode", "ProductLanguage", "ProductName", "ProductVersion"};
			foreach (var requiredProperty in requiredProperties)
			{
				if( !properties.ContainsKey(requiredProperty) )
				{
					throw new ArgumentException(string.Format("Property '{0}' not found (MSI: {1}).", requiredProperty, path));
				}
			}

			Path = path;
			Properties = properties.Clone() as Hashtable;

			Manufacturer = properties["Manufacturer"] as string;

			Guid productCode;
			if (!Guid.TryParse(properties["ProductCode"] as string, out productCode))
			{
				throw new ArgumentException(string.Format("Property 'ProductCode' is an invalid GUID (value: {0}; MSI {1}).", properties["ProductCode"], path));
			}
			ProductCode = productCode;

			int langID;
			if (! int.TryParse(properties["ProductLanguage"] as string, out langID))
			{
				throw new ArgumentException(string.Format("Property 'ProductLanguage' is an invalid integer (value: {0}; MSI {1}).", properties["ProductLanguage"], path));
			}
			ProductLanguage = langID;

			ProductName = properties["ProductName"] as string;

			ProductVersion = properties["ProductVersion"] as string;

		}

		public string Manufacturer { get; private set; }
		public string Path { get; private set; }
		public Guid ProductCode { get; private set; }
		public int ProductLanguage { get; private set; }
		public string ProductName { get; private set; }
		public string ProductVersion { get; private set; }
		public Hashtable Properties { get; private set; }

		public override string ToString()
		{
			return Path;
		}

		public override bool Equals(object obj)
		{
			if (obj as MsiInfo == null)
			{
				return false;
			}

			var other = obj as MsiInfo;
			return (other.Manufacturer == Manufacturer &&
			        other.ProductCode == ProductCode &&
			        other.ProductLanguage == ProductLanguage &&
			        other.ProductName == ProductName &&
			        other.ProductVersion == ProductVersion);
		}

		public override int GetHashCode()
		{
			return Path.GetHashCode();
		}

	}


}

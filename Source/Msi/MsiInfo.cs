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
using System.Collections;
using System.Runtime.InteropServices;
#if NET452
using WindowsInstaller;
#endif

namespace Carbon.Msi
{
	[Obsolete("Functionality moved to Carbon.Windows.Installer module.")]
	public sealed class MsiInfo
	{
		public MsiInfo(string path)
		{
#if CORECLR
            throw new PlatformNotSupportedException("Reading MSI information is not supported under .NET Core. The WindowsInstaller COM component doesn't support .NET Core.");
#else
            if (String.IsNullOrEmpty(path))
			{
				throw new ArgumentException("Path must not be null or empty.", "path");
			}

			var winInstallerType = Type.GetTypeFromProgID("WindowsInstaller.Installer");
			if (winInstallerType == null)
			{
				throw new Exception("Unable to get type from prog ID 'WindowsInstaller.Installer'.");
			}

			var installer = Activator.CreateInstance(winInstallerType) as Installer;
			if (installer == null)
			{
				throw new Exception("Unable to create instance of prog ID 'WindowsInstaller.Installer'.");
			}

			Database database = null;
			View view = null;

			try
			{

				database = installer.OpenDatabase(path, 0);
				if (database == null)
				{
					throw new Exception(string.Format("Unable to open database '{0}'.", path));
				}

				const string query = "select * from Property";

				view = database.OpenView(query);
				if (view == null)
				{
					throw new Exception(string.Format("Failed to query properties for MSI '{0}'.", path));
				}

				view.Execute();
				var record = view.Fetch();

				Properties = new Hashtable();

				while (record != null)
				{
					Properties[record.StringData[1]] = record.StringData[2];
					record = view.Fetch();
				}

				Initialize(path);
			}
			finally
			{
				if (view != null)
				{
					view.Close();
					Marshal.FinalReleaseComObject(view);
				}

				if (database != null)
				{
					Marshal.FinalReleaseComObject(database);
				}

				if (installer != null)
				{
					Marshal.FinalReleaseComObject(installer);
				}
			}
#endif
        }

		private void Initialize(string path)
		{
			var requiredProperties = new[] {"Manufacturer", "ProductCode", "ProductLanguage", "ProductName", "ProductVersion"};
			foreach (var requiredProperty in requiredProperties)
			{
				if (!Properties.ContainsKey(requiredProperty))
				{
					throw new ArgumentException(string.Format("Property '{0}' not found (MSI: {1}).", requiredProperty, path));
				}
			}

			Path = path;

			Manufacturer = Properties["Manufacturer"] as string;

			Guid productCode;
			if (!Guid.TryParse(Properties["ProductCode"] as string, out productCode))
			{
				throw new ArgumentException(string.Format("Property 'ProductCode' is an invalid GUID (value: {0}; MSI {1}).",
					Properties["ProductCode"], path));
			}
			ProductCode = productCode;

			int langID;
			if (!int.TryParse(Properties["ProductLanguage"] as string, out langID))
			{
				throw new ArgumentException(string.Format("Property 'ProductLanguage' is an invalid integer (value: {0}; MSI {1}).",
					Properties["ProductLanguage"], path));
			}
			ProductLanguage = langID;

			ProductName = Properties["ProductName"] as string;

			ProductVersion = Properties["ProductVersion"] as string;
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


// Copyright 2012 Aaron Jensen
//   
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
using System.Globalization;
using Microsoft.Win32;

namespace Carbon.Computer
{
	public sealed class ProgramInstallInfo
	{
		public ProgramInstallInfo(RegistryKey key)
		{
			Key = key;

			Comments = GetValueAsString("Comments");
			Contact = GetValueAsString("Contact");
			DisplayName = GetValueAsString("DisplayName");
			DisplayVersion = GetValueAsString("DisplayVersion");
			EstimatedSize = GetValueAsInt("EstimatedSize");
			HelpLink = GetValueAsString("HelpLink");
			HelpTelephone = GetValueAsString("HelpTelephone");

			var installDateValue = GetValueAsString("InstallDate");
			DateTime installDate;
			if (! DateTime.TryParse(installDateValue, out installDate))
			{
				DateTime.TryParseExact(installDateValue, "yyyyMMdd", CultureInfo.CurrentCulture, DateTimeStyles.None, out installDate);
			}
			InstallDate = installDate;

			InstallLocation = GetValueAsString("InstallLocation");
			InstallSource = GetValueAsString("InstallSource");
			Language = GetValueAsInt("Language");
			ModifyPath = GetValueAsString("ModifyPath");
			Path = GetValueAsString("Path");
			Publisher = GetValueAsString("Publisher");
			Readme = GetValueAsString("Readme");
			Size = GetValueAsString("Size");
			UninstallString = GetValueAsString("UninstallString");
			UrlInfoAbout = GetValueAsString("URLInfoAbout");
			UrlUpdateInfo = GetValueAsString("URLUpdateInfo");
			Version = GetValueAsInt("Version");
			VersionMajor = GetValueAsInt("VersionMajor");
			VersionMinor = GetValueAsInt("VersionMinor");

			var windowsInstallerValue = GetValueAsInt("WindowsInstaller");
			WindowsInstaller = (windowsInstallerValue > 0);
		}

		private string GetValueAsString(string valueName)
		{
			var value = Key.GetValue(valueName);
			if (value == null)
			{
				return string.Empty;
			}
			return value.ToString();
		}

		private int GetValueAsInt(string valueName)
		{
			int value;
			var rawValue = Key.GetValue(valueName);
			if (rawValue == null)
			{
				return 0;
			}

			Int32.TryParse(Convert.ToString(rawValue), out value);	
			return value;
		}

		public string Contact { get; private set; }

		public string Comments { get; private set; }

		public string DisplayName { get; private set; }

		public string DisplayVersion { get; private set; }

		public int EstimatedSize { get; private set; }

		public string HelpLink { get; private set; }

		public string HelpTelephone { get; private set; }

		public DateTime InstallDate { get; private set; }

		public string InstallLocation { get; private set; }

		public string InstallSource { get; private set; }

		public int Language { get; private set; }

		public string ModifyPath { get; private set; }

		public RegistryKey Key { get; private set; }
	
		public string Path { get; private set; }

		public string Publisher { get; private set; }

		public string Readme { get; private set; }

		public string Size { get; private set; }

		public string UninstallString { get; private set; }

		public string UrlInfoAbout { get; private set; }
	
		public string UrlUpdateInfo { get; private set; }

		public int Version { get; private set; }

		public int VersionMajor { get; private set; }
	
		public int VersionMinor { get; private set; }

		public bool WindowsInstaller { get; private set; }

		public override bool Equals(object obj)
		{
			var programInfo = obj as ProgramInstallInfo;
			if( programInfo == null )
			{
				return false;
			}

			return (DisplayName == programInfo.DisplayName && 
					Publisher == programInfo.Publisher && 
					DisplayVersion == programInfo.DisplayVersion);
		}

		public override int GetHashCode()
		{
			unchecked // Overflow is fine, just wrap
			{
				int hash = 17;
				// Suitable nullity checks etc, of course :)
				hash = hash * 23 + DisplayName.GetHashCode();
				hash = hash * 23 + Publisher.GetHashCode();
				hash = hash * 23 + DisplayVersion.GetHashCode();
				return hash;
			}
		}
	}
}

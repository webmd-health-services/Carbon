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
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

namespace Carbon.Firewall
{
	public sealed class Rule
	{
		public Rule(string name, bool enabled, RuleDirection direction, RuleProfile profile, string grouping, string localIPAddress,
			string localPort, string remoteIPAddress, string remotePort, string protocol, string edgeTraversal, RuleAction action, 
			RuleInterfaceType interfaceType,  RuleSecurity security, string source, string description, string program, string service)
		{
			Name = name;
			Enabled = enabled;
			Direction = direction;
			Profile = profile;
			if (Profile == RuleProfile.Any)
			{
				Profiles = "Any";
			}
			else
			{
				var profiles = new List<string>();
				if (IsDomainProfile)
				{
					profiles.Add("Domain");
				}
				if (IsPrivateProfile)
				{
					profiles.Add("Private");
				}
				if (IsPublicProfile)
				{
					profiles.Add("Public");
				}
				Profiles = string.Join(",", profiles.ToArray());
			}

			Grouping = LoadIndirectString(grouping);
			LocalIPAddress = localIPAddress;
			LocalPort = localPort;
			RemoteIPAddress = remoteIPAddress;
			RemotePort = remotePort;
			Protocol = protocol;
			EdgeTraversal = edgeTraversal;
			switch (edgeTraversal.ToLowerInvariant())
			{
				case "yes":
					EdgeTraversalPolicy = RuleEdgeTraversalPolicy.Yes;
					break;
				case "no":
					EdgeTraversalPolicy = RuleEdgeTraversalPolicy.No;
					break;
				case "defer to user":
					EdgeTraversalPolicy = RuleEdgeTraversalPolicy.DeferUser;
					break;
				case "defer to application":
					EdgeTraversalPolicy = RuleEdgeTraversalPolicy.DeferApp;
					break;
			}
			Action = action;
			InterfaceType = interfaceType;
			Security = security;
			Source = source;
			Description = description;
			Program = program;
			Service = service;
		}

		public RuleAction Action { get; private set; }
		public string Description { get; private set; }
		public RuleDirection Direction { get; private set; }
		public string EdgeTraversal { get; private set; }
		public RuleEdgeTraversalPolicy EdgeTraversalPolicy { get; private set; }
		public bool Enabled { get; private set; }
		public string Grouping { get; private set; }
		public RuleInterfaceType InterfaceType { get; private set; }
		public bool IsDomainProfile { get { return (Profile & RuleProfile.Domain) == RuleProfile.Domain; } }
		public bool IsPrivateProfile { get { return (Profile & RuleProfile.Private) == RuleProfile.Private; } }
		public bool IsPublicProfile { get { return (Profile & RuleProfile.Public) == RuleProfile.Public; } }
		public string LocalIPAddress { get; private set; }
		public string LocalPort { get; private set; }
		public string Name { get; private set; }
		public RuleProfile Profile { get; private set; }
		public string Profiles { get; private set; }
		public string Program { get; private set; }
		public string Protocol { get; private set; }
		public string RemoteIPAddress { get; private set; }
		public string RemotePort { get; private set; }
		public RuleSecurity Security { get; private set; }
		public string Service { get; private set; }
		public string Source { get; private set; }

		[DllImport("shlwapi.dll", BestFitMapping = false, CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = false, ThrowOnUnmappableChar = true)]
		internal static extern int SHLoadIndirectString(string pszSource, StringBuilder pszOutBuf, int cchOutBuf, IntPtr ppvReserved);
		
		internal static string LoadIndirectString(string resourceInfo)
		{
			Trace.WriteLine(string.Format("Indirect String: {0}", resourceInfo));
			int capacity = 2056;
			while (true)
			{
				try
				{
					var groupBuilder = new StringBuilder(capacity);
					var result = SHLoadIndirectString(resourceInfo, groupBuilder, capacity, IntPtr.Zero);
					Trace.WriteLine(String.Format("Return value:    {0}", result));
					Trace.WriteLine(string.Format("Resource Value:  {0}", groupBuilder.ToString()));
					Trace.WriteLine("");
					return groupBuilder.ToString();
				}
				catch (NullReferenceException)
				{
					capacity *= 2;
				}
			}
		}
	}
}


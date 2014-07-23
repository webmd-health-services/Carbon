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

using System.Collections.Generic;

namespace Carbon.Firewall
{
	public sealed class Rule
	{
		public Rule(string name, bool enabled, RuleDirection direction, RuleProfile profile, string grouping,
			string localIP, string localPort, string remoteIP, string remotePort, string protocol, string edgeTraversal,
			RuleAction action)
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

			Grouping = grouping;
			LocalIP = localIP;
			LocalPort = localPort;
			RemoteIP = remoteIP;
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
					EdgeTraversalPolicy = RuleEdgeTraversalPolicy.DeferUser;
					break;
			}
			Action = action;
		}

		public RuleAction Action { get; private set; }
		public RuleDirection Direction { get; private set; }
		public string EdgeTraversal { get; private set; }
		public RuleEdgeTraversalPolicy EdgeTraversalPolicy { get; private set; }
		public bool Enabled { get; private set; }
		public string Grouping { get; private set; }
		public bool IsDomainProfile { get { return Profile == RuleProfile.Any || (Profile & RuleProfile.Domain) == RuleProfile.Domain; } }
		public bool IsPrivateProfile { get { return Profile == RuleProfile.Any || (Profile & RuleProfile.Private) == RuleProfile.Private; } }
		public bool IsPublicProfile { get { return Profile == RuleProfile.Any || (Profile & RuleProfile.Public) == RuleProfile.Public; } }
		public string LocalIP { get; private set; }
		public string LocalPort { get; private set; }
		public string Name { get; private set; }
		public RuleProfile Profile { get; private set; }
		public string Profiles { get; private set; }
		public string Protocol { get; private set; }
		public string RemoteIP { get; private set; }
		public string RemotePort { get; private set; }
	}
}

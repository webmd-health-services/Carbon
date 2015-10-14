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
using System.ComponentModel;
using System.Configuration.Install;
using System.Diagnostics;

namespace Carbon.Test.Installer
{
	[RunInstaller(true)]
	public partial class Installer1 : System.Configuration.Install.Installer
	{
		public Installer1()
		{
			InitializeComponent();
		}

		protected override void OnBeforeInstall(IDictionary savedState)
		{
			base.OnBeforeInstall(savedState);

			foreach (string paramName in this.Context.Parameters.Keys)
			{
				Trace.WriteLine(string.Format("{0} = {1}", paramName, this.Context.Parameters[paramName]));
			}

			var env = Environment.GetEnvironmentVariables();
			foreach (var envVarName in env.Keys)
			{
				Trace.WriteLine(string.Format("{0} = {1}", envVarName, env[envVarName]));
			}

			if (Environment.GetEnvironmentVariable("CARBON_TEST_INSTALLER_THROW_INSTALL_EXCEPTION") != null)
			{
				throw new InstallException("You can't install me!");
			}
		}

		protected override void OnBeforeUninstall(IDictionary savedState)
		{
			base.OnBeforeUninstall(savedState);

			if (Environment.GetEnvironmentVariable("CARBON_TEST_INSTALLER_THROW_UNINSTALL_EXCEPTION") != null)
			{
				throw new InstallException("You can't uninstall me!");
			}
		}
	}
}


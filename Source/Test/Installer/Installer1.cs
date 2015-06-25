using System;
using System.Collections;
using System.ComponentModel;
using System.Configuration.Install;
using System.Diagnostics;

namespace ThrowInstallException
{
	[RunInstaller(true)]
	public partial class Installer1 : Installer
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

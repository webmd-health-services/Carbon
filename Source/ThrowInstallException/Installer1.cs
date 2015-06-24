using System.Collections;
using System.ComponentModel;
using System.Configuration.Install;

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

			throw new InstallException("You can't install me!");
		}
	}
}

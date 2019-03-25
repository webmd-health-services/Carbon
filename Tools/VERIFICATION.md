
# VERIFICATION

This package contains several assemblies created and owned by the Carbon 
project itself:

* Carbon.dll
* Carbon.Iis.dll
* Carbon.Xdt.dll

These assemblies depend on and use these packages, which are downloaded from 
NuGet.

* [DotNetZip/Ionic.Zip](https://www.nuget.org/packages/DotNetZip/)
* [Microsoft.Web.Administration](https://www.nuget.org/packages/Microsoft.Web.Administration/)
* [Microsoft.Web.Xdt](https://www.nuget.org/packages/Microsoft.Web.Xdt/)
* [Microsoft.Win32.Registry](https://www.nuget.org/packages/Microsoft.Win32.Registry/)
* [System.DirectoryServices.AccountManagement](https://www.nuget.org/packages/System.DirectoryServices.AccountManagement/)
* [System.Runtime.InteropServices](https://www.nuget.org/packages/System.Runtime.InteropServices/)
* [System.ServiceProcess.ServiceController](https://www.nuget.org/packages/System.ServiceProcess.ServiceController/)

All other assemblies are included because they are dependencies required by one
or more of the references above or required to run under different versions of
.NET Core.

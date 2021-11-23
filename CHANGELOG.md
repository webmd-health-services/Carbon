# 2.12.0

* Fixed: Importing Carbon fails under PowerShell 4.
* The `Install-CMsi`, `Get-CMsi`, and `Get-CProgramInstallInfo` functions have moved to a new `Carbon.Windows.Installer`
module, now available on the PowerShell Gallery. Please switch to the new module and update usages. If you use these
functions from Carbon, a warning message will be written. These function will be removed in the next major version of
Carbon.


# 2.11.0

* Fixed: Resolve-CPathCase fails on PowerShell Core.
* New: 'Grant-Permission', 'Get-Permission', and 'Revoke-Permission' scripts now execute correctly on
non-Windows platforms.
* Fixed: Install-CService now will update services when file permissions or user account privileges have changed.


# 2.10.2

* Fixed: Carbon fails to import if IIS isn't installed.


# 2.10.1

* Fixed: Carbon fails to import on PowerShell 4.


# 2.10.0

## TL;DR Changes

* Fixed: Carbon's backward compatible aliases replaced with shim functions. Carbon no longer aggressively loads its
functions.
* New: Carbon now warns when you're using a function shim with a deprecated name. Update your code so that all Carbon
functions have a `C` prefix. Carbon has a `Use-CarbonPrefix.ps1` script in its bin directory that will update files to
use the new prefix.
* Migrated the following functions to new Carbon.Core and Carbon.Cryptography modules. These functions still exist in
Carbon 2, so if you use all these modules together, you'll probably run into naming collisions and errors depending on
how you install, import, and use Carbon. You'll get a warning if you use any of the functions that migrated.
    * `ConvertTo-CBase64`, `Get-CPowerShellPath`, and `Invoke-CPowerShell` are now in the Carbon.Core module.
    * The `Test-COSIs32Bit` and `Test-COSIs64Bit` functions merged into a `Test-COperatingSystem` function in the
    Carbon.Core module.
    * The `Test-CPowerShellIs32Bit` and `Test-CPowerShellIs64Bit` functions merged into a `Test-CPowerShell` function in
    the Carbon.Core module.
    * New: `Convert-CSecureStringToString`, `Get-CCertificate`, `Install-CCertificate`, `Uninstall-CCertificate`,
    `Protect-CString`, and `Unprotect-CString` migrated to the Carbon.Cryptography module.
* Fixed: the `Install-CCertificate` function causes an extra file to be written to the Windows directory where private
keys are saved. Depending on your environment, this could put many, many extra very small files on the file system or a
full disk.
* Fixed: the `Install-CCertificate` function could fail to install a certificate with a private key in a remote
computer's LocalMachine store if you passed in a certificate object to install.
* Fixed: the `Install-CCertificate` function always installs a certificate even if it exists in the destination store.
Depending on your environment, this could put many, many extra very small files on the file system or a full disk. Use
the `-Force` switch to always install a certificate even if it already exists in the destination store.
* Added a `-Force` switch to the `Install-CCertificate` function to force certificates to be installed if they already
exist in the destination store.
* Fixed: `Install-Service` always writes a verbose message when installing a service.

## Naming Collisions Solved (Again)

Fixed: In Carbon 2.7.0, we added a `C` prefix to all the Carbon functions, with aliases that used the old function
names to preserve backwards-compatability. We didn't realize at the time that aliases have the highest precedence of
commands, so Carbon's aliases hid any other commands on your system that may have been named the same. Bad idea. With
this release, Carbon no longer uses aliases for backwards-compatability. Instead, it dynamically creates shim functions
named after the old functions. These shim functions write a warning that the function with the old name is deprecated
then calls the function using its new name. Hopefully, this will finally fix the name collisions problems. The function
names with out the `C` prefix will be removed in Carbon 3, so update your code to make upgrading easier.
Because Carbon creates these backwards-compatible function shims dynamically, Carbon *won't* create a shim if a
function with the old name exists. If there is a name conflict between Carbon and another module, if you import that
module first, Carbon won't export its shim function.

## Carbon on PowerShell Core

We need parts of Carbon to work on PowerShell Core. The current size of Carbon makes that hard (over 200 functions and
automated tests that take a long time). So, we're breaking Carbon into smaller modules. The new modules will all require
PowerShell 5.1+. If you use Carbon 2 and the new modules together, you'll get naming conflicts during installation and
when importing.
The first two modules are already out: Carbon.Core and Carbon.Cryptography. 

## Carbon.Core
Carbon.Core will contain all the functions that are foundational to all or most other future Carbon modules, or generic
functions we feel are core to Carbon and/or PowerShell. It has no dependencies. The following functions were migrated to
it:
* `ConvertTo-CBase64` (with some added functionality)
* `Get-CPowerShellPath`
* `Invoke-CPowerShell`
* `Test-COperatingSystem`: Replaces `Test-OSIs32Bit` and `Test-OSIs64Bit`. Tests operating system type, too, so you
can use this function instead of the `$IsWindows`, `$IsLinux`, or `$IsMacOS` variables. Works on versions of PowerShell
that don't define those variables.
* `Test-CPowerShell`: Replaces `Test-PowerShellIs32Bit` and `Test-PowerShellIs64Bit`. Tests edition, too. Use this
function instead of `$PSVersionTable.PSEdition`. Handles when $PSVersionTable doesn't have the PSEdition property.

## Carbon.Cryptography
Carbon.Crytography contains functions that are used when encrypting and decrypting strings. This is where certificate
management funtions live. These function were migrated from Carbon:
* `Convert-CSecureStringToString`
* `Get-CCertificate`: works on Linux and macOS when opening certificate files.
* `Install-CCertificate`
* `Uninstall-CCertificate`
* `Protect-CString`: works on Linux and macOS.
* `Unprotect-CString`: works on Linux and macOS.


# 2.9.4

* Fixed: Convert-XmlFile fails in PowerShell Core (thanks to
(Joseph Block)[https://github.com/JosephBlock] for the fix).


# 2.9.3

* Fixed: Protect-CString and Unprotect-CString failed under PowerShell Core.
* Fixed: Invoke-CPowerShell failed under PowerShell Core.
* Fixed: Install-CCertificate fails under PowerShell Core.
* Fixed: Unprotect-CString adds extra null bytes to the end of a decrypted string when using AES (`-Key`) encryption.


# 2.9.2

* Fixed: when encryptiong/decrypting with a thumbprint, `Protect-String` and `Unprotect-String` take more time the more
certificates you have in your stores.


# 2.9.1

* Fixed: `Import-Carbon.ps1` fails if Carbon is already imported from a different location than the location from which
it will import Carbon.


# 2.9.0

* Carbon should now import in less than a second.
* Fixed: `Grant-CHttpUrlPermission` documentation uses command named `Grant-CHttpUrlAclPermission`. (Fixes
[issue 66](https://github.com/webmd-health-services/Carbon/issues/66).)
* Fixed: `Enable-CNtfsCompression` always enables compression even if compression is already enabled.
* Fixed: `Disable-CNtfsCompression` always disables compression even if compression is already disabled.
* Fixed: `Uninstall-CService` can write an error when a service's process exits at unexpected times.
* Fixed: `Get-CUser` can sometimes take 60 to 90 seconds to lookup a specific user.
* Fixed: `Get-CGroup` can sometimes take 60 to 90 seconds to lookup a specific group.
* Improved `Set-CEnvironmentVariable` and `Remove-CEnvironmentVariable` functions' reliability when setting and removing
variables for a specific user (they now use `Start-Job` instead of Carbon's `Invoke-CPowerShell`).
* Fixed: Carbon was hiding the ServerManager module's `Get-WindowsFeature`, `Install-WindowsFeature`, and
`Uninstall-WindowsFeature` cmdlets (fixes issue #55).
* Fixed: `Set-CHostsEntry` can sometimes clear the hosts file (fixes issue #39).
* Fixed: `Get-CServiceConfiguration` fails with a terminating exception if a service doesn't exist.


# 2.8.1

* Added verification information to Chocolatey package.
* Updated copyright.


# 2.8.0

* Carbon is now *importable* on PowerShell Core on all platforms. Most functions will not work on Linux/MacOS since they
are Windows-specific. Many functions will also not work on PowerShell Core. The next major version of Carbon, 3, should
fully support PowerShell Core on Windows.
* `Get-CScheduledTask` can now return `RegisteredTask` objects from the Scheduler.Service COM API. Use the new
`AsComObject` switch. Getting COM objects is an order of magnitude faster than the old way.
* Fixed: `Get-CScheduledTask` isn't able to parse some task information returned on Windows 10.
* Deprecated `Test-CWindowsFeature`.
* Fixed: `Get-CComPermission` fails when there are permission to a non-existent identity.
* Fixed: looking up local users/groups is extremely slow on some machines.


# 2.7.0

* Uninstall-Service now kills a service's process when that service stops but is actually still running. This should decrease the frequency of needing to reboot a computer when uninstalling a service.
* Added `C` prefix to all Carbon commands, with aliases from old command names to new ones to maintain backwards compatability. 
* Added `bin\Use-CarbonPrefix.ps1` script to Carbon that will update files to use the new Carbon function names.
* `Get-CCertificate`: Added `Path` note property to returned objects.
* Fixed: Chocolatey uninstaller fails if the `PSModulePath` environment variable contains trailing or sequential semicolons.


# 2.6.0

* `Enable-IisSecurityAuthentication` and `Disable-IisSecurityAuthentication` sometimes hang. We don't know why, but we're working around the problem. These functions no longer always apply a configuration change. Instead, they only enable/disable security authentication if its not already enabled/disabled. 
* `Install-Service` now outputs a verbose message showing the command line arguments used when calling `sc.exe` to install/update a service. 
* Added `ArgumentList` property/parameter to `Carbon_Service` DSC resource. Thanks to [Luigi Grilli](https://github.com/gigi81) for the contribution. 
* Fixed: `Get-HttpUrlAcl` returns no ACLs if any ACLs exist whose identities no longer exist.


# 2.5.1, 2.5.2, 2.5.3, and 2.5.4 (3 June 2018)

*Note*: 2.5.1 through 2.5.4 contain the same code and changes. We created new build and deployment automation that, due to bugs, required us to publish multiple versions.

## Bug Fixes

 * Fixed: Carbon takes 10 to 20 seconds to load. In trying to detect if the Win32_OptionalFeature class is available on the current operating system, it was actually loading all the Win32_OptionalFeature instances. Oops. Now, it just checks for the existence of the Win32_OptionalFeature class. Load times should now be about two to three seconds. ([Fixes issue #35.](https://github.com/pshdo/Carbon/issues/35))
 * Import-Carbon.ps1 now hides verbose messages typically shown by Import-Module and Remove-Module cmdlets.
 * Fixed: `Assert-FirewallConfigurable` fails on Windows 10 due to firewall service display name change.


# 2.5.0 (18 June 2017)

## Enhancements

 * Added `DelayedAutoStart` boolean property to objects returned by `Get-ServiceConfiguration`. This flag is `true` when a service is set to start automatically, delayed. `False` otherwise. Added extended 
 * The `Install-Service` function and the `Carbon_Service` DSC resource can now set a service's startup type to `Automatic (Delayed)`. Pass `Automatic` to the `StartupType` parameter and use the new `Delayed` switch. The `Delayed` switch is ignored unless `StartupType` is `Automatic`. Fixes [issue #216](https://bitbucket.org/splatteredbits/carbon/issues/216/community-add-automaticdelayed-in).
 * The `Uninstall-Certificate` function can now delete a certificate by just its thumbprint. The certificate will be uninstalled from *all* stores. You can pipe the thumbprint or a certificate object to `Uninstall-Certificate`.
 * Added an `EnsureRunning` switch to `Install-Service` function to ensure that any service is started after configuring. (By default, `Install-Service` leaves a service stopped if it was stopped when `Install-Service` begins.)
 * Added `IsSymbolicLink` extended type property to directory and file objects (i.e. `System.IO.DirectoryInfo` and `System.IO.FileInfo` objects).
 * Added `TargetPath` extended type property to file (i.e. `System.IO.FileInfo`) objects. If a file is a symbolic link, this property will return the file the link points to.
 * The `TargetPath` extended type property on directory (i.e. `System.IO.DirectoryInfo) objects now returns target paths when a directory is a symbolic link.
 * `Initiazlie-Lcm` can't be used on Windows Server 2016 and later to put the DSC local configuration manager into pull mode. `Initialize-Lcm` now writes an error when you try.
 
## Bug Fixes

 * `Install-Service` and the `Carbon_Service` DSC resource write errors when a service is running and its startup type is changed to `Disabled`.
 * The `Carbon_ScheduledTask` DSC resource writes incorrect information to verbose log when the current and desired credential for the scheduled task are different.
 * The `Carbon_ScheduledTask` DSC resource doesn't correctly detect when a task's identity has changed (it wasn't converting usernames to their canonical representation before comparing the existing identity with the desired identity).
 * Fixed: Importing Carbon in 32-bit PowerShell fails on a 64-bit operating system. DSC isn't available so the `Initialize-Lcm` function can't be exported. Thanks to [Anders Andersson](https://bitbucket.org/McAndersDK/) for contribuging the fix.
 * Fixed: `Install-Service` and `Carbon_Service` DSC resource fail to change the identity a service runs as if switching from a custom account to the default `NetworkService` account.
 * Fixed: `Get-PowerShellModuleInstallPath` returns nothing when run under 32-bit (x86) PowerShell on 64-bit Windows.Fixed: `Get-PowerShellModuleInstallPath` returns nothing when run under 32-bit (x86) PowerShell on 64-bit Windows.


# 2.4.1 (21 February 2017)

## Bug Fixes

 * Fixed: `Carbon_Permission` fails when revoking permissions and the `Permissions` property doesn''t have a value.
 * Fixed: `Protect-String` doesn't convert secure strings properly so they get encrypted with extra bytes in them.
 * Fixed: `Revoke-Permission' fails when an identity has multiple access control entries on an item. Thanks to [bozho_](https://bitbucket.org/bozho_/) for reporting [issue #221](https://bitbucket.org/splatteredbits/carbon/issues/221/community-revoke-permission-fails-if-the) and contributing the fix.
 * Fixed: `Compress-Item`' writes an error when using the `WhatIf` switch.
 * Fixed: `Install-IisWebsite` help examples contain invalid/broken code (thanks to John Mitchell for reporting).
 * Fixed: `Install-Service` fails when password contains double quote character, i.e. `"` (fixes [issue #219](https://bitbucket.org/splatteredbits/carbon/issues/219/community-install-service-fails-to)).
 * Fixed: `Read-File` and `Write-File` fail to retry writing to a locked file when `$Global:Error` is full. Fixes [issue #217](https://bitbucket.org/splatteredbits/carbon/issues/217/community-error-handling-in-read-file-and). 
 * Fixed: `Get-FirewallRule` sets the `EdgeTraversalPolicy` to `DeferUser` on rules whose policy is "defer to application". 
 * Fixed: `Get-FirewallRule` fails on non-english-speaking computers. (It was parsing the output of `netsh advfirewall`. Now it uses the Windows Firewall with Advanced Security API.) [Fixes [issue #208](https://bitbucket.org/splatteredbits/carbon/issues/208/community-get-firewallrule-could-not-find).
 * Fixed: `Get-FirewallRule` incorrectly parsed interface types. It assumed interface type was one of multiple values. In reality, it can be set to one or more different values. The underlying enumeration and its values have been updated to be a set of flags (i.e. a bit field).
 * Fixed: `Carbon_FirewallRule` fails when Profile property has more than one value.
 * Fixed: `Get-ScheduledTask` doesn't handle when a scheduled task doesn't exist on Windows 2008.


# 2.4.0 (9 November 2016)

## Enhancements

 * `Protect-String` can now encrypt a `SecureString`. The `String` parameter's type was changed to `[object]`. When you pass in a `SecureString`, it is converted to an array of bytes, encrypted, and the array of bytes are cleared from memory.
 * Renamed `Protect-Acl` to `Disable-AclInheritance` to make it clearer what the function does. Created a `Protect-Acl` alias in place to preserve backwards-compatability.
 * `Disable-AclInheritance` only disables inheritance if it is currently enabled.
 * Created `Enable-AclInheritance` to re-enable access rule inheritance on file system and registry ACLs. This function is paired with `Disable-AclInheritance`.

## Bug Fixes

 * Fixed: `Get-ProgramInstallInfo` fails when a program's `Version` registry key value can't be converted into a `Version` object.
 * Fixed: `Test-Service` failed to detect if a device driver service is installed.
 * Fixed: `Install-Service` fails if a service depends on a device driver. (Note: in our testing, we can't get a device driver set as a dependency. If you know what the secret sauce is to get this to work with sc.exe (or another means), please let us know.)
 * Fixed: `Disable-AclInheritance` (ne `Protect-Acl`) fails when piped a registry key.
 * Fixed: `Get-PathProvider` fails when passed a fully-qualified registry key PowerShell path, e.g. `Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER\Software`.
 

# 2.3.0 (29 September 2016)

## Enhancements

 * `Protect-String` can now encrypt with a key, password, or passphrase (i.e. it can now encrypt with symmetric encryption).
 * `Unprotect-String` can now decrypt with a key, password, or passphrase (i.e. it can now decrypt using symmetric encryption).
 * `Set-HostsEntry` now supports IPv6 addresses ([fixes issue](https://bitbucket.org/splatteredbits/carbon/issues/181/community-set-hostsentry-add-support-for)).
 * `Grant-Permission` now supports creating `Deny` access rules. Use the new `Type` parameter. [Fixes issue #152.](https://bitbucket.org/splatteredbits/carbon/issues/152)
 * `Set-EnvironmentVariable`: 
   * Added `-Force` switch to make all variable modifications immediately visible in the current PowerShell process's `env:` drive. Restarts are no longer required.
   * You can now set an environment variable for other users. Use the `Credential` parameter to specify the user's credentials. [Fixes issue #151.](https://bitbucket.org/splatteredbits/carbon/issues/151)
 * `Remove-EnvironmentVariable`: 
   * Added `-Force` switch to make all variable removals immediately visible in the current PowerShell process's `env:` drive. Restarts are no longer required.
   * You can now remove variables from multiple targets/scopes at once.
   * You can now remove an environment variable for other users. Use the `Credential` parameter to specify the user's credentials.
 * `Invoke-PowerShell`:
   * It now runs PowerShell commands. Pass a string of PowerShell code with the `Command` parameter. 
   * It now runs encoded PowerShell commands. Pass the string of PowerShell code with the `Command` parameter and use the `-Encode` switch.
   * It now runs scripts and commands as another user. Use the `Credential` parameter to pass the user's credentials along with the `FilePath` and `Command` parameters to run scripts and commands, respectively.
   
## Bug Fixes

 * Fixed: `Set-RegistryKeyValue` fails when `-String` parameter's value is `$null` or empty ([fixes issue #211](https://bitbucket.org/splatteredbits/carbon/issues/211/set-registrykeyvalue-null-string-invalid)).
 * Fixed: Can't import Carbon in a 32-bit PowerShell 4 session on a 64-bit operating system ([fixes issue #199](https://bitbucket.org/splatteredbits/carbon/issues/199/community-issue-importing-carbon-on-x64)).
 * Fixed: Documentation for the `Install-ScheduledTask` function's `HighestAvailableRunLevel` is lying ([fixes issue #205](https://bitbucket.org/splatteredbits/carbon/issues/205/documentation-install-scheduledtask-typo)).
 * Fixed: `Carbon_FirewallRule` fails when `Profile` property set to multiple values ([fixes issue #209](https://bitbucket.org/splatteredbits/carbon/issues/209/dsc-carbon_firewallrule-does-not-accept)).
 * Fixed: `Install-IisAppPool` can't set .NET framework version to `No Managed Code` ([fixes issue #210](https://bitbucket.org/splatteredbits/carbon/issues/210/install-iisapppool-need-to-be-able-to-set)).
 * Fixed: `Get-SslCertificateBinding` fails if the operating system's culture is not `en-US` ([fixes issue #171](https://bitbucket.org/splatteredbits/carbon/issues/171/get-sslcertificatebinding-fails-when-os)).
 * Fixed: `Install-ScheduledTask` fails when creating a task that runs during a specific week of the month on Sundays. (You're going to love this: the underlying int value for `[DayOfWeek]::Sunday` is `0`, so when testing if a `DayOfWeek` typed variable set to `Sunday` has a value, it returns `$false`. This made `Install-ScheduledTask` add the `/D` parameter without a value.


# 2.2.0 (11 May 2016)

## Enhancements

 * Aded a `LiteralPath` parameter to `Test-PathIsJunction` for testing paths that contain wildcard characters (e.g. `[`, `]`, etc.).
 * `Remove-Junction` now supports removing multiple junctions with wildcards.
 * Added a `LiteralPath` parameter to `Remove-Junction` for deleting junctions whose paths contain wildcard characters (e.g. `[`, `]`, etc.).
 * Added a `LiteralPath` parameter to `Uninstall-Junction` for deleting junctions whose paths contain wildcard characters (e.g. `[`, `]`, etc.).
 * Created `Remove-DotNetAppSetting` function for removing app settings from .NET framework machine.config files.
 * Created `Read-File` function for reading text files and retrying if the read fails. Good for reading files that get intermittently locked, like the Windows hosts file.
 * Created `Write-File` function for writing text files and retrying if the write fails. Good for writing files that get intermittently locked, like the Windows hosts file.
 * Made the following functions obsolete:
   * `Get-WindowsFeature`
   * `Install-Msmq`
   * `Install-WindowsFeature`
   * `Resolve-WindowsFeatureName`
   * `Uninstall-WindowsFeature`

## Bug Fixes

 * Fixed: `Add-GroupMember`, over PowerShell remoting, fails to add a member to groups that have non-local users/groups (fixes [issue #187: Add-GroupMember fails when using PowerShell Remoting](https://bitbucket.org/splatteredbits/carbon/issues/187/add-groupmember-fails-when-using))
 * Fixed: `Remove-GroupMember`, over PowerShell remoting, fails to remove a member from groups that have non-local users/groups.
 * Fixed: `Test-PathIsJunction` returns multiple results if the `Path` parameter contains wildcards and matches multiple items.
 * Fixed: `Install-Junction` can't install a junction whose path contains wildcard characters (fixes [issue #190](https://bitbucket.org/splatteredbits/carbon/issues/190/install-junction-fails-when-the-path)).
 * Fixed: `New-Junction` writes wrong error when creating an existing junction whose path contains wildcard characters.
 * Fixed: `Install-Service` doesn't update/change an existing service's account when using the `Credential` parameter (fixes [issue #185](https://bitbucket.org/splatteredbits/carbon/issues/185/install-service-never-updates-logon-as-if)).
 * Fixed: `Uninstall-FileShare` fails if a share's physical path doesn't exist.
 * Fixed (hopefully): `Get-FileSharePermission` writes an error if a share's security information is corrupted (fixes [issue #188](https://bitbucket.org/splatteredbits/carbon/issues/188/get-filesharepermission-crashes-when-a)). I was unable to reproduce the error, and the error was reported anonyously, so I did my best.
 * Fixed: `Get-PowerShellModuleInstallPath` returns multiple paths if the standard PowerShell module path is listed twice in the `PSModulePath` environment variable.
 * Fixed: Chocolatey package fails if the standard PowerShell module path is listed twice in the`PSModulePath` environment (fixes [issue #192](https://bitbucket.org/splatteredbits/carbon/issues/192/installation-of-carbon-via-chocolatey)).
 * Fixed: `Get-PowerShellModuleInstallPath` doesn't return the module install path if it doesn't exist. Sometimes it doesn't yet.
 * Fixed: `Carbon_ScheduledTask` and `Carbon_IniFile` DSC resources' `Get-TargetResource` functions don't return correct resource properties and causes `Get-DscConfiguration` to fail (fixes [issue #193](https://bitbucket.org/splatteredbits/carbon/issues/193/get-targetresource-returns-taskname-in-its)).
 * Fixed: `Carbon_FirewallRule` DSC resource always re-installs a firewall rule if `Profile` property contains multiple values (i.e. it doesn't properly parse netsh output).
 * Fixed: `about_Carbon_Installation` help topic had a typo.
 * Fixed: `Set-HostsEntry` fails to stop when the hosts file is in use and can't be read.
 

# 2.1.1 (25 February 2016)

## Bug Fixes

 * Fixed: unable to publish module to PowerShell Gallery because `RequiredAssemblies` module manifest data used an absolute path generated with `Join-Path` and `$PSScriptRoot`, which aren't allowed in module manifests.
 * Fixed: missing PowerShell Gallery tags, license URI, project URI, and release notes metadata.
 * Fixed: copyright date in module manifest is 2015.
 * Fixed: PowerShell gallery missing function list.
 * Fixed: Restricted user accounts can't import Carbon ([issue #180](https://bitbucket.org/splatteredbits/carbon/issues/180)).
 * Fixed: `Carbon_Privilege` DSC resource fails to remove all a user's privileges ([issue #178](https://bitbucket.org/splatteredbits/carbon/issues/178)).
 * Fixed: `Remove-IniEntry` fails to remove last INI entry in a file ([issue #179](https://bitbucket.org/splatteredbits/carbon/issues/179)).
 
 
# 2.1.0 (8 February 2016)

## New Functions

 * `Get-HttpUrlAcl`: uses Windows API to return HTTP URL ACLs; replaces the `netsh http show urlacl` command.
 * `Grant-HttpUrlPermission`: uses Windows API to grant listen/delegate permissions on HTTP URLs; replaces the `netsh http add urlacl` command.
 * `Revoke-HttpUrlPermission`: uses Windows API to revoke all a user or group's permissions on HTTP URLs; replaces the `netsh http delete urlacl` command.
 * `Install-Directory`: creates a directory (and any missing parents), if it doesn't exist already. Finally!
 * `Uninstall-Directory`: removes a directory, if it exists. Finally!
 * `Uninstall-Group`: uses the `DirectoryServices.AccountManagement` .NET API to remove a group, if it exists.
 * `Test-GroupMember`: uses the `DirectoryServices.AccountManagemetn` .NET API to test if a principal is a member of a group.

## New DSC Resource

 * `Carbon_Group`: resource for configuring local groups.
 
## Bug Fixes
 
 * Fixed: `Install-FileShare` always re-configures existing shares; it doesn't properly detect permissions that need to be removed.
 * Fixed: `Set-IniEntry` fails to preserve unicode characters with diacritics in INI entry names and values.
 * Fixed: `Remove-IniEntry` fails to preserve unicode characters with diacritics in INI entry names and values.
 * Fixed: `Set-HostsEntry` leaves trailing tabs and whitespace after all but the last line.
 * Fixed: `Get-PowerShellModuleInstallPath` returns wrong path for PowerShell 4.
 * Fixed: `Protect-String` fails when Carbon is installed in a module path that contains spaces ([fixes issue #174](https://bitbucket.org/splatteredbits/carbon/issues/174/protect-string-throws-when-module-path)).
 * Fixed: `New-RsaKeyPair` generates a key pair that isn't supported for encrypting/decrypting DSC credentials or supported by the CMS message cmdlets.
 * Fixed: `Get-ScheduledTask` returns invalid task commands when those commands contain quotes (works around an issue where `schtasks.exe` CSV output can't be parsed correctly by `ConvertFrom-Csv`).
 * Fixed: `Add-GroupMember` and `Remove-GroupMember` fail when adding `Everyone` or `NT Service\*` accounts to a group ([fixes issue #177](https://bitbucket.org/splatteredbits/carbon/issues/177/add-groupmembers-201-doesnt-like-vsa-names)).
 * Fixed: `Get-SheduledTask` writes an error if a scheduled task's XML definition is for an executable and doesn't contain an arguments element.
 
## Other Improvements

 * Obsolete function parameters will no longer show in Intellisense (added the `DontShow` parameter property).
 * `Test-AdminPrivilege`: changed its verbose message to a debug message.
 * `Set-HostsEntry`: 
    * only updates hosts file if it needs to change
    * added an improved verbose message when setting a hosts entry
    * improved error handling when hosts file can't be opened for reading
 * `Install-Certificate` can now install a certificate on a remote computer.
 * `Initialize-Lcm` now uses `Install-Certificate` to install the decryption certificate on the remote computer.
 * `Uninstall-Certificate` can now uninstall a certificate on a remote computer.
 * The following functions now write warning if you pass them a plain-text password. You should pass a `SecureString` instead.
    * `Install-Certificate`
    * `Initialize-Lcm`
 * `New-RsaKeyPair`:
    * Refactored to use `certreq.exe` instead of `makecert.exe` and `pvk2pfx.exe`.
    * Can now run non-interactively: added a `-Password` parameter used to protect the private key (it used to prompt you).
    * Fixed: generates a key pair that isn't supported for encrypting/decrypting DSC credentials or supported by the CMS message cmdlets.
    * Made the `-ValidFrom` and `-Authority` parameters obsolete.
 * Added some verbose messages to `Install-Group` and `Add-MemberToGroup` when they create/modify their objects.
 * `Install-Group` only saves changes to a group if changes were made.


# 2.0.1 (19 October 2015)

 * Fixed: errors importing Carbon when IIS not installed on Windows 2012 R2 and Windows 10 (fixes [issue 168: Cannot import Carbon 2.0 module due to issues with IIS related functionality](https://bitbucket.org/splatteredbits/carbon/issues/168)).
 * Fixed Carbon copyright statements.
 * Improved Carbon's module description.


# 2.0.0 (10 October 2015)

## Overview

Carbon version 2.0 is a *huge* release, with lots of new enhancements and bug fixes. We hope you like them. Carbon 2.0 now requires PowerShell 4, so it is not backwards-compatabile with Carbon 1.x. Because of this, we made some additional backwards-incompatible changes. See the `Upgrade Instructions` section for things to look out for.

If you're upgrading from a previous 2.0 alpha release, you'll want to review the changes since your alpha version (found after the *Upgrade Instructions* section). We improved backwards-compatability with Carbon 1.x since the last alpha release, but that broke compatability with the alphas. 

## Upgrade Instructions

Make sure you're running PowerShell 4. 

`Install-Certificate`'s parameters have changed:

 * Remove the `Exportable` switch from any usages of `Install-Certificate` when installing from an `X509Certificate2` *object*, since that switch only gets used when installing a certificate from a file.

Some functions now return different objects and/or the objects returned have changed:

* Use the `Sid` property on objects returned by `Test-Identity` when using the `PassThru` switch: it now returns a `Carbon.Identity` object if the identity exists *and* you use the `-PassThru` switch, e.g. `Test-Identity -Name $userName -PassThru | Select-Object -Expand 'Sid'`.
 * Update usages of `Carbon.Computer.ProgramInstallInfo`'s `Version` property (returned by `Get-ProgramInstallInfo`). It was an `int` and is now a [Version](http://msdn.microsoft.com/en-us/library/y0hf9t2e.aspx) object.

The Carbon assembly was re-organized. If you were reaching into `Carbon.dll` (***NOT RECOMMENDED***), you'll want to:

 * Rename usages of `[Carbon.AdvApi32]` class to `[Carbon.Service.ServiceSecurity]`.
 * Rename usages of `[Carbon.Lsa]` class to `[Carbon.Security.Privilege]`.
 * Rename usages of `[Carbon.Win32]` class to `[Carbon.FileSystem.Path]`.
 * Rename usages of `[Carbon.HandleInfo]` class to `[Carbon.Win32.HandleInfo]`.
 * Remove usages of `[Carbon.Lsa]::LookupPrivilegeValue` class method. It was incorrectly exposed as a public method.
 * Remove usages of `[Carbon.Kernel32]::LocalFree` class method. It was incorrectly exposed as a public method.

The following commands no longer return the stdout output from the console applications each one calls. To see the old output, use the `-Verbose` switch. Remove any usage of the output you were processing.

 * All IIS functions.
 * `Disable-FirewallStatefulFtp`
 * `Enable-FirewallStatefulFtp`
 * `Install-Service`
 * `Install-SmbShare`
 * `Remove-SslCertificateBinding`
 * `Set-SslCertificateBinding`
 * `Uninstall-Service`

The following functions' internal behavior has changed. This may or may not impact you.

 * `Grant-Permission` now only grants permissions on an object if those permissions aren't present.  To preserve previous behavior, add the `-Force` switch to all `Grant-Permission` usages.
 * `Grant-Permission` now writes an error if you don't have access to a private key. Previously, it would skip the key without any messages.
 * `Install-Msi` (fka `Invoke-WindowsInstaller`) now only installs the MSI if it isn't already installed. To preserve the previous behavior and always install, add the `-Force` switch to all `Invoke-WindowsInstaller`\`Install-Msi` usages.
 * All IIS functions were re-written to use the `Microsoft.Web.Administration` API instead of `appcmd.exe`.
 * `Install-IisWebsite` no longer deletes and re-creates websites. If a website exists, it updates its configuration to match parameters passed in. To preserve previous behavior and delete the website before installing, use the `-Force` switch.
 * `Install-IisVirtualDirectory` no longer deletes and re-creates virtual directories. If a virtual directory exists, its configuration is updated in place. To preserve previous behavior and delete the virtual directory before installing, use the `Force` switch.
 * `Install-FileShare` (fka `Install-SmbShare`) no longer deletes and re-creates the share, instead it modifies existing shares in place. To preserve previous behavior and delete existing shares before re-creating, use the `Force` switch.
 * `Set-RegistryKeyValue` only sets the value if the value doesn't exist or the current value is different than the desired value.

We've added parameter validation to some functions. This shouldn't impact anybody, since if you were passing data that breaks this new validation, the function wouldn't have worked even in previous versions of Carbon.

 * Ensure that all thumbprints passed to `Set-SslCertificateBinding` are valid (40 character hex strings), since it now validates thumbprints.
 * Check that all IP addresses passed to `Set-HostsEntry` are valid IP v4 or v6 addresses.  `Set-HostsEntry`'s IPAddress parameter is now a `System.Net.IPAddress` object.  Previously it was a string validated with a regular expression, so you *should* be OK.

All Carbon functions now respect each caller's common parameters (e.g. `-Verbose`, `-ErrorAction`, etc.). This means if you pass a common parameter to a script that calls a Carbon function, that Carbon function will use that common parameter. This may or may not impact you.

## Bug Fixes

 * Carbon's `System.ServiceProcess.ServiceController` extended type data causes errors when PowerShell formats `System.ServiceProcess.ServiceController` objects that represent services on remote computers.
 * `Compress-Item` doesn't remove handled errors from global error array.
 * `Grant-Permission` fails with an unhelpful error message if it is unable to get the ACL on a private key.
 * `Install-Msi` didn't properly detect when installation failed.
 * `Install-ScheduledTask` fails under PowerShell 5 to create a scheduled task to run on Sunday.
 * `Install-Service`:
   * No longer writes a warning about being unable to stop an already stopped service (fixes [issue #158](https://bitbucket.org/splatteredbits/carbon/issues/158/install-service-extraneous-warning-about)).
   * Starting the service now respects caller's error action preference. Before, `Start-Service` would write an error even if somone called `Install-Service` with an `Ignore` or `SilentlyContinue` error action preference.
   * Service arguments that are quoted still get quoted. Now, quotes are trimmed before arguments are quoted.
 * `Set-EnvironmentVariable` fails to set process-level environment variable. 
 * `Set-HostsEntry` fails to preserve whitespace if existing lines end with a comment/description. Thanks to [Konstantin Ushenin](https://vk.com/kostanew) for the fix.


## Enhancements

### General

 * Carbon now requires PowerShell 4.
 * `Import-Carbon.ps1` is more intelligent about when it tries to re-load Carbon. It will force a re-import of Carbon if any of Carbon's files have changed or the version has changed.
 * Added new `FileIndex`, `LinkCount`, and `VolumeSerialNumber` extended type data on `System.IO.FileInfo` objects for getting a file's index, its hard link count, and volume serial number, respectively.
 * The product version of the Carbon assembly now includes pre-release version information, as defined by the [Semantic Versioning specification](http://semver.org). To get this version, run `Get-Item Carbon.dll | Select-Object -ExpandProperty 'VersionInfo' | Select-Object -ExpandProperty 'ProductVersion'`.
 * The Carbon NuGet package now supports installing and uninstalling under Chocolatey.
 * All IIS functions were re-written to use the `Microsoft.Web.Administration` API instead of `appcmd.exe`. As a side effect, they no longer return `appcmd.exe` console output.
 * The following functions no longer use `Write-Host`. Instead, they use `Write-Verbose`:
   * `Disable-NtfsCompression`
   * `Enable-NtfsCompression`
   * `Grant-ComPermission`
   * `Grant-Permission`
   * `Install-Service` 
   * `Remove-SslCertificateBinding` 
   * `Revoke-ComPermission` 
 * Created default, table-based display formats for `System.DirectoryServices.AccountManagement.UserPrincipal`, `System.DirectoryServices.AccountManagement.GroupPrincipal`, `Microsoft.Web.Administration.ApplicationPool`, `Microsoft.Web.Administration.Site`, and `Microsoft.Web.Administration.Application` objects.
 * Re-organized Carbon's internal directory structure. You shouldn't be reaching into Carbon's internals, so this shouldn't matter, but wanted to let everyone know just in case.
 
### New Functions

 * `Clear-DscLocalResourceCache` clears the local LCM's DSC resource. This makes developing resources easier.
 * `Clear-MofAuthoringMetadata` removes authoring metadata from .mof files.
 * `Copy-DscResource` copies DSC resources (ZIP files, MSI archives, MOF files, etc.), including timestamps, checksums, and copying only changed files.
 * `ConvertTo-SecurityIdentifer` converts a binary, string, or `System.Security.Principal.SecurityIdentifier` object into a `System.Security.Principal.SecurityIdentifier` object.
 * `Get-DscError` gets any DSC errors that were written to a computer's DSC event log.
 * `Get-DscWinEvent` gets DSC events that were written to a computer's DSC event log.
 * `Get-FileSharePermission` gets the sharing permissions on a file/SMB share (*not* the NTFS file system permissions).
 * `Get-FileShare` uses WMI to get `Win32_Share` objects for the file shares installed on the local computer.
 * `Get-Group` gets a local group or all local groups.
 * `Get-Msi` reads installer information and properties from an MSI file.
 * `Get-PowerShellModuleInstallPath` gets the path where new module's should be installed. Beginning with PowerShell 4, modules should get installed into `$env:ProgramFiles\Windows PowerShell\Modules`. Under PowerShell 3, it is `$PSHome\Modules`. This function returns the correct location for the version of PowerShell you're using.
 * `Get-User` gets a local user or all local users.
 * `Initialize-Lcm` configures the DSC Local Configuration Manager on computers, including installing the private key needed for decrypting credentials.
 * `Remove-GroupMember` removes a user/group from a local group. Thanks to [Philip Kluss](https://bitbucket.org/philkloose) for the contribution. 
 * `Resolve-Identity` converts a system, local, or domain principal name or a SID (as a `SecurityIdentifer`, string SDDL, or byte array) into its canonical representation and includes extended identity information: domain, type, and SID.
 * `Start-DscPullConfiguration` starts a configuration check on a computer that is configured to use the PULL refresh mode.
 * `Test-DscTargetResource` compares target resource with desired resource. Helpful when writing `Test-TargetResource` functions.
 * `Test-Group` checks if a *local* group exists.
 * `Test-FileShare` uses WMI to check if a file/SMB share exists on the local computer.
 * `Test-TypeDataMember` tests if a type has an extended type member defined.
 * `Uninstall-FileShare` uninstalls/removes a file share, if it exists.
 * `Write-DscError` writes DSC `ErrorLogRecord` objects as errors.

### New DSC Resources

 * `Carbon_EnvironmentVariable` creates/removes machine-level environment variables.
 * `Carbon_FirewallRule` configures firewall rules.
 * `Carbon_IniFile` manages the contents of INI files.
 * `Carbon_Permission` configures file, directory, registry, and certificate permissions.
 * `Carbon_Privilege` configures an identity's privileges.
 * `Carbon_ScheduledTask` configures scheduled tasks with `schtasks.exe`.
 * `Carbon_Service` configures Windows services.
 
### Added `PassThru` Switches

Added a `PassThru` switch to the following functions, which will return objects of the given type:

 * `Grant-ComPermission`: `Carbon.Security.ComAccessRule`, representing the granted permission.
 * `Grant-Permission`: `System.Security.AccessControl.AccessRule`, representing the granted permission.
 * `Install-Group`: `System.DirectoryServices.AccountManagement.GroupPrincipal`, representing the group. 
 * `Install-IisApplication`: `Microsoft.Web.Administration.Application`, representing the application.
 * `Install-IisWebsite`: `Microsoft.Web.Administration.Site`, representing the website.
 * `Install-Junction`: `System.IO.DirectoryInfo`, representing new target directories and any new/updated junctions.
 * `Install-Service`: `System.ServiceProcess.ServiceController`, representing the service.
 * `Install-User`: `System.DirectoryServices.AccountManagement.UserPrincipal`, representing the user.
 * `Set-SslCertificateBinding`: `Carbon.Certificates.SslCertificateBinding`, representing the configured binding.
 
### No More Console Output

The following functions no longer return the console output of the program each one runs. Instead, the output is written to the verbose stream (i.e. use the `-Verbose` switch to see it).

 * `Disable-FirewallStatefulFtp`
 * `Enable-FirewallStatefulFtp`
 * `Install-Service`
 * `Remove-SslCertificateBinding`
 * `Set-SslCertificateBinding`
 * `Uninstall-Service`
 
### Obsolete Functions and Parameters

The following functions are now obsolete. Please don't use them and stop using them if you are. They will be removed from a future major version of Carbon. You'll get warnings if you use them.

 * `Complete-Job`: It's total crap. Use PowerShell's `Wait-Job` cmdlet instead.
 * `Invoke-AppCmd`: Switch to Carbon's IIS functions, or use `Get-IisConfigurationSection` to get `ConfigurationElement` objects from the `Microsoft.Web.Administration` API that you can modify.
 * `Resolve-NetPath`: Switch to something else. Carbon doesn't use `net.exe` anymore.
 
The following functions now have obsolete parameters, which will be removed from a future major version of Carbon. You'll get warnings if you use them.

 * `Install-IisAppPool's` `UserName` and `Password` parameters. Use the new `Credential` parameter instead.
 * `Install-Msi's` `Quiet` switch. `Install-Msi` always installs in quiet mode. Please remove usages.
 * `Install-Service's` `Password` parameter. Use the new `Credential` parameter instead.
 * `Install-User's` `UserName` and `Password` parameters. Use the new `Credential` parameter instead.
 * `Set-RegistryKeyValue`'s `Quiet` parameter. Please remove usages.
 
### Renamed Functions

The following functions were renamed, but with backwards-compatible aliases in place, so you shouldn't have to change any code.

 * `Invoke-WindowsInstaller` -> `Install-Msi`
 * `Install-SmbShare` -> `Install-FileShare`
 
### Switch to System.DirectoryServices.AccountManagement API for User/Group Management

The following functions were re-written to use the `System.DirectoryServices.AccountManagement` API, introduced in .NET 3.5.

 * `Add-MemberToGroup`
 * `Install-Group`
 * `Install-User` 
 * `Test-User`
 * `Uninstall-User`
 
### Miscellaneous Changes

 * `Get-IisAppPool`
    * Now return all application pools installed on the local computer when called with no parameters.
    * Added a default table format for `Microsoft.Web.Administration.ApplicationPool` objects.
 * `Get-ProgramInstallInfo`
    * Return object's `Version` property changed from an `int` to a [Version](http://msdn.microsoft.com/en-us/library/y0hf9t2e.aspx) object.
    * Return object's now have `ProductCode` and `User` properties. If a program doesn't have a product code, it is set to `[Guid]::Empty`. The `User` property is only set for per-user software installs.
 * `Get-ServiceConfiguration` now supports services from remote computers.
 * `Grant-Permission` now only grants permissions on an object if those permissions aren't present.  To preserve previous behavior, add the `-Force` switch to all `Grant-Permission` usages.
 * `Install-Certificate's` `Exportable` switch is now only allowed when installing a certificate from a file. Previously, you could supply the switch when installing from an X509Certificate2 object but it was ignored.
 * `Install-Group's` `Members` parameter renamed to `Member` (with backwards-compatible alias).
 * Added `Credential` parameter to `Install-IisAppPool` for increased security and to follow PowerShell guidelines.
 * `Install-IisVirtualDirectory` no longer deletes and re-creates existing virtual directories, but modifies existing virtual directories in place.
 * `Install-IisWebsite`
    * Added `SiteID` parameter tfor setting a website's IIS ID.
    * No longer deletes and re-creates websites, but modifies existing websites in place. This may or may not be a breaking change in your environment.
 * `Install-Msi`
    * `Path` parameter now supports wildcards.
    * Now only installs an MSI if it isn't already installed. To preserve the previous behavior and always install, add the `-Force` switch to all `Invoke-WindowsInstaller`\`Install-Msi` usages.
 * `Install-Service`
    * Now supports service startup parameters/arguments via the `ArgumentList` parameter.
    * Improved error handling and messages. It now uses `net helpmsg` to get helpful error messages based on sc.exe exit codes.
    * Added `Credential` parameter for increased security and to follow PowerShell guidelines.
    * Added `Description` parameter for setting a service's description.
    * Added `DisplayName` parameter for setting a service's display name.
 * `Install-FileShare` (fka `Install-SmbShare`):
    * Re-written to use WMI isntead of `net.exe`, so it no longer returns any console output.
    * Modifies existing shares in place, instead of deleting and re-creating, *unless* the share's path changes. Changing a share's path requires the old share to be deleted and a new one created.
 * `Install-User`
    * Added `PasswordExpires` switch for creating accounts with passwords that expire.
    * Added `UserCannotChangePassword` to prevent user from changing his password.
 * `Remove-SslCertificateBinding` has better error handling.
 * Added `SID` parameter to `Resolve-IdentityName` to resolve a SID into its identity name.
 * `Set-HostsEntry's` `IPAddress` parameter is now a `System.Net.IPAddress` object. It used to be a string validated with a regular expression.
 * `Set-RegistryKeyValue`: 
    * Added `UDWord` and `UQWord` parameters for setting registry key values to unsigned integers (i.e. integer values greater than `[int]::MaxValue` and `[long]::MaxValue`). Fixes [issue #165: Set-RegistryKeyValue rejects unsigned integers larger than [int]::MaxValue](https://bitbucket.org/splatteredbits/carbon/issues/165/set-registrykeyvalue).
    * Deprecated `Quiet` switch.
    *  Only sets the value if the value doesn't exist or the current value is different than the desired value. Use the `Force` parameter to preserve previous behavior.
 * `Test-Identity` now returns a `Carbon.Identity` object if the identity exists *and* you use the `-PassThru` switch. It used to return the identity's SID. Update scripts to use the `FullName` property to get the old return value, e.g. `Test-Identity -Name $userName -PassThru | Select-Object -Expand 'FullName'`.
 * `Test-OSIs32Bit` now uses the Environment class's new [Is64BitOperatingSystem](http://msdn.microsoft.com/en-us/library/system.environment.is64bitoperatingsystem.aspx) property.
 * `Test-OSIs64Bit` now uses the Environment class's new [Is64BitOperatingSystem](http://msdn.microsoft.com/en-us/library/system.environment.is64bitoperatingsystem.aspx) property.
 * `Test-PowerShellIs32Bit` now uses the `Environment` class's new [Is64BitProcess](http://msdn.microsoft.com/en-us/library/system.environment.is64bitprocess.aspx) property.
 * `Test-PowerShellIs64Bit` now uses the `Environment` class's new [Is64BitProcess](http://msdn.microsoft.com/en-us/library/system.environment.is64bitprocess.aspx) property.
 * `Uninstall-ScheduledTask` now retries when un-installing a task fails with "The function attempted to use a name that is reserved for use by another transaction." error.
 * `Unprotect-String`
    * Added `AsSecureString` switch, which will return a secure string instead of a normal string.
    * The `Password` parameter now accepts `SecureString` values.
 * `Initialize-Lcm`
    * Added support for PowerShell 5: `RefreshIntervalMinutes` default value changed to from 15 to 30; `RefreshIntervalMinutes` minimum value is now 30; `ConfigurationFrequency`'s minimum value is now 1 (from 2).
 
## Changes Since `alpha.26`

### Enhancements

 * Includes all changes made in version 1.9.0.
 * PowerShell 4 is now required. Carbon won't even import under PowerShell 3.
 * Removed `Carbon_Script` resource. It only existed so I could pass values to my script blocks. Turns out, the built-in `Script` resource supports this with the `$using:` scope. Remember, your most important features is documentation!
 * Created a new `Carbon_ScheduledTask` DSC resource for managing scheduled tasks.
 * The `Version` property on the objects returned by `Get-ProgramInstallInfo` is now a proper .NET `Version` object instead of an integer.
 
### Bug Fixes

 * `Carbon_Permission` DSC resource fails when assigning multiple permissions
 * Grant-Permission fails when clearing multiple existing, non-inherited permission on an item.
 
## Changes Since `alpha.31`

### Bug Fixes

 * `Set-HostsEntry` fails to preserve whitespace if existing lines end with a comment/description. Thanks to [Konstantin Ushenin](https://vk.com/kostanew) for the fix.
 * Carbon's `System.ServiceProcess.ServiceController` extended type data causes errors when PowerShell formats `System.ServiceProcess.ServiceController` objects that represent services on remote computers.
 * `Install-Msi` didn't properly detect when installation failed.
 * `Set-EnvironmentVariable` fails to set process-level environment variable.
 * `Compress-Item` doesn't remove handled errors from global error array.
 * `Grant-Permission` fails with an unhelpful error message if it is unable to get the ACL on a private key.
 
### Enhancements

 * `Import-Carbon.ps1` is more intelligent about when it tries to re-load Carbon. It will force a re-import of Carbon if any of Carbon's files have changed or the version has changed.
 * Created `Uninstall-Junction` for uninstalling a junction in an idempotent way (i.e. without errors). Thanks to [Konstantin Ushenin](https://vk.com/kostanew) for the contribution.
 * Improved error handling in `Remove-Junction`.
 * `Install-Service`:
   * Now supports service startup parameters/arguments.
   * No longer returns `ServiceController` objects by default. This should improve backwards-compatability. Added a `PassThru` switch you can use to get a `ServiceController` object returned to you.
   * Improved error handling. It now uses `net helpmsg` to get helpful error messages based on sc.exe exit codes.
   * Improved handling of arguments/services with spaces in them under PowerShell 5.
   * Added `Credential` parameter for increased security and to follow PowerShell guidelines.
   * Now supports setting a service's description and display name.
   * Starting the service now respects caller's error action preference. Before, `Start-Service` would write an error even if somone called `Install-Service` with an `Ignore` or `SilentlyContinue` error action preference.
 * New `Test-TypeDataMember` for testing if a type has an extended type member defined.
 * `Install-IisAppPool` no longer returns appcmd.exe output.
 * Added `PassThru` parameter to `Install-IisAppPool` to control when a `Microsoft.Web.Administration.ApplicationPool` for the installed app pool is returned.
 * `Get-ServiceConfiguration` and Carbon's extended type data for `System.ServiceProcess.ServiceController` objects now supports services from remote computers.
 * `Uninstall-ScheduledTask` now retries when un-installing a task fails with "The function attempted to use a name that is reserved for use by another transaction." error.
 * Added new `FileIndex`, `LinkCount`, and `VolumeSerialNumber` extended type data on `System.IO.FileInfo` objects for getting a file's index, its hard link count, and volume serial number, respectively.
 * `Grant-Permission` now only returns an access rule object when the new `PassThru` switch is used. In previous 2.0 alpha releases, it only returned something when permissions on an object were added or changed.
 * `Install-User` only returns a user object when the new `PassThru` switch is used. In previous 2.0 alpha releases, it only returned an object if a user was created or updated.
 * `Grant-ComPermissions` only returns an access rule object when the new `PassThru` switch is used. In previous 2.0 alpha releases, it only returned an object if permissions were changed.
 * `Install-IisApplication` only returns an IIS application object when the new `PassThru` switch is used. In previous 2.0 alpha releases, it only returned an object if the application was created or modified.
 * Created `Get-Msi` function for reading MSI information and properties from an MSI file.
 * `Carbon.Computer.ProgramInstallInfo` objects (returned from `Get-ProgramInstallInfo`) now have `ProductCode` and `User` properties. If a program doesn't have a product code, it is set to `[Guid]::Empty`. The `User` property is only set for per-user software installs.
 * `Invoke-WindowsInstaller` renamed `Install-Msi`, with a backwards-compatibility-preserving alias.
 * `Install-Msi` now supports wildcards for MSI path to install.
 * `Install-Msi` now only installs an MSI if it isn't already installed. To preserve the previous behavior and always install, add the `-Force` switch to all `Invoke-WindowsInstaller`\`Install-Msi` usages.
 * Added `SiteID` parameter to `Install-IisWebsite` for setting a website's IIS ID.
 * Put the `Resolve-IdentityName` function back. It was removed from previous alpha releases.
 * `Install-IisWebsite` no longer deletes and re-creates websites. This may or may not be a breaking change in your environment.
 * `Install-SmbShare` no longer returns net.exe output, instead writing it to the verbose stream. To see previous output, use the `-Verbose` switch.
 * Changed `-PasswordNeverExpires` switch to  `PasswordExpires` on `Install-User` for improved backwards-compatability.
 * `Set-SslCertificateBinding` no longer returns binding objects by default. Use new `PassThru` switch to get the old behavior.
 * The product version of the Carbon assembly now includes pre-release version information, as defined by the [Semantic Versioning specification](http://semver.org). To get this version, run `Get-Item Carbon.dll | Select-Object -ExpandProperty 'VersionInfo' | Select-Object -ExpandProperty 'ProductVersion'`
 * The Carbon NuGet package now supports installing and uninstalling using Chocolatey.
 * Added `AsSecureString` switch to `Unprotect-String` which causes `Unprotect-String` to return a secure string instead of a normal string.
 * `Unprotect-String` now accepts a `SecureString` as the value for the `Password` parameter, which is the password for the private key used to decrypt from password-protected RSA certificate file.
 * Added `Credential` parameter to `Install-IisAppPool` for increased security and to follow PowerShell guidelines.
 * Added `Credential` parameter to `Install-User` for increased security and to follow PowerShell guidelines.
 * `Install-IisVirtualDirectory` now modifies existing virtual directories in place, instead of deleting and re-creating.
 * `Invoke-AppCmd` is now obsolete and will be removed from a future version of Carbon. Switch to Carbon's IIS functions, or use `Get-IisConfigurationSection` to get `ConfigurationElement` objects from the `Microsoft.Web.Administration` API that you can modify.
 * Added `Description` and `DisplayName` properties to `Carbon_Service` for setting a service's description and display name.
 * `Grant-Permission` now writes an error if you don't have access to a private key. Previously, it would skip the key without any messages.
 * `Resolve-Identity` now converts SIDs to a `Carbon.Identity` object. The SID may be a string (SID in SDDL form), byte array, or a `SecurityIdentifier` object.
 * `Get-FileSharePermission` gets the sharing permissions on a file/SMB share (*not* the NTFS file system permissions).
 * Created `Get-FileShare` function. It uses WMI to get `Win32_Share` objects for the file shares installed on the local computer.
 * Renamed `Install-SmbShare` to `Install-FileShare`, with a backwards-compatible alias in place.
 * Added `SID` parameter to `Resolve-IdentityName` to resolve a SID into its identity name.
 * Created `ConvertTo-SecurityIdentifer` function to convert a binary, string, or `System.Security.Principal.SecurityIdentifier` object into a `System.Security.Principal.SecurityIdentifier` object.
 * `Install-FileShare` (fka `Install-SmbShare`):
    * Re-written to use WMI isntead of `net.exe`.
    * Modifies existing shares in place, instead of deleting and re-creating, *unless* the share's path changes. Changing a share's path requires the old share to be deleted and a new one created.
 * `Carbon_FirewallRule` now fails with an error if it finds multiple firewall rules with the same name.
 * `Set-RegistryKeyValue`: 
    * Added `UDWord` and `UQWord` parameters for setting registry key values to unsigned integers (i.e. integer values greater than `[int]::MaxValue` and `[long]::MaxValue`). Fixes [issue #165: Set-RegistryKeyValue rejects unsigned integers larger than [int]::MaxValue](https://bitbucket.org/splatteredbits/carbon/issues/165/set-registrykeyvalue).
    * Deprecated `Quiet` switch.
    * Only sets value if the value is changed. Use the `Force` parameter to preserve previous behavior.
 * `Uninstall-Service` no longer returns sc.exe stdout.


# 1.9.0 (8 November 2014)

This is the last minor release for version 1.0. Future 1.0-compatible releases will *only* contain bug fixes, no new features. It takes too much time to maintain two versions, and I'd rather spend my time getting 2.0 out the door.  Carbon 2.0 will require PowerShell 4.0, so start planning.

## Enhancements

### Certificates

 * Added `KeyStorageFlags` parameter to `Get-Certificate` when loading a certificate from a file for better control when storing the certificate.
 
### Hosts File

 * `Set-HostsEntry` now handles writing to an in-use/locked hosts file, retrying up to 10 times before writing an error, waiting a random amount of time (from 0 to 1000 milliseconds) between each retry attempt.

### IIS

 * `Get-IisMimeMap`, `Remove-IisMimeMap`, and `Set-IisMimeMap` now support managing MIME types for websites, virtual directories, and applications.

### Scheduled Tasks

 * Created `Get-ScheduledTask` function for getting the scheduled tasks on the local computer using `schtasks.exe`.
 * Created `Install-ScheduledTask` function for installing a scheduled task using `schtasks.exe`.
 * Created `Test-ScheduledTask` function for testing if a scheduled tasks on the local computer exists using `schtasks.exe`.
 * Created `Uninstall-ScheduledTask` function for deleting a scheduled task using `schtasks.exe`.
 
### Services

 * `Install-Service` now supports setting a command to run when a service fails.
 
## Bug Fixes

### General

 * `Import-Carbon` fails when `-WhatIf` switch is used.
 * Importing Carbon no longer writes an error if the `PATH` environment variable contains a path to a non-existent drive (issue [#134](https://bitbucket.org/splatteredbits/carbon/issue/134/import-carbon-fails-with-path-environment)).
 
### INI

 * `Set-IniEntry` fails when adding the first section-less setting to a file.
 
### Internet Explorer

 * `Enable-IEActivationPermission` no longer returns the `hkcr:` drive.
 
### Security

 * Fixed an error that occurs when setting permissions on a private key fails: the error message is created using an invalid format string (issue [#133](https://bitbucket.org/splatteredbits/carbon/issue/133/set-cryptokeysecurity-invalid-parameters)).
 * Fixed an exception that gets thrown when setting a private key's permissions and the only certificate key is AT_SIGNATURE (issue [#132](https://bitbucket.org/splatteredbits/carbon/issue/132/set-cryptokeysecurity-throws-exception)).
 
### Services

 * `Install-Service` stops Windows service even when no settings/configuration has changed (fixes issue [#131](https://bitbucket.org/splatteredbits/carbon/issue/131/install-service-always-restarts-service)). 
 * `Install-Service` didn't clear services depended on during a re-install.
 * `Install-Service` wasn't restarting a manual service if it was running when configuration began.
 * `Uninstall-Service` hard codes the path to the Windows directory (fixes issue [#143](https://bitbucket.org/splatteredbits/carbon/issue/143/uninstall-service-script-has-hard-coded)). Thanks to [Travis Mathison](https://bitbucket.org/tdmathison) for the fix.


# 1.8.0 (7 September 2014)

## Enhancements

### General

 * The following functions now write messages with `Write-Verbose` instead of `Write-Host`. See [Write-Host Considered Harmful](http://www.jsnover.com/blog/2013/12/07/write-host-considered-harmful/).
    * `Add-GroupMember`
    * `Clear-TrustedHost`
    * `Convert-XmlFile`
    * `Disable-FirewallStatefulFtp`
    * `Disable-IEEnhancedSecurityConfiguration`
    * `Disable-IisSecurityAuthentication`
    * `Disable-NtfsCompression`
    * `Enable-FirewallStatefulFtp`
    * `Enable-IEActivationPermission`
    * `Enable-IisSecurityAuthentication`
    * `Enable-NtfsCompression`
    * `Grant-ComPermission`
    * `Grant-MsmqMessageQueuePermission`
    * `Grant-Permission`
    * `Grant-ServiceControlPermission`
    * `Install-Group`
    * `Install-IisApplication`
    * `Install-MsmqMessageQueue`
    * `Install-PerformanceCounter`
    * `Install-RegistryKey`
    * `Install-Service`
    * `Install-User`
    * `Install-WindowsFeature`
    * `Invoke-WindowsInstaller`
    * `Lock-IisConfigurationSection`
    * `New-Junction`
    * `Protect-Acl`
    * `Remove-IniEntry` 
    * `Remove-Junction`
    * `Remove-SslCertificateBinding`
    * `Reset-HostsFile`
    * `Reset-MsmqQueueManagerID`
    * `Revoke-ComPermission`
    * `Revoke-ServicePermission`
    * `Set-IisHttpHeader`
    * `Set-IisMimeMap`
    * `Set-IisWebsiteID`
    * `Set-IisWindowsAuthentication`
    * `Set-IniEntry`
    * `Set-RegistryKeyValue`
    * `Set-SslCertificateBinding`
    * `Uninstall-IisAppPool`
    * `Uninstall-WindowsFeature`
    * `Unlock-IisConfigurationSection`
 * The following internal functions (which we warned you not to use!) are no longer exported:
    * Add-IisServerManagerMember
    * Get-IdentityPrincipalContext
    * Invoke-ConsoleCommand
    * ConvertTo-ProviderAccessControlRights
    * Assert-WindowsFeatureFunctionsSupported
    * Resolve-WindowsFeatureName
    
### Certificates

 * Improving error handling when `Get-Certificate` fails to load a certificate from a file.
 * `Install-Certificate` now supports installing with an `X509Certificate2` object instead of just a path to a certificate.
 * `Remove-SslCertificateBinding`: improved error handling.
 * `Set-SslCertificateBinding`: improved error handling.
 * Improved documentation for `Get-Certificate`.
 * Added extended script property `StoreName` to `X509Store` objects to return the store's `System.Security.Cryptography.X509Certificates.StoreName` value.
 * Added a table view/format for `X509Store` objects. PowerShell's default view is a list, so you'll have to explicitly format the objects as a table, e.g. `dir cert:\LocalMachine | Format-Table`.
 * `Get-Certificate`'s `Path` parameter now supports wildcards and certificate provider paths, e.g. `cert:\`.
 * `Get-Certificate` now writes an error if a certificate isn't found when getting a certificate by its path.

### Computer

 * Created `Get-ProgramInstallInfo` function to get the information displayed by the `Programs and Features` UI.

### Cryptography

 * `Protect-String` can now encrypt strings as a specific user. Use the `Credential` parameter.
 * Created `New-RsaKeyPair` for creating public/private RSA key pair using `makecert.exe` and `pkv2pfx.exe`. Requires that you've installed a Windows SDK.
 * `Protect-String` can now encrypt strings using an RSA public key.
 * `Unprotect-String` can now decrypt strings using an RSA private key.
 
### File System

 * `Disable-NtfsCompression`: improved error handling.
 * `Enable-NtfsCompression`: improved error handling.
 * Created `Compress-Item` function for compressing files/directories into a ZIP file.
 * Created `Test-ZipFile` function for testing if a file is a ZIP file.
 * Created `Expand-Item` function for decompressing a ZIP file.
 * `New-TempDirectory` now supports adding a prefix to the temporary directory's name, so you can more easily track down those scripts/processes that don't clean up after themselves.

### Firewall

 * `Disable-FirewallStatefulFtp`: improved error handling.
 * Added `Name` and `LiteralName` parameters to `Get-FirewallRule` to return specific rules instead of all of them.
 * `Get-FirewallRule`, now returns `Carbon.Firewall.Rule` objects, instead of anonymous hashes.
 * Added default table format for `Get-FirewallRule` output.
 * `Get-FirewallRule` now returns additional rule information: interface type, security, source, description, program, and service. Who knew `netsh advfirewall firewall rule show` had a `verbose` switch? RTFM.

### INI

 * `Remove-IniEntry` now handles case-sensitive INI files.
 * `Set-IniEntry` now handles case-sensitive INI files.
 * `Split-Ini` now handles case-sensitive INI files.

### MSI

 * `Invoke-WindowsInstaller`: improved error message if installation fails.

### Security

 * Creating `Revoke-Permission` function for revoking a user's permission to a file, directory, registry key, or certificate's private key/key container.
 * Creating `ConvertTo-ContainerInheritanceFlags` function for converting  `System.Security.AccessControl.InheritanceFlags` and `System.Security.AccessControl.PropagationFlag` values into a `Carbon.Security.ContainerInheritanceFlags` value.
 * `Get-Permission` now supports returning the permissions on private keys/key containers.
 * `Grant-Permission` now supports granting permissions on private keys//key containers.
 * `Test-Permission` now supports testing permissions on certificate private keys/key containers.

### Services

 * Created `Get-ServiceConfiguration` function for loading a service's configuration: description, account name/username, failure actions, etc.
 * Added the following extended type data to `System.ServiceController.Service`:
   * Description
   * ErrorControl
   * FailureProgram
   * FirstFailure
   * LoadOrderGroup
   * Path
   * RebootDelay
   * RebootDelayMinutes
   * RebootMessage
   * ResetPeriod
   * ResetPeriodDays
   * RestartDelay
   * RestartDelayMinutes
   * SecondFailure
   * StartMode
   * StartType
   * TagID
   * ThirdFailure
   * UserName


## Bug Fixes

### General

 * Importing Carbon gives an error if `PATH` environment variable contains an empty path.
 * Improved the error handling in the following functions so they properly catch exceptions and write friendlier errors:
   * `Get-Certificate`
   * `Grant-Privilege`
   * `Revoke-Privilege`

### Certificates

 * `Get-Certificate` couldn't open CA/CertificateAuthority store (fixes issue [#130](https://bitbucket.org/splatteredbits/carbon/issue/130/get-certificate-doesnt-find-any)).
 * Extended script property `DisplayName` on `X509Store` objects returning wrong store name for custom stores, now returns an empty string.

### File System

 * `Disable-NtfsCompression` now *really* supports multiple paths.
 * `Enable-NtfsCompression` now *really* supports multiple paths.

### Path

 * `Resolve-PathCase` didn't work under Windows 2012 R2.

### Users and Groups

 * The `Carbon.Identity.FindByName` method and the `Resolve-IdentityName` and `Test-Identity` functions now handle identity names with `.` for the domain/machine name, e.g. `.\Administrator`.
 * The `Carbon.Identity.FullName` property returns the wrong value when domain is empty/null, e.g. `Resolve-IdentityName -Name 'Everyone'` returns `\Everyone`, when it should return `Everyone`.
 * The `Carbon.Identity.FindByName` method and the `Resolve-IdentityName` and `Test-Identity` functions unable to resolve `LocalSystem` account (which is actually `NT AUTHORITY\SYSTEM`).


# 1.7.0 (30 April 2014)

There is now [a Carbon support mailing list](https://groups.google.com/forum/#!forum/carbonps).

## Enhancements

### General

 * Import-Carbon.ps1 now supports the `-WhatIf` switch.
 * Import-Carbon.ps1 now hides verbose log messages when removing/importing Carbon even when supplying the `-Verbose` switch because I think the verbose output is too verbose and not helpful at all.
 * Import-Carbon.ps1 now supports adding a prefix when importing the Carbon module (with the `Prefix` parameter) to avoid name collisions and [follow best practices](http://blogs.msdn.com/b/powershell/archive/2014/04/07/what-s-in-a-name-using-the-ps-prefix.aspx).

### Certificates

 * `Get-CertificateStore` now supports non-standard, custom certificate stores.
 * `Get-Certificate` now supports non-standard, custom certificate stores.
 * `Install-Certificate` now supports non-standard, custom certificate stores.
 * `Uninstall-Certificate` now supports non-standard, custom certificate stores.

## Bug Fixes

### General

 * No more silent errors when importing Carbon on Windows 2012 R2.

### Certificates

 * `Get-Certificate` no longer writes a silent error when a certificate does not exist. Instead, no error is written.

### File System

 * `Install-Junction` fails when target path is hidden.
 * `Test-NtfsCompression` fails when file/directory is hidden.
 * `Test-PathIsJunction` fails when tested directory is hidden.

### Security

 * `Grant-Permission` fails when item is hidden.
 * `Grant-Permission` doesn't handle non-existent paths, causing cascading errors.
 * `Test-Permission` always returns `$false` when testing leaf-level permissions and the `ApplyTo` parameter is provided, i.e. it doesn't ignore inheritance/propagation flags on leaves.


# 1.6.0 (1 February 2014)

## Bug Fixes

### Certificates

 * `Get-Certificate` fails when passed a relative path.
 * `Install-Certificate` fails when passed a relative path.

### File System

 * `Remove-Junction` doesn't delete a junction when given a relative path to the junction.

### Services

 * `Install-Service` doesn't properly resolve a service's path.

### Shares

 * Fixed `Install-SmbShare` example to use correct syntax. [#111.](https://bitbucket.org/splatteredbits/carbon/issue/111)

## Enhancements

### Hosts File

 * Created `Remove-HostsEntry` function for removing hostnames from a hosts file.

### IIS

 * Created `Join-IisVirtualPath` for joining paths used by the IIS APIs.
 * Renamed all IIS `Path` parameters which represented virtual paths to `VirtualPath` (with backwards-compatible aliases):
    * `Disable-IisSecurityAuthentication`
    * `Enable-IisDirectoryBrowsing`
    * `Enable-IisSecurityAuthentication`
    * `Enable-IisSsl`
    * `Get-IisApplication`
    * `Get-IisConfigurationSection`
    * `Get-IisHttpHeader`
    * `Get-IisHttpRedirect`
    * `Get-IisMimeMap`
    * `Get-IisSecurityAuthentication`
    * `Set-IisHttpHeader`
    * `Set-IisHttpRedirect`
    * `Set-IisWindowsAuthentication`
    * `Test-IisConfigurationSection`
    * `Test-IisSecurityAuthentication`
 * Renamed `Get-IisWebsite`'s `SiteName` parameter to `Name` (with a backwards-compatible alias).
 * Renamed all IIS `Name` parameters which represented virtual paths to `VirtualPath` (with backwards-compatible aliases):
    * `Install-IisApplication`
    * `Install-IisVirtualDirectory`
 * Renamed all IIS `Path` parameters which represented physical paths to `PhysicalPath` (with backwards-compatible aliases):
    * `Install-IisApplication`
    * `Install-IisVirtualDirectory`
    * `Install-IisWebsite`

### .NET

 * Created `Test-DotNet` for testing if v2 or v4 of the .NET framework is installed.

### Path

 * Created `Get-PathProvider` function for getting a path's PowerShell provider.

### PowerShell

 * Updated `Invoke-PowerShell` to test if the appropriate .NET framework is installed if the user chooses an explicit runtime to use.

### Security

 * Created `Test-Permission` function for checking if a user/group has a set of permissions and, optionally, a set of inheritance and propagation flags on a file, directory, or registry key.
 * `Test-Permission` now automatically includes the `Synchronize` permission when checking for exact permissions, since this permission is always on and can never be removed from a file/directory.

### Services

 * `Install-Service` no longer requires a password, in order to support [managed service accounts and virtual accounts](http://technet.microsoft.com/en-us/library/dd548356.aspx).  We have no idea if this works, since we can't test locally.  Please let us know if this fix works for you. [#114](https://bitbucket.org/splatteredbits/carbon/issue/114)

### Users and Groups

 * Updated `Install-User` to support passwords longer than 14 characters.  Thanks to [James Crowley](http://www.jamescrowley.co.uk/) for the fix.

### Windows Features

 * Marked Assert-WindowsFeatureFunctionsSupported as an internal function.  Please don't use.  It will be removed from future versions of PowerShell.
 * Updated `Test-WindowsFeature` to work on Windows 8/2012.
 * Created new `Carbon.Identity` class for representing identities.  It also contains a static `FindByName` method which uses The Windows `LookupAccountName` function to find full account names, domains, and sids.
 * Updated `Test-Identity` to use `[Carbon.Identity]::FindByName` to find identities so it no longer throws exceptions when an identity can't be found.
 * Updated `Resolve-IdentityName` to use `[Carbon.Identity]::FindByName` to find identities so it no longer throws exceptions when an identity can't be found.


 # 1.5.1 (3 October 2013)

## Bug Fixes

### IIS

 * `Set-IisWebsiteID` wasn't consistently starting a website after changing its ID.

### Shares

 * `Install-SmbShare` has an unused variable which uses an undefined variable to create its value.  When running in strict mode, PowerShell writes an error about using the undefined variable.  Removed the unused variable.


# 1.5.0 (6 September 2013)

## Enhancements

### IIS

 * `Set-IisWebsiteID` now attempts to start a website whose ID has changed, since IIS stops a website whenever its ID changes.

### Network

 * Added `Get-IPAddress` function for getting the IPv4/IPv6 addresses currently in use on the local computer's network interfaces.
 * Added `Test-IPAddress` function for testing if an IP address is in use on one the local computer's network interfaces.

### Path

 * Added `Test-UncPath` function for testing if a path is a UNC or not.

### PowerShell

 * `Invoke-PowerShell` now runs script blocks in PowerShell 3 under a v2.0 CLR.

### Shares

 * `Install-SmbShare` now creates the share's directory if it doesn't exist.

## Bug Fixes

### Certificates

 * `Get-Certificate` throws an exception and halts script execution when loading a certificate file with a private key and the user doesn't have permission to write to Windows' MachineKeys directory.  It now writes an error instead.

### PowerShell

 * `Invoke-PowerShell` doesn't run under a v2.0 CLR when using parameters `-Runtime 'v2.0'`.


# 1.4.0 (10 August 2013)

## Enhancements

### File System

 * Created `Install-Junction` function for creating new and/or updating existing junctions. This is a more idempotent way of creating junctions, as opposed to `New-Junction` and `Remove-Junction` which report errors if a junction already exists or doesn't exist, respectively.

### IIS

 * Objects returned by `Get-IisWebsite` now have a dynamic `PhysicalPath` script property, so you don't have to traverse down into the default application's default virtual directory object to get it.
 * `Install-IisApplication`, `Install-IisWebsite`, and `Install-IisVirtualDirectory` now canonicalize physical paths, i.e. they convert any path with a relative part (e.g. '..') to a full path.  It turns out IIS doesn't like paths with relative parts.
 * Created `Get-IisApplication` function to get `Microsoft.Web.Administration.Application` objects for all or specific applications under a website.
 * `Install-IisApplication` now uses the `Microsoft.Web.Administration` API instead of `appcmd.exe`.

### PowerShell

 * Added `ExecutionPolicy` parameter to `Invoke-PowerShell` to allow setting a custom exeuction policy when using `Invoke-PowerShell` to run a script.

## Bug Fixes

### IIS

 * `Install-IisApplication` not updating/changing physical path on existing application.

### .NET

 * `Set-DotNetAppSetting` and `Set-DotNetConnectionString` failed if setting .NET configuration under an architecture where the PowerShell execution policy doesn't allow running scripts.


# 1.3.0 (8 July 2013)

## Enhancements

### PowerShell

 * `Invoke-PowerShell` now supports running an external script.
 * Added `OutputFormat` argument to `Invoke-PowerShell` so your scripts/script blocks can return XML results instead of plain text.
 * Renamed `Invoke-PowerShell`'s `Args` parameter to `ArgumentList` (with backwards compatibile `Args` alias).
 * Renamed `Invoke-PowerShell`'s `Command` parameter to `ScriptBlock` (with backwards-compatible `Command` alias).
 * `Invoke-PowerShell` now runs 64-bit PowerShell from 32-bit PowerShell.
 * `Get-PowerShellPath` now returns path for 64-bit PowerShell when running 32-bit PowerShell.

### Text

 * Created new `ConvertTo-Base64` function for encoding strings in base-64.
 * Created new `ConvertFrom-Base64` function for decoding base-64 strings.


## Bug Fixes

### .NET

 * `Set-DotNetAppSetting` and `Set-DotNetConnectionString` weren't able to set .NET 2.0 app settings and connections string when running under PowerShell 3.


# 1.2.0 (25 June 2013)

## Enhancements

### General

 * Carbon should now work under PowerShell v3.0!

### Certificates

 * Added support for IPv6 addresses to `Get-SslCertificateBinding`, `Remove-SslCertificateBinding`, and `Set-SslCertificateBinding`.

### .NET

 * Added `ProviderName` parameter to `Set-DotNetConnectionString` for setting a connection string's `providerName` attribute/value.

### File System

 * Created `Disable-NtfsCompression` function for disabling NTFS compression on files/directories.
 * Created `Enable-NtfsCompression` function for enabling NTFS compression on files/directories.
 * Created `Test-NtfsCompression` function for testing if NTFS compression is enabled on a file/directory.

### IIS
 * The [site object](http://msdn.microsoft.com/en-us/library/microsoft.web.administration.site.aspx) returned by `Get-IisWebsite` now as a `CommitChanges` method so you can persist modifications you make to the site.
 * `Get-IisWebsite` now returns all websites if no `SiteName` is given.
 * Created `Set-IisWebsiteID` function for explicitly setting a website's ID.

### INI

 * Created `Remove-IniEntry` function for removing entries/settings from an INI file.

### Performance Counters

 * `Install-PerformanceCounter` now supports installing a base performance counter.  Thanks to Philip Teilmeier for the contribution.
 * `Install-PerformanceCounter`'s `Description` parameter is now optional.

### PowerShell

 * `Invoke-PowerShell` now defaults to running under the current CLR, instead of defaulting to a v2.0 CLR.  This makes upgrading to PowerShell v3.0 easier.
 * `Invoke-PowerShell` now writes an error and returns if running PowerShell v3.0 and you want to run under a v2.0 CLR.  Unfortunately, PowerShell v3.0 requires .NET 4.0, so you can't run anything on an earlier CLR.

### Privileges

 * `Revoke-Privilege` now supports case-insensitive privilege names.
 * Updated `Grant-Privilege` to better handle when passing a privilege name with the wrong case.
 * Updated `Grant-Privilege` documentation to make it clear privilege names are case-sensitive.

### XML

 * New `Convert-XmlFile`, for transforming an XML file with Microsoft's XDT (XML Data Transformation) technology.  Thanks to Mark Sargent for the contribution.


## Bug Fixes

### General

 * Deleted the obsolete variable `$CarbonImported`.  Carbon no longer exports any of its variables.

### Certificates

 * `Get-SslCertificateBinding` can't parse bindings to IPv6 addresses.

### Performance Counters

 * `Install-PerformanceCounter` couldn't be used to create counters that used/required a base counter. Thanks to Philip Teilmeier for the contribution.


# 1.1.0 (1 April 2013)

## Upgrade Instructions

 * On Windows 2008 R2, custom identies that run IIS app pools need the `SeBatchLogonRight`.  `Install-IisAppPool` now grants this privilege on all operating systems.  If this won't work in your environment, you can remove these privileges with `Revoke-Privilege`.

## Enhancements

### General

 * Fixed some typos and ommissions in the v0.5.0.1 and v0.5.0.0 sections of the release notes.
 * Updated `Import-Carbon.ps1` script to import Carbon regardless of the name of the directory Carbon is installed in.

### Certificates

 * Added `IssuedTo` and `IssuedBy` properties to [X509Certificate2](http://msdn.microsoft.com/en-us/library/ms148409(v=vs.90).aspx) objects.  The values match what the Certificates MMC snap-in displays.
 * Added `DisplayName` property to [X509Store](http://msdn.microsoft.com/en-us/library/d228271e(v=vs.90).aspx) objects, to show the names of the stores as they are displayed in the Certificates MMC snap-in.

### Computer

 * Created `Resolve-NetPath` for getting the path to the Windows `net.exe` command/application.  Updated all functions that call `net.exe` to use this function to resolve its path.  Thanks to Paul Aage Aasheim for discovering that when running login scripts, `net.exe` isn't in the path.

### IIS

 * Created `Get-IisHttpHeader` for getting the custom HTTP headers for a website or one of its sub-directories.
 * Created `Set-IisHttpHeader` for creating/setting a custom HTTP header for a website or one of its sub-directories.
 * Created `Get-IisMimeMap` for getting the file extension to MIME type mappings for the IIS web server.
 * Created `Remove-IisMimeMap` for removing a file extension to MIME type mapping for the IIS web server.
 * Created `Set-IisMimeMap` for creating/setting a file extension to MIME type mapping for the IIS web server.
 * When creating an app pool that runs under a custom, non-service account, `Install-IisAppPool` grants that user the `SeBatchLogonRight`.
 * `Install-IisAppPool` writes an error if its user account doesn't exist (i.e. if the value of the `Username` parameter doesn't exist).

### Privileges

 * Improved exception handling in `Grant-Privilege` and `Revoke-Privilege`.
 * `Grant-Privilege` and `Revoke-Privilege` now write an error message if an identity doesn't exist.


## Bug Fixes

### Computer

 * `Install-SmbShare` can't find `net.exe` when running as part of a Windows logon script.  Thanks to Paul Aage Aasheim for identifying and reporting this bug.  All usages of the `net.exe` application were updated to use the new `Resolve-NetPath` function, which get the path to `net.exe` without assuming it is in the user's `PATH` environment variable.


### Users and Groups

 * `Test-Identity` no longer writes an error if it can't find a fully-qualified local user, e.g. `$env:COMPUTERNAME\Username`.


# 1.0.0 (6 March 2013)

## Upgrade Instructions

 * Remove the `Quiet` parameter from calls to the `Import-Carbon.ps1` script.
 * If you're nesting Carbon as a sub-module of another module, ***STOP***.  This causes havoc.  Create an `Import-*.ps1` script for your module which imports Carbon before importing your own module.  Update your scripts to import your module with your fancy new `Import-*.ps1` script.  See [Best Practices for Importing PowerShell Modules](http://pshdo.com/archive/2012/6/4/best-practices-for-importing-powershell-modules.html) for details.

## Enhancements

### General

 * The `Import-Carbon.ps1` script no longer checks if Carbon is a sub-module of another module, so the `Quiet` parameter was removed.  ***Please don't nest Carbon in your modules!***  It will cause havoc.
 * `Import-Carbon.ps1` will no longer stop execution if an error occurs during an import (i.e. the `$ErrorActionPreference = 'Stop'` line was removed).

### IIS

 * Added `Test-IisWebsiteExists` alias for `Test-IisWebsite`, for backwards-compatibility with earlier releases.

### Security

 * Added `Unprotect-AclAccessRules` alias for `Protect-Acl`, for backwards-compatibility with earlier releases.
 * Added rename of `Unprotect-AclAccessRules` to `Protect-Acl` to v0.5.0.0 section of release notes.

### Services

 * Renamed `Install-Service`'s `Dependencies` parameter to `Dependency` (with backwards-compatible alias), to follow PowerShell naming standards.

### Users and Groups

 * `Install-User`: you can now set a user's full name with the optional `FullName` parameter.

## Bug Fixes

### Security

 * `Grant-Permission` returns boolean values to the pipeline when clearing access rules.

### Service

 * `Install-Service` fails if `Dependency` parameter doesn't have a value.  Sometimes.

### Shares

 * `Install-SmbShare` fails if a principal name contains a space.

### Users and Groups

 * `Add-GroupMember` doesn't handle when the .NET Active Directory throws an exception when adding members to a group, causing script termination.


# 0.5.0.1 (9 January 2013)

## Enhancements

### Active Directory

 * Renamed `Format-ADSpecialCharacters` to `Format-ADSearchFilterValue`, with backwards-compatible alias.

### Certificates

 * Renamed `Get-SslCertificateBindings` to `Get-SslCertificateBinding`, with backwards-compatible alias.
 * Added `Remove-Certificate` alias for `Uninstall-Certificate`, for backwards-compatibility with earlier releases.

### COM

 * Renamed `Get-ComPermissions` to `Get-ComPermission`, with backwards-compatible alias.
 * Renamed `Grant-ComPermissions` to `Grant-ComPermission`, with backwards-compatible alias.
 * Renamed `Revoke-ComPermissions` to `Revoke-ComPermission`, with backwards-compatible alias.

### Firewall

 * Renamed `Get-FirewallRules` to `Get-FirewallRule`, with backwards-compatible alias.

### IIS

 * Renamed `Add-IisServerManagerMembers` to `Add-IisServerManagerMembers`, with backwards-compatible alias.
 * Added `StatusCode` alias for `Set-IisHttpRedirect's` `HttpResponseStatus` parameter, for backwards-compatibility with earlier releases.
 * Added `Test-IisAppPoolExists` alias for `Test-IisAppPool`, for backwards-compatibility with earlier releases.
 * Added `Remove-IisWebsite` alias for `Uninstall-IisWebsite`, for backwards-compatibility with earlier releases.

### Internet Explorer

 * Renamed `Enable-IEActivationPermissions` to `Enable-IEActivationPermission`, with backwards-compatible alias.

### MSMQ

 * Renamed `Grant-MsmqMessageQueuePermissions` to `Grant-MsmqMessageQueuePermission`, with backwards-compatible alias.
 * Added `Remove-MsmqMessageQueue` alias for `Uninstall-MsmqMessageQueue`, for backwards-compatibility with earlier releases.

### Path

 * Added `ConvertTo-FullPath` alias for `Resolve-FullPath`, for backwards-compatibility with earlier releases.
 * Added `Get-PathCanonicalCase` alias for `Resolve-PathCase`, for backwards-compatibility with earlier releases.

### Performance Counters

 * Renamed `Get-PerformanceCounters` to `Get-PerformanceCounter`, with backwards-compatible alias.

### PowerShell

 * Renamed `Add-TrustedHosts` to `Add-TrustedHost`, with backwards-compatible alias.
 * Renamed `Add-TrustedHost`'s `Entries` parameter to `Entry`, with backwards-compatible alias.
 * Renamed `Clear-TrustedHosts` to `Clear-TrustedHost`, with backwards-compatible alias.
 * Renamed `Complete-Jobs` to `Complete-Job`, with backwards-compatible alias.
 * Renamed `Complete-Job`'s `Jobs` parameter to `Job`, with backwards-compatible alias.
 * Renamed `Get-TrustedHosts` to `Get-TrustedHost`, with backwards-compatible alias.
 * Renamed `Set-TrustedHosts` to `Set-TrustedHost`, with backwards-compatible alias.
 * Renamed `Set-TrustedHost`'s `Entries` parameter to `Entry`, with backwards-compatible alias.

### Security

 * Renamed `Assert-AdminPrivileges` to `Assert-AdminPrivilege`, with backwards-compatible alias.
 * Renamed `ConvertTo-InheritanceFlags` to `ConvertTo-InheritanceFlag`, with backwards-compatible alias.
 * Renamed `ConvertTo-InheritanceFlag`'s `ContainerInheritanceFlags` parameter to `ConvertTo-InheritanceFlag`, with backwards-compatible alias.
 * Renamed `ConvertTo-PropagationFlags` to `ConvertTo-PropagationFlag`, with backwards-compatible alias.
 * Renamed `ConvertTo-PropagationFlag`'s `ContainerInheritanceFlags` parameter to `ConvertTo-InheritanceFlag`, with backwards-compatible alias.
 * Renamed `Get-Permissions` to `Get-Permission`, with backwards-compatible alias.
 * Renamed `Grant-Permissions` to `Grant-Permission`, with backwards-compatible alias.
 * Renamed `Grant-Permission`'s `Permissions` parameter to `Permission`, with backwards-compatible alias.
 * Renamed `Test-AdminPrivileges` to `Test-AdminPrivilege`, with backwards-compatible alias.

### Service

 * Renamed `Get-ServicePermissions` to `Get-ServicePermission`, with backwards-compatible alias.
 * Added `Remove-Service` alias for `Uninstall-Service`, for backwards-compatibility with earlier releases.

### Users and Groups

 * Renamed `Add-GroupMembers` to `Add-GroupMember`, with backwards-compatible alias.
 * Renamed `Add-GroupMember`'s `Members` parameter to `Member`.
 * Added `Remove-User` alias for `Uninstall-User`, for backwards-compatibility with earlier releases.

### Windows Features

 * Added `Install-WindowsFeatures` alias for `Install-WindowsFeature`, for backwards-compatibility with earlier releases.
 * Added `Features` alias for  `Install-WindowsFeature's` `Name` parameter, for backwards-compatibility with earlier releases.
 * Added `Uninstall-WindowsFeatures` alias for `Uninstall-WindowsFeature`, for backwards-compatibility with earlier releases.
 * Added `Features` alias for  `Uninstall-WindowsFeature's` `Name` parameter, for backwards-compatibility with earlier releases.


# 0.5.0.0 (7 January 2013)

## Upgrade Instructions

This release contains many backwards incompatible changes.  We apologize for this inconvenience.  We are making these changes so we can get ready for the v1.0 release.  One of our goals for v1.0 is to get the functions and their interfaces internally consistent and consistent with PowerShell naming schemes.  Once v1.0 is out the door, backwards-incompatible changes will be phased in as much as possible.

Take the following steps to get your scripts to work with this release.

### Certificates

Replaces usages of:

 * `Get-SslCertificateBindings` with `Get-SslCertificateBinding`
 * `Get-SslCertificateBinding -IPPort '0.0.0.0:443'` with `Get-SslCertificateBinding`
 * `Get-SslCertificateBinding -IPPort '10.1.1.1:8001` with `Get-SslCertificateBinding -IPAddress '10.1.1.1' -Port 8001`
 * `Test-SslCertificateBinding -IPPort '0.0.0.0:443` with `Test-SslCertificateBinding`
 * `Test-SslCertificateBinding -IPPort '10.1.1.1:8001` with `Test-SslCertificateBinding -IPAddress '10.1.1.1' -Port 8001`
 * `Set-SslCertificateBinding -IPPort '0.0.0.0:443` with `Set-SslCertificateBinding`
 * `Set-SslCertificateBinding -IPort '1.2.3.4:8001' with `Set-SslCertificateBinding -IPAddress '1.2.3.4' -Port 8001
 * `Remove-SslCertificateBinding -IPPort '0.0.0.0:443` with `Remove-SslCertificateBinding`
 * `Remove-SslCertificateBinding -IPPort '10.1.1.1:8001` with `Remove-SslCertificateBinding -IPAddress '10.1.1.1' -Port 8001`

### Computer

Replace usages of

 * `Set-EnvironmentVariable -Scope 'Process'` with `Set-EnvironmentVariable -ForProcess`
 * `Set-EnvironmentVariable -Scope 'User'` with `Set-EnvironmentVariable -ForUser`
 * `Set-EnvironmentVariable -Scope 'ForComputer'` with `Set-EnvironmentVariable -ForComputer`
 * `Remove-EnvironmentVariable -Scope 'Process'` with `Remove-EnvironmentVariable -ForProcess`
 * `Remove-EnvironmentVariable -Scope 'User'` with `Remove-EnvironmentVariable -ForUser`
 * `Remove-EnvironmentVariable -Scope 'ForComputer'` with `Remove-EnvironmentVariable -ForComputer`

### Cryptography

 * `Protect-String -Scope CurrentUser` with `Protect-String -ForUser`
 * `Protect-String -Scope LocalMachine` with `Protect-String -ForComputer`

### IIS

 * Renamed the `StatusCode` property on the object returned by `Get-IisHttpRedirect` to `HttpResponseStatus`.  Update usages accordingly.
 * The `Bindings` property returned by `Get-IisWebsite` is now a collection of `Microsoft.Web.Administration.Binding` objects.  Update usages of `$site.Bindings[$idx].IPAddress` and `$site.Bindings[$idx].Port` to `$site.Bindings[$idx].Endpoint.Address` and `$site.Bindings[$idx].Endpoint.Port`, respectively.

Replace usages of:

 * `Set-IisAnonymousAuthentication` with `Enable-IisSecurityAuthentication -Anonymous`
 * `Set-IisAnonymousAuthentication -Disabled` with `Disable-IisSecurityAuthentication -Anonymous`
 * `Set-IisBasicAuthentication` with `Enable-IisSecurityAuthentication -Basic`
 * `Set-IisBasicAuthentication -Disabled` with `Disable-IisSecurityAuthentication -Basic`
 * `Set-IisWindowsAuthentication` with `Enable-IisSecurityAuthentication -Windows` and `Set-IisWindowsAuthentication -DisableKernelMode`
 * `Set-IisWindowsAuthentication -UseKernelMode` with `Set-IisWindowsAuthentication`
 * `Set-IisWindowsAuthentication -Disabled` with `Disable-IisSecurityAuthentication -Windows`
 * `Unlock-IisConfigSection -Name <string>` with `Unlock-IisConfigurationSection -SectionPath <string>` (run `appcmd.exe lock config -section:?` for values to the new `SectionPath` parameter)
 * `Unlock-IisBasicAuthentication` with `Unlock-IisConfigurationSection -SectionPath 'system.webServer/security/authentication/basicAuthentication'`
 * `Unlock-IisCgi` with `Unlock-IisConfigurationSection -SectionPath 'system.webServer/cgi'`
 * `Unlock-IisWindowsAuthentication` with `Unlock-IisConfigurationSection -SectionPath 'system.webServer/security/authentication/windowsAuthentication'`


### INI

Replace usages of:

 * `Split-Ini -Path <string>` with `Split-Ini -Path <string> -AsHashtable` (hashtable is no longer returned by default)
 * `Split-Ini -Path <string> -PassThru` with `Split-Ini -Path <string>` (per-line objects are now returned by default)


### Path

Replace usages of

 * `Get-PathRelativeTo -To <string> -From <string>'` with `Resolve-RelativePath -Path <string> -FromDirectory <string>`
 * `Get-PathRelativeTo -To <string> -From <string> -FromType 'File'` with `Resolve-RelativePath -Path <string> -FromFile <string>`

### Performance Counters

 * `Get-PerformanceCounters` no longer returns an empty list if there are zero counters or a single element list if there is one counter.  It now returns `null` and a single object, respectively.  Update usages accordingly.

### PowerShell

 * `Get-TrustedHosts` no longer returns an empty list if there are no trusted hosts.  It now return nothing/`null`.  Update usages accordingly.

### Security

 * `Assert-AdminPrivileges` now returns `True` or `False` if the user doesn't have admin privileges. It also no longer throws an exception, but writes an error.  If you want to preserve current behavior where it stops script execution, replace usages with `Assert-AdminPrivileges -ErrorAction Stop`.

### Shares

Replace usages of:

 * `Install-Share -Permissions '"ShareAdmins,FULL"','"ShareWriters,CHANGE"','"ShareReaders,READ"'` with `Install-SmbShare -FullAccess ShareAdmins -ChangeAccess ShareWriters -ReadAccess ShareReaders`.

### Windows Features

Replace usages of:

 * `Test-WindowsFeature` with `Test-WindowsFeature -Installed`
 * `Install-WindowsFeatureIis` with `Install-WindowsFeature -Iis`
 * `Install-WindowsFeatureIis -HttpRedirection` with `Install-WindowsFeature -Iis -IisHttpRedirection`
 * `Install-WindowsFeatureMsmq` with `Install-WindowsFeature -Msmq`
 * `Install-WindowsFeatureMsmq -HttpSupport` with `Install-WindowsFeature -Msmq -MsmqHttpSupport`
 * `Install-WindowsFeatureMsmq -ActiveDirectoryIntegration` with `Install-WindowsFeature -MsmqActiveDirectoryIntegration`

## New Features

### IIS
 * Created `Get-IisConfigurationSection` function for getting a site's (and optional sub-directory's) [Microsoft.Web.Administration.ConfigurationSection](http://msdn.microsoft.com/en-us/library/microsoft.web.administration.configurationsection(v=vs.90).aspx) objects for an arbitrary IIS configuration section.
 * Created `Get-IisSecurityAuthentication` function for getting a site's (and optional sub-directory's)  [anonymous, basic, digest, or Windows authentication configuration section](http://msdn.microsoft.com/en-us/library/microsoft.web.administration.configurationsection(v=vs.90).aspx).
 * Created `Test-IisSecurityAuthentication` function for testing if anonymous, basic, digest, or Windows authentication is enabled for a website (and optional sub-directory).
 * Created `Get-IisConfigurationSection` function for returning an arbitrary IIS configuration section using the Microsoft.Web.Administration API.
 * Created `Lock-IisConfigurationSection` function for locking arbitrary global IIS configuration sections.
 * Created `Test-IisConfigurationSection` function for testing if an configuration section exists or is locked or not.
 * Created function `Get-IisAppPool` for getting a `Microsoft.Web.Administration.AppPool` object for an application pool.
 * Created function `Uninstall-IisAppPool` for removing an IIS application pool.

### Windows Features
 * Created new `Get-WindowsFeature` function for getting a list of available Windows features.


## Bug Fixes

### Service
 * `Install-Service` not granting default service identity, Network Service, the correct permissions.
 * `Install-Service` not correctly resolving local identity account names.


## Enhancements

### Certificates
 * Moved functionality of `Get-SslCertificateBinding` into `Get-SslCertificateBindings`.  Can now filter by `IPAddress` and/or `Port`.
 * `Get-SslCertificateBindings` now returns `Carbon.Certificates.SslCertificateBinding` objects.  All information displayed by the `netsh http show sslcert` command is returned as part of those objects.
 * `Get-SslCertificateBindings` now supports filtering by `IPAddress` and `Port` separately, instead of requiring both.  The old `IPPort` parameter is replaced with `IPAddress` and `Port` parameters.
 * `Test-SslCertificateBinding` now supports testig by `IPAddress` and `Port` separately, instead of requiring both.  The old `IPPort` parameter is replaced with `IPAddress` and `Port` parameters.
 * Replaced `IPPort` parameter on `Get-SslCertificateBinding` with separate `IPAddress` and `Port` parameters on  `Get-SslCertificateBindings`.  Set `IPAddress` only if you want to bind to a specific IP address (i.e. *not* 0.0.0.0).  Set `Port` if *not* binding to port 443.
 * Replaced `IPPort` parameter on `Remove-SslCertificateBinding` with separate `IPAddress` and `Port` parameters.  Set `IPAddress` only if you want to remove a binding for a specific IP address (i.e. *not* 0.0.0.0).  Set `Port` if the binding is *not* on port 443.
 * Renamed `Remove-Certificate` to `Uninstall-Certificate` (added backwards-compatible alias in v0.5.0.1).

### Computer
 * Replaced the `Scope` parameter on `Set-EnvironmentVariable` and `Remove-EnvironmentVariable` with scope-specific `ForProcess`, `ForUser`, and `ForComputer` switches.

### Cryptography
 * Replaced `Protect-String`'s `Scope` parameteter with the `ForUser` or `ForComputer` scope-specific switches.

### Hosts File
 * `Set-HostsEntry` no longer throws an exception if the hosts file contains an invalid line.  Instead, a warning is written and the line is commented out.

### INI
 * `Split-Ini` now returns strongly-typed `Carbon.Ini.IniNode` objects instead of hashtables.
 * The line numbers returned by `Split-Ini` start at 1 instead of 0.
 * `Split-Ini` now returns name/value objects by default (the `PassThru` switch is no longer needed for this behaviro).  This makes it more PowerShell-y.  The old behavior of returning a `Hashtable` is available be using the new `AsHashtable` switch.

### IIS
 * Replaced `Set-IisAnonymousAuthentication` with `Enable-IisSecurityAuthentication` and `Disable-IisSecurityAuthentication`.
 * Replaced `Set-IisBasicAuthentication` with `Enable-IisSecurityAuthentication` and `Disable-IisSecurityAuthentication`.
 * Moved code to enable/disable Windows authentication from `Set-IisWindowsAuthentication` to  `Enable-IisSecurityAuthentication` and `Disable-IisSecurityAuthentication`.
 * Switched the default behavior of `Set-IisWindowsAuthentication` to enable kernel mode.  To disable kernel mode, use the `DisableKernelMode` switch.
 * Renamed `Unlock-IisConfigSection` to `Unlock-IisConfigurationSection`.
 * Removed `Unlock-IisConfigurationSection`'s `Name` parameter and replaced it with `SectionPath`, which takes a list of full path to the configuration section(s) to unlock.
 * Removed `Unlock-IisBasicAuthentication` in favor of `Unlock-IisConfigurationSection -SectionPath 'system.webServer/security/authentication/basicAuthentication'`.
 * Removed `Unlock-IisCgi` in favor of `Unlock-IisConfigurationSection -SectionPath 'system.webServer/cgi'`.
 * Removed `Unlock-IisWindowsAuthentication` in favor of `Unlock-IisConfigurationSection -SectionPath 'system.webServer/security/authentication/windowsAuthentication'`.
 * Renamed `Remove-Service` to `Uninstall-Service` (added backwards-compatible alias in v0.5.0.1).
 * `Install-Service` writes errors instead of throwing exceptions.
 * `Install-Service` grants `ReadAndExecute` file system permissions on the service executable to the service identity instead of `FullControl`.
 * Improved `Install-Service`'s `WhatIf` support.
 * Renamed `Test-IisAppPoolExists` to `Test-IisAppPool` (added backwards-compatible alias in v0.5.0.1).
 * Renamed `Remove-IisWebsite` with `Uninstall-IisWebsite` (added backwards-compatible alias in v0.5.0.1).
 * `Install-IisAppPool` now always sets the application pool to run as the system's default application pool identity if the `ServiceAccount` parameter isn't given.
 * `Install-IisAppPool` now starts an IIS application pool if it is stoppped.
 * `Get-IisHttpRedirect` now returns a `Carbon.Iis.HttpRedirectConfigurationSection` object.  The `StatusCode` property on the old object is now named `HttpResponseStatus`.
 * Renamed the `StatusCode` parameter on `Set-IisHttpRedirect` to `HttpResponseStatus` (added backwards-compatible alias in v0.5.0.1).
 * `Get-IisWebsite` now returns a `Microsoft.Web.Administration.Site` object.

### MSMQ
 * Renamed `Remove-MsmqMessageQueue` to `Uninstall-MsmqMessageQueue` (added backwards compatible alias in v0.5.0.1).

### Path
 * Renamed `Get-PathRelativeTo` to `Resolve-RelativePath`.  Renamed its `To` parameter to `Path`, and moved it to position 0.  Replaced/combined the `From` and `FromType` parameters with `FromDirectory` and `FromFile` parameters.
 * Renamed `ConvertTo-FullPath` to `Resolve-FullPath` (added backwards-compatible alias in v0.5.0.1).  Added support for converting unrooted paths using the current location.
 * Renamed `Get-PathCanonicalCase` with `Resolve-PathCase` (added backwards-compatible alias in v0.5.0.1).  Added support for piping in `Get-Item` and `Get-ChildItem` output, e.g. `Get-Item C:\WINDOWS | Resolve-PathCase` returns C:\Windows.

### Performance Counters
 * `Get-PerformanceCounters` now returns nothing/`null` or a single object instead of an empty/single element array when there are no or one performance counters.
 * `Install-PerformanceCounter` no longer re-installs a counter if a counter with its name, description, and type already exist.

### PowerShell
 * `Get-TrustedHosts` now returns nothing/`null` if there are no trusted hosts.  (It used to return an empty array.)

### Security
 * `Assert-AdminPrivileges` no longer throws an exception if the user doesn't have administrative privileges.  Instead, it writes an error and returns `False`.  It returns `True` if the user has privileges.
 * Renamed `Unprotect-AclAccessRules` to `Protect-Acl` (added backwards-compatible alias in v1.0.0).

### Shares
 * Replaced the `Permissions` parameter on `Install-SmbShare` with `FullAccess`, `ChangeAccess`, and `ReadAccess` parameters. Previously, to set share permissions, you passed in specially-formatted values to the `Permission` parameter, e.g. `"MyGroup,FULL","MyOtherGroup,READ"`.  Now, just pass a list of identity name(s) to the `FullAccess`, `ChangeAccess`, or `ReadAccess` parameters to grant those identies full, change, or read access, e.g. `-FullAccess MyGroup -ReadAccess MyOtherGroup`.

### Users and Groups
 * Renamed `Remove-User` to `Uninstall-User` (added backwards-compatible alias in v0.5.0.1).

### Windows Features
 * `Test-WindowsFeature` now tests if a Windows feature exists, instead of if it is installed.  Added an `Installed` switch to detect if a feature exists *and* if it is installed.
 * Renamed `Install-WindowsFeatures` to `Install-WindowsFeature` (added backwards-compatible alias in v0.5.0.1).
 * Renamed `Install-WindowsFeature`'s `Features` parameter to `Name` (added backwards-compatible alias in v0.5.0.1).
 * Removed `Install-WindowsFeatureIis` and replaced with `Iis` and `IisHttpRedirection` switches on `Install-WindowsFeature`.
 * Removed `Install-WindowsFeatureMsmq` and replaced with `Msmq`, `MsmqHttpSupport`, and `MsmqActiveDirectoryIntegration` switches on `Install-WindowsFeature`.
 * Renamed `Uninstall-WindowsFeatures` to `Uninstall-WindowsFeature` (added backwards-compatible alias in v0.5.0.1).
 * Renamed `Uninstall-WindowsFeature`'s `Features` parameter to `Name` (added backwards-compatible alias in v0.5.0.1).
 * Added `Iis`, `IisHttpRedirection`, `Msmq`, `MsmqHttpSupport`, and `HttpActiveDirectoryIntegration` switches to `Uninstall-WindowsFeature`.
 * `Install-WindowsFeature`, `Test-WindowsFeature`, and `Uninstall-WindowsFeature` are now available even if the current operating system doesn't support managing Windows features.  They don't do anything in those situations, but they exist.
 * `Install-WindowsFeature`, `Test-WindowsFeature`, and `Uninstall-WindowsFeature` are not available if the PowerShell v3.0 server manager cmdlets exists (on Windows 8/2012).

### Miscellaneous
 * Replaced all instances where functions were throwing exceptions with `Write-Error`.
 * The Carbon assembly is now versioned and signed.


# 0.4.0.1 (18 December 2012)

## Bug fixes
 * `Enable-IisSsl` not setting SSL flags correctly when requiring client certificates.


# 0.4.0.0 (17 November 2012)

## Upgrade Instructions
 * If you install a manual or disabled Windows service with `Install-Service`, you now have to call `Start-Service` yourself.  `Install-Service` only starts services whose startup type is set to `Automatic` (which is the default).
 * We've stopped distributing Microsoft's `subinacl.exe` program. We didn't have permission to distribute.  Plus its no longer supported. If any of your scripts used `Invoke-SubInAcl`, you'll want to [download `subinacl.exe` yourself](http://www.microsoft.com/en-us/download/details.aspx?id=23510) and copy `Invoke-SubInAcl` before upgrading (you can find it in the Carbon directory in the `Services.ps1` file.
 * If you're using `Grant-Permission` without named parameters, the `Path` parameter moved from position 3 to position 1.  Re-order your parameters accordingly.
 * Rename usages of `Set-IisDirectoryBrowsing` to `Enable-IisDirectoryBrowsing`.  If you use named parameters, rename its `Directory` paremter to `Path`.
 * Replace usages of `Set-HgrcDefaultPushUrl` with `Set-IniEntry` instead, e.g. `Set-IniEntry -Path 'Path\to\repo\.hg\hgrc' -Section paths -Name 'default.push' -Value 'DefaultPushUrl'`
 * Rename usages of `Get-FullPath` with `ConvertTo-FullPath`.

## Enhancements

 * Created `Get-Privileges`, `Grant-Privilege`, `Revoke-Privilege`, and `Test-Privilege` for managing an identity's security operation privileges.
 * `Install-Service` now uses `Grant-Privilege` to grant custom service identities the `SeServiceLogonRight` privilege. This replaces usage of Microsoft's legacy [ntrights.exe](http://support.microsoft.com/kb/315276), which we probably didn't have permission to distribute.
 * Created `Get-ServicePermissions` function for getting the permissions for a service, i.e. what users can control a service.
 * Created `Assert-Service` function to write an error if a service doesn't exist.
 * Created `Get-ServiceAcl` function to get the discretionary access control list (DACL) for a service.
 * Created `Get-ServiceSecurityDescriptor` function to get the raw security descriptor for a service.
 * Created `Grant-ServicePermission` function to grant service control permissions to an identity.
 * Created `Revoke-ServicePermission` function to revoke all of an identity's permissioms to control a service.
 * Created `Set-ServiceAcl` function to set a service's discretionary access control list (DACL).
 * Created `Test-Service` function to check if a service exists *without* writing an error.
 * Removed `Invoke-SubInAcl` function and the `subinacl.exe` program.  Use the `Grant-ServicePermission` and `Revoke-ServicePermission` functions instead.  If you still need `subinacl.exe`, please [download it from Microsoft](http://www.microsoft.com/en-us/download/details.aspx?id=23510).
 * `Grant-Permissions` now supports controlling inheritance and propagation flags via the `ApplyTo` parameter, which should be a value of the new `Carbon.Security.ContainerInheritanceFlags` enumeration, which encapsualtes all the valid combinations of inheritance/propagation flags.  See the help for `Grant-Permissions` for more information.  Thanks to Jonathan Valdez for the feature request and initial code.
 * Created `ConvertTo-InheritanceFlags` function for converting a `Carbon.Security.ContainerInheritanceFlags` to the necessary/applicable `System.Security.AccessControl.InheritanceFlags`.
 * Created `ConvertTo-PropagationFlags` function for converting a `Carbon.Security.ContainerInheritanceFlags` to the necessary/applicable `System.Security.AccessControl.PropagationFlags`.
 * Created `Get-Permissions` function for getting the non-inherited permissions on a file, directory, registry key, or registry value with the ability to return a specific identity's permissions and/or inherited permissions.
 * Renamed `Set-IisDirectoryBrowsing` to `Enable-IisDirectoryBrowsing` and renamed its `Directory` parameter to `Path`.
 * Removed `Set-HgrcDefaultPushUrl`.  Use `Set-IniEntry` instead.
 * Renamed `Test-IisWebsiteExists` to `Test-IisWebsite` to adhere to PowerShell naming conventions (added backwards-compatible alias in v1.0.0).
 * Renamed `Get-FullPath` to `ConvertTo-FullPath` to adhere to PowerShell naming conventions.

## Bug fixes
 * `Install-Service` no longer tries to start a service if its `StartupType` is set to `Manual` or `Disabled`.
 * `Path` is now the first parameter to `Grant-Permissions` (it was the third) to match PowerShell standards/patterns.
 * `Find-ADUser` writes an error and returns null instead of throwing an exception.


# 0.3.1.0 (29 October 2012)

## Enhancements
 * Improved `Disable-IEEnhancedSecurityConfiguration` and `Enable-IEActivationPermissions` for enabling Internet Explorer to run headless by non-priveleged users.
 * Changed the way `Invoke-WindowsInstaller` waits for MSI to finish installing: instead of searching for any MSI process, it now searches for an MSI process that is a child of the current PowerShell process.
 * Simplified how `Add-GroupMembers` adds group members.
 * The version number in the module manifest now gets updated correctly for each release.  You should now be able to tell what version you're running by looking in `Carbon\Carbon.psd1`, or, if Carbon is imported in your console, running `Get-Module Carbon | Select-Object Version`.
 * Created `Get-ComPermissions` function for getting COM Access or Launch and Activation Permissions.  These are the permissions you see in Component Services (i.e. dcomcnfg) when you right-click `My Computer`, select `Properties`, click the `COM Security` tab then click the `Edit Default..` or `Edit Limits...` buttons under **Access Permissions** or **Launch and Activation Permissions**, respectively.
 * Created `Grant-ComPermissions` for granting COM Access and/or Launch and Activation permissions.
 * Created `Revoke-ComPermissions` for revoking COM Access and/or Launch and ACtivation permissions.
 * Created `Test-Identity` function for testing if user or group exists on the local computer or in a domain.
 * Created `Resolve-IdentityName` function for determinig a user/group's canonical name.  For example, it converts `Administrators` into `BUILTIN\Administrators`.
 * Improved the way the Windows Features functions detect the best way to manage Windows features.  The old way would write an error to the error stream, which bubbled up at weird times and made diagnosing real errors harder.
 * Added a `Quiet` parameter to `Set-RegistryKeyValue` so that `Write-Host` output is muffled.
 * Created `Reset-MsmqQueueManagerID` function, which resets MSMQ's Queue Manager ID.


# 0.3.0 (28 September 2012)

## Upgrade Instructions

This release contains backwards-**incompatible** changes to the following functions:

 * `Set-IisSslFlags`
 * `Set-TrustedHosts`
 * `Invoke-PowerShell`

### Set-IisSslFlags

This function was renamed to `Enable-IisSsl`.  Its `Enable128BitSsl` parameter was renamed to `Require128BitSsl`.

Configuring client certificates is now a little stricter/clearer.  You can no longer specify both `AcceptClientCertificates` and `RequireClientCertificates`.  Also, if you specify `RequireClientCertificates`, you must now also supply the `RequireSsl` switch (before, setting the `RequireClientCertificates` switch implicitly set the `RequireSsl` switch).

### Set-TrustedHosts

Make sure you're not calling `Set-TrustedHosts` with an empty array/value for the `Entries` parameter.  The function now throw an error in that situation.  If you need to clear the list of trusted hosts, use `Clear-TrustedHosts`.

### Invoke-PowerShell

If you call `Invoke-PowerShell` without the `x86` switch and PowerShell is 32-bit, you'll get an error.  Under Windows x64, 32-bit PowerShell can't start the 64-bit instance because Windows redirects all access from C:\Windows\system32 to C:\Windows\SysWOW64.  If anyone knows how to get around this, let me know!

## Enhancements
 * Renamed `Set-IisSslFlags` to `Enable-IisSsl` to better reflect what it does.  Also, created parameter sets around client certificate settings so you can't configure them incorrectly.  ([Fixes #25: Set-IisSslFlags: Create parameter sets to accurately reflect what flags are allowed to be set simultaneously.](https://bitbucket.org/splatteredbits/carbon/issue/25/set-iissslflags-create-parameter-sets-to))
 * Added `WhatIf` support to `Install-MsmqMessageQueue`.
 * Created new `Clear-TrustedHosts` for clearing PowerShell's trusted hosts list.

## Bug Fixes
 * Rename `Enable-IisSsl/Set-IisSslFlags's` `Enable128BitSsl` parameter to `Require128BitSsl`] ([Fix #24 Set-IisSslFlags: Rename the Enable128BitSsl parameter to Require128BitSsl](https://bitbucket.org/splatteredbits/carbon/issue/24/set-iissslflags-rename-the-enable128bitssl)).
 * [Fix issue #19](https://bitbucket.org/splatteredbits/carbon/issue/19/install-iisapppool-doesnt-change-an): `Install-IisAppPool` doesn't change an existing 32-bit app pool to be a 64-bit app pool.
 * [Fix issue #33](https://bitbucket.org/splatteredbits/carbon/issue/33/install-msmqmessagequeue-can-wait-forever): `Install-MsmqMessageQueue`: Can wait forever for a queue to get created.  It now waits 10 seconds.
 * [Fix issue #36](https://bitbucket.org/splatteredbits/carbon/issue/36/get-powershellpath-returns-the-wrong-path): `Get-PowerShellPath` returns the wrong path when running x86 PowerShell on x64 computers.
 * [Fix issue #37](https://bitbucket.org/splatteredbits/carbon/issue/37/invoke-powershell-should-write-an-error): `Invoke-PowerShell` should write an error when running as x86 on Windows x64 without the x86 flag (i.e. 32-bit PowerShell can't launch a 64-bit PowerShell, so throw an error in that situation).
 * [Fix issue #38](https://bitbucket.org/splatteredbits/carbon/issue/38/set-trustedhosts-passing-an-empty-value): `Set-TrustedHosts`: passing an empty value for the Entries parameter clears the hosts list.  The `Entries` parameter is now required.  To clear the trusted hosts list, use `Clear-TrustedHosts`.


# 0.2.7 (3 September 2012)

## Enhancements
 * New functions for working with the registry:
  * `Get-RegistryKeyValue`: Get a value from a registry key.
  * `Install-RegistryKey`: Create a new registry key.
  * `Remove-RegistryKeyValue`: Remove a value from a registry key.
  * `Set-RegistryKeyValue`: Set/create a value in a registry key.
  * `Test-RegistryKeyValue`: Test if a value exists in a registry key.
 * `Unprotect-AclAccessRules`: Turns off inherited access rules on an item in the file system or registry.
 * Added a `Clear` parameter to the `Grant-Permissions` function for clearing any non-inherited permissions on a file system/registry item.


# 0.2.6 (30 June 2012)

## Enhancements
 * Improved documentation for:
  * `Grant-ServiceControlPermission`
  * `Install-Service`
  * `Invoke-SubInAcl`
  * `Remove-Service`
  * `Restart-RemoteService`
  * `Install-Share`
  * `Add-GroupMembers`
  * `Get-WmiLocalUserAccount`
  * `Install-Group`
  * `Install-User`
  * `Remove-User`
  * `Test-User`
  * `Install-WindowsFeatureIis`
  * `Install-WindowsFeatureMsmq`
  * `Install-WindowsFeatures`
  * `Test-WindowsFeature`
  * `Uninstall-WindowsFeatures`
  * `Assert-FirewallConfigurable`
  * `Disable-FirewallStatefulFtp`
  * `Enable-FirewallStatefulFtp`
  * `Get-FirewallRules`
  * `Test-FirewallStatefulFtp`
  * `Find-ADUser`
  * `Format-ADSpecialCharacters`
  * `Get-Certificate`
  * `Get-CertificateStore`
  * `Set-HgrcDefaultPushUrl`
 * Help files and example scripts now included in Carbon download package.
 * Added test to help ensure all functions have proper documentation.

## Bug fixes
 * `Install-IisWebsite` now validates website bindings


# 0.2.5 (29 June 2012)

## Enhancements
 * Improved documentation for:
  * `Test-IisAppPool`
  * `Test-IisWebsiteExists`
  * `Unlock-IisBasicAuthentication`
  * `Unlock-IisCgi`
  * `Unlock-IisConfigSection`
  * Import-Carbon.ps1
  * `Set-IniEntry`
  * `Split-Ini`
  * `Set-HgrcDefaultPushUrl`
  * `Get-MsmqMessageQueue`
  * `Get-MsmqMessageQueuePath`
  * `Grant-MsmqMessageQueuePermissions`
  * `Install-Msmq`
  * `Install-MsmqMessageQueue`
  * `Remove-MsmqMessageQueue`
  * `Test-MsmqMessageQueue`
  * `Get-PerformanceCounters`
  * `Install-PerformanceCounter`
  * `Test-PerformanceCounter`
  * `Test-PerformanceCounterCategory`
  * `Uninstall-PerformanceCounterCategory`
  * `Complete-Jobs`
  * `Get-PowershellPath`
  * `Invoke-PowerShell`
  * `Test-PowerShellIs32Bit`
  * `Test-PowerShellIs64Bit`
  * `Add-TrustedHosts`
  * `Get-TrustedHosts`
  * `Set-TrustedHosts`
  * `Assert-AdminPrivileges`
  * `Convert-SecureStringToString`
  * `Grant-Permissions`
  * `New-Credential`
  * `Test-AdminPrivileges`
* Improved whitespace in HTML documentation code samples.


# 0.2.4 (28 June 2012)

## Enhancements
 * Improved documentation for:
  * Get-PathCanonicalCase
  * Get-PathRelativeTo
  * New-Junction
  * New-TempDir
  * Remove-Junction
  * Test-PathIsJunction
  * Reset-HostsFile
  * Set-HostsEntry
  * Add-IisDefaultDocument
  * Get-IisHttpRedirect
  * Get-IisVersion
  * Get-IisWebsite
  * Install-IisApplication
  * Install-IisAppPool
  * Install-IisVirtualDirectory
  * Install-IisWebsite
  * Invoke-AppCmd
  * Remove-IisWebsite
  * Set-IisAnonymousAuthentication
  * Set-IisBasicAuthentication
  * Set-IisDirectoryBrowsing
  * Set-IisHttpRedirect
  * Set-IisSslFlags
  * Set-IisWebsiteSslCertifiate
  * Set-IisWindowsAuthentication


# 0.2.3 (27 June 2012)

## Enhancements
 * Improved documentation for:
  * Disable-IEEnhancedSecurityConfiguration
  * Enable-IEActivationPermissions
  * Get-FullPath
  * Invoke-WindowsInstaller
  * Protect-String
  * Remove-EnvironmentVariable
  * Set-DotNetAppSetting
  * Set-DotNetConnectionString
  * Set-EnvironmentVariable
  * Test-OSIs32Bit
  * Test-OSIs64Bit
  * Unprotect-String

## Bug fixes
 * Invoke-WindowsInstaller doesn't validate that installer path ends in '.msi'.
 * Invoke-WindowsInstaller not showing correct exit code when installation fails.


# 0.2.2 (19 June 2012)

## Enhancements
 * Created Import-Carbon script to help users properly import Carbon.

## Bug fixes
 * Add-GroupMembers fails to add Administrators and ANONYMOUS LOGON built-in accounts.
 * Add-GroupMembers fails when adding built-in accounts multiple times.
 * Add-GroupMembers fails to add domain user to a local group.


# 0.2.1 (28 April 2012)
 * Added IsJunction property to DirectoryInfo objects.  Returns true if a directory is a junction/reparse point.
 * Created a Carbon assembly for compiled code.  Moved P/Invoke functions from FileSystem.ps1 into assembly.  This is a backwards compatible change.
 * Created a Carbon.IO.JunctionPoint helper class for creating/removing/getting junction/reparse points.  Updated New-Junction and Remove-Junction to use the new helper class.
 * Added TargetPath property to DirectoryInfo objects.  If the directory is a junction/reparse points, returns the path to the junction's target.  Otherwise, $null.


# 0.2.0 (4 April 2012)

## Enhancements
  * fix issue #3: Added -Runtime switch to Invoke-PowerShell function for running PowerShell under .NET 2.0 or 4.0.  Valid values are 'v2.0' (for .NET 2) and 'v4.0' (for .NET 4).
  * **BREAKING CHANGE:** Added -Clr2 and -Clr4 switches to Set-DotNetAppSetting and Set-DotNetConnectionString functions for modifying the .NET 2 and/or 4 machine.config files.  One or both of these parameters is required.

## Bug fixes
  * Improved documentation for Get-ADDomainController, Get-ADUser, Format-ADSpecialCharacters, Get-Certificate, Invoke-PowerShell, Set-DotNetAppSetting, and Set-DotNetConnectionString functions.
  * fix issue #2: Get-PowerShellPath Returns Wrong Value on x86 Systems


# 0.1.0 (2 April 2012):
 * First packaged release.

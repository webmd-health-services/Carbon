# TOPIC

about\_Carbon

# SHORT DESCRIPTION

Carbon is a PowerShell module for automating the configuration of computers running Windows 2008, 2008 RS and 7.    


# LONG DESCRIPTION

Carbon is a DevOps PowerShell module for automating the configuration of Windows 2008, Windows 2008 R2, 7, 2012, and 2012 R2 computers. Carbon can configure and manage:

 * Local users and groups
 * IIS websites, virtual directories, and applications
 * Certificates
 * .NET connection strings and app settings
 * Junctions
 * File system permissions
 * Hosts file
 * INI files
 * Performance counters
 * Services
 * Shares
 * Windows features/components

And much more!


## System Requirements

Carbon's automated test suite runs in the following environment:

 * PowerShell v3.0
 * .NET Framework v4.5
 * Windows 2008 R2 (x64)/Windows 7 (x64)

But it should support PowerShell 2 and 3 running on Windows Server 2008/2008 R2/2012/2012 R2 and Windows 7/8/8.1.

To get help, [send an e-mail to the Carbon mailing list](mailto:carbon@freelist.org).


## Installation

 1. Download the latest release.
 2. Unblock the .zip file (right-click it, choose "Properties", click "Unblock", then click "OK").
 3. Unzip the Carbon module anywhere on your file system. Import the module by running the `Import-Carbon.ps` script:
        
        > & 'Path\To\Carbon\Directory\Import-Carbon.ps1' 
    
    Replace `Path\To\Carbon\Directory` with the actual path where you unzipped Carbon.

    If you don't want to worry about remembering/finding the path to Carbon, put the Carbon directory into one of the following directories:

        Join-Path -Path $PSHOME -ChildPath Modules
        Join-Path -Path $env:USERPROFILE -ChildPath Documents\WindowsPowerShell\Modules

    Then, you can simply

        > Import-Module Carbon 


## Usage

If importing Carbon in a script, we recommend always using relative paths to create a full path to Import-Carbon.ps1. This makes your scripts portable. You can get the directory in which the current script is executing, and use that to get the path to Carbon, like this:

    # You only need this line for PowerShell 2:
    $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
    & (Join-Path -Path $PSScriptRoot -ChildPath ..\Tools\Carbon\Import-Carbon.ps1 -Resolve) 

To get a list of all commands imported by Carbon:

    > Get-Command | Where-Object { $_.ModuleName -eq 'Carbon' }

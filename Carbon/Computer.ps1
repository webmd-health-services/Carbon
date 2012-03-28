# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Disable-IEEnhancedSecurityConfiguration
{
 	<#
    .SYNOPSIS
    Disables the Internet Explorer Enhanced Security Configuration. 
	This is neccessary to run QUnit tests.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
 	param()
    $regPathAdmin = "HKLM:SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $regPathUser = "HKLM:SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    
    if(-not (Test-Path -Path $regPathAdmin))
    {
        Write-Warning "Could not find the registry path for admins $regPathAdmin). Aborting"
        return
         
	}
	
    if(-not (Test-Path -Path $regPathUser))
    {
        Write-Warning "Could not find the registry path for users ($regPathUser). Aborting"
        return
         
	}
    if( $pscmdlet.ShouldProcess( "Set Registry Information" ) )
    {
        Set-ItemProperty  $regPathAdmin -name "IsInstalled" -value 0 
        Set-ItemProperty  $regPathUser -name "IsInstalled" -value 0
    }
    if( $pscmdlet.ShouldProcess("iesetup.dll", "Call dll reg methods" ) )
    {
    
        Rundll32 iesetup.dll, IEHardenLMSettings
        Rundll32 iesetup.dll, IEHardenUser
        Rundll32 iesetup.dll, IEHardenAdmin 
        
    }
    
}

function Enable-IEActivationPermissions
{
    $sddlForIe =   "O:BAG:BAD:(A;;CCDCSW;;;SY)(A;;CCDCLCSWRP;;;BA)(A;;CCDCSW;;;IU)(A;;CCDCLCSWRP;;;S-1-5-21-762517215-2652837481-3023104750-5681)"
    $binarySD = ([wmiclass]"Win32_SecurityDescriptorHelper").SDDLToBinarySD($sddlForIE)
    $ieRegPath = "hkcr:\AppID\{0002DF01-0000-0000-C000-000000000046}"
    $ieRegPath64 = "hkcr:\Wow6432Node\AppID\{0002DF01-0000-0000-C000-000000000046}"

    if(-not (Test-Path "HKCR:\AppID"))
    {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    }

    if(-not (Test-Path $ieRegPath))
    {
       New-Item $ieRegPath
       New-ItemProperty $ieRegpath "(default)" -value "Internet Explorer(Ver 1.0)" -PropertyType Binary
    }

    if(-not (Test-Path $ieRegPath64))
    {
       New-Item $ieRegPath64
       New-ItemProperty $ieRegPath64 "(default)" -value "Internet Explorer(Ver 1.0)" -PropertyType Binary
    }
 
    Set-ItemProperty $ieRegPath "LaunchPermission" ([byte[]]$binarySD.binarySD)
    Set-ItemProperty $ieRegPath64 "LaunchPermission" ([byte[]]$binarySD.binarySD)

}

function Invoke-WindowsInstaller
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        # The installer to run.
        $Path,
        
        [Switch]
        # Runs the installer in quiet mode.
        $Quiet
    )
    
    if( -not (Test-Path $Path -PathType Leaf) )
    {
        Write-Error "Installer '$Path' doesn't exist."
        return
    }
    
    # There is an MSI service that is continually running.  We need to wait for the installer to finish before continuing,
    # so we find the msiexec process that *isn't* the service.
    $msiServerPid = -1
    $msiServer = (Get-WmiObject Win32_Service -Filter "Name='msiserver'")
    if( $msiServer )
    {
        $msiServerPid = $msiServer.ProcessId
    }
    
    if( $pscmdlet.ShouldProcess( $Path, "install" ) )
    {
        Write-Host "Installing '$Path'."
        msiexec.exe /i $Path /quiet
        $msiProcess = Get-Process -Name msiexec -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $msiServerPid }
        if( $msiProcess )
        {
            $msiProcess.WaitForExit()
            if( $msiProcess.ExitCode -ne $null -and $msiProcess.ExitCode -ne 0 )
            {
                Write-Error "Installation failed (msiexec returned '$LastExitCode')."
            }
        }
    }
}

function Remove-EnvironmentVariable
{
    <#
    .SYNOPSIS
    Removes an environment variable.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        # The environment variable to remove
        $Name,
        [Parameter(Mandatory=$true)]
        # The target where the variable should be removed.
        [EnvironmentVariableTarget]
        $Scope
    )
    
    if( $pscmdlet.ShouldProcess( "$Scope-level environment variable '$Name'", "remove" ) )
    {
        [Environment]::SetEnvironmentVariable( $Name, $null, $Scope )
    }
}

function Set-EnvironmentVariable
{
    <#
    .SYNOPSIS
    Creates or sets an environment variable.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        # The name of environment variable to add/set.
        $Name,
        
        [Parameter(Mandatory=$true)]
        # The environment variable's value.
        $Value,
        
        [Parameter(Mandatory=$true)]
        # The target where the variable should be added/set.
        [EnvironmentVariableTarget]
        $Scope
    )
    
    if( $pscmdlet.ShouldProcess( "$Scope-level environment variable '$Name'", "set") )
    {
        [Environment]::SetEnvironmentVariable( $Name, $Value, $Scope )
    }
    
}


function Test-OSIs32Bit
{
    <#
    .SYNOPSIS
    Tests if the current operating system is 32-bit.
    #>
    [CmdletBinding()]
    param(
    )
    
    return -not (Test-OSIs64Bit)
}

function Test-OSIs64Bit
{
    <#
    .SYNOPSIS
    Tests if the current operating system is 64-bit.
    #>
    [CmdletBinding()]
    param(
    )
    
    return (Test-Path env:"ProgramFiles(x86)")
}

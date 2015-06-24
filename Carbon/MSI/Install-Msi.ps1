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

function Invoke-WindowsInstaller
{
    <#
    .SYNOPSIS
    Runs an MSI installer.

    .DESCRIPTION
    There are two problems running an MSI (for MicroSoft Installer):
    
     * The installer runs asynchronously, which means running/invoking it returns immediately, with no notification about whether it succeeded or failed.
     * A UI is shown.
    
    This function will run an MSI installer and wait for the MSI to finish.  If the install process returns a non-zero exit code, an error will be written.
    
    You can optionally run the installer in quiet mode.  This hides any installer UI and installs the package with the default options.
    
    .EXAMPLE
    Invoke-WindowsInstaller -Path Path\to\installer.msi
    
    Runs installer.msi, and waits untils for the installer to finish.  If the installer has a UI, it is shown to the user.
    
    .EXAMPLE
    Invoke-WindowsInstaller -Path Path\to\installer.msi -Quiet
    Runs installer.msi without showing its UI (i.e. performs a silent install using the package's default options).
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The installer to run.
        $Path,
        
        [Switch]
        # Runs the installer in quiet mode.
        $Quiet
    )

    Set-StrictMode -Version 'Latest'
    
    if( -not (Test-Path $Path -PathType Leaf) )
    {
        Write-Error "Installer '$Path' not found."
        return
    }
    
    if( $Path -notlike '*.msi' )
    {
        Write-Error "Installer '$Path' not an MSI package: filename must end in .msi."
        return
    }
    
    if( $PSCmdlet.ShouldProcess( $Path, "install" ) )
    {
        msiexec.exe /i $Path /quiet
        $msiProcess = Get-Process -Name msiexec -ErrorAction SilentlyContinue | 
                        Where-Object { $_.ParentProcessId -eq [Diagnostics.Process]::GetCurrentProcess().ID }

        if( $msiProcess )
        {
            $msiProcess.WaitForExit()
            if( $msiProcess.ExitCode -ne $null -and $msiProcess.ExitCode -ne 0 )
            {
                Write-Error ("Installation of '{0}' failed (msiexec returned '{1}')." -f $Path,$msiProcess.ExitCode)
            }
        }
    }
}

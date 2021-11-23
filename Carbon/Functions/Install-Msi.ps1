
function Install-CMsi
{
    <#
    .SYNOPSIS
    Installs software from an MSI file.

    .DESCRIPTION
    `Install-CMsi` installs software from an MSI file. If the install fails, it writes an error. Installation is always done in quiet mode, i.e. you won't see any UI.

    In Carbon 1.9 and earlier, this function was called `Invoke-WindowsInstaller`.

    Beginning with Carbon 2.0, `Install-CMsi` only runs the MSI if the software isn't installed. Use the `-Force` switch to always run the installer.
    
    .EXAMPLE
    Install-CMsi -Path Path\to\installer.msi
    
    Runs installer.msi, and waits untils for the installer to finish.  If the installer has a UI, it is shown to the user.

    .EXAMPLE
    Get-ChildItem *.msi | Install-CMsi

    Demonstrates how to pipe MSI files into `Install-CMsi` for installation.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path to the installer to run. Wildcards supported.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [String[]] $Path,
        
        # OBSOLETE. Installers are run in quiet mode by default. This switch will be removed in a future major version of Carbon. 
        [Parameter(DontShow)]
        [switch] $Quiet,

        # Install the MSI even if it has already been installed. Will cause a repair/reinstall to run.
        [switch] $Force
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Windows.Installer'

    if( $PSBoundParameters.ContainsKey('Quiet') )
    {
        $msg = 'Install-CMsi''s `Quiet` switch is obsolete and will be removed in the next major version of Carbon. ' +
               'Installers are now run in quiet mode by default. Remove usages of the `Quiet` switch.'
        Write-CWarningOnce -Message $msg
    }

    Get-CMsi -Path $Path |
        Where-Object {
            if( $Force )
            {
                return $true
            }

            $installInfo = Get-CProgramInstallInfo -Name $_.ProductName -ErrorAction Ignore
            if( -not $installInfo )
            {
                return $true
            }

            $result = ($installInfo.ProductCode -ne $_.ProductCode)
            if( -not $result )
            {
                Write-Verbose -Message ('[MSI] [{0}] Installed {1}.' -f $installInfo.DisplayName,$installInfo.InstallDate)
            }
            return $result
        } |
        ForEach-Object {
            $msi = $_
            if( $PSCmdlet.ShouldProcess( $msi.Path, "install" ) )
            {
                Write-Verbose -Message ('[MSI] [{0}] Installing from {1}.' -f $msi.ProductName,$msi.Path)
                $msiProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList "/quiet","/i",('"{0}"' -f $msi.Path) -NoNewWindow -Wait -PassThru

                if( $msiProcess.ExitCode -ne $null -and $msiProcess.ExitCode -ne 0 )
                {
                    Write-Error ("{0} {1} installation failed. (Exit code: {2}; MSI: {3})" -f $msi.ProductName,$msi.ProductVersion,$msiProcess.ExitCode,$msi.Path)
                }
            }
        }
}

Set-Alias -Name 'Invoke-WindowsInstaller' -Value 'Install-CMsi'


function Install-RegistryKey
{
    <#
    .SYNOPSIS
    Creates a registry key.  If it already exists, does nothing.
    
    .DESCRIPTION
    Given the path to a registry key, creates the key and all its parents.  If the key already exists, nothing happens.
    
    .EXAMPLE
    Install-RegistryKey -Path 'hklm:\Software\Carbon\Test'
    
    Creates the `hklm:\Software\Carbon\Temp` registry key if it doesn't already exist.
    #>
    [CmdletBinding(SupportsShouldPRocess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key to create.
        $Path
    )
    
    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        Write-Host "Creating registry key '$Path'."
        New-Item -Path $Path -ItemType RegistryKey -Force
    }
}
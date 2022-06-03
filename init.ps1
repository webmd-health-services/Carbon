[CmdletBinding()]
param(
)

Set-StrictMode -Version 'Latest'
$InformationPreference = 'Continue'

# Run in a background job so that old PackageManagement assemblies don't get loaded.
$job = Start-Job {
    $InformationPreference = 'Continue'
    $psGalleryRepo = Get-PSRepository -Name 'PSGallery'
    $repoToUse = $psGalleryRepo.Name
    # On Windows 2012 R2, Windows PowerShell 5.1, and .NET 4.6.2, PSGallery's URL ends with a '/'.
    if( -not $psGalleryRepo -or $psgalleryRepo.SourceLocation -ne 'https://www.powershellgallery.com/api/v2' )
    {
        $repoToUse = 'PSGallery2'
        Register-PSRepository -Name $repoToUse `
                              -InstallationPolicy Trusted `
                              -SourceLocation 'https://www.powershellgallery.com/api/v2' `
                              -PackageManagementProvider $psGalleryRepo.PackageManagementProvider
    }

    Write-Information -MessageData 'Installing latest version of PowerShell module Prism.'
    Install-Module -Name 'Prism' -Scope CurrentUser -Repository $repoToUse -AllowClobber -Force

    if( -not (Get-Module -Name 'PackageManagement' -ListAvailable | Where-Object 'Version' -eq '1.4.7') )
    {
        Write-Information -MessageData 'Installing PowerShell module PackageManagement 1.4.7.'
        Install-Module -Name 'PackageManagement' -RequiredVersion '1.4.7'-Repository $repoToUse -AllowClobber -Force
    }

    if( -not (Get-Module -Name 'PowerShellGet' -ListAvailable | Where-Object 'Version' -eq '2.2.5') )
    {
        Write-Information -MessageData 'Installing PowerShell module PowerShellGet 2.2.5.'
        Install-Module -Name 'PowerShellGet' -RequiredVersion '2.2.5' -Repository $repoToUse -AllowClobber -Force
    }
}

if( (Get-Command -Name 'Receive-Job' -ParameterName 'AutoRemoveJob') )
{
    $job | Receive-Job -AutoRemoveJob -Wait
}
else
{
    $job | Wait-Job | Receive-Job
    $job | Remove-Job
}
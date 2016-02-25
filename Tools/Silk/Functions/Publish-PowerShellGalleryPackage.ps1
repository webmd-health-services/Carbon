#>
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

function Publish-PowerShellGalleryModule
{
    <#
    .SYNOPSIS
    Publishes a module to the PowerShell gallery.

    .DESCRIPTION
    The `Publish-PowerShellGalleryModule` functin publishes a module to the PowerShell Gallery. If the given version of the module already exists in the Gallery, a warning is written and no other work is done.

    If you don't supply a PowerShell Gallery API key via the `ApiKey` parameter, you'll be prompted for it.

    Returns a `PSGetItemInfo` object if the module gets published (the object returned by the `Find-Module` cmdlet). If the version of the module already exists in the Gallery, you'll get a warning that the module has already been published.

    This function requires the `PowerShellGet` module. If it isn't available, you'll get an error.

    .OUTPUTS
    PSGetItemInfo

    .EXAMPLE
    Publish-PowerShellGalleryModule -Name 'Carbon' -Version '2.0.0' -LicenseUri ''http://www.apache.org/licenses/LICENSE-2.0'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # Path to the module's manifest.
        $ManifestPath,

        [Parameter(Mandatory=$true)]
        [string]
        # The path to the module.
        $ModulePath,

        [Parameter(Mandatory=$true)]
        [string]
        # The release notes.
        $ReleaseNotesPath,

        [string]
        # The name of the module being published. Defaults to the name in the module manifest.
        $Name,

        [string]
        # The API key for the PowerShell Gallery.
        $ApiKey,

        [Parameter(Mandatory=$true)]
        [string]
        # The URL to the module's license.
        $LicenseUri,

        [string[]]
        # Any tags for the module.
        $Tags,

        [string]
        # The URL to the project's home page.
        $ProjectUri
    )

    Set-StrictMode -Version 'Latest'

    $manifest = Test-ModuleManifest -Path $ManifestPath
    if( -not $manifest )
    {
        return
    }

    if( -not $Name )
    {
        $Name = $manifest.Name
    }

    if( Get-Module -ListAvailable -Name 'PowerShellGet' )
    {
        if( -not (Find-Module -Name $Name -RequiredVersion $manifest.Version -Repository 'PSGallery' -ErrorAction Ignore) )
        {
            $releaseNotes = Get-ModuleReleaseNotes -ManifestPath $ManifestPath -ReleaseNotesPath $ReleaseNotesPath
            Write-Verbose -Message ('Publishing to PowerShell Gallery.')
            if( -not $ApiKey )
            {
                $ApiKey = Read-Host -Prompt ('Please enter PowerShell Gallery API key')
            }

            Publish-Module -Path $ModulePath `
                           -Repository 'PSGallery' `
                           -NuGetApiKey $ApiKey `
                           -LicenseUri $LicenseUri `
                           -ReleaseNotes $releaseNotes `
                           -Tags $Tags `
                           -ProjectUri $ProjectUri

            Find-Module -Name $Name -RequiredVersion $manifest.Version -Repository 'PSGallery'
        }
        else
        {
            Write-Warning -Message ('{0} {1} already exists in the PowerShell Gallery.' -f $Name,$manifest.Version)
        }
    }
    else
    {
        Write-Error -Message ('Unable to publish to PowerShell Gallery: PowerShellGet module not found.')
    }

}
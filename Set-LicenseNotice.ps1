<#
.SYNOPSIS
Adds the license notice to a set of files.

.DESCRIPTION
Given a path, or a pipeline of files, will add or update the Apache license notice to the top of it.  The notice is pulled from a LICENSE file, which is expected to live next to this file.

.EXAMPLE
>dir .\Carbon,.\Test *ps*1 -Recurse | .\Set-LicenseNotice.ps1 -Copyright '2012 Aaron Jensen' 

Adds or updates the license notice on all the *.ps*1 files under the .\Carbon and .\Test directories.

.EXAMPLE
> .\Set-LicenseNotice.ps1 -Path .\Test\Test-LicenseNotices.ps1 -Copyright '2012 Aaron Jensen'

Adds or updates the license notice in the .\Test\Test-LicenseNotices.ps1 file.
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

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true,ParameterSetName='FromUser')]
    # Path to the file whose license to set.
    $Path,
    
    [Parameter(Mandatory=$true,ParameterSetName='FromPipeline',ValueFromPipeline=$true)]
    # The files whose licenses should be set.
    $InputObject,
    
    [Parameter(Mandatory=$true)]
    [string]
    # The copyright string, i.e. everything after the word "Copyright".
    $Copyright
)

begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

    $noticeLines = New-Object Collections.Generic.List[string]

    $licenseFilePath = JOin-Path $PSScriptRoot LICENSE -Resolve
    $foundNotice = $false
    Get-Content $licenseFilePath | ForEach-Object {
        if( $_ -eq '   Copyright [yyyy] [name of copyright owner]' )
        {
            $noticeLines.Add( '# Copyright ' + $Copyright )
            $foundNotice = $true
            return
        }
        
        if( -not $foundNotice )
        {
            return
        }
        
        $trimmedLine = $_
        if( $_.Length -gt 3 )
        {
            $trimmedLine = $_.Substring( 3 )
        }
        $noticeLines.Add( '# ' + $trimmedLine )
    }

}

process
{
    $filePath = ''
    if( $pscmdlet.ParameterSetName -eq 'FromUser' )
    {
        $filePath = $Path
    }
    elseif( $pscmdlet.ParameterSetName -eq 'FromPipeline' )
    {
        $filePath = Select-Object -InputObject $_ -Property FullName
        if( $filePath.FullName )
        {
            $filePath = $filePath.FullName
        }
    }
    
    if( -not (Test-Path -Path $filePath -PathType Leaf) )
    {
        Write-Warning "Unable to add license to '$filePath': not a file."
        return
    }
    
    $fileContents = Get-Content -Path $filePath
    $file = ($fileContents[1..$fileContents.Length]) -join "`n"
    $notice = $noticeLines.GetRange(1, $noticeLines.Count - 1) -join "`n"
    if( $file.StartsWith( $notice ) )
    {
        $fileContents = $fileContents[$noticeLines.Count..$fileContents.Length]
    }
    $noticeLines | Out-File -FilePath $filePath -Encoding OEM
    $fileContents | Out-File -FilePath $filePath -Append -Encoding OEM
}

end
{
}
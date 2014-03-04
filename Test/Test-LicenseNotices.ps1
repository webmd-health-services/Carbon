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

function Setup
{
}

function TearDown
{
}

function Test-AllFilesShouldHaveLicense
{
    $projectRoot = Join-Path $TestDir .. -Resolve
    $licenseFilePath = Join-Path $projectRoot LICENSE.txt -Resolve
    
    $noticeLines = New-Object Collections.Generic.List[string]
    $foundNotice = $false
    
    Get-Content $licenseFilePath | ForEach-Object {
        if( $_ -eq '   Copyright [yyyy] [name of copyright owner]' )
        {
            $_ = $_ -replace '\[yyyy\]','2012'
            $_ = $_ -replace '\[name of copyright owner\]','Aaron Jensen'
            $foundNotice = $true
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
    
    $expectedNotice = $noticeLines -join "`n"
    $filesToSkip = @(
        '*\Install-Website.ps1',
        '*\Carbon\Import-Carbon.ps1',
        '*\Set-LicenseNotice.ps1',
        '*\Publish-Carbon.ps1',
        '*\Carbon\about_Carbon.help.txt',
        '*\Carbon\Carbon.types.ps1xml',
        '*\Carbon\Carbon.format.ps1xml',
		'*\examples\Initialize-BuildServer.ps1',
		'*\examples\Initialize-WebServer.ps1',
        '*\bin\Set-DotNetAppSetting.ps1',
        '*\bin\Set-DotNetConnectionString.ps1',
        '*\Tools\Blade\*'
    )
    
    $filesMissingLicense = New-Object Collections.Generic.List[string]
    
    Get-ChildItem $projectRoot *.ps*1 -Recurse | 
        Where-Object { -not $_.PsIsContainer -and $_.FullName -notmatch '\\(.hg|Tools\\Pest)\\'  } |
        Where-Object { 
            $fullName = $_.FullName
            return (-not ( $filesToSkip | Where-Object { $fullName -like $_ } ) )
        } | ForEach-Object {
            $projectFile = (Get-Content $_.FullName) -join "`n"
            if( -not $projectFile.StartsWith( $expectedNotice ) )
            {
                
                $filesMissingLicense.Add( $_.FullName.Remove( 0, $projectRoot.Length + 1 ) )
            }
        }
    
    Assert-Equal 0 $filesMissingLicense.Count "The following files are missing license notices:`n$($filesMissingLicense -join "`n")"
}

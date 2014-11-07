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

function Test-AllFilesShouldHaveLicense
{
    $projectRoot = Join-Path $TestDir .. -Resolve
    $licenseFilePath = Join-Path $projectRoot LICENSE.txt -Resolve
    
    $noticeLines = Invoke-Command {
                            'Copyright 2012 Aaron Jensen'
                            Get-Content -Path $licenseFilePath |
                                Select-Object -Last 12
                        } |
                        ForEach-Object { $_ -replace '^   ','' } |
                        Select-Object -First 13
    $noticeLines | Write-Verbose
    
    $filesToSkip = @(
                        '*.dll',
                        '*.dll-*',
                        '*.pdb',
                        '.hg*',
                        '*.user',
                        '*.zip',
                        '*.exe',
                        '*.msi',
                        '*.orig',
                        '*.snk',
                        '*.json',
                        'nunit.framework.xml',
                        '*.cer',
                        '*.md',
                        'license.txt',
                        '*.help.txt',
                        'RELEASE NOTES.txt',
                        '*.sln',
                        '*.pfx',
                        'task*.xml'
                    )
    [object[]]$filesMissingLicense = Get-ChildItem -Path $projectRoot -Exclude 'Tools','Website','.hg' |
        Get-ChildItem -Recurse -Exclude $filesToSkip |
        Where-Object { -not $_.PSIsContainer } |
        Where-Object { $_.FullName -notlike '*\obj\*' } |
        Where-Object { $name = $_.FullName ; -not ($filesToSkip | ForEach-Object { $name -like $_ }) } |
        ForEach-Object {
            $fileInfo = $_
            $file = [IO.File]::ReadAllText( $fileInfo.FullName )
            $ok = switch -Regex ( $fileInfo.Extension )
            {
                '^\.ps(m|d)*1$'
                {
                    $expectedNotice = $noticeLines -join ('{0}# ' -f ([Environment]::NewLine))
                    $expectedNotice = '# {0}' -f $expectedNotice
                    if( $file.StartsWith('<#') )
                    {
                        $file.Contains( $expectedNotice )
                    }
                    else
                    {
                        $file.StartsWith( $expectedNotice )
                    }
                    break
                }
                '^\.cs$'
                {
                    $expectedNotice = $noticeLines -join ('{0}// ' -f ([Environment]::NewLine))
                    $expectedNotice = '// {0}' -f $noticeLines
                    $file.StartsWith( $expectedNotice )
                    break
                }
                '^\.(ps1xml|csproj)$'
                {
                    $expectedNotice = $noticeLines -join ('{0}   ' -f ([Environment]::NewLine))
                    $expectedNotice = '<?xml version="1.0" encoding="utf-8"?>{0}<!--{0}   {1}{0}-->{0}' -f ([Environment]::NewLine),$expectedNotice
                    $file.StartsWith( $expectedNotice )
                    break
                }
                '^\.nuspec$'
                {
                    $expectedNotice = $noticeLines -join ('{0}   ' -f ([Environment]::NewLine))
                    $expectedNotice = '<?xml version="1.0"?>{0}<!--{0}   {1}{0}-->{0}' -f ([Environment]::NewLine),$expectedNotice
                    $file.StartsWith( $expectedNotice )
                    break
                }
                '^\.html$'
                {
                    $expectedNotice = $noticeLines -join ('{0}   ' -f ([Environment]::NewLine))
                    $expectedNotice = '<!--{0}   {1}{0}-->{0}' -f ([Environment]::NewLine),$expectedNotice
                    $file.StartsWith( $expectedNotice )
                    break
                }
                default
                {
                    Write-Verbose -Verbose $fileInfo.FullName
                    $false
                    break
                }
            }
            if( -not $ok )
            {
                $fileInfo.FullName
            }
        }
    
    if( $filesMissingLicense )
    {
        Assert-Equal 0 $filesMissingLicense.Count "The following files are missing license notices:`n$($filesMissingLicense -join "`n")"
    }
}

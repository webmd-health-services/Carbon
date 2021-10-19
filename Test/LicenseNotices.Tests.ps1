
Set-StrictMode -Version 'Latest'

Describe 'License Notices' {

    It 'all published files should have a license notice' {
        $projectRoot = Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve
        $carbonRoot = Join-Path -Path $projectRoot -ChildPath 'Carbon' -Resolve
        $licenseFilePath = Join-Path $projectRoot LICENSE.txt -Resolve
    
        $noticeLines = Get-Content -Path $licenseFilePath -Tail 11 |
                            ForEach-Object { $_ -replace '^   ','' } |
                            Select-Object -First 13
        $noticeLines | Write-Verbose
    
        [object[]]$filesMissingLicense = 
            & {
                Get-ChildItem -Path (Join-Path -Path $projectRoot -ChildPath 'Tools\*.ps1')

                Get-ChildItem -Path $projectRoot -Filter '*.nuspec'

                if( Test-Path -Path 'env:APPVEYOR' )
                {
                    Get-ChildItem -Path $carbonRoot -Recurse -File
                }
                else 
                {
                    $searchRoot = Join-Path -Path $carbonRoot -ChildPath '*'
                    Get-ChildItem -Path $searchRoot -File -Exclude 'Carbon.psm1.*'

                    Get-ChildItem -Path $carbonRoot -Directory -Exclude 'en-US','Functions' |
                        Get-ChildItem -Recurse -File

                    $functionsRoot = Join-Path -Path $carbonRoot -ChildPath 'Functions\*'
                    Get-ChildItem -Path $functionsRoot -Include 'Initialize-Lcm.ps1','Use-CallerPreference.ps1'

                    Get-ChildItem -Path $functionsRoot -Include '*-Iis*.ps1' |
                        Select-Object -First 1
                }

            } |
            Where-Object { $_.Name -notmatch '\.(deps\.json|dll|pdb|orig|txt)$' } |
            ForEach-Object {
                Write-Debug -Message $_.FullName
                $fileInfo = $_
                $file = Get-Content $fileInfo.FullName -Raw
                if( -not $file )
                {
                    $fileInfo.FullName
                    return
                }

                $ok = switch -Regex ( $fileInfo.Extension )
                {
                    '^\.ps(m|d)*1$'
                    {
                        $expectedNotice = $noticeLines | ForEach-Object { if ($_.length -gt 0) {"# $_"} else {"#"} }
                        $expectedNotice = $expectedNotice -join [Environment]::NewLine
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
                    '^\.(ps1xml)$'
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
                    '^\.mof$'
                    {
                        $expectedNotice = $noticeLines -join [Environment]::NewLine
                        $expectedNotice = '/*{0}{1}{0}*/' -f ([Environment]::NewLine),$expectedNotice
                        $file.StartsWith( $expectedNotice )
                        break
                    }
                    default
                    {
                        Write-Verbose $fileInfo.FullName
                        $false
                        break
                    }
                }
                if( -not $ok )
                {
                    Write-Debug -Message $fileInfo.FullName
                    $fileInfo.FullName
                }
            }
    
        if( $filesMissingLicense )
        {
                ,$filesMissingLicense | Should -BeNullOrEmpty
        }
    }
}

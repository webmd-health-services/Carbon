param(
)

$silkJsonPath = Join-Path -Path $PSScriptRoot -ChildPath 'silk.json' -Resolve
$silkJson = Get-Content -Path $silkJsonPath -Raw | ConvertFrom-Json

if( -not (Get-Member -InputObject $silkJson -Name 'Navigation') )
{
    Add-Member -InputObject $silkJson -MemberType NoteProperty -Name 'Navigation' -Value @{ }
}

$silkJson.Navigation = [ordered]@{ }

$moduleRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon'
$categories = Get-ChildItem -Path $moduleRoot -Directory -Exclude 'bin' | 
                Sort-Object -Property 'BaseName'

$dirNameTitleNameMap = @{
                            'ActiveDirectory' = 'Active Directory';
                            'DotNet' = '.NET';
                            'FileSystem' = 'File System';
                            'HostsFile' = 'Hosts File';
                            'InternetExplorer' = 'Internet Explorer';
                            'PerformanceCounters' = 'Performance Counters';
                            'UsersAndGroups' = 'Users and Groups';
                            'WindowsFeatures' = 'Windows Features';
                        }

foreach( $category in $categories )
{
    $categoryName = $category.Name
    if( $dirNameTitleNameMap.ContainsKey($categoryName) )
    {
        $categoryName = $dirNameTitleNameMap.$categoryName
    }
    [object[]]$categoryTopics = Get-ChildItem -Path $category.FullName -Filter '*.ps1' |
                                    Sort-Object -Property BaseName |
                                    Select-Object -ExpandProperty BaseName
    $silkJson.Navigation.$categoryName = $categoryTopics
}

$silkJson | ConvertTo-Json | Set-Content -Path $silkJsonPath
    
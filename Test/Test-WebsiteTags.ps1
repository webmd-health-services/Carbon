
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

function Test-AllFunctionShouldBeTagged
{
    $tags = Get-Content -Raw -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\tags.json' -Resolve) | ConvertFrom-Json
    $taggedCommands = @{ }
    $tags | ForEach-Object { $taggedCommands[$_.Name] = $_.Name }

    $missingCommandNames = Get-Command -Module 'Carbon' | 
                                Where-Object { $_.CommandType -ne [Management.Automation.CommandTypes]::Alias } |
                                Select-Object -ExpandProperty 'Name' | 
                                Where-Object { -not $taggedCommands.ContainsKey($_) }

    if( $missingCommandNames )
    {
        Fail @"
The following commands are missing from tags.json:

 * $($missingCommandNames -join ('{0} * ' -f [Environment]::NewLine))

"@
    }
}
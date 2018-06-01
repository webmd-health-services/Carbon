param(
    [Parameter(Mandatory=$true)]
    [string]
    # Directory where the test output files are.
    $OutputPath
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

$OutputPath = Join-Path -Path $OutputPath -ChildPath '*'

Get-ChildItem -Path $OutputPath -Include 'pester*.xml','*blade*.xml' |
    Get-Content -Raw |
    ForEach-Object { [xml]$_ } |
    ForEach-Object { 
        $_.SelectNodes('/test-results/test-suite/results/test-suite')
    } |
    Group-Object -Property { $_.GetAttribute('name') -replace '^([^. ]+)(\.|\ ).*$','$1' } |
    ForEach-Object {
        $totalTime = 0.0
        
        $testSuiteName = $_.Name
        foreach( $testSuite in $_.Group )
        {
            $time = [double]$testSuite.time
            $totalTime += $time
        }
        
        [int]$seconds = [math]::Truncate($totalTime)
        [int]$milliseconds = ($totalTime - $seconds) * 1000
        [pscustomobject]@{ 
                            Name = $testSuiteName;
                            TotalTime = $totalTime;
                            Seconds = $seconds
                            Milliseconds = $milliseconds
                            Duration = (New-Object -TypeName 'TimeSpan' -ArgumentList (0,0,0,$seconds,$milliseconds))
                        }
    } | 
    Sort-Object -Property 'Duration' -Descending |
    Format-Table -Property 'Name','Duration' -AutoSize

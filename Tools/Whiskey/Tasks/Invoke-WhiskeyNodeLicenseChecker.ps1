
function Invoke-WhiskeyNodeLicenseChecker
{
    [CmdletBinding()]
    [Whiskey.Task('NodeLicenseChecker')]
    [Whiskey.RequiresTool('Node', 'NodePath',VersionParameterName='NodeVersion')]
    [Whiskey.RequiresTool('NodeModule::license-checker', 'LicenseCheckerPath', VersionParameterName='Version')]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $licenseCheckerPath = Assert-WhiskeyNodeModulePath -Path $TaskParameter['LicenseCheckerPath'] -CommandPath 'bin\license-checker' -ErrorAction Stop

    $nodePath = Assert-WhiskeyNodePath -Path $TaskParameter['NodePath'] -ErrorAction Stop

    Write-WhiskeyTiming -Message ('Generating license report')
    $reportJson = Invoke-Command -NoNewScope -ScriptBlock {
        & $nodePath $licenseCheckerPath '--json'
    }
    Write-WhiskeyTiming -Message ('COMPLETE')

    $report = Invoke-Command -NoNewScope -ScriptBlock {
        ($reportJson -join [Environment]::NewLine) | ConvertFrom-Json
    }
    if (-not $report)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message 'License Checker failed to output a valid JSON report.'
    }

    Write-WhiskeyTiming -Message 'Converting license report.'
    # The default license checker report has a crazy format. It is an object with properties for each module.
    # Let's transform it to a more sane format: an array of objects.
    [object[]]$newReport = $report | 
                                Get-Member -MemberType NoteProperty | 
                                Select-Object -ExpandProperty 'Name' | 
                                ForEach-Object { $report.$_ | Add-Member -MemberType NoteProperty -Name 'name' -Value $_ -PassThru }

    # show the report
    $newReport | Sort-Object -Property 'licenses','name' | Format-Table -Property 'licenses','name' -AutoSize | Out-String | Write-WhiskeyVerbose -Context $TaskContext

    $licensePath = 'node-license-checker-report.json'
    $licensePath = Join-Path -Path $TaskContext.OutputDirectory -ChildPath $licensePath
    ConvertTo-Json -InputObject $newReport -Depth 100 | Set-Content -Path $licensePath
    Write-WhiskeyTiming -Message ('COMPLETE')
}

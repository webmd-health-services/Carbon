
function Invoke-WhiskeyPester3Task
{
    [Whiskey.Task('Pester3')]
    [Whiskey.RequiresTool('PowerShellModule::Pester','PesterPath',Version='3.*',VersionParameterName='Version')]
    [CmdletBinding()]
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

    if( -not ($TaskParameter.ContainsKey('Path')))
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Element ''Path'' is mandatory. It should be one or more paths, which should be a list of Pester Tests to run with Pester3, e.g. 
        
        Build:
        - Pester3:
            Path:
            - My.Tests.ps1
            - Tests')
    }

    $path = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'
    
    $outputFile = Join-Path -Path $TaskContext.OutputDirectory -ChildPath ('pester+{0}.xml' -f [IO.Path]::GetRandomFileName())

    # We do this in the background so we can test this with Pester.
    $job = Start-Job -ScriptBlock {
        $script = $using:Path
        $pesterModulePath = $using:TaskParameter['PesterPath']
        $outputFile = $using:outputFile

        Invoke-Command -ScriptBlock {
                                        $VerbosePreference = 'SilentlyContinue'
                                        Import-Module -Name $pesterModulePath
                                    }

        Invoke-Pester -Script $script -OutputFile $outputFile -OutputFormat NUnitXml -PassThru
    } 
    
    # There's a bug where Write-Host output gets duplicated by Receive-Job if $InformationPreference is set to "Continue".
    # Since Pester uses Write-Host, this is a workaround to avoid seeing duplicate Pester output.
    $informationActionParameter = @{ }
    if( (Get-Command -Name 'Receive-Job' -ParameterName 'InformationAction') )
    {
        $informationActionParameter['InformationAction'] = 'SilentlyContinue'
    }

    do
    {
        $job | Receive-Job @informationActionParameter
    }
    while( -not ($job | Wait-Job -Timeout 1) )

    $job | Receive-Job @informationActionParameter

    Publish-WhiskeyPesterTestResult -Path $outputFile

    $result = [xml](Get-Content -Path $outputFile -Raw)

    if( -not $result )
    {
        throw ('Unable to parse Pester output XML report ''{0}''.' -f $outputFile)
    }

    if( $result.'test-results'.errors -ne '0' -or $result.'test-results'.failures -ne '0' )
    {
        throw ('Pester tests failed.')
    }
}


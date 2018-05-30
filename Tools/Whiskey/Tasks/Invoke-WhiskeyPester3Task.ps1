
function Invoke-WhiskeyPester3Task
{
    [Whiskey.Task("Pester3",SupportsClean=$true, SupportsInitialize=$true)]
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

    if( $TaskParameter.ContainsKey('Version') )
    {
        $version = $TaskParameter['Version'] | ConvertTo-WhiskeySemanticVersion
        if( -not $version )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -message ('Property ''Version'' isn''t a valid version number. It must be a version number of the form MAJOR.MINOR.PATCH.')
        }

        if( $version.Major -ne 3)
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Version property''s value ''{0}'' is invalid. It must start with ''3.'' (i.e. the major version number must always be ''3'')."' -f $version)
        }
        
        $version = [version]('{0}.{1}.{2}' -f $version.Major,$version.Minor,$version.Patch)
    }
    else
    {
        $version = '3.*'
    }

    if( $TaskContext.ShouldClean )
    {
        Uninstall-WhiskeyTool -ModuleName 'Pester' -BuildRoot $TaskContext.BuildRoot -Version $version
        return
    }
    
    $pesterModulePath = Install-WhiskeyTool -ModuleName 'Pester' -Version $version -DownloadRoot $TaskContext.BuildRoot

    if( $TaskContext.ShouldInitialize )
    {
        return
    }

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
    
    if( -not $pesterModulePath )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Failed to download or install Pester {0}, most likely because version {0} does not exist. Available version numbers can be found at https://www.powershellgallery.com/packages/Pester' -f $version)
    }

    $outputFile = Join-Path -Path $TaskContext.OutputDirectory -ChildPath ('pester+{0}.xml' -f [IO.Path]::GetRandomFileName())

    # We do this in the background so we can test this with Pester.
    $job = Start-Job -ScriptBlock {
        $script = $using:Path
        $pesterModulePath = $using:pesterModulePath
        $outputFile = $using:outputFile

        Invoke-Command -ScriptBlock {
                                        $VerbosePreference = 'SilentlyContinue'
                                        Import-Module -Name $pesterModulePath
                                    }

        Invoke-Pester -Script $script -OutputFile $outputFile -OutputFormat NUnitXml -PassThru
    } 
    
    do
    {
        $job | Receive-Job
    }
    while( -not ($job | Wait-Job -Timeout 1) )

    $job | Receive-Job

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


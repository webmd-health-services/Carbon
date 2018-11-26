
function Publish-WhiskeyProGetUniversalPackage
{
    [CmdletBinding()]
    [Whiskey.Task("PublishProGetUniversalPackage")]
    [Whiskey.RequiresTool('PowerShellModule::ProGetAutomation','ProGetAutomationPath',Version='0.4.*',VersionParameterName='ProGetAutomationVersion')]
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

    Import-WhiskeyPowerShellModule -Name 'ProGetAutomation'

    $exampleTask = 'Publish:
        - PublishProGetUniversalPackage:
            CredentialID: ProGetCredential
            Uri: https://proget.example.com
            FeedName: UniversalPackages'


    if( -not $TaskParameter['CredentialID'] )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message "CredentialID is a mandatory property. It should be the ID of the credential to use when connecting to ProGet:
        
        $exampleTask
        
        Use the `Add-WhiskeyCredential` function to add credentials to the build."
    }
    
    if( -not $TaskParameter['Uri'] )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message "Uri is a mandatory property. It should be the URI to the ProGet instance where you want to publish your package:
        
        $exampleTask
        "
    }

    if( -not $TaskParameter['FeedName'] )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message "FeedName is a mandatory property. It should be the name of the universal feed in ProGet where you want to publish your package:
        
        $exampleTask
        "
    }
    
    $credential = Get-WhiskeyCredential -Context $TaskContext -ID $TaskParameter['CredentialID'] -PropertyName 'CredentialID'

    $session = New-ProGetSession -Uri $TaskParameter['Uri'] -Credential $credential

    if( -not ($TaskParameter.ContainsKey('Path')) )
    {
        $TaskParameter['Path'] = Join-Path -Path ($TaskContext.OutputDirectory | Split-Path -Leaf) -ChildPath '*.upack'
    }
    
    $errorActionParam = @{ }
    $allowMissingPackages = $false
    if( $TaskParameter.ContainsKey('AllowMissingPackage') )
    {
        $allowMissingPackages = $TaskParameter['AllowMissingPackage'] | ConvertFrom-WhiskeyYamlScalar
    }

    if( $allowMissingPackages )
    {
        $errorActionParam['ErrorAction'] = 'Ignore'
    }
    $packages = $TaskParameter['Path'] | 
                    Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path' @errorActionParam |
                    Where-Object {
                        if( -not $TaskParameter.ContainsKey('Exclude') )
                        {
                            return $true
                        }

                        foreach( $exclusion in $TaskParameter['Exclude'] )
                        {
                            if( $_ -like $exclusion )
                            {
                                return $false
                            }
                        }

                        return $true
                    }


    if( $allowMissingPackages -and -not $packages )
    {
        Write-WhiskeyVerbose -Context $TaskContext -Message ('There are no packages to publish.')
        return
    }

    if( -not $packages )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -PropertyDescription '' -Message ('Found no packages to publish. By default, the PublishProGetUniversalPackage task publishes all files with a .upack extension in the output directory. Check your whiskey.yml file to make sure you''re running the `ProGetUniversalPackage` task before this task (or some other task that creates universal ProGet packages). To publish other .upack files, set this task''s `Path` property to the path to those files. If you don''t want your build to fail when there are missing packages, then set this task''s `AllowMissingPackage` property to `true`.' -f $TaskContext.OutputDirectory)
    }

    $feedName = $TaskParameter['FeedName']
    $taskPrefix = '[{0}]  [{1}]' -f $session.Uri,$feedName

    $optionalParam = @{ }
    if( $TaskParameter['Timeout'] )
    {
        $optionalParam['Timeout'] = $TaskParameter['Timeout']
    }
    if( $TaskParameter['Overwrite'] )
    {
        $optionalParam['Force'] = $TaskParameter['Overwrite'] | ConvertFrom-WhiskeyYamlScalar
    }

    Write-WhiskeyVerbose -Context $TaskContext -Message ('{0}' -f $taskPrefix)
    foreach( $package in $packages )
    {
        Write-WhiskeyVerbose -Context $TaskContext -Message ('{0}  {1}' -f (' ' * $taskPrefix.Length),$package)
        Publish-ProGetUniversalPackage -Session $session -FeedName $feedName -PackagePath $package @optionalParam -ErrorAction Stop
    }
}

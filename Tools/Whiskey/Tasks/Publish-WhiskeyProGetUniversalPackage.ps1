
function Publish-WhiskeyProGetUniversalPackage
{
    <#
    .SYNOPSIS
    Uploads a universal package to ProGet.

    .DESCRIPTION
    The `PublishProGetUniversalPackage` task uploads a universal package to ProGet. By default, it uploads all `*.upack` files in the `.output` directory. Pass paths to specific upack files to the `Path` property. It uses the `Publish-ProGetUniversalPackage` function from the `ProGetAutomation` module to upload the file. If a upack file is invalid, you'll get an error and nothing will upload.

    If uploading requires authentication, set the `CredentialID` property to the ID of the credential to use when uploading. Add the credential with the `Add-WhiskeyCredential` function.

    Set the `Uri` property to the base URI to ProGet. Set the `FeedName` property to the name of the universal feed to which you want to upload. By default, the upload will time out after 100 seconds. To change the default timeout, set the `Timeout` property to the number of seconds to wait before cancelling and timing out the upload.

    ## Property

    * `Uri` (mandatory): the base URI to the instance of ProGet where the package should be uploaded.
    * `FeedName` (mandatory): the name of the universal feed in ProGet where the package should be uploaded.
    * `CredentialID`: if ProGet requires authentication when uploading universal packages, this should be the ID of the credential to use. Add credentials to your build with the `Add-WhiskeyCredential` function.
    * `Path`: the path to any upack files to upload. By default, all `*.upack` files in the `.output` directory are uploaded.
    * `Timeout`: the timeout, in seconds, to use when uploading the file. If the upload request takes longer than this, it will be cancelled and the build will fail.
    * `Overwrite`: replace/overwrite the package if it already exists in ProGet. The default behavior is to fail/stop if the package exists.

    ## Examples

    ### Example 1

        Publish:
        - PublishProGetUniversalPackage:
            Uri: https://proget.example.com
            FeedName: Apps

    Demonstrates the minimal configuration needed to upload a package. In this case, all `*.upack` files in the `.output` directory will be uploaded to `http://proget.example.com/upack/Apps`. No authenticaton will be used.

    ### Example 2

        - PublishProGetUniversalPackage:
            Uri: https://proget.example.com
            FeedName: Apps
            Path:
            - .output\App-*.upack
            CredentialID: proget.example.com
            Timeout: 600

    Demonstrates the full configuration available to upload a packae. In this example, only the `App-*.upack` file(s) will be uploaded to `http://proget.example.com/upack/Apps` using the credential with the `proget.example.com` ID. The upload will be allowed to take ten minutes, then will be cancelled.
    #>
    [CmdletBinding()]
    [Whiskey.Task("PublishProGetUniversalPackage")]
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

    if( $TaskParameter.ContainsKey('Path') )
    {
        $packages = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'
    }
    else
    {
        $packages = Get-ChildItem -Path $TaskContext.OutputDirectory -Filter '*.upack' -ErrorAction Ignore | Select-Object -ExpandProperty 'FullName'
        if( -not $packages )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -PropertyDescription '' -Message ('There are no packages to publish in the output directory ''{0}''. By default, the PublishProGetUniversalPackage task publishes all .upack files in the output directory. Check your whiskey.yml file to make sure you''re running the `ProGetUniversalPackage` task before this task (or some other task that creates universal ProGet packages). To publish other .upack files, set this task''s `Path` property to the path to those files.' -f $TaskContext.OutputDirectory)
        }
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

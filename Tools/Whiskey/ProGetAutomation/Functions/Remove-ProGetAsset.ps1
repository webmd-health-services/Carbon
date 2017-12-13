function Remove-ProGetAsset
{
    <#
        .SYNOPSIS
        Removes assets from ProGet. 

        .DESCRIPTION
        The `Remove-ProGetAsset` function removes assets from ProGet. Pass the name of the root asset directory to the `DirectoryName` parameter. If the URL to an asset directory in ProGet is `https://proget.example.com/assets/versions/subdirectory/file`, the directory parameter is the first directory after `assets/` in this example `versions`, The path parameter is the rest of the url, in this case `subdirectory/file`. If the file does not exist no error will be thrown. All the files in the asset directory that match `$filter` parameter will be deleted.

        .EXAMPLE
        Remove-ProGetAsset -Session $session -Path 'myAssetName' -DirectoryName 'versions'

        Removes asset or assets that match `myAssetName`. if `myAssetName` is a directory it will delete the files in the directory but not the directory itself.

        .Example
        Remove-ProGetAsset -Session $session -Path 'versions/myAssetName' -DirectoryName 'example'

        Removes asset or assets that match `example/versions/myAssetName` in ProGet

        .Example
        Remove-ProGetAsset -Session $session -Path 'versions/example' -DirectoryName 'subexample' -filter '*a*'

        Removes all assets that match the wildcard `subexample/versions/example/*a*`
    #>
    param(
        [Parameter(Mandatory = $true)]
        [Object]
        # A session object that represents the ProGet instance to use. Use the `New-ProGetSession` function to create session objects.
        $Session,

        [Parameter(Mandatory = $true)]
        [string]
        # The name of the root asset directory to Remove the desired asset in ProGet. 
        $DirectoryName, 

        [string]
        # the asset path in the ProGet assets directory that will be removed. If the file does not exist no error will be thrown.
        $Path,

        [string]
        # Name of the assets in the ProGet assets directory that will be deleted. only files that match `$filter` in the directory will be deleted. Wildcards are supported.
        $Filter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $uri = '/endpoints/{0}/content/{1}' -f $DirectoryName,$Path
    $assetList = Get-ProGetAsset -Session $Session -Path $Path -DirectoryName $DirectoryName -Filter $filter

    foreach($asset in $assetList)
    {
        $asset = $asset.Name
        if($Path)
        {
            $asset = (join-Path -Path $Path -ChildPath $asset)
        }
        $uri = '/endpoints/{0}/content/{1}' -f $DirectoryName, $asset
        Invoke-ProGetRestMethod -Session $Session -Path $uri -Method Delete
    }
}

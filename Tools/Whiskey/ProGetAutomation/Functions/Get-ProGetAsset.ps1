function Get-ProGetAsset
{
    <#
        .SYNOPSIS
        Gets metadata about items in an asset directory.

        .DESCRIPTION
        The `Get-ProGetAsset` function gets metadata from ProGet about assets. Pass the name of the root asset directory to the `DirectoryName` parameter. Information about all the files in that asset directory is returned. If the URL to an asset directory in ProGet is `https://proget.example.com/assets/versions/subdirectory/file`, the directory parameter is the first directory after `assets/` in this example `versions`, The path parameter the rest of the url in this case `subdirectory/file`. 

        If you also pass a value to the `$filter` parameter, only files that match `$filter` value in the directory will be returned. Wildcards are supported.

        Pass a ProGet session object to the `$Session` parameter. This object controls what instance of ProGet to use and what credentials and/or API keys to use. Use the `New-ProGetSession` function to create session objects.

        .Example
        Get-ProGetAsset -Session $session -Path 'myAsset' -DirectoryName 'versions'
        
        Demonstrates how to get metadata about an asset. In this case, information about the `/versions/myAsset` file is returned. if `myAsset` is a directory then all files in that directory will be returned

        .Example
        Get-ProGetAsset -Session $session -Directory 'versions/subdirectory'
        
        Demonstrates how to get metadata from all files in the `versions/subdirectory` asset directory. If no files found an empty list is returned.

    #>
    param(
        [Parameter(Mandatory = $true)]
        [Object]
        # A session object that represents the ProGet instance to use. Use the `New-ProGetSession` function to create session objects.
        $Session,

        [Parameter(Mandatory = $true)]
        [string]
        # The name of a valid path to the directory to get metadata of the desired assets in ProGet. 
        $DirectoryName,        

        [string]
        # The path to the subdirectory in the asset directory in ProGet.
        $Path,

        [string]
        # Name of the asset in the ProGet assets directory that will be retrieved. only file metadata that match `$Name` in the directory will be returned. Wildcards are supported.
        $Filter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $uri = '/endpoints/{0}/dir/{1}' -f $DirectoryName,$Path


    if(!$Filter)
    {
        $Filter = '*'
    }
    return Invoke-ProGetRestMethod -Session $Session -Path $uri -Method Get | Where-Object { $_.Name -like $Filter }
}

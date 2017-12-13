function Set-ProGetAsset
{
    <#
        .SYNOPSIS
        Adds and updates assets to the ProGet asset manager. 

        .DESCRIPTION
        The `Set-ProGetAsset` adds assets to ProGet A session, FilePath, DirectoryName and Path is required. 
        A root directory needs to be created in ProGet using the `New-ProGetFeed` function with Type `Asset`.
        
        The FilePath parameter is relative path to the file you wish to upload.
        The DirectoryName parameter is the root asset directory you wish the asset to be located in.
        The Path parameter is the path to the file you wish to place the asset.

        .EXAMPLE
        Set-ProGetAsset -Session $session -Path 'subdir/exampleAsset.txt' -DirectoryName 'assetDirectory' -FilePath 'path/to/file.txt'

        Example of adding an asset located on the machine at `path/to/file.txt` to ProGet in the `assetDirectory/subdir` folder. If `assetDirectory` is not created it will throw an error. If subdir is not created it will create the folder.
        
        .EXAMPLE
        Set-ProGetAsset -Session $session -Path 'exampleAsset.txt' -Directory 'assetDirectory' -Path 'path/to/file.txt'

        Example of adding an asset located on the machine at `path/to/file.txt` to ProGet in the `assetDirectory` folder. If `assetDirectory` is not created it will throw an error. If subdir is not created it will create the folder.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [Object]
        # A session object that represents the ProGet instance to use. Use the `New-ProGetSession` function to create session objects.
        $Session,
        
        [Parameter(Mandatory = $true)]
        [string]
        # The name of a valid directory to upload the desired asset in ProGet. If no root directories exist, use the `New-ProGetFeed` with parameter `-Type 'Asset'` to create a new directory in the ProGet assets page.
        $DirectoryName,        
        
        [Parameter(Mandatory = $true)]
        [string]
        # Desired path of the asset that will be uploaded. Any directories that do not exist will be created automatically.
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        # The Relative Path of the file to be uploaded. 
        $FilePath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    if( -not (Test-path -Path $FilePath) )
    {
        Write-error ('Could Not find file named ''{0}''. please pass in the correct path value' -f $FilePath)
        return
    }

    return Invoke-ProGetRestMethod -Session $Session -Path ('/endpoints/{0}/content/{1}' -f $DirectoryName, $Path) -Method Post -Infile $FilePath
}

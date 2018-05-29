
function Copy-WhiskeyFile
{
    [Whiskey.Task("CopyFile")]
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

    $pathErrorMessage = @'
'Path' property is missing. Please set it to the list of files to copy, e.g.

Build:
- CopyFile:
    Path: myfile.txt
    Destination: \\computer\share
'@
    $destDirErrorMessage = @'
'DestinationDirectory' property is missing. Please set it to the list of target locations to copy to, e.g.

Build:
- CopyFile:
    Path: myfile.txt
    DestinationDirectory: \\computer\share
'@

    if(!$TaskParameter.ContainsKey('Path'))
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ($pathErrorMessage)
    }

    $sourceFiles = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'
    if(!$sourceFiles)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ($pathErrorMessage)
    }

    if(!$TaskParameter.ContainsKey('DestinationDirectory'))
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ($destDirErrorMessage)
    }
    
    if(!$TaskParameter['DestinationDirectory'])
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ($destDirErrorMessage)
    }

    foreach($sourceFile in $sourceFiles)
    {
        if((Test-Path -Path $sourceFile -PathType Container))
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Path ''{0}'' is directory. The CopyFile task only copies files. Please remove this path from your ''Path'' property.' -f $sourceFile)
        }
    }
    
    $idx = 0
    $destinations = $TaskParameter['DestinationDirectory'] |
                        ForEach-Object {

                            $path = $_

                            if( -not [IO.Path]::IsPathRooted($path) )
                            {
                                $path = Join-Path -Path $TaskContext.BuildRoot -ChildPath $path
                            }

                            if( [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($path) )
                            {
                                $path = Resolve-Path -Path $path -ErrorAction Ignore | Select-Object -ExpandProperty 'ProviderPath'
                                if( -not $path )
                                {
                                    Stop-WhiskeyTask -TaskContext $TaskContext -Message ('DestinationDirectory[{0}]:  Wildcard pattern ''{1}'' doesn''t point to an existing directory.' -f $idx, $_)
                                }
                                $path
                            }
                            else
                            {
                                $path
                            }
                            
                            $idx++
                        }

    foreach ($destDir in $destinations)
    {

        if(!(Test-Path -Path $destDir -PathType Container))
        {
            $null = New-Item -Path $destDir -ItemType 'Directory' -Force
        }
        
        if(!(Test-Path -Path $destDir -PathType Container))
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Failed to create destination directory ''{0}''. Make sure the current user, ''{1}\{2}'' has access to create directories in ''{0}''. If it is a file share, check that the share exists and the share''s permissions.' -f $destDir, $env:USERDOMAIN, $env:USERNAME)
        }
    }

    foreach( $destDir in $destinations )
    {
        foreach($sourceFile in $sourceFiles)
        {
            Write-WhiskeyVerbose -Context $TaskContext ('{0} -> {1}' -f $sourceFile,$destDir)
            Copy-Item -Path $sourceFile -Destination $destDir
        }
    }
}


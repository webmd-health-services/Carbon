
function Resolve-CPathCase
{
    <#
    .SYNOPSIS
    Returns the real, canonical case of a path.
    
    .DESCRIPTION
    The .NET and Windows path/file system APIs respect and preserve the case of paths passed to them.  This function will return the actual case of a path on the file system, regardless of the case of the string passed in.
    
    If the path doesn't an exist, an error is written and nothing is returned.

    .EXAMPLE
    Resolve-CPathCase -Path "C:\WINDOWS\SYSTEM32"
    
    Returns `C:\Windows\system32`.
    
    .EXAMPLE
    Resolve-CPathCase -Path 'c:\projects\carbon' 
    
    Returns `C:\Projects\Carbon`.
    #>
    [CmdletBinding()]
    param(
        # The path whose real, canonical case should be returned.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('FullName')]
        [String] $Path
    )
    
    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if( -not (Test-Path -Path $Path) )
        {
            Write-Error "Path ""$($Path)"" not found."
            return
        }

        $uri = [uri]$Path
        if( $uri.IsUnc )
        {
            Write-Error ("Path ""$($Path)"" is a UNC path, which is not supported.")
            return
        }

        if( -not ([IO.Path]::IsPathRooted($Path)) )
        {
            $Path = (Resolve-Path -Path $Path).Path
        }
        
        $qualifier = '{0}\' -f (Split-Path -Qualifier -Path $Path)
        $qualifier = Get-Item -Path $qualifier | Select-Object -ExpandProperty 'Name'
        $canonicalPath = ''
        do
        {
            $parent = Split-Path -Parent -Path $Path
            $leaf = Split-Path -Leaf -Path $Path
            $canonicalLeaf = Get-ChildItem -Path $parent -Filter $leaf | Select-Object -ExpandProperty 'Name'
            if( $canonicalPath )
            {
                $canonicalPath = Join-Path -Path $canonicalLeaf -ChildPath $canonicalPath
            }
            else
            {
                $canonicalPath = $canonicalLeaf
            }
        }
        while( $parent -ne $qualifier -and ($Path = Split-Path -Parent -Path $Path) )

        return Join-Path -Path $qualifier -ChildPath $canonicalPath
    }
}

Set-Alias -Name 'Get-PathCanonicalCase' -Value 'Resolve-CPathCase'


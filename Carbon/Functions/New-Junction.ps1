
function New-CJunction
{
    <#
    .SYNOPSIS
    Creates a new junction.
    
    .DESCRIPTION
    Creates a junction given by `-Link` which points to the path given by `-Target`.  If something already exists at `Link`, an error is written.  

    Returns a `System.IO.DirectoryInfo` object for the junction, if one is created.

    .OUTPUTS
    System.IO.DirectoryInfo.
    
    .LINK
    Install-CJunction

    .LINK
    Remove-CJunction

    .EXAMPLE
    New-CJunction -Link 'C:\Windows\system32Link' -Target 'C:\Windows\system32'
    
    Creates the `C:\Windows\system32Link` directory, which points to `C:\Windows\system32`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias("Junction")]
        [string]
        # The new junction to create
        $Link,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The target of the junction, i.e. where the junction will point to
        $Target
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( Test-Path -LiteralPath $Link -PathType Container )
    {
        Write-Error "'$Link' already exists."
    }
    else
    {
        Write-Verbose -Message "Creating junction $Link <=> $Target"
        [Carbon.IO.JunctionPoint]::Create( $Link, $Target, $false )
        if( Test-Path $Link -PathType Container ) 
        { 
            Get-Item $Link 
        } 
    }
}


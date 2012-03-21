
function Get-PowershellPath
{
    <#
    .SYNOPSIS
    Gets the path to powershell.exe.
    #>
    [CmdletBinding()]
    param(
        [Switch]
        # Gets the path to 32-bit powershell.
        $x86
    )
    
    $powershellPath = Join-Path $PSHome powershell.exe
    if( $x86 )
    {
        return $powerShellPath -replace 'System32','SysWOW64'
    }
    return $powerShellPath
}

function Invoke-PowerShell
{
    <#
    .SYNOPSIS
    Invokes a script block in a separate powershell.exe process.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ScriptBlock]
        # The command to run.
        $Command,
        
        [object[]]
        # Any arguments to pass to the command.
        $Args,
        
        [Switch]
        # Run the x86 (32-bit) version of PowerShell.
        $x86
    )
    
    $params = @{ }
    if( $x86 )
    {
        $params.x86 = $true
    }
    
    & (Get-PowerShellPath @params) -NoProfile -NoLogo -Command $command -Args $Args
}

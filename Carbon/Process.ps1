
function Test-ProcessIs32Bit
{
    <#
    .SYNOPSIS
    Tests if the current process is 32-bit.
    #>
    [CmdletBinding()]
    param(
    )
    
    return ($env:PROCESSOR_ARCHITECTURE -eq 'x86')
}

function Test-ProcessIs64Bit
{
    <#
    .SYNOPSIS
    Tests if the current process is 64-bit.
    #>
    [CmdletBinding()]
    param(
    )
    
    return ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64')
}


function ConvertTo-WhiskeyTask
{
    <#
    .SYNOPSIS
    Converts an object parsed from a whiskey.yml file into a task name and task parameters.

    .DESCRIPTION
    The `ConvertTo-WhiskeyTask` function takes an object parsed from a whiskey.yml file and converts it to a task name and hashtable of parameters and returns both in that order.

    .EXAMPLE
    $name,$parameter = ConvertTo-WhiskeyTask -InputObject $parsedTask
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [object]
        $InputObject
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    if( $InputObject -is [string] )
    {
        $InputObject
        @{ }
        return
    }
    elseif( $InputObject -and ($InputObject | Get-Member -Name 'Keys') )
    {
        $taskName = $InputObject.Keys | Select-Object -First 1
        $parameter = $InputObject[$taskName]
        if( -not $parameter )
        {
            $parameter = @{ }
        }
        elseif( -not ($parameter | Get-Member -Name 'Keys') )
        {
            $parameter = @{ '' = $parameter }
        }
        $taskName
        $parameter
        return
    }

    $options = [YamlDotNet.Serialization.SerializationOptions]::None
    $yamlWriter = New-Object "System.IO.StringWriter"
    $serializer = New-Object "YamlDotNet.Serialization.Serializer" $options
    $serializer.Serialize($yamlWriter, $InputObject)
    $yaml = $yamlWriter.ToString()
    $yaml = $yaml -split [regex]::Escape([Environment]::NewLine) |
                Where-Object { @( '...', '---' ) -notcontains $_ } |
                ForEach-Object { '    {0}' -f $_ }
    Write-Error -Message ('Invalid task YAML:{0} {0}{1}{0}A task must have a name followed by optional parameters, e.g.
 
    Build:
    - Task1
    - Task2:
        Parameter1: Value1
        Parameter2: Value2
 
    ' -f [Environment]::NewLine,($yaml -join [Environment]::NewLine))
}
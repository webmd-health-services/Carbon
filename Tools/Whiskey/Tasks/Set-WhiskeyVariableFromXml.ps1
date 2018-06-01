
function Set-WhiskeyVariableFromXml
{
    [Whiskey.Task("SetVariableFromXml")]
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
    
    $path = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path' -PathType File
    if( ($path | Measure-Object).Count -ne 1 )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -PropertyName 'Path' -Message ('resolves to multiple files. The "Path" property must only resolve to one file.')
    }

    Write-WhiskeyVerbose -Context $TaskContext -Message ($path)
    [xml]$xml = $null
    try
    {
        $xml = Get-Content -Path $path -Raw
    }
    catch
    {
        $Global:Error.RemoveAt(0)
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Exception reading XML from file "{0}": {1}"' -f $path,$_)
    }

    $nsManager = New-Object -TypeName 'Xml.XmlNamespaceManager' -ArgumentList $xml.NameTable
    $prefixes = $TaskParameter['NamespacePrefixes'] 
    if( $prefixes -and ($prefixes | Get-Member 'Keys') )
    {
        foreach( $prefix in $prefixes.Keys )
        {
            $nsManager.AddNamespace($prefix, $prefixes[$prefix])
        }
    }

    $allowMissingNodes = $TaskParameter['AllowMissingNodes'] | ConvertFrom-WhiskeyYamlScalar

    $variables = $TaskParameter['Variables']
    if( $variables -and ($variables | Get-Member 'Keys') )
    {
        foreach( $variableName in $variables.Keys )
        {
            $xpath = $variables[$variableName]
            $value = $xml.SelectNodes($xpath, $nsManager) | ForEach-Object { 
                if( $_ | Get-Member 'InnerText' )
                {
                    $_.InnerText
                }
                elseif( $_ | Get-Member '#text' )
                {
                    $_.'#text'
                }
            }
            $exists = ' '
            if( $value -eq $null )
            {
                if( -not $allowMissingNodes )
                {
                    Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Variable {0}: XPath expression "{1}" matched no elements/attributes in XML file "{2}".' -f $variableName,$xpath,$path)
                }
                $value = ''
                $exists = '!'
            }
            Write-WhiskeyVerbose -Context $TaskContext -Message ('  {0} {1}' -f $exists,$xpath)
            Write-WhiskeyVerbose -Context $TaskContext -Message ('        {0} = {1}' -f $variableName,($value | Select-Object -First 1))
            $value | Select-Object -Skip 1 | ForEach-Object {
                Write-WhiskeyVerbose -Context $TaskContext -Message ('        {0}   {1}' -f (' ' * $variableName.Length),$_)
            }
            Add-WhiskeyVariable -Context $TaskContext -Name $variableName -Value $value
        }
    }
}

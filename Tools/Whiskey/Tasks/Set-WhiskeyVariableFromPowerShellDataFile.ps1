
function Set-WhiskeyVariableFromPowerShellDataFile
{
    [CmdletBinding()]
    [Whiskey.Task('SetVariableFromPowerShellDataFile')]
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

    $path = Resolve-WhiskeyTaskPath -TaskContext $TaskContext -Path $TaskParameter['Path'] -PropertyName 'Path'

    $data = Import-PowerShellDataFile -Path $path
    if( -not $data )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -PropertyName 'Path' -Message ('Failed to parse PowerShell Data File "{0}". Make sure this is a properly formatted PowerShell data file. Use the `Import-PowerShellDataFile` cmdlet.' -f $path)
        return
    }

    function Set-VariableFromData
    {
        param(
            [object]
            $Variable,

            [hashtable]
            $Data,
            
            [string]
            $ParentPropertyName = ''
        )

        foreach( $propertyName in $Variable.Keys )
        {
            $variableName = $Variable[$propertyName]
            if( -not $Data.ContainsKey($propertyName) )
            {
                Stop-WhiskeyTask -TaskContext $TaskContext -PropertyName 'Variables' -Message ('PowerShell Data File "{0}" does not contain "{1}{2}" property.' -f $path,$ParentPropertyName,$propertyName)
                continue
            }

            $variableValue = $Data[$propertyName]
            if( $variableName | Get-Member 'Keys' )
            {
                Set-VariableFromData -Variable $variableName -Data $variableValue -ParentPropertyName ('{0}{1}.' -f $ParentPropertyName,$propertyName)
                continue
            }

            Add-WhiskeyVariable -Context $TaskContext -Name $variableName -Value $variableValue
        }
    }

    Set-VariableFromData -Variable $TaskParameter['Variables'] -Data $data
}
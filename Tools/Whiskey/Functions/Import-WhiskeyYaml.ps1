
function Import-WhiskeyYaml
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='FromFile')]
        [string]
        $Path,

        [Parameter(Mandatory=$true,ParameterSetName='FromString')]
        [string]
        $Yaml
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'FromFile' )
    {
        $Yaml = Get-Content -Path $Path -Raw 
    }

    $builder = New-Object 'YamlDotNet.Serialization.DeserializerBuilder'
    $deserializer = $builder.Build()

    $reader = New-Object 'IO.StringReader' $Yaml
    $config = @{}
    try
    {
        $config = $deserializer.Deserialize( $reader )
    }
    finally
    {
        $reader.Close()
    }
    
    if( -not $config )
    {
        $config = @{} 
    }

    if( $config -is [string] )
    {
        $config = @{ $config = '' }
    }

    return $config
}
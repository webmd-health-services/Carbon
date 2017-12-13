
function Import-WhiskeyYaml
{
    param(
        $Path
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $yamlString = Get-Content -Path $Path -Raw 

    $builder = New-Object 'YamlDotNet.Serialization.DeserializerBuilder'
    $deserializer = $builder.Build()

    $reader = New-Object 'IO.StringReader' $yamlString
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
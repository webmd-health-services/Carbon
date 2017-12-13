
function ConvertFrom-WhiskeyYamlScalar
{
    <#
    .SYNOPSIS
    Converts a string that came from a YAML configuation file into a strongly-typed object.

    .DESCRIPTION
    The `ConvertFrom-WhiskeyYamlScalar` function converts a string that came from a YAML configuration file into a strongly-typed object according to the parsing rules in the YAML specification. It converts strings into booleans, integers, floating-point numbers, and timestamps. See the YAML specification for examples on how to represent these values in your YAML file.
    
    It will convert:

    * `y`, `yes`, `true`, and `on` to `$true`
    * `n`, `no`, `false`, and `off` to `$false`
    * Numbers to `int32` or `int64` types. Numbers can be prefixed with `0x` (for hex), `0b` (for bits), or `0` for octal.
    * Floating point numbers to `double`, or `single` types. Floating point numbers can be expressed as decimals (`1.5`), or with scientific notation (`6.8523015e+5`).
    * `~`, `null`, and `` to `$null`
    * timestamps (e.g. `2001-12-14t21:59:43.10-05:00`) to date

    If it can't convert a string into a known type, `ConvertFrom-WhiskeyYamlScalar` writes an error.

    .EXAMPLE
    $value | ConvertFrom-WhiskeyYamlScalar

    Demonstrates how to pipe values to `ConvertFrom-WhiskeyYamlScalar`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        # The object to convert.
        $InputObject
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if( [string]::IsNullOrEmpty($InputObject)  -or $InputObject -match '^(~|null)' )
        {
            return $null
        }

        if( $InputObject -match '^(y|yes|n|no|true|false|on|off)$' )
        {
            return $InputObject -match '^(y|yes|true|on)$'
        }

        # Integer
        $regex = @'
^(
 [-+]?0b[0-1_]+ # (base 2)
|[-+]?0[0-7_]+ # (base 8)
|[-+]?(0|[1-9][0-9_]*) # (base 10)
|[-+]?0x[0-9a-fA-F_]+ # (base 16)
|[-+]?[1-9][0-9_]*(:[0-5]?[0-9])+ # (base 60)
)$
'@
        if( [Text.RegularExpressions.Regex]::IsMatch($InputObject, $regex, [Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace) ) 
        {
            [int64]$int64 = 0

            $value = $InputObject -replace '_',''

            if( $value -match '^0x' -and [int64]::TryParse(($value -replace '0x',''), [Globalization.NumberStyles]::HexNumber, $null,[ref]$int64))
            {
            }
            elseif( $value -match '^0b' )
            {
                $int64 = [Convert]::ToInt64(($value -replace ('^0b','')),2)
            }
            elseif( $value -match '^0' )
            {
                $int64 = [Convert]::ToInt64($value,8)
            }
            elseif( [int64]::TryParse($value,[ref]$int64) )
            {
            }
            
            if( $int64 -gt [Int32]::MaxValue )
            {
                return $int64
            }

            return [int32]$int64
        }    

        $regex = @'
^(
 [-+]?([0-9][0-9_]*)?\.[0-9_]*([eE][-+][0-9]+)? # (base 10)
|[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]* # (base 60)
|[-+]?\.(inf|Inf|INF) # (infinity)
|\.(nan|NaN|NAN) # (not a number)
)$
'@
        if( [Text.RegularExpressions.Regex]::IsMatch($InputObject, $regex, [Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace) ) 
        {
            $value = $InputObject -replace '_',''
            [double]$double = 0.0
            if( $value -eq '.NaN' )
            {
                return [double]::NaN
            }

            if( $value -match '-\.inf' )
            {
                return [double]::NegativeInfinity
            }

            if( $value -match '\+?.inf' )
            {
                return [double]::PositiveInfinity
            }

            if( [double]::TryParse($value,[ref]$double) )
            {
                return $double
            }
        }

        $regex = '^\d\d\d\d-\d\d?-\d\d?(([Tt]|[ \t]+)\d\d?\:\d\d\:\d\d(\.\d+)?(Z|\ *[-+]\d\d?(:\d\d)?)?)?$'
        if( [Text.RegularExpressions.Regex]::IsMatch($InputObject, $regex, [Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace) ) 
        {
            [DateTime]$datetime = [DateTime]::MinValue
            if( ([DateTime]::TryParse(($InputObject -replace 'T',' '),[ref]$datetime)) ) 
            {
                return $datetime
            }
        }

        Write-Error -Message ('Unable to convert scalar value ''{0}''. See http://yaml.org/type/ for documentation on YAML''s scalars.' -f $InputObject) -ErrorAction $ErrorActionPreference
    }

}
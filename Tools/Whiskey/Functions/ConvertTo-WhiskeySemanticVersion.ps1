
function ConvertTo-WhiskeySemanticVersion
{
    <#
    .SYNOPSIS
    Converts an object to a semantic version.

    .DESCRIPTION
    The `ConvertTo-WhiskeySemanticVersion` function converts strings, numbers, and date/time objects to semantic versions. If the conversion fails, it writes an error and you get nothing back. 

    .EXAMPLE
    '1.2.3' | ConvertTo-WhiskeySemanticVersion

    Demonstrates how to convert an object into a semantic version.
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [object]
        # The object to convert to a semantic version. Can be a version string, number, or date/time.
        $InputObject
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        [version]$asVersion = $null
        if( $InputObject -is [string] )
        {
            [int]$asInt = 0
            [double]$asDouble = 0.0
            [SemVersion.SemanticVersion]$semVersion = $null
            if( [SemVersion.SemanticVersion]::TryParse($InputObject,[ref]$semVersion) )
            {
                return $semVersion
            }

            if( [version]::TryParse($InputObject,[ref]$asVersion) )
            {
                $InputObject = $asVersion
            }
            elseif( [int]::TryParse($InputObject,[ref]$asInt) )
            {
                $InputObject = $asInt
            }
        }
        
        if( $InputObject -is [SemVersion.SemanticVersion] )
        {
            return $InputObject
        }
        elseif( $InputObject -is [datetime] )
        {
            $original = $InputObject.ToShortDateString()
            if( $original -match ('(\d+){0}(\d+){0}(\d+)' -f ([regex]::Escape([Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.DateSeparator))) )
            {
                $InputObject = '{0}.{1}.{2}' -f $Matches[1],$Matches[2],$Matches[3]
            }
            else
            {
                Write-Error -Message ('Unable to convert ''{0}'', a date/time, back to a version number. If this value came from a YAML file, please put quotes around it to ensure it is in a format we can parse.' -f $PSBoundParameters['InputObject']) -ErrorAction $ErrorActionPreference
                return
            }
        }
        elseif( $InputObject -is [double] )
        {
            $major,$minor = $InputObject.ToString('g') -split '\.'
            if( -not $minor )
            {
                $minor = '0'
            }
            $InputObject = '{0}.{1}.0' -f $major,$minor
        }
        elseif( $InputObject -is [int] )
        {
            $InputObject = '{0}.0.0' -f $InputObject
        }
        elseif( $InputObject -is [version] )
        {
            if( $InputObject.Build -le -1 )
            {
                $InputObject = '{0}.0' -f $InputObject
            }
            else
            {
                $InputObject = $InputObject.ToString()
            }
        }
        else
        {
            Write-Error -Message ('Unable to convert ''{0}'' to a semantic version. We tried parsing it as a version, date, double, and integer. Sorry. But we''re giving up.' -f $PSBoundParameters['InputObject']) -ErrorAction $ErrorActionPreference
            return
        }

        $semVersion = $null
        if( ([SemVersion.SemanticVersion]::TryParse($InputObject,[ref]$semVersion)) )
        {
            return $semVersion
        }

        Write-Error -Message ('Unable to convert ''{0}'' of type ''{1}'' to a semantic version.' -f $PSBoundParameters['InputObject'],$PSBoundParameters['InputObject'].GetType().FullName) -ErrorAction $ErrorActionPreference
    }
}


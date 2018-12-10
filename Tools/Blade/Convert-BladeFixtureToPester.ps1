[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    # The path to convert.
    $Path
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

function ConvertTo-Expression
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]
        # The format.
        $InputObject
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($line, [ref]$tokens, [ref]$errors)
        [object[]]$formatArgs = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]},$true) |
            Select-Object -First 1 | 
            Select-Object -ExpandProperty 'CommandElements' | 
            Select-Object -Skip 1

        $result = $InputObject -f $formatArgs
        $result = '    {0}{1}' -f $indent,$result
        return $result
    }
}

$alreadyDescribed = $false
$skipNextLine = $false

Get-Item -Path $path | ForEach-Object {
    $fixture = $_
    $lineNum = -1
    $lines = Invoke-Command {
        Get-Content -Path $fixture | ForEach-Object {
            $line = $_
            $lineNum++

            if( $skipNextLine )
            {
                $skipNextLine = $false
                return
            }

            if( -not $alreadyDescribed -and $line -match 'function (Start|Stop)-Test(Fixture)?' )
            {
                'Describe ''{0}'' {{' -f ($fixture.BaseName -replace '\.Tests$','')
                $alreadyDescribed = $true
            }

            if( $line -match 'function ((Start|Stop)-Test(Fixture)?)\b' )
            {
                $skipNextLine = $true
                $beforeAfterTranslations = @{
                                                'Start-TestFixture' = 'BeforeAll';
                                                'Stop-TestFixture' = 'AfterAll';
                                                'Start-Test' = 'BeforeEach';
                                                'Stop-Test' = 'AfterEach';
                                            }
                return '    {0} {{' -f $beforeAfterTranslations[$Matches[1]]
            }

            if( $line -match '^(\s*)function (Test|Ignore)-(\S+)$' )
            {
                $skipNextLine = $true

                return '    {0}It ''{1}'' {{' -f $Matches[1],($Matches[3] -creplace '([A-Z])',' $1').ToLowerInvariant().Trim()
            }

            Write-Debug $line
            if( $line -match '\bAssert-(.+?)\b' )
            {
                $assertion = $Matches[1]
                $Matches | Out-String | Write-Debug 
                $errors = [Management.Automation.PSParseError[]] @()
                $tokens = [System.Management.Automation.PsParser]::Tokenize( $line, [ref] $errors )
                if( $errors )
                {
                    Write-Error -Message ('There were errors parsing line ''{0}''.' -f $line)
                    return $line
                }
                
                $line -match '^(\s*)' | Out-Null
                $indent = $Matches[1]
                switch ($assertion)
                {
                    'Empty'
                    {
                        Write-Warning -Message ('Line {0} asserts a variable is not empty. If the variable is an array, it won''t work correctly in Pester.' -f $lineNum)
                        Write-Warning -Message ($line)
                        return '{0} | Should BeNullOrEmpty' | ConvertTo-Expression
                    }
                    'Equal'
                    {
                        return '{1} | Should Be {0}' | ConvertTo-Expression
                    }
                    'Error'
                    {
                        '{0}    $Global:Error.Count | Should BeGreaterThan 0' -f $indent
                        $regex = $line.Substring($tokens[-1].Start, $tokens[-1].Length)
                        if( $tokens[-1].Type -eq [Management.Automation.PSTokenType]::String -and $tokens[-2].Type -eq [Management.Automation.PSTokenType]::String )
                        {
                            $regex = $line.Substring($tokens[-2].Start, $tokens[-2].Length)
                        }
                        if( $line -match '-Last\b' )
                        {
                            return '    {0}$Global:Error[0] | Should Match {1}' -f $indent,$regex
                        }
                        return
                    }
                    'False'
                    {
                        return '{0} | Should Be $false' | ConvertTo-Expression
                    }
                    'GreaterThan'
                    {
                        return '{0} | Should BeGreaterThan {1}' | ConvertTo-Expression
                    }
                    'Is'
                    {
                        return '{0} | Should BeOfType {1}' | ConvertTo-Expression
                    }
                    'NoError'
                    {
                        return '$Global:Error.Count | Should Be 0' | ConvertTo-Expression
                    }
                    'NotEmpty'
                    {
                        Write-Warning -Message ('Line {0} asserts a variable is empty. If the variable is an array, it won''t work correctly in Pester.' -f $lineNum)
                        Write-Warning -Message ($line)
                        return '{0} | Should Not BeNullOrEmpty' | ConvertTo-Expression
                    }
                    'NotEqual'
                    {
                        return '{1} | Should Not Be {0}' | ConvertTo-Expression
                    }
                    'NotNull'
                    {
                        return '{0} | Should Not BeNullOrEmpty' | ConvertTo-Expression
                    }
                    'Null'
                    {
                        return '{0} | Should BeNullOrEmpty' | ConvertTo-Expression
                    }
                    'True'
                    {
                        return '{0} | Should Be $true' | ConvertTo-Expression
                    }
                }
            }

            if( $alreadyDescribed )
            {
                return '    {0}' -f $line
            }

            return $line
        } 

        '}'
    }
    $lines | Set-Content -Path $fixture
}

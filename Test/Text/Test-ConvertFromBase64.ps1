# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldConvertToBase64
{
    $value = 'YAAxADIAMwA0ADUANgA3ADgAOQAwAC0APQBxAHcAZQByAHQAeQB1AGkAbwBwAFsAXQBcAGEAcwBkAGYAZwBoAGoAawBsADsAJwB6AHgAYwB2AGIAbgBtACwALgAvACAAfgAhAEAAIwAkACUAXgAmACoAKAApAF8AKwBRAFcARQBSAFQAWQBVAEkATwBQAHsAfQB8AEEAUwBEAEYARwBIAEoASwBMADoAIgBaAFgAQwBWAEIATgBNADwAPgA/AA=='
    $expectedValue = '`1234567890-=qwertyuiop[]\asdfghjkl;''zxcvbnm,./ ~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?'
    
    $actualValue = ConvertFrom-Base64 -Value $value
    
    Assert-Equal $expectedValue $actualValue
}

function Test-ShouldAcceptPipelineInput
{
    [String[]]$result = ('VgBhAGwAdQBlADEA','VgBhAGwAdQBlADIA') | ConvertFrom-Base64
    Assert-Equal 2 $result.Length
    Assert-Equal (ConvertFrom-Base64 -Value 'VgBhAGwAdQBlADEA') $result[0]
    Assert-Equal (ConvertFrom-Base64 -Value 'VgBhAGwAdQBlADIA') $result[1]
}

function Test-ShouldAcceptArrayInput
{
    $result = ConvertFrom-Base64 -Value 'VgBhAGwAdQBlADEA','VgBhAGwAdQBlADIA'
    Assert-Equal 2 $result.Length
    Assert-Equal (ConvertFrom-Base64 -Value 'VgBhAGwAdQBlADEA') $result[0]
    Assert-Equal (ConvertFrom-Base64 -Value 'VgBhAGwAdQBlADIA') $result[1]
}

function Test-ShouldAllowDifferentEncoding
{
    $value = 'Value1'
    $result = $value | 
                    ConvertTo-Base64 -Encoding ([Text.Encoding]::ASCII) -NoWarn |
                    ConvertFrom-Base64 -Encoding ([Text.Encoding]::ASCII)
    Assert-Equal $value $result
}


function Test-ShouldAllowEmptyString
{
    $result = ConvertFrom-Base64 ''
    Assert-Equal '' $result
}

function Test-ShouldAllowNull
{
    $result = ConvertFrom-Base64 $null
    Assert-Null $null
}

function Test-ShouldAllowNullFromPipeline
{
    $values = @('MQA=', $null, '', 'MwA=')
    $result = $values | ConvertFrom-Base64 
    Assert-NotNull $result
    Assert-Equal 4 $result.Count
    Assert-Null $result[1]
    Assert-Empty $result[2]
}

function Test-ShouldAllowNullInArray
{
    $result = ConvertFrom-Base64 -Value @( $null, $null )
    Assert-NotNull $result
    Assert-Equal 2 $result.Count
    Assert-Empty $result[0]
    Assert-Empty $result[1]
}


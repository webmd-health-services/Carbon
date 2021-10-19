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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonDscResource.ps1' -Resolve)

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([Collections.Hashtable])]
	param
	(
		[Parameter(Mandatory=$true)]
		[string]
        # The name of the environment variable.
		$Name,

		[string]
        # the value of the environment variable.        
		$Value,

		[ValidateSet("Present","Absent")]
		[string]
        # Create or delete the resource?
		$Ensure = 'Present'
	)
    
    Set-StrictMode -Version 'Latest'

    $actualValue = [Environment]::GetEnvironmentVariable($Name,[EnvironmentVariableTarget]::Machine)

    $Ensure = 'Present'
    if( $actualValue -eq $null )
    {
        $Ensure = 'Absent'
    }

    @{
        Name = $Name;
        Ensure = $Ensure;
        Value = $actualValue;
    }
}


function Set-TargetResource
{
    <#
    .SYNOPSIS
    DSC resource for managing environment variables.

    .DESCRIPTION
    The Carbon_EnvironmentVariable resource will add, update, or remove environment variables. The environment variable is set/removed at both the computer *and* process level, so that the process applying the DSC configuration will have access to the variable in later resources.

    `Carbon_EnvironmentVariable` is new in Carbon 2.0.

    .LINK
    Set-CEnvironmentVariable

    .EXAMPLE
    > 
    Demonstrates how to create or update an environment variable:

        Carbon_EnvironmentVariable SetCarbonEnv
        {
            Name = 'CARBON_ENV';
            Value = 'developer';
            Ensure = 'Present';
        }

    .EXAMPLE
    >
    Demonstrates how to remove an environment variable.
        
        Carbon_EnvironmentVariable RemoveCarbonEnv
        {
            Name = 'CARBON_ENV';
            Ensure = 'Absent';
        }

    #>
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[string]
        # The name of the environment variable.
		$Name,

		[string]
        # The value of the environment variable.
		$Value,

		[ValidateSet("Present","Absent")]
		[string]
        # Set to `Present` to create the environment variable. Set to `Absent` to delete it.
		$Ensure = 'Present'
	)

    Set-StrictMode -Version 'Latest'

    if( $Ensure -eq 'Absent' )
    {
        Write-Verbose ('{0}: removing' -f $Name)
    }

    [Environment]::SetEnvironmentVariable($Name,$null,([EnvironmentVariableTarget]::Machine))
    [Environment]::SetEnvironmentVariable($Name,$null,([EnvironmentVariableTarget]::Process))

    if( $Ensure -eq 'Present' )
    {
        Write-Verbose ('{0}: setting' -f $Name)
        Set-CEnvironmentVariable -Name $Name -Value $Value -ForComputer -ForProcess
    }

}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[String]
		$Name,

		[String]
		$Value,

		[ValidateSet("Present","Absent")]
		[String]
		$Ensure = 'Present'
	)

    Set-StrictMode -Version 'Latest'

    $resource = $null
    $resource = Get-TargetResource -Name $Name

    if( $Ensure -eq 'Present' )
    {
        $result = ($resource.Value -eq $Value);
        if( $result )
        {
            Write-Verbose ('{0}: value OK' -f $Name)
        }
        else
        {
            Write-Verbose ('{0}: value differs' -f $Name)
        }
        return $result
    }
    else
    {
        $result = ($resource.Value -eq $null)
        if( $result )
        {
            Write-Verbose ('{0}: has no value' -f $Name)
        }
        else
        {
            Write-Verbose ('{0}: has a value' -f $Name) 
        }
        return $result
    }

    $false
}

Export-ModuleMember -Function '*-TargetResource'


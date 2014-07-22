
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([Collections.Hashtable])]
	param
	(
		[Parameter(Mandatory=$true)]
		[string]
        # The name of the NPM config value.
		$Name,

		[string]
        # the value of the NPM config value.        
		$Value,

		[ValidateSet("Present","Absent")]
		[string]
        # Create or delete the NPM config value?
		$Ensure
	)
    
    Set-StrictMode -Version 'Latest'

    $value = npm config get $Name --global
    $Ensure = 'Present'

    $exists = $true
    $currentValue = npm config get $Name
    if( $currentValue -eq 'undefined' )
    {
        $exists = Invoke-Command -ScriptBlock {
                            npm config ls -l --global
                            npm config list --global
                        } | Where-Object { $_ -clike ('{0} =' -f $Name) }
        if( $exists )
        {
            $exists = $true
        }
        else
        {
            $exists = $false
        }
    }

    if( $exists )
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
        $currentValue = $null
    }

    @{
        Name = $Name;
        Value = $currentValue;
        Ensure = $Ensure;
    }
}

function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		[string]
        # The name of the NPM config value.
		$Name,

		[string]
        # the value of the NPM config value.        
		$Value,

		[ValidateSet("Present","Absent")]
		[string]
        # Create or delete the NPM config value?
		$Ensure
	)
    
    Set-StrictMode -Version 'Latest'

    $resource = Get-TargetResource -Name $Name
    if( $resource.Ensure -eq 'Present' -and $Ensure -eq 'Absent' )
    {
        Write-Verbose ('Removing {0}' -f $Name)
        npm config delete $Name --global
        return
    }

    if( $Ensure -eq 'Present' )
    {
        Write-Verbose ('Setting {0}' -f $Name)
        npm config set $Name $Value --global
    }
}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory=$true)]
		[string]
        # The name of the NPM config value.
		$Name,

		[string]
        # The value of the NPM config value.        
		$Value,

		[ValidateSet("Present","Absent")]
		[string]
        # Create or delete the NPM config value?
		$Ensure
	)
    
    Set-StrictMode -Version 'Latest'

    $resource = Get-TargetResource -Name $Name
    if( -not $resource )
    {
        return $false
    }

    if( $Ensure -eq 'Present' )
    {
        $result = ($resource.Value -ceq $Value)
        if( $result )
        {
            Write-Verbose ('{0}: current value unchanged' -f $Name)
        }
        else
        {
            Write-Verbose ('{0}: current value differs' -f $Name)
        }
    }
    else
    {
        $result = ($resource.Ensure -eq 'Absent')
        if( $result )
        {
            Write-Verbose ('{0}: not found' -f $Name) 
        }
        else
        {
            Write-Verbose ('{0}: found' -f $Name)
        }
    }
    return $result
}

Export-ModuleMember -Function '*-TargetResource'

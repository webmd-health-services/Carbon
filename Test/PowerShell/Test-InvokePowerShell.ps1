
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldInvokePowerShell
{
    $command = {
        param(
            $Argument
        )
        
        $Argument
    }
    
    $result = Invoke-PowerShell -Command $command -Args 'Hello World!'
    Assert-Equal 'Hello world!' $result
}

function Test-ShouldInvokePowerShellx86
{
    $command = {
        $env:PROCESSOR_ARCHITECTURE
    }
    
    $result = Invoke-PowerShell -Command $command -x86
    Assert-Equal 'x86' $result
}
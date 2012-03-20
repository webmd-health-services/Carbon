
$originalText = $null
$protectedText = $null

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force

    $originalText = [Guid]::NewGuid().ToString()
    $protectedText = Protect-String -String $originalText
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldUnprotectString
{
    $actualText = Unprotect-String -ProtectedString $protectedText
    Assert-Equal $originalText $actualText "String not decrypted."
}


function Test-ShouldUnprotectStringFromMachineScope
{
    $secret = Protect-String -String 'Hello World' -Scope LocalMachine
    $machine = Unprotect-String -ProtectedString $secret
    Assert-Equal 'Hello World' $machine 'decrypting from local machine scope failed'
}

function Test-ShouldUnprotectStringFromUserScope
{
    $secret = Protect-String -String 'Hello World' -Scope CurrentUser
    $machine = Unprotect-String -ProtectedString $secret
    Assert-Equal 'Hello World' $machine 'decrypting from user scope failed'
}


function Test-ShouldUnrotectStringsInPipeline
{
    $secrets = @('Foo','Fizz','Buzz','Bar') | Protect-String | Unprotect-String 
    Assert-Equal 'Foo' $secrets[0] 'Didn''t decrypt first item in pipeline'
    Assert-Equal 'Fizz' $secrets[1] 'Didn''t decrypt first item in pipeline'
    Assert-Equal 'Buzz' $secrets[2] 'Didn''t decrypt first item in pipeline'
    Assert-Equal 'Bar' $secrets[3] 'Didn''t decrypt first item in pipeline'
}

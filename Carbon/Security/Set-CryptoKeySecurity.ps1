# Copyright 2012 Aaron Jensen
# 
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

function Set-CryptoKeySecurity
{
    param(
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        [Parameter(Mandatory=$true)]
        [Security.AccessControl.CryptoKeySecurity]
        $CryptoKeySecurity,

        [Parameter(Mandatory=$true)]
        [string]
        $Action,

        [Parameter(Mandatory=$true)]
        [string]
        # The PS provider path for the certificate. Used to determine where the private key is stored.
        $PSPath
    )

    Set-StrictMode -Version 'Latest'

    $keyContainerInfo = $Certificate.PrivateKey.CspKeyContainerInfo
    $cspParams = New-Object 'Security.Cryptography.CspParameters' ($keyContainerInfo.ProviderType, $keyContainerInfo.ProviderName, $keyContainerInfo.KeyContainerName)
    $cspParams.Flags = [Security.Cryptography.CspProviderFlags]::UseExistingKey
    $cspParams.KeyNumber = $keyContainerInfo.KeyNumber
    if( (Split-Path -NoQualifier -Path $PSPath) -like 'LocalMachine\*' )
    {
        $cspParams.Flags = $cspParams.Flags -bor [Security.Cryptography.CspProviderFlags]::UseMachineKeyStore
    }
    $cspParams.CryptoKeySecurity = $CryptoKeySecurity
                        
    try
    {                    
        # persist the rule change
        if( $PSCmdlet.ShouldProcess( ('{0} ({1})' -f $Certificate.Subject,$Certificate.Thumbprint), $Action ) )
        {
            $null = New-Object 'Security.Cryptography.RSACryptoServiceProvider' ($cspParams)
        }
    }
    catch
    {
        $actualException = $_.Exception
        while( $actualException.InnerException )
        {
            $actualException = $actualException.InnerException
        }
        Write-Error ('Failed to {0} to ''{1}'' ({2}) certificate''s private key: {3}: {4}' -f $Action,$Certificate.Subject,$Certificate.Thumbprint,$actualException.GetType().FullName,$actualException.Message)
    }
}
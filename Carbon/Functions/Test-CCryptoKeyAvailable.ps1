function Test-CCryptoKeyAvailable
{
    return $null -ne [Type]::GetType('System.Security.AccessControl.CryptoKeyRights')
}
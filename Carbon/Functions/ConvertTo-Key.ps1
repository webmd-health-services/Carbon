
function ConvertTo-Key
{
    param(
        $From,
        $InputObject
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState    

    if( $InputObject -isnot [byte[]] )
    {
        if( $InputObject -is [SecureString] )
        {
            $InputObject = Convert-CSecureStringToString -SecureString $InputObject -NoWarn
        }
        elseif( $InputObject -isnot [string] )
        {
            Write-Error -Message ('Encryption key must be a SecureString, a string, or an array of bytes not a {0}. If you are passing an array of bytes, make sure you explicitly cast it as a `byte[]`, e.g. `([byte[]])@( ... )`.' -f $InputObject.GetType().FullName)
            return
        }

        $Key = [Text.Encoding]::UTF8.GetBytes($InputObject)
    }
    else
    {
        $Key = $InputObject
    }

    if( $Key.Length -ne 128/8 -and $Key.Length -ne 192/8 -and $Key.Length -ne 256/8 )
    {
        Write-Error -Message ('Key is the wrong length. {0} is using AES, which requires a 128-bit, 192-bit, or 256-bit key (16, 24, or 32 bytes, respectively). You passed a key of {1} bits ({2} bytes).' -f $From,($Key.Length*8),$Key.Length)
        return
    }

    return $Key
}

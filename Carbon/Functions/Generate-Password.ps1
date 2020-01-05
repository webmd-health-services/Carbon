
function Generate-Password
{
    <#
    .SYNOPSIS
    Creates hard password.

    .DESCRIPTION
    Removes a *local* user account.  If the account doesn't exist, nothing happens.

    .EXAMPLE
    Generate-Password -maxValue 9

    #>
    Param
    (
        [parameter(Mandatory=$true)]
        [ValidateRange(8,99)]
        [Int]
        $maxValue
    ) 
        $newPass = '' 

    1..$maxValue | ForEach-Object { 
        $newPass += [char](Get-Random -Minimum 48 -Maximum 122) 
    }  
    $txt = "Za!" 
    $passnew = $newPass+$txt 
    return $passnew 
}
Generate-Password -maxValue 9



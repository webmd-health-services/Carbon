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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$username = 'CarbonInstallUser'
$password = 'IM33tRequ!rem$'

function Assert-Credential
{
    param(
        $Password
    )

    try
    {
        $ctx = [DirectoryServices.AccountManagement.ContextType]::Machine
        $px = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' $ctx,$env:COMPUTERNAME
        ($px.ValidateCredentials( $username, $password )) | Should -BeTrue
    }
    finally
    {
        $px.Dispose()
    }
}

Describe 'Install-CUser' {
    BeforeEach {
        Remove-TestUser
    }
    
    AfterEach {
        Remove-TestUser
    }
    
    function Remove-TestUser
    {
        Uninstall-CUser -Username $username
    }
    
    It 'should create new user using obsolete function name and parameters' {
        $fullName = 'Carbon Install User'
        $description = "Test user for testing the Carbon Install-CUser function."
        $user = Install-User -UserName $username `
                              -Password $password `
                              -Description $description `
                              -FullName $fullName `
                              -PassThru
        $user | Should -Not -BeNullOrEmpty
        try
        {
            $user | Should -BeOfType ([DirectoryServices.AccountManagement.UserPrincipal])
            (Test-CUser -Username $username) | Should -BeTrue
        }
        finally
        {
            $user.Dispose()
        }
    
        [DirectoryServices.AccountManagement.UserPrincipal]$user = Get-CUser -Username $username
        $user | Should -Not -BeNullOrEmpty
        try
        {
            $user.Description | Should -Be $description
            $user.PasswordNeverExpires | Should -BeTrue
            $user.Enabled | Should -BeTrue
            $user.SamAccountName | Should -Be $username
            $user.UserCannotChangePassword | Should -BeFalse
            $user.DisplayName | Should -Be $fullName
            Assert-Credential -Password $password
        }
        finally
        {
            $user.Dispose()
        }
    }
    
    
    It 'should create new user with credential' {
        $fullName = 'Carbon Install User'
        $description = "Test user for testing the Carbon Install-CUser function."
        $c = New-Credential -UserName $username -Password $password
        $user = Install-CUser -Credential $c -Description $description -FullName $fullName -PassThru
        $user | Should -Not -BeNullOrEmpty
        try
        {
            $user | Should -BeOfType ([DirectoryServices.AccountManagement.UserPrincipal])
            (Test-CUser -Username $username) | Should -BeTrue
        }
        finally
        {
            $user.Dispose()
        }
    
        [DirectoryServices.AccountManagement.UserPrincipal]$user = Get-CUser -Username $username
        $user | Should -Not -BeNullOrEmpty
        try
        {
            $user.Description | Should -Be $description
            $user.PasswordNeverExpires | Should -BeTrue
            $user.Enabled | Should -BeTrue
            $user.SamAccountName | Should -Be $username
            $user.UserCannotChangePassword | Should -BeFalse
            $user.DisplayName | Should -Be $fullName
            Assert-Credential -Password $password
        }
        finally
        {
            $user.Dispose()
        }
    }
    
    It 'should update existing users properties' {
        $fullName = 'Carbon Install User'
        $result = Install-CUser -Username $username -Password $password -Description "Original description" -FullName $fullName
        $result | Should -BeNullOrEmpty
    
        $originalUser = Get-CUser -Username $username
        $originalUser | Should -Not -BeNullOrEmpty
        try
        {
        
            $newFullName = 'New {0}' -f $fullName
            $newDescription = "New description"
            $newPassword = 'IM33tRequ!re$2'
            $result = Install-CUser -Username $username `
                                   -Password $newPassword `
                                   -Description $newDescription `
                                   -FullName $newFullName `
                                   -UserCannotChangePassword `
                                   -PasswordExpires 
            try
            {
                $result | Should -BeNullOrEmpty
            }
            finally
            {
                if( $result )
                {
                    $result.Dispose()
                }
            }
    
            [DirectoryServices.AccountManagement.UserPrincipal]$newUser = Get-CUser -Username $username
            $newUser | Should -Not -BeNullOrEmpty
            try
            {
                $newUser.SID | Should -Be $originalUser.SID
                $newUser.Description | Should -Be $newDescription
                $newUser.DisplayName | Should -Be $newFullName
                $newUser.PasswordNeverExpires | Should -BeFalse
                $newUser.UserCannotChangePassword | Should -BeTrue
                Assert-Credential -Password $newPassword
            }
            finally
            {
                $newUser.Dispose()
            }
        }
        finally
        {
            $originalUser.Dispose()
        }
    }
    
    It 'should update existing users properties with credential' {
        $fullName = 'Carbon Install User'
        $credential = New-Credential -Username $username -Password $password
        $result = Install-CUser -Credential $credential -Description "Original description" -FullName $fullName
        try
        {
            $result | Should -BeNullOrEmpty
        }
        finally
        {
            if( $result )
            {
                $result.Dispose()
            }
        }
    
        $originalUser = Get-CUser -Username $username
        $originalUser | Should -Not -BeNullOrEmpty
        try
        {
        
            $newFullName = 'New {0}' -f $fullName
            $newDescription = "New description"
            $newPassword = [Guid]::NewGuid().ToString().Substring(0,14)
            $credential = New-Credential -UserName $username -Password $newPassword
            
            $result = Install-CUser -Credential $credential `
                                   -Description $newDescription `
                                   -FullName $newFullName `
                                   -UserCannotChangePassword `
                                   -PasswordExpires 
            try
            {
                $result | Should -BeNullOrEmpty
            }
            finally
            {
                if( $result )
                {
                    $result.Dispose()
                }
            }
    
            [DirectoryServices.AccountManagement.UserPrincipal]$newUser = Get-CUser -Username $username
            $newUser | Should -Not -BeNullOrEmpty
            try
            {
                $newUser.SID | Should -Be $originalUser.SID
                $newUser.Description | Should -Be $newDescription
                $newUser.DisplayName | Should -Be $newFullName
                $newUser.PasswordNeverExpires | Should -BeFalse
                $newUser.UserCannotChangePassword | Should -BeTrue
                Assert-Credential -Password $newPassword
            }
            finally
            {
                $newUser.Dispose()
            }
        }
        finally
        {
            $originalUser.Dispose()
        }
    }
    
    It 'should allow optional full name' {
        $fullName = 'Carbon Install User'
        $description = "Test user for testing the Carbon Install-CUser function."
        $result = Install-CUser -Username $username -Password $password -FullName $fullName -Description $description
        try
        {
            $result | Should -BeNullOrEmpty
        }
        finally
        {
            if( $result )
            {
                $result.Dispose()
            }
        }
    
        $user = Get-CUser -Username $Username
        try
        {
            $user.DisplayName | Should -Be $fullName
        }
        finally
        {
            $user.Dispose()
        }
    }
    
    It 'should support what if' {
        $user = Install-CUser -Username $username -Password $password -WhatIf -PassThru
        try
        {
            $user | Should -Not -BeNullOrEmpty
        }
        finally
        {
            $user.Dispose()
        }
    
        $user = Get-CUser -Username $username -ErrorAction SilentlyContinue
        try
        {
            $user | Should -BeNullOrEmpty
        }
        finally
        {
            if( $user )
            {
                $user.Dispose()
            }
        }
    }
}

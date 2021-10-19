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

Describe 'Resolve-PathCase' {
    It 'should get canonical case for directory' {
        $currentDir = (Resolve-Path '.').Path
        foreach( $badPath in ($currentDir.ToUpper(),$currentDir.ToLower()) )
        {
            $canonicalCase = Resolve-CPathCase -Path $badPath
            ($currentDir -ceq $canonicalCase) | Should -BeTrue
        }
    }
    
    It 'should get canonical case for file' {
        $canonicalCase = Resolve-CPathCase -Path ($PSCommandPath.ToUpper())
        ($PSCommandPath -ceq $canonicalCase) | Should -BeTrue
    }
    
    It 'should not get case for file that does not exist' {
        $error.Clear()
        $result = Resolve-CPathCase 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue
        $result | Should -BeNullOrEmpty
        $error.Count | Should -Be 1
    }
    
    It 'should accept pipeline input' {
        Get-ChildItem 'C:\WINDOWS' |
            Resolve-CPathCase |
            Where-Object { $_ -CLike 'C:\Windows\*' } |
            Should -Not -BeNullOrEmpty
    }
    
    It 'should get relative path' {
        Push-Location -Path $PSScriptRoot
        try
        {
            $path = '..\Carbon\Import-Carbon.ps1'
            $canonicalCase = Resolve-CPathCase ($path.ToUpper())
            $canonicalCase | Should -Be (Resolve-Path -Path $path).Path
    
        }
        finally
        {
            Pop-Location
        }
    }
    
    # Only on Windows PowerShell (until we update to use Get-CimInstance).
    $skip = -not (Get-Command -Name 'Get-WmiObject' -ErrorAction Ignore) -or -not (Test-CAdminPrivilege)
    It 'should get path to share' -Skip:$skip {
        $tempDir = New-CTempDirectory -Prefix $PSCommandPath 
        $shareName = Split-Path -Leaf -Path $tempDir
        try
        {
            Install-CFileShare -Name $shareName -Path $tempDir.FullName -ReadAccess 'Everyone'
            try
            {
                $path = '\\{0}\{1}' -f $env:COMPUTERNAME,$shareName
                $canonicalCase = Resolve-CPathCase ($path.ToUpper()) -ErrorAction SilentlyContinue
                $Global:Error.Count | Should -BeGreaterThan 0
                $Global:Error[0] | Should -Match 'UNC .* not supported'
                $canonicalCase | Should -BeNullOrEmpty
            }
            finally
            {
                Uninstall-CFileShare -Name $shareName
            }
        }
        finally
        {
            Remove-Item -Path $tempDir -Recurse -Force
        }
    }
}

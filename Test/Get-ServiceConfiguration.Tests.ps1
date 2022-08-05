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

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Get-ServiceConfiguration' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should load all service configuration' {
        Get-Service | 
            # Skip Carbon services. They could get uninstalled at any moment.
            Where-Object { $_.Name -notlike 'Carbon*' } |
            Get-CServiceConfiguration -ErrorAction 'SilentlyContinue' | 
            Format-List -Property *
        
        # ComputerName parameter does not exists under PowerShell Core.
        if( Get-Command -Name 'Get-Service' -ParameterName 'ComputerName' -ErrorAction Ignore )
        {
            $Global:Error.Count | Should -Be 0
        }
        else
        {
            $Global:Error[0] | Should -Match 'this version of PowerShell doesn''t support services on remote computers.'
        }
    }

    It 'should write an error if the service doesn''t exist' {
        $info = Get-CServiceConfiguration -Name 'YOLOyolo' -ErrorAction SilentlyContinue
        $info | Should -BeNullOrEmpty
        $Global:Error | Should -Match 'Cannot\ find\ any\ service'
    }

    It 'should ignore missing service' {
        $info = Get-CServiceConfiguration -Name 'FUBARsnafu' -ErrorAction Ignore
        $info | Should -BeNullOrEmpty
        $Global:Error | Should -BeNullOrEmpty
    }
    
    It 'should load extended type data' {
        $services = Get-Service | Where-Object { $_.Name -notlike 'Carbon*' }
        $memberNames = $null
            
        foreach( $service in $services )
        {
            $info = Get-CServiceConfiguration -Name $service.Name
            if( -not $memberNames )
            {
                $memberNames = 
                    $info | 
                    Get-Member -MemberType 'Property' | 
                    Select-Object -ExpandProperty 'Name'
            }

            foreach( $memberName in $memberNames )
            {
                $info.$memberName | Should -Be $service.$memberName
            }
        }
        $Global:Error.Count | Should -Be 0
    }
}

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//   
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
using System;

namespace Carbon.Security
{
	// from https://msdn.microsoft.com/en-us/library/aa394063.aspx
	[Flags]
	internal enum AceAccessMask : int
	{
		ReadData = 0x1,
		WriteData  = 0x2,
		AppendData = 0x4,
		ReadExtendedAttribute = 0x8,
		WriteExtendedAttribute = 0x10,
		ExecuteOrTraverse = 0x20,
		DeleteChild = 0x40,
		ReadAttributes = 0x80,
		WriteAttributes = 0x100,
		Delete = 0x10000,
		ReadControl = 0x20000,
		WriteDac = 0x40000,
		WriteOwner = 0x80000,
		Synchronize = 0x100000
	}

	[Flags]
	public enum ShareRights : int
	{
		// 0010 0000 0000 1010 1001: 0x1 |             0x8 |        0x20 |        0x80 |                   0x20000                    
		Read = AceAccessMask.ReadData | 
						AceAccessMask.ReadExtendedAttribute | 
						AceAccessMask.ExecuteOrTraverse | 
						AceAccessMask.ReadAttributes | 
						AceAccessMask.ReadControl |
						AceAccessMask.Synchronize,
		// 0011 0000 0001 1011 1111: 0x1 | 0x2 | 0x4 | 0x8 | 0x10 | 0x20 |        0x80 | 0x100 | 0x10000 | 0x20000                    
		Change = Read | AceAccessMask.WriteData |
							AceAccessMask.AppendData |
							AceAccessMask.WriteExtendedAttribute |
							AceAccessMask.WriteAttributes |
							AceAccessMask.Delete,
		// 1111 0000 0001 1111 1111: 0x1 | 0x2 | 0x4 | 0x8 | 0x10 | 0x20 | 0x40 | 0x80 | 0x100 | 0x10000 | 0x20000 | 0x40000 | 0x80000
		FullControl = Change | AceAccessMask.DeleteChild |
									AceAccessMask.WriteDac |
									AceAccessMask.WriteOwner
	}
}


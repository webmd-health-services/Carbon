// Copyright 2012 Aaron Jensen
//   
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

namespace Carbon
{
    public static class Win32ErrorCodes
    {
        public const int ACCESS_DENIED             = 0x005;
        public const int INVALID_HANDLE            = 0x006;
        public const int INVALID_PARAMETER         = 0x057;
        public const int INSUFFICIENT_BUFFER       = 0x07A;
        public const int INVALID_FLAGS             = 0x3EC;
        public const int SERVICE_MARKED_FOR_DELETE = 0x430;
        public const int NONE_MAPPED               = 0x534;
    }
}

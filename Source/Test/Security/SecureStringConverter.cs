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

using NUnit.Framework;

namespace Carbon.Test.Security
{
    [TestFixture]
    public sealed class SecureStringConverterTestFixture
    {
        [Test]
        public void ShouldConvertSecureString()
        {
            const string password = "waffles";
            var securePassword = new System.Security.SecureString();
            foreach( var passwordChar in password.ToCharArray() )
            {
                securePassword.AppendChar(passwordChar);
            }

            var securePasswordBytes = Carbon.Security.SecureStringConverter.ToBytes(securePassword);

            var passwordBytes = System.Text.Encoding.UTF8.GetBytes(password);
            Assert.That(passwordBytes.Length, Is.EqualTo(securePasswordBytes.Length));
            for (var idx = 0; idx < passwordBytes.Length; ++idx)
            {
                Assert.That(passwordBytes[idx], Is.EqualTo(securePasswordBytes[idx]));
            }
        }
    }
}

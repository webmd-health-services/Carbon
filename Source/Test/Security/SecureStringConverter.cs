using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using NUnit.Framework;

namespace Carbon.Test.Security
{
    [TestFixture]
    public sealed class SecureStringConverterTestFixture
    {
        [Test]
        public void ShouldConvertSecureString()
        {
            var password = "waffles";
            var passwordChars = password.ToCharArray();
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

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
using System.Net;
using Carbon.Certificates;
using NUnit.Framework;

namespace Carbon.Test.Certificates
{
    [TestFixture]
    public sealed class SslCertificateBindingTestFixture
    {
	    [Test]
	    public void ShouldGetAllBindings()
	    {
		    SslCertificateBinding.GetSslCertificateBindings();
	    }

        [Test]
        public void ShouldCompareTwoBindings()
        {
            var binding1 = new SslCertificateBinding(IPAddress.Parse("10.1.1.1"), 4838,
                "1234567890abcdef1234567890abcdef12345678", Guid.NewGuid(), null, false, false, false, 0, 0, null, null,
                false, false);
            var binding2 = new SslCertificateBinding(binding1.IPAddress, binding1.Port, binding1.CertificateHash,
                binding1.ApplicationID, null, false, false, false, 0, 0, null, null, false, false);

            Assert.That(binding1, Is.EqualTo(binding2));
        }

        [Test]
        public void ShouldCompareNull()
        {
            var binding1 = new SslCertificateBinding(IPAddress.Parse("10.1.1.1"), 4838,
                "1234567890abcdef1234567890abcdef12345678", Guid.NewGuid(), null, false, false, false, 0, 0, null, null,
                false, false);

            Assert.That(binding1.Equals(null), Is.False);
        }

        [Test]
        public void ShouldCompareDifferentObject()
        {
            var binding1 = new SslCertificateBinding(IPAddress.Parse("10.1.1.1"), 4838,
                "1234567890abcdef1234567890abcdef12345678", Guid.NewGuid(), null, false, false, false, 0, 0, null, null,
                false, false);

            Assert.That(binding1.Equals("10.1.1.1"), Is.False);
        }
    }
}


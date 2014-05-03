using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Runtime.Remoting;
using System.Text;
using Carbon.Certificates;
using NUnit.Framework;

namespace Carbon.Test.Certificates
{
    [TestFixture]
    public sealed class SslCertificateBindingTestFixture
    {
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

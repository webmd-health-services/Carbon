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

using System;
using System.Net;
using System.Security.Cryptography.X509Certificates;
using System.Text.RegularExpressions;

namespace Carbon.Certificates
{
    public sealed class SslCertificateBinding
    {
        public SslCertificateBinding(
            IPAddress ipAddress, ushort port, string certificateHash, Guid applicationID, StoreName? storeName, bool verifyClientCertRevocation,  
            bool verifyRevocationUsingCachedClientCertsOnly, bool usageCheckEnabled, uint revocationFreshnessTime, uint urlRetrievalTimeout, string ctlIdentifier, 
            string ctlStoreName, bool dsMapperUsageEnabled, bool negotiateClientCertificate)
        {
            IPAddress = ipAddress;
            Port = port;
            ApplicationID = applicationID;
            CertificateHash = certificateHash;
            CertificateStoreName = storeName;
            VerifyClientCertificateRevocation = verifyClientCertRevocation;
            VerifyRevocationUsingCachedClientCertificatesOnly = verifyRevocationUsingCachedClientCertsOnly;
            UsageCheckEnabled = usageCheckEnabled;
            RevocationFreshnessTime = revocationFreshnessTime;
            UrlRetrievalTimeout = urlRetrievalTimeout;
            CtlIdentifier = ctlIdentifier;
            CtlStoreName = ctlStoreName;
            DSMapperUsageEnabled = dsMapperUsageEnabled;
            NegotiateClientCertificate = negotiateClientCertificate;
        }

        public Guid ApplicationID { get; private set; }

        public string CertificateHash { get; private set; }

        public StoreName? CertificateStoreName { get; private set; }

        public string CtlIdentifier { get; private set; }

        public string CtlStoreName { get; private set; }

        public bool DSMapperUsageEnabled { get; private set; }

        public IPAddress IPAddress { get; private set; }

        public string IPPort
        {
            get { return string.Format("{0}:{1}", IPAddress, Port); }
        }

        public bool NegotiateClientCertificate { get; private set; }

        public ushort Port { get; private set; }

        public uint RevocationFreshnessTime { get; private set; }

        public uint UrlRetrievalTimeout { get; private set; }

        public bool UsageCheckEnabled { get; private set; }

        public bool VerifyClientCertificateRevocation { get; private set; }

        public bool VerifyRevocationUsingCachedClientCertificatesOnly { get; private set; }

        public override bool Equals(object obj)
        {
            var binding = obj as SslCertificateBinding;

            if (binding == null)
            {
                return false;
            }

            return IPAddress.Equals(binding.IPAddress) &&
                   Port.Equals(binding.Port) &&
                   CertificateHash.Equals(binding.CertificateHash) &&
                   ApplicationID.Equals(binding.ApplicationID);
        }

        public override int GetHashCode()
        {
            unchecked // Overflow is fine, just wrap
            {
                int hash = 17;
                // Suitable nullity checks etc, of course :)
                hash = hash * 23 + IPAddress.GetHashCode();
                hash = hash * 23 + Port.GetHashCode();
                hash = hash * 23 + CertificateHash.GetHashCode();
                hash = hash * 23 + ApplicationID.GetHashCode();
                return hash;
            }
        }
    }
}

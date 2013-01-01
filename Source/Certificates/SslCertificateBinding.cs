using System;
using System.Net;
using System.Security.Cryptography.X509Certificates;

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
    }
}

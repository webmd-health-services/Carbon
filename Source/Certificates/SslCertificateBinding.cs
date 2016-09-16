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
using System.Collections.Generic;
using System.ComponentModel;
using System.Net;
using System.Runtime.InteropServices;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.RegularExpressions;
using Carbon.Win32;

namespace Carbon.Certificates
{
    public sealed class SslCertificateBinding
    {

		#region httpapi.dll
		private const uint HttpInitializeConfig = 0x00000002;

		[Flags]
	    private enum SslParamDefaultFlags : uint
	    {
			UseDsMapper = 0x00000001,
			NegotiateClientCert = 0x00000002,
			NoRawFilter = 0x00000004
	    }

		// ReSharper disable InconsistentNaming
		// ReSharper disable FieldCanBeMadeReadOnly.Local
		// ReSharper disable OptionalParameterRefOut
		// ReSharper disable MemberCanBePrivate.Local
		// ReSharper disable UnusedMember.Local
		private enum HTTP_SERVICE_CONFIG_ID
		{
			HttpServiceConfigIPListenList = 0,
			HttpServiceConfigSSLCertInfo,
			HttpServiceConfigUrlAclInfo,
			HttpServiceConfigMax
		}

		private enum HTTP_SERVICE_CONFIG_QUERY_TYPE
		{
			HttpServiceConfigQueryExact = 0,
			HttpServiceConfigQueryNext,
			HttpServiceConfigQueryMax
		}

		[StructLayout(LayoutKind.Sequential)]
		private struct HTTP_SERVICE_CONFIG_SSL_KEY
		{
			public IntPtr pIpPort;
		}
		
		[StructLayout(LayoutKind.Sequential)]
		private struct HTTP_SERVICE_CONFIG_SSL_QUERY
		{
			public HTTP_SERVICE_CONFIG_QUERY_TYPE QueryDesc;
			public HTTP_SERVICE_CONFIG_SSL_KEY KeyDesc;
			public uint dwToken;
		}
		
		[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
		private struct HTTP_SERVICE_CONFIG_URLACL_KEY
		{
			[MarshalAs(UnmanagedType.LPWStr)]
			public string pUrlPrefix;

			public HTTP_SERVICE_CONFIG_URLACL_KEY(string urlPrefix)
			{
				pUrlPrefix = urlPrefix;
			}
		}

		[StructLayout(LayoutKind.Sequential)]
		private struct HTTP_SERVICE_CONFIG_URLACL_QUERY
		{
			public HTTP_SERVICE_CONFIG_QUERY_TYPE QueryDesc;
			public HTTP_SERVICE_CONFIG_URLACL_KEY KeyDesc;
			public uint dwToken;
		}

		[StructLayout(LayoutKind.Sequential, Pack = 2)]
		private struct HTTPAPI_VERSION
		{
			public ushort HttpApiMajorVersion;
			public ushort HttpApiMinorVersion;

			public HTTPAPI_VERSION(ushort majorVersion, ushort minorVersion)
			{
				HttpApiMajorVersion = majorVersion;
				HttpApiMinorVersion = minorVersion;
			}
		}

		[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
		private struct HTTP_SERVICE_CONFIG_SSL_PARAM
		{
			public int SslHashLength;
			public IntPtr pSslHash;
			public Guid AppId;
			[MarshalAs(UnmanagedType.LPWStr)]
			public string pSslCertStoreName;
			public uint DefaultCertCheckMode;
			public int DefaultRevocationFreshnessTime;
			public int DefaultRevocationUrlRetrievalTimeout;
			[MarshalAs(UnmanagedType.LPWStr)]
			public string pDefaultSslCtlIdentifier;
			[MarshalAs(UnmanagedType.LPWStr)]
			public string pDefaultSslCtlStoreName;
			public SslParamDefaultFlags DefaultFlags;
		}
		
		[StructLayout(LayoutKind.Sequential)]
		private struct HTTP_SERVICE_CONFIG_SSL_SET
		{
			public HTTP_SERVICE_CONFIG_SSL_KEY KeyDesc;
			public HTTP_SERVICE_CONFIG_SSL_PARAM ParamDesc;
		}
		
		[DllImport("httpapi.dll", SetLastError = true)]
		private static extern ulong HttpInitialize(HTTPAPI_VERSION Version, uint Flags, IntPtr pReserved);

		[DllImport("httpapi.dll", SetLastError = true)]
		private static extern ulong HttpQueryServiceConfiguration(
			IntPtr ServiceIntPtr,
			HTTP_SERVICE_CONFIG_ID ConfigId,
			IntPtr pInputConfigInfo,
			int InputConfigInfoLength,
			IntPtr pOutputConfigInfo,
			int OutputConfigInfoLength,
			[Optional] out int pReturnLength,
			IntPtr pOverlapped);

		[DllImport("httpapi.dll", SetLastError = true)]
		static extern ulong HttpDeleteServiceConfiguration(
			 IntPtr ServiceIntPtr,
			 HTTP_SERVICE_CONFIG_ID ConfigId,
			 IntPtr pConfigInformation,
			 int ConfigInformationLength,
			 IntPtr pOverlapped);

		[DllImport("httpapi.dll", SetLastError = true)]
		static extern ulong HttpSetServiceConfiguration(
			 IntPtr ServiceIntPtr,
			 HTTP_SERVICE_CONFIG_ID ConfigId,
			 IntPtr pConfigInformation,
			 int ConfigInformationLength,
			 IntPtr pOverlapped);

		[DllImport("httpapi.dll", SetLastError = true)]
		private static extern ulong HttpTerminate(uint Flags, IntPtr pReserved);

		private enum SockAddrFamily
		{
			Inet = 2,
			Inet6 = 23
		}

		[StructLayout(LayoutKind.Sequential)]
		private struct SockAddr
		{
			public ushort Family;
			[MarshalAs(UnmanagedType.ByValArray, SizeConst = 14)]
			public byte[] Data;
		};

		[StructLayout(LayoutKind.Sequential)]
		private struct SockAddrIn
		{
			public ushort Family;
			public ushort Port;
			public uint Addr;
			[MarshalAs(UnmanagedType.ByValArray, SizeConst = 8)]
			public byte[] Zero;
		}

		[StructLayout(LayoutKind.Sequential)]
		private struct SockAddrIn6
		{
			public ushort Family;
			public ushort Port;
			public uint FlowInfo;
			[MarshalAs(UnmanagedType.ByValArray, SizeConst = 16)]
			public byte[] Addr;
			public uint ScopeId;
		};

	    private static IPAddress ConvertSockAddrPtrToIPAddress(IntPtr sockAddrPtr, out ushort port)
	    {
		    var sockAddr = (SockAddr) Marshal.PtrToStructure(sockAddrPtr, typeof (SockAddr));
		    switch ((SockAddrFamily) sockAddr.Family)
		    {
			    case SockAddrFamily.Inet:
			    {
				    var sockAddrIn = (SockAddrIn) Marshal.PtrToStructure(sockAddrPtr, typeof (SockAddrIn));
				    port = sockAddrIn.Port;
				    return new IPAddress(sockAddrIn.Addr);
			    }
			    case SockAddrFamily.Inet6:
			    {
				    var sockAddrIn6 = (SockAddrIn6) Marshal.PtrToStructure(sockAddrPtr, typeof (SockAddrIn6));
				    port = sockAddrIn6.Port;
				    return new IPAddress(sockAddrIn6.Addr);
			    }
			    default:
				    throw new Exception(string.Format("Non-IP address family: {0}", sockAddr.Family));
		    }
	    }

	    // ReSharper restore UnusedMember.Local
		// ReSharper restore MemberCanBePrivate.Local
		// ReSharper restore OptionalParameterRefOut
		// ReSharper restore FieldCanBeMadeReadOnly.Local
		// ReSharper restore InconsistentNaming
		#endregion

		public SslCertificateBinding(
            IPAddress ipAddress, ushort port, string certificateHash, Guid applicationID, StoreName? storeName, bool verifyClientCertRevocation,  
            bool verifyRevocationUsingCachedClientCertsOnly, bool usageCheckEnabled, uint revocationFreshnessTime, uint urlRetrievalTimeout, string ctlIdentifier, 
            string ctlStoreName, bool dsMapperUsageEnabled, bool negotiateClientCertificate)
        {
            if (ipAddress == null)
            {
                throw new ArgumentNullException("ipAddress");
            }

            if ( ! Regex.IsMatch(certificateHash, "^[0-9a-f]{40}$") )
            {
                throw new ArgumentException(
                    string.Format("'{0}' not a valid certificate hash/thumbprint.", certificateHash), "certificateHash");
            }

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

		[StructLayout(LayoutKind.Sequential)]
		internal struct sockaddr_in
		{
			internal short sin_family;
			internal ushort sin_port;
			internal in_addr sin_addr;
			[MarshalAs(UnmanagedType.ByValArray, SizeConst = 8)]
			internal byte[] sin_zero;

		}

		[StructLayout(LayoutKind.Explicit, Size = 4)]
		internal struct in_addr
		{
			[FieldOffset(0)]
			internal byte s_b1;
			[FieldOffset(1)]
			internal byte s_b2;
			[FieldOffset(2)]
			internal byte s_b3;
			[FieldOffset(3)]
			internal byte s_b4;

			[FieldOffset(0)]
			internal ushort s_w1;
			[FieldOffset(2)]
			internal ushort s_w2;

			[FieldOffset(0)]
			internal uint S_addr;

			/// <summary>
			/// can be used for most tcp & ip code
			/// </summary>
			internal uint s_addr
			{
				get { return S_addr; }
			}

			/// <summary>
			/// host on imp
			/// </summary>
			internal byte s_host
			{
				get { return s_b2; }
			}

			/// <summary>
			/// network
			/// </summary>
			internal byte s_net
			{
				get { return s_b1; }
			}

			/// <summary>
			/// imp
			/// </summary>
			internal ushort s_imp
			{
				get { return s_w2; }
			}

			/// <summary>
			/// imp #
			/// </summary>
			internal byte s_impno
			{
				get { return s_b4; }
			}

			/// <summary>
			/// logical host
			/// </summary>
			internal byte s_lh
			{
				get { return s_b3; }
			}
		}
		
		public static SslCertificateBinding[] GetSslCertificateBindings()
		{

			InitializeHttp();

			try
			{
				var bindings = new List<SslCertificateBinding>();

				uint recordNum = 0;
				while (true)
				{
					var inputConfigInfoQuery = new HTTP_SERVICE_CONFIG_SSL_QUERY 
					{
						QueryDesc = HTTP_SERVICE_CONFIG_QUERY_TYPE.HttpServiceConfigQueryNext,
						dwToken = recordNum++
					};

					var size = Marshal.SizeOf(typeof(HTTP_SERVICE_CONFIG_SSL_QUERY));
					var pInputConfigInfo = Marshal.AllocCoTaskMem(size);
					Marshal.StructureToPtr(inputConfigInfoQuery, pInputConfigInfo, false);

					var pOutputConfigInfo = Marshal.AllocCoTaskMem(0);
					var returnLength = 0;

					var retVal = HttpQueryServiceConfiguration(IntPtr.Zero,
						HTTP_SERVICE_CONFIG_ID.HttpServiceConfigSSLCertInfo,
						pInputConfigInfo,
						Marshal.SizeOf(inputConfigInfoQuery),
						pOutputConfigInfo,
						returnLength,
						out returnLength,
						IntPtr.Zero);

					if (Win32ErrorCodes.InsufficientBuffer == retVal)
					{
						Marshal.FreeCoTaskMem(pOutputConfigInfo);
						pOutputConfigInfo = Marshal.AllocCoTaskMem(Convert.ToInt32(returnLength));

						retVal = HttpQueryServiceConfiguration(IntPtr.Zero,
							HTTP_SERVICE_CONFIG_ID.HttpServiceConfigSSLCertInfo,
							pInputConfigInfo,
							Marshal.SizeOf(inputConfigInfoQuery),
							pOutputConfigInfo,
							returnLength,
							out returnLength,
							IntPtr.Zero);
					}
					else if (Win32ErrorCodes.NoMoreItems == retVal)
					{
						break;
					}

					if (Win32ErrorCodes.Ok == retVal)
					{
						var outputConfigInfo = (HTTP_SERVICE_CONFIG_SSL_SET)
							Marshal.PtrToStructure(pOutputConfigInfo, typeof(HTTP_SERVICE_CONFIG_SSL_SET));

						var paramInfo = outputConfigInfo.ParamDesc;
						ushort port;
						var ipAddress = ConvertSockAddrPtrToIPAddress(outputConfigInfo.KeyDesc.pIpPort, out port);
						var portBytes = BitConverter.GetBytes(port);
						var reversedPortBytes = new [] {portBytes[1], portBytes[0]};
						port = BitConverter.ToUInt16(reversedPortBytes, 0);

						var hash = new byte[outputConfigInfo.ParamDesc.SslHashLength];
						Marshal.Copy(outputConfigInfo.ParamDesc.pSslHash, hash, 0, hash.Length);

						var hex = new StringBuilder(hash.Length * 2);
						foreach (var b in hash)
						{
							hex.AppendFormat("{0:x2}", b);
						}
						var certificateHash = hex.ToString();

						var appID = paramInfo.AppId;

						var storeName = ConvertToStoreName(paramInfo.pSslCertStoreName);

						var verifyClientCertRevocation = ((paramInfo.DefaultCertCheckMode & 1) == 0);
						var verifyRevocationUsingCachedClientCertsOnly = (paramInfo.DefaultCertCheckMode & 2) == 2;
						var usageCheckEnabled = (paramInfo.DefaultCertCheckMode & 16) == 0;
						var revocationFreshnessTime = (uint)paramInfo.DefaultRevocationFreshnessTime;
						var urlRetrievalTimeout = (uint)paramInfo.DefaultRevocationUrlRetrievalTimeout;
						string ctlIdentifier = paramInfo.pDefaultSslCtlIdentifier ?? String.Empty;
						string ctlStoreName = paramInfo.pDefaultSslCtlStoreName ?? String.Empty;
						var dsMapperUsageEnabled = paramInfo.DefaultFlags.HasFlag(SslParamDefaultFlags.UseDsMapper);
						var negotiateClientCertificate = paramInfo.DefaultFlags.HasFlag(SslParamDefaultFlags.NegotiateClientCert);

						var binding = new SslCertificateBinding(ipAddress, port, certificateHash, appID, storeName,
							verifyClientCertRevocation,
							verifyRevocationUsingCachedClientCertsOnly, usageCheckEnabled, revocationFreshnessTime, urlRetrievalTimeout,
							ctlIdentifier, ctlStoreName, dsMapperUsageEnabled, negotiateClientCertificate);

						bindings.Add(binding);
					}
					else
					{
						throw new Win32Exception();
					}

				}

				return bindings.ToArray();
			}
			finally
			{
				TerminateHttp();
			}
		}

	    private static StoreName? ConvertToStoreName(string name)
	    {
			StoreName storeNameEnum;
			if (Enum.TryParse(name, true, out storeNameEnum))
			{
				return storeNameEnum;
			}
		    return null;
	    }

		private static void InitializeHttp()
		{
			var httpApiVersion = new HTTPAPI_VERSION(1, 0);

			var retVal = HttpInitialize(httpApiVersion, HttpInitializeConfig, IntPtr.Zero);
			if (Win32ErrorCodes.Ok != retVal)
			{
				throw new Win32Exception();
			}
		}

		private static void TerminateHttp()
		{
			HttpTerminate(HttpInitializeConfig, IntPtr.Zero);
		}
	}
}


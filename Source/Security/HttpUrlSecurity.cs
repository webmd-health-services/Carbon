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
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using Carbon.Win32;

namespace Carbon.Security
{
	public sealed class HttpUrlSecurity : CommonObjectSecurity
	{
		private const uint HttpInitializeConfig = 0x00000002;
		private const string AuditingNotSupportedMessage = "HTTP URL security does not support audit rules.";

		#region httpapi.dll
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

		[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
		private struct HTTP_SERVICE_CONFIG_URLACL_KEY
		{
			[MarshalAs(UnmanagedType.LPWStr)] public string pUrlPrefix;

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
		private struct HTTP_SERVICE_CONFIG_URLACL_PARAM
		{
			[MarshalAs(UnmanagedType.LPWStr)] public string pStringSecurityDescriptor;

			public HTTP_SERVICE_CONFIG_URLACL_PARAM(string securityDescriptor)
			{
				pStringSecurityDescriptor = securityDescriptor;
			}
		}

		[StructLayout(LayoutKind.Sequential)]
		private struct HTTP_SERVICE_CONFIG_URLACL_SET
		{
			public HTTP_SERVICE_CONFIG_URLACL_KEY KeyDesc;
			public HTTP_SERVICE_CONFIG_URLACL_PARAM ParamDesc;
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
		// ReSharper restore UnusedMember.Local
		// ReSharper restore MemberCanBePrivate.Local
		// ReSharper restore OptionalParameterRefOut
		// ReSharper restore FieldCanBeMadeReadOnly.Local
		// ReSharper restore InconsistentNaming
		#endregion

		public HttpUrlSecurity(string url) : base(false)
		{
			if (! url.EndsWith("/"))
			{
				url = string.Format("{0}/", url);
			}

			Url = url;
		}

		public override Type AccessRightType
		{
			get { return typeof(HttpUrlAccessRights); }
		}

		public override Type AccessRuleType
		{
			get { return typeof(HttpUrlAccessRule); }
		}

		public override Type AuditRuleType
		{
			get { throw new NotImplementedException(AuditingNotSupportedMessage); }
		}

		public string Url { get; private set; }

		public override AccessRule AccessRuleFactory(IdentityReference identityReference, int accessMask, bool isInherited,
			InheritanceFlags inheritanceFlags, PropagationFlags propagationFlags, AccessControlType type)
		{
			return new HttpUrlAccessRule(identityReference, (HttpUrlAccessRights)accessMask);
		}

		public override AuditRule AuditRuleFactory(IdentityReference identityReference, int accessMask, bool isInherited,
			InheritanceFlags inheritanceFlags, PropagationFlags propagationFlags, AuditFlags flags)
		{
			throw new NotImplementedException(AuditingNotSupportedMessage);
		}

		public static HttpUrlSecurity[] GetHttpUrlSecurity()
		{

			InitializeHttp();

			try
			{
				var urls = new List<HttpUrlSecurity>();

				uint recordNum = 0;
				while (true)
				{
					var inputConfigInfoQuery = new HTTP_SERVICE_CONFIG_URLACL_QUERY
					{
						QueryDesc = HTTP_SERVICE_CONFIG_QUERY_TYPE.HttpServiceConfigQueryNext,
						dwToken = recordNum++
					};

					var size = Marshal.SizeOf(typeof(HTTP_SERVICE_CONFIG_URLACL_QUERY));
					var pInputConfigInfo = Marshal.AllocCoTaskMem(size);
					Marshal.StructureToPtr(inputConfigInfoQuery, pInputConfigInfo, false);

					var pOutputConfigInfo = Marshal.AllocCoTaskMem(0);
					var returnLength = 0;

					var retVal = HttpQueryServiceConfiguration(IntPtr.Zero,
						HTTP_SERVICE_CONFIG_ID.HttpServiceConfigUrlAclInfo,
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
							HTTP_SERVICE_CONFIG_ID.HttpServiceConfigUrlAclInfo,
							pInputConfigInfo,
							Marshal.SizeOf(inputConfigInfoQuery),
							pOutputConfigInfo,
							returnLength,
							out returnLength,
							IntPtr.Zero);
					}
					else if( Win32ErrorCodes.NoMoreItems == retVal )
					{
						break;
					}

					if (Win32ErrorCodes.Ok == retVal)
					{
						var outputConfigInfo = (HTTP_SERVICE_CONFIG_URLACL_SET)
							Marshal.PtrToStructure(pOutputConfigInfo, typeof(HTTP_SERVICE_CONFIG_URLACL_SET));
						var sd = new CommonSecurityDescriptor(false, false, outputConfigInfo.ParamDesc.pStringSecurityDescriptor);
						var urlAcl = new HttpUrlSecurity(outputConfigInfo.KeyDesc.pUrlPrefix);

						foreach (var genericAce in sd.DiscretionaryAcl)
						{
							var rule = (CommonAce) genericAce;
							IdentityReference id = rule.SecurityIdentifier;
							if (id.IsValidTargetType(typeof(NTAccount)))
							{
                                try
                                {
                                    id = id.Translate(typeof(NTAccount));
                                }
                                catch
                                {
                                }
                            }
							urlAcl.AddAccessRule(new HttpUrlAccessRule(id, (HttpUrlAccessRights)rule.AccessMask));
						}
						urls.Add(urlAcl);
					}
					else
					{
						throw new Win32Exception();
					}

				}

				return urls.ToArray();
			}
			finally
			{
				TerminateHttp();
			}
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

		public void RemoveAccessRule(HttpUrlAccessRule rule)
		{
			RemoveAccessRuleAll(rule);
			SetHttpUrlSddl();
		}

		public void SetAccessRule(HttpUrlAccessRule rule)
		{
			AddAccessRule(rule);
			SetHttpUrlSddl();
		}

		private void SetHttpUrlSddl()
		{
			InitializeHttp();

			try
			{
				var keyDesc = new HTTP_SERVICE_CONFIG_URLACL_KEY(Url);

				var sddl = GetSecurityDescriptorSddlForm(AccessControlSections.Access);

				var paramDesc = new HTTP_SERVICE_CONFIG_URLACL_PARAM(sddl);

				var inputConfigInfoSet = new HTTP_SERVICE_CONFIG_URLACL_SET {KeyDesc = keyDesc, ParamDesc = paramDesc};

				var pInputConfigInfo = Marshal.AllocCoTaskMem(Marshal.SizeOf(typeof (HTTP_SERVICE_CONFIG_URLACL_SET)));
				Marshal.StructureToPtr(inputConfigInfoSet, pInputConfigInfo, false);

				ulong retVal;
				var currentAccess = GetAccessRules(true, true, typeof (SecurityIdentifier));
				if (currentAccess.Count == 0)
				{
					retVal = HttpDeleteServiceConfiguration(IntPtr.Zero,
						HTTP_SERVICE_CONFIG_ID.HttpServiceConfigUrlAclInfo,
						pInputConfigInfo,
						Marshal.SizeOf(inputConfigInfoSet),
						IntPtr.Zero);
				}
				else
				{
					retVal = HttpSetServiceConfiguration(IntPtr.Zero,
						HTTP_SERVICE_CONFIG_ID.HttpServiceConfigUrlAclInfo,
						pInputConfigInfo,
						Marshal.SizeOf(inputConfigInfoSet),
						IntPtr.Zero);

					if (Win32ErrorCodes.AlreadyExists == retVal)
					{
						retVal = HttpDeleteServiceConfiguration(IntPtr.Zero,
							HTTP_SERVICE_CONFIG_ID.HttpServiceConfigUrlAclInfo,
							pInputConfigInfo,
							Marshal.SizeOf(inputConfigInfoSet),
							IntPtr.Zero);

						if (Win32ErrorCodes.Ok == retVal)
						{
							retVal = HttpSetServiceConfiguration(IntPtr.Zero,
								HTTP_SERVICE_CONFIG_ID.HttpServiceConfigUrlAclInfo,
								pInputConfigInfo,
								Marshal.SizeOf(inputConfigInfoSet),
								IntPtr.Zero);
						}
					}
				}

				if (Win32ErrorCodes.Ok != retVal)
				{
					throw new Win32Exception();
				}

				Marshal.FreeCoTaskMem(pInputConfigInfo);
			}
			finally
			{
				TerminateHttp();
			}
		}

		private static void TerminateHttp()
		{
			HttpTerminate(HttpInitializeConfig, IntPtr.Zero);
		}

	}
}

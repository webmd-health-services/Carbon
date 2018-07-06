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

internal static class SslCert
{
    private static readonly HTTPAPI_VERSION HttpApiVersion = new HTTPAPI_VERSION(1, 0);

    #region DllImport

    [DllImport("httpapi.dll", SetLastError = true)]
    static extern uint HttpInitialize(
        HTTPAPI_VERSION version,
        uint flags,
        IntPtr pReserved);

    [DllImport("httpapi.dll", SetLastError = true)]
    static extern uint HttpSetServiceConfiguration(
            IntPtr serviceIntPtr,
            HTTP_SERVICE_CONFIG_ID configId,
            IntPtr pConfigInformation,
            int configInformationLength,
            IntPtr pOverlapped);

    [DllImport("httpapi.dll", SetLastError = true)]
    static extern uint HttpDeleteServiceConfiguration(
        IntPtr serviceIntPtr,
        HTTP_SERVICE_CONFIG_ID configId,
        IntPtr pConfigInformation,
        int configInformationLength,
        IntPtr pOverlapped);

    [DllImport("httpapi.dll", SetLastError = true)]
    static extern uint HttpTerminate(
        uint Flags,
        IntPtr pReserved);

    [DllImport("httpapi.dll", SetLastError = true)]
    static extern uint HttpQueryServiceConfiguration(
            IntPtr serviceIntPtr,
            HTTP_SERVICE_CONFIG_ID configId,
            IntPtr pInputConfigInfo,
            int inputConfigInfoLength,
            IntPtr pOutputConfigInfo,
            int outputConfigInfoLength,
            [Optional]
                    out int pReturnLength,
            IntPtr pOverlapped);


    enum HTTP_SERVICE_CONFIG_ID
    {

        HttpServiceConfigIPListenList = 0,
        HttpServiceConfigSSLCertInfo,
        HttpServiceConfigUrlAclInfo,
        HttpServiceConfigMax
    }

    [StructLayout(LayoutKind.Sequential)]
    struct HTTP_SERVICE_CONFIG_SSL_SET
    {
        public HTTP_SERVICE_CONFIG_SSL_KEY KeyDesc;
        public HTTP_SERVICE_CONFIG_SSL_PARAM ParamDesc;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct HTTP_SERVICE_CONFIG_SSL_KEY
    {
        public IntPtr pIpPort;

        public HTTP_SERVICE_CONFIG_SSL_KEY(IntPtr pIpPort)
        {
            this.pIpPort = pIpPort;
        }
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct HTTP_SERVICE_CONFIG_SSL_PARAM
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
        public uint DefaultFlags;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 2)]
    struct HTTPAPI_VERSION
    {
        public ushort HttpApiMajorVersion;
        public ushort HttpApiMinorVersion;

        public HTTPAPI_VERSION(ushort majorVersion, ushort minorVersion)
        {
            HttpApiMajorVersion = majorVersion;
            HttpApiMinorVersion = minorVersion;
        }
    }

    [StructLayout(LayoutKind.Sequential)]
    struct HTTP_SERVICE_CONFIG_SSL_QUERY
    {
        public HTTP_SERVICE_CONFIG_QUERY_TYPE QueryDesc;
        public HTTP_SERVICE_CONFIG_SSL_KEY KeyDesc;
        public uint dwToken;
    }

    enum HTTP_SERVICE_CONFIG_QUERY_TYPE
    {
        HttpServiceConfigQueryExact = 0,
        HttpServiceConfigQueryNext,
        HttpServiceConfigQueryMax
    }

    #endregion

    #region Constants

    public const uint HTTP_INITIALIZE_CONFIG = 0x00000002;
    public const uint HTTP_SERVICE_CONFIG_SSL_FLAG_NEGOTIATE_CLIENT_CERT = 0x00000002;
    public const uint HTTP_SERVICE_CONFIG_SSL_FLAG_NO_RAW_FILTER = 0x00000004;
    private const uint NOERROR = 0;
    private const uint ERROR_INSUFFICIENT_BUFFER = 122;
    private const uint ERROR_ALREADY_EXISTS = 183;
    private const uint ERROR_FILE_NOT_FOUND = 2;
    private const int ERROR_NO_MORE_ITEMS = 259;

    #endregion

    #region Public methods

    public class SslCertificateInfo
    {
        public byte[] Hash { get; set; }
        public Guid AppId { get; set; }
        public string StoreName { get; set; }
        public IPEndPoint IpPort { get; set; }
    }

    public static SslCertificateInfo QuerySslCertificateInfo(IPEndPoint ipPort)
    {
        SslCertificateInfo result = null;

        uint retVal;
        CallHttpApi(delegate
        {
            GCHandle sockAddrHandle = CreateSockaddrStructure(ipPort);
            IntPtr pIpPort = sockAddrHandle.AddrOfPinnedObject();
            HTTP_SERVICE_CONFIG_SSL_KEY sslKey = new HTTP_SERVICE_CONFIG_SSL_KEY(pIpPort);

            HTTP_SERVICE_CONFIG_SSL_QUERY inputConfigInfoQuery =
                new HTTP_SERVICE_CONFIG_SSL_QUERY
                {
                    QueryDesc = HTTP_SERVICE_CONFIG_QUERY_TYPE.HttpServiceConfigQueryExact,
                    KeyDesc = sslKey
                };

            IntPtr pInputConfigInfo =
                Marshal.AllocCoTaskMem(Marshal.SizeOf(typeof(HTTP_SERVICE_CONFIG_SSL_QUERY)));
            Marshal.StructureToPtr(inputConfigInfoQuery, pInputConfigInfo, false);

            IntPtr pOutputConfigInfo = IntPtr.Zero;
            int returnLength = 0;

            try
            {
                HTTP_SERVICE_CONFIG_ID queryType = HTTP_SERVICE_CONFIG_ID.HttpServiceConfigSSLCertInfo;
                int inputConfigInfoSize = Marshal.SizeOf(inputConfigInfoQuery);
                retVal = HttpQueryServiceConfiguration(IntPtr.Zero,
                                                        queryType,
                                                        pInputConfigInfo,
                                                        inputConfigInfoSize,
                                                        pOutputConfigInfo,
                                                        returnLength,
                                                        out returnLength,
                                                        IntPtr.Zero);
                if (retVal == ERROR_FILE_NOT_FOUND)
                    return;

                if (ERROR_INSUFFICIENT_BUFFER == retVal) // ERROR_INSUFFICIENT_BUFFER = 122
                {
                    pOutputConfigInfo = Marshal.AllocCoTaskMem(returnLength);

                    try
                    {
                        retVal = HttpQueryServiceConfiguration(IntPtr.Zero,
                                                                                queryType,
                                                                                pInputConfigInfo,
                                                                                inputConfigInfoSize,
                                                                                pOutputConfigInfo,
                                                                                returnLength,
                                                                                out returnLength,
                                                                                IntPtr.Zero);
                        ThrowWin32ExceptionIfError(retVal);

                        var outputConfigInfo =
                            (HTTP_SERVICE_CONFIG_SSL_SET)
                            Marshal.PtrToStructure(pOutputConfigInfo, typeof(HTTP_SERVICE_CONFIG_SSL_SET));

                        byte[] hash = new byte[outputConfigInfo.ParamDesc.SslHashLength];
                        Marshal.Copy(outputConfigInfo.ParamDesc.pSslHash, hash, 0, hash.Length);

                        Guid appId = outputConfigInfo.ParamDesc.AppId;
                        string storeName = outputConfigInfo.ParamDesc.pSslCertStoreName;

                        result = new SslCertificateInfo { AppId = appId, Hash = hash, StoreName = storeName, IpPort = ipPort };
                    }
                    finally
                    {
                        Marshal.FreeCoTaskMem(pOutputConfigInfo);
                    }
                }
                else
                {
                    ThrowWin32ExceptionIfError(retVal);
                }

            }
            finally
            {
                Marshal.FreeCoTaskMem(pInputConfigInfo);
                if (sockAddrHandle.IsAllocated)
                    sockAddrHandle.Free();
            }

        });

        return result;
    }

    public static void BindCertificate(IPEndPoint ipPort, byte[] hash, StoreName storeName, Guid appId)
    {
        if (ipPort == null) throw new ArgumentNullException("ipPort");
        if (hash == null) throw new ArgumentNullException("hash");

        CallHttpApi(
            delegate
            {
                HTTP_SERVICE_CONFIG_SSL_SET configSslSet = new HTTP_SERVICE_CONFIG_SSL_SET();

                GCHandle sockAddrHandle = CreateSockaddrStructure(ipPort);
                IntPtr pIpPort = sockAddrHandle.AddrOfPinnedObject();
                HTTP_SERVICE_CONFIG_SSL_KEY httpServiceConfigSslKey =
                    new HTTP_SERVICE_CONFIG_SSL_KEY(pIpPort);
                HTTP_SERVICE_CONFIG_SSL_PARAM configSslParam = new HTTP_SERVICE_CONFIG_SSL_PARAM();


                GCHandle handleHash = GCHandle.Alloc(hash, GCHandleType.Pinned);
                configSslParam.AppId = appId;
                configSslParam.DefaultCertCheckMode = 0;
                configSslParam.DefaultFlags = 0; //HTTP_SERVICE_CONFIG_SSL_FLAG_NEGOTIATE_CLIENT_CERT;
                configSslParam.DefaultRevocationFreshnessTime = 0;
                configSslParam.DefaultRevocationUrlRetrievalTimeout = 0;
                configSslParam.pSslCertStoreName = storeName.ToString();
                configSslParam.pSslHash = handleHash.AddrOfPinnedObject();
                configSslParam.SslHashLength = hash.Length;
                configSslSet.ParamDesc = configSslParam;
                configSslSet.KeyDesc = httpServiceConfigSslKey;

                IntPtr pInputConfigInfo =
                    Marshal.AllocCoTaskMem(Marshal.SizeOf(typeof(HTTP_SERVICE_CONFIG_SSL_SET)));
                Marshal.StructureToPtr(configSslSet, pInputConfigInfo, false);

                try
                {
                    uint retVal = HttpSetServiceConfiguration(IntPtr.Zero,
                                                                HTTP_SERVICE_CONFIG_ID.HttpServiceConfigSSLCertInfo,
                                                                pInputConfigInfo,
                                                                Marshal.SizeOf(configSslSet),
                                                                IntPtr.Zero);

                    if (ERROR_ALREADY_EXISTS != retVal)
                    {
                        ThrowWin32ExceptionIfError(retVal);
                    }
                    else
                    {
                        retVal = HttpDeleteServiceConfiguration(IntPtr.Zero,
                                                                HTTP_SERVICE_CONFIG_ID.HttpServiceConfigSSLCertInfo,
                                                                pInputConfigInfo,
                                                                Marshal.SizeOf(configSslSet),
                                                                IntPtr.Zero);
                        ThrowWin32ExceptionIfError(retVal);

                        retVal = HttpSetServiceConfiguration(IntPtr.Zero,
                                                                HTTP_SERVICE_CONFIG_ID.HttpServiceConfigSSLCertInfo,
                                                                pInputConfigInfo,
                                                                Marshal.SizeOf(configSslSet),
                                                                IntPtr.Zero);
                        ThrowWin32ExceptionIfError(retVal);
                    }
                }
                finally
                {
                    Marshal.FreeCoTaskMem(pInputConfigInfo);
                    if (handleHash.IsAllocated)
                        handleHash.Free();
                    if (sockAddrHandle.IsAllocated)
                        sockAddrHandle.Free();
                }
            });
    }

    public static void DeleteCertificateBinding(params IPEndPoint[] ipPorts)
    {
        if (ipPorts == null || ipPorts.Length == 0)
            return;

        CallHttpApi(
        delegate
        {
            foreach (var ipPort in ipPorts)
            {
                HTTP_SERVICE_CONFIG_SSL_SET configSslSet =
                    new HTTP_SERVICE_CONFIG_SSL_SET();

                GCHandle sockAddrHandle = CreateSockaddrStructure(ipPort);
                IntPtr pIpPort = sockAddrHandle.AddrOfPinnedObject();
                HTTP_SERVICE_CONFIG_SSL_KEY httpServiceConfigSslKey =
                    new HTTP_SERVICE_CONFIG_SSL_KEY(pIpPort);
                configSslSet.KeyDesc = httpServiceConfigSslKey;

                IntPtr pInputConfigInfo =
                    Marshal.AllocCoTaskMem(
                        Marshal.SizeOf(typeof(HTTP_SERVICE_CONFIG_SSL_SET)));
                Marshal.StructureToPtr(configSslSet, pInputConfigInfo, false);

                try
                {
                    uint retVal = HttpDeleteServiceConfiguration(IntPtr.Zero,
                                                                    HTTP_SERVICE_CONFIG_ID.HttpServiceConfigSSLCertInfo,
                                                                    pInputConfigInfo,
                                                                    Marshal.SizeOf(configSslSet),
                                                                    IntPtr.Zero);
                    ThrowWin32ExceptionIfError(retVal);
                }
                finally
                {
                    Marshal.FreeCoTaskMem(pInputConfigInfo);
                    if (sockAddrHandle.IsAllocated)
                        sockAddrHandle.Free();
                }
            }
        });
    }

    public static SslCertificateInfo[] QuerySslCertificateInfo()
    {
        var result = new List<SslCertificateInfo>();

        CallHttpApi(
            delegate
            {
                uint token = 0;

                uint retVal;
                do
                {
                    HTTP_SERVICE_CONFIG_SSL_QUERY inputConfigInfoQuery =
                        new HTTP_SERVICE_CONFIG_SSL_QUERY
                        {
                            QueryDesc = HTTP_SERVICE_CONFIG_QUERY_TYPE.HttpServiceConfigQueryNext,
                            dwToken = token,
                        };

                    IntPtr pInputConfigInfo =
                        Marshal.AllocCoTaskMem(Marshal.SizeOf(typeof(HTTP_SERVICE_CONFIG_SSL_QUERY)));
                    Marshal.StructureToPtr(inputConfigInfoQuery, pInputConfigInfo, false);

                    IntPtr pOutputConfigInfo = IntPtr.Zero;
                    int returnLength = 0;

                    const HTTP_SERVICE_CONFIG_ID queryType = HTTP_SERVICE_CONFIG_ID.HttpServiceConfigSSLCertInfo;

                    try
                    {
                        int inputConfigInfoSize = Marshal.SizeOf(inputConfigInfoQuery);
                        retVal = HttpQueryServiceConfiguration(IntPtr.Zero,
                                                                queryType,
                                                                pInputConfigInfo,
                                                                inputConfigInfoSize,
                                                                pOutputConfigInfo,
                                                                returnLength,
                                                                out returnLength,
                                                                IntPtr.Zero);
                        if (ERROR_NO_MORE_ITEMS == retVal)
                            break;
                        if (ERROR_INSUFFICIENT_BUFFER == retVal) // ERROR_INSUFFICIENT_BUFFER = 122
                        {
                            pOutputConfigInfo = Marshal.AllocCoTaskMem(returnLength);

                            try
                            {
                                retVal = HttpQueryServiceConfiguration(IntPtr.Zero,
                                                                    queryType,
                                                                    pInputConfigInfo,
                                                                    inputConfigInfoSize,
                                                                    pOutputConfigInfo,
                                                                    returnLength,
                                                                    out returnLength,
                                                                    IntPtr.Zero);
                                ThrowWin32ExceptionIfError(retVal);

                                var outputConfigInfo = (HTTP_SERVICE_CONFIG_SSL_SET)Marshal.PtrToStructure(
                                    pOutputConfigInfo, typeof(HTTP_SERVICE_CONFIG_SSL_SET));

                                byte[] hash = new byte[outputConfigInfo.ParamDesc.SslHashLength];
                                Marshal.Copy(outputConfigInfo.ParamDesc.pSslHash, hash, 0, hash.Length);

                                Guid appId = outputConfigInfo.ParamDesc.AppId;
                                string storeName = outputConfigInfo.ParamDesc.pSslCertStoreName;
                                IPEndPoint ipPort = ReadSockaddrStructure(outputConfigInfo.KeyDesc.pIpPort);

                                var resultItem = new SslCertificateInfo
                                {
                                    AppId = appId,
                                    Hash = hash,
                                    StoreName = storeName,
                                    IpPort = ipPort
                                };
                                result.Add(resultItem);
                                token++;
                            }
                            finally
                            {
                                Marshal.FreeCoTaskMem(pOutputConfigInfo);
                            }
                        }
                        else
                        {
                            ThrowWin32ExceptionIfError(retVal);
                        }
                    }
                    finally
                    {
                        Marshal.FreeCoTaskMem(pInputConfigInfo);
                    }

                } while (NOERROR == retVal);

            });

        return result.ToArray();
    }


    #endregion

    private static void ThrowWin32ExceptionIfError(uint retVal)
    {
        if (NOERROR != retVal)
        {
            throw new Win32Exception(Convert.ToInt32(retVal));
        }
    }

    private static void CallHttpApi(Action body)
    {
        uint retVal = HttpInitialize(HttpApiVersion, HTTP_INITIALIZE_CONFIG, IntPtr.Zero);
        ThrowWin32ExceptionIfError(retVal);

        try
        {
            body();
        }
        finally
        {
            HttpTerminate(HTTP_INITIALIZE_CONFIG, IntPtr.Zero);
        }
    }

}
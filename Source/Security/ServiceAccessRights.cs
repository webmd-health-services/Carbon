using System;

namespace Carbon.Security
{
    [Flags]
    public enum ServiceAccessRights : uint
    {
        QueryConfig = 0x1,
        ChangeConfig = 0x2,
        QueryStatus = 0x4,
        EnumerateDependents = 0x8,
        Start = 0x10,
        Stop = 0x20,
        PauseContinue = 0x40,
        Interrogate = 0x80,
        UserDefinedControl = 0x100,
        Delete = 0x10000,
        ReadControl = 0x20000,
        WriteDac = 0x40000,
        WriteOwner = 0x80000,

        FullControl =
            QueryConfig | ChangeConfig | QueryStatus | EnumerateDependents | Start | Stop | PauseContinue | Interrogate |
            UserDefinedControl | Delete | ReadControl | WriteDac | WriteOwner
    }
}
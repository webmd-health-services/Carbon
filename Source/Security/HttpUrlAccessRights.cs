namespace Carbon.Security
{
	public enum HttpUrlAccessRights
	{
		// https://msdn.microsoft.com/en-us/library/aa364653.aspx
		Read = -2147483648, // Because 0x80000000 isn't allowed!?
		Listen = 0x20000000,   // GENERIC_EXECUTE
		Delegate = 0x40000000,   // GENERIC_WRITE
		ListenAndDelegate = 0x10000000
	}
}

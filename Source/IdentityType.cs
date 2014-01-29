namespace Carbon
{
    // http://msdn.microsoft.com/en-us/library/windows/desktop/aa379601.aspx
    public enum IdentityType
    {
        User = 1,
        Group,
        Domain,
        Alias,
        WellKnownGroup,
        DeletedAccount,
        Invalid,
        Unknown,
        Computer,
        Label
    }
}
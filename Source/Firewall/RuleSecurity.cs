namespace Carbon.Firewall
{
	public enum RuleSecurity
	{
		NotRequired = 0,
		Authenticate,
		AuthEnc,
		AuthDynEnc,
		AuthNoEncap
	}
}

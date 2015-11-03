using Carbon.Security;
using NUnit.Framework;

namespace Carbon.Test.Security
{
	[TestFixture]
	public sealed class UrlSecurityTests
	{
		[Test]
		public void ShouldReturnAllUrlSecurity()
		{
			var result = HttpUrlSecurity.GetHttpUrlSecurity();
			Assert.That(result, Is.Not.Null);
		}
	}
}

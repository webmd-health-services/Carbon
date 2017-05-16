using System;
using System.IO;
using Carbon.IO;
using NUnit.Framework;
using IOPath = System.IO.Path;

namespace Carbon.Test.IO
{
    [TestFixture]
    public sealed class ReparsePointTestFixture
    {
        [Test]
        public void ShouldGetTargetPathForJunction()
        {
            var path = IOPath.Combine(Environment.GetEnvironmentVariable("TEMP"), IOPath.GetRandomFileName());
            Directory.CreateDirectory(path);
            var junctionPath = string.Format("{0}+junction", path);
            JunctionPoint.Create(junctionPath, path, true);
            Assert.That(ReparsePoint.GetTarget(junctionPath), Is.EqualTo(path));
        }
    }
}

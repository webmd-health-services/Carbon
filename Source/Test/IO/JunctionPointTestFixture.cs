using System;
using System.IO;
using Carbon.IO;
using NUnit.Framework;
using Path = System.IO.Path;
using File = System.IO.File;

namespace Carbon.Test.IO
{
    [TestFixture]
    public sealed class JunctionPointTestFixture
    {
        [Test]
        public void ShouldCreateJunctionPoint()
        {
            var path = Path.Combine(Environment.GetEnvironmentVariable("TEMP"), Path.GetRandomFileName());
            Directory.CreateDirectory(path);
            var file = Path.Combine(path, "file.txt");
            using (File.Create(file))
            {
            }

            var junctionPath = string.Format("{0}+junction", path);
            JunctionPoint.Create(junctionPath, path, true);
            var junctionFiles = Directory.GetFiles(junctionPath);
            Assert.That(junctionFiles.Length, Is.EqualTo(1));
            Assert.That(junctionFiles[0], Is.EqualTo(Path.Combine(junctionPath,"file.txt")));


            JunctionPoint.Delete(junctionPath);

            Assert.That(Directory.Exists(junctionPath), Is.False);
            Assert.That(File.Exists(file), Is.True);
        }
    }
}

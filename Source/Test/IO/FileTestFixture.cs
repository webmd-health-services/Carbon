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
using System.Reflection;
using Carbon.IO;
using NUnit.Framework;

namespace Carbon.Test.IO
{
    [TestFixture]
    public sealed class FileTestFixture
    {
        [Test]
        public void ShouldCreateFile()
        {
            var tempID = System.IO.Path.GetRandomFileName();
            var sourceFile = System.IO.Path.Combine(Environment.GetEnvironmentVariable("TEMP"), string.Format("sourceFile+{0}.txt", tempID));
            var destinationFile = System.IO.Path.Combine(Environment.GetEnvironmentVariable("TEMP"), string.Format("destinationFile+{0}.txt", tempID));
            var content = Guid.NewGuid().ToString();
            System.IO.File.WriteAllText(sourceFile, content);
            SymbolicLink.Create(destinationFile, sourceFile, false);
            Assert.That(System.IO.File.ReadAllText(destinationFile), Is.EqualTo(content));
            Assert.That(SymbolicLink.GetTargetPath(destinationFile), Is.EqualTo(sourceFile));
            Assert.That(SymbolicLink.IsSymbolicLink(destinationFile), Is.True);
        }

        [Test]
        public void ShouldReturnNothingForNonSymbolicLink()
        {
            Assert.That(SymbolicLink.IsSymbolicLink(Assembly.GetExecutingAssembly().Location), Is.False);
            Assert.That(SymbolicLink.GetTargetPath(Assembly.GetExecutingAssembly().Location), Is.Null);
        }

        [Test]
        public void ShouldCreateDirectory()
        {
            var tempID = System.IO.Path.GetRandomFileName();
            var sourceDir = System.IO.Path.Combine(Environment.GetEnvironmentVariable("TEMP"), string.Format("sourceDir+{0}", tempID));
            var destinationDir = System.IO.Path.Combine(Environment.GetEnvironmentVariable("TEMP"), string.Format("destinationDir+{0}", tempID));
            System.IO.Directory.CreateDirectory(sourceDir);
            var childFilePath = System.IO.Path.Combine(sourceDir, "file.txt");
            System.IO.File.WriteAllText(childFilePath, "");
            SymbolicLink.Create(destinationDir, sourceDir, true);
            var destChildFilePath = System.IO.Path.Combine(destinationDir, "file.txt");
            Assert.That(System.IO.File.Exists(destChildFilePath), Is.True);
            Assert.That(SymbolicLink.IsSymbolicLink(destinationDir), Is.True);
            Assert.That(SymbolicLink.GetTargetPath(destinationDir), Is.EqualTo(sourceDir));
        }
    }
}

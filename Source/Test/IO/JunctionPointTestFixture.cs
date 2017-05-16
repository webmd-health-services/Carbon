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

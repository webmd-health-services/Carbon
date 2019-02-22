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

using Microsoft.Web.XmlTransform;
using System.Linq;
using System.Xml;

namespace Carbon.Test.Xdt
{
    /// <summary>
    /// https://github.com/appharbor/appharbor-transformtester/blob/master/AppHarbor.TransformTester/Transforms/Merge.cs
    /// </summary>
    public class Merge : Transform
    {
        public Merge() : base(TransformFlags.UseParentAsTargetNode)
        {
        }

        protected override void Apply()
        {
            Apply((XmlElement)TargetNode, (XmlElement)TransformNode);
        }

        public void Apply(XmlElement targetElement, XmlElement transformElement)
        {
            var targetChildElement = targetElement.ChildNodes.OfType<XmlElement>().FirstOrDefault(x => x.LocalName == transformElement.LocalName);
            if (targetChildElement == null)
            {
                InsertTransformElement(targetElement, transformElement);
                return;
            }

            foreach (var transformChildElement in transformElement.ChildNodes.OfType<XmlElement>())
            {
                Apply(targetChildElement, transformChildElement);
            }
        }

        protected virtual void InsertTransformElement(XmlElement targetElement, XmlElement transformElement)
        {
            targetElement.AppendChild(transformElement);
        }
    }
}


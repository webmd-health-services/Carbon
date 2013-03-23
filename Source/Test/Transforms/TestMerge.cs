using Carbon.Transforms;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.Web.XmlTransform;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;

namespace Carbon.Test.Transforms
{
    [TestClass]
    public class TestMerge
    {
        [TestMethod]
        public void Test1()
        {
            Apply_ShouldMerge("<foo><baz></baz></foo>", "<bar></bar>", "<foo><baz></baz><bar></bar></foo>");
        }

        [TestMethod]
        public void TestMergeTransformation()
        {
            var input = @"<?xml version=""1.0""?><configuration></configuration>";

            var transformText = @"<?xml version=""1.0""?>
<configuration xmlns:xdt=""http://schemas.microsoft.com/XML-Document-Transform"">
    <xdt:Import path=""F:\Development\BitBucket\mycarbon\Carbon\bin\Carbon.net4.dll"" namespace=""Carbon.Transforms""/>
	<connectionStrings xdt:Transform=""Merge""/>
</configuration>
";

            using (XmlTransformableDocument document = new XmlTransformableDocument())
            {
                document.PreserveWhitespace = true;
                document.Load(new StringReader(input));

                using (XmlTransformation transform = new XmlTransformation(transformText, false, new NullTransformationLogger()))
                {
                    var success = transform.Apply(document);
                    StringBuilder sb = new StringBuilder();
                    using (StringWriter writer = new StringWriter(sb))
                    {
                        document.Save(writer);
                    }

                    Console.WriteLine(sb.ToString());              
                    Assert.IsTrue(success);
                }
            }
        }

        //  [Theory]
        //	[InlineData("<foo></foo>", "<bar />", "<foo><bar /></foo>")]
        //	[InlineData("<foo></foo>", "<bar></bar>", "<foo><bar></bar></foo>")]
        //	[InlineData("<foo><bar></bar></foo>", "<bar></bar>", "<foo><bar></bar></foo>")]
        //	[InlineData("<foo><baz></baz></foo>", "<bar></bar>", "<foo><baz></baz><bar></bar></foo>")]
        public void Apply_ShouldMerge(string targetXml, string transformXml, string expectedXml)
        {
            var targetDocument = ArrangeTargetDocument(targetXml);
            var transformElement = ArrangeTransformElement(targetDocument, transformXml);

            var merge = new Merge();
            merge.Apply(targetDocument.DocumentElement, transformElement);

            Assert.AreEqual(expectedXml, targetDocument.OuterXml);
        }

        //[Theory]
        //[InlineData("<foo><baz></baz></foo>", "<bar></bar>", "<foo><bar></bar><baz></baz></foo>", new[] { "/foo/baz" })]
        //[InlineData("<foo><baz></baz></foo>", "<bar></bar>", "<foo><bar></bar><baz></baz></foo>", new[] { "/foo/*" })]
        //[InlineData("<foo><baz></baz></foo>", "<baz></baz>", "<foo><baz></baz></foo>", new[] { "/foo/*" })]
        //[InlineData("<foo><bar><baz></baz></bar></foo>", "<baz></baz>", "<foo><bar><baz></baz></bar></foo>", new[] { "/foo/bar/*" })]
        //public void Apply_ShouldMergeTop(string targetXml, string transformXml, string expectedXml, IList<string> arguments)
        //{
        //    var targetDocument = ArrangeTargetDocument(targetXml);
        //    var transformElement = ArrangeTransformElement(targetDocument, transformXml);

        //    var merge = new MergeBefore();
        //    merge.Apply(targetDocument.DocumentElement, transformElement, arguments);

        //    Assert.Equal(expectedXml, targetDocument.OuterXml);
        //}

        private XmlDocument ArrangeTargetDocument(string xml)
        {
            var document = new XmlDocument();
            document.LoadXml(xml);
            return document;
        }

        private XmlElement ArrangeTransformElement(XmlDocument document, string xml)
        {
            using (var textReader = new StringReader(xml))
            {
                using (var xmlReader = new XmlTextReader(textReader))
                {
                    var node = document.ReadNode(xmlReader);
                    return (XmlElement)node;
                }
            }
        }
    }
}

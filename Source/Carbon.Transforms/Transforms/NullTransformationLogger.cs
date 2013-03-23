using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Carbon.Transforms
{
    public class NullTransformationLogger : Microsoft.Web.XmlTransform.IXmlTransformationLogger
    {
        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.EndSection(Microsoft.Web.XmlTransform.MessageType type, string message, params object[] messageArgs)
        {
            
        }

        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.EndSection(string message, params object[] messageArgs)
        {
            
        }

        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.LogError(string file, int lineNumber, int linePosition, string message, params object[] messageArgs)
        {
            
        }

        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.LogError(string file, string message, params object[] messageArgs)
        {
            
        }

        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.LogError(string message, params object[] messageArgs)
        {
            
        }

        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.LogErrorFromException(Exception ex, string file, int lineNumber, int linePosition)
        {
            
        }

        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.LogErrorFromException(Exception ex, string file)
        {
            
        }

        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.LogErrorFromException(Exception ex)
        {
            
        }

        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.LogMessage(Microsoft.Web.XmlTransform.MessageType type, string message, params object[] messageArgs)
        {
            
        }

        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.LogMessage(string message, params object[] messageArgs)
        {
            
        }

        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.LogWarning(string file, int lineNumber, int linePosition, string message, params object[] messageArgs)
        {
            
        }

        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.LogWarning(string file, string message, params object[] messageArgs)
        {
            
        }

        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.LogWarning(string message, params object[] messageArgs)
        {
            
        }

        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.StartSection(Microsoft.Web.XmlTransform.MessageType type, string message, params object[] messageArgs)
        {
            
        }

        void Microsoft.Web.XmlTransform.IXmlTransformationLogger.StartSection(string message, params object[] messageArgs)
        {
            
        }
    }
}

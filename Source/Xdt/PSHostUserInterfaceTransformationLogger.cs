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
using System.Management.Automation;
using Microsoft.Web.XmlTransform;

namespace Carbon.Xdt
{
	public sealed class PSHostUserInterfaceTransformationLogger : IXmlTransformationLogger
	{
		private readonly ICommandRuntime _commandRuntime;

		public PSHostUserInterfaceTransformationLogger(ICommandRuntime commandRuntime)
		{
			if (commandRuntime == null)
			{
				throw new ArgumentNullException("commandRuntime", "PowerShell command runtime object required.");
			}

			_commandRuntime = commandRuntime;
		}

		public void LogMessage(string message, params object[] messageArgs)
		{
			WriteVerbose(message, messageArgs);
		}

		public void LogMessage(MessageType type, string message, params object[] messageArgs)
		{
			WriteVerbose(message, messageArgs);
		}

		public void LogWarning(string message, params object[] messageArgs)
		{
			WriteWarning(message, messageArgs);
		}

		public void LogWarning(string file, string message, params object[] messageArgs)
		{
			WriteWarning(string.Format("{0}: {1}", file, string.Format(message, messageArgs)));
		}

		public void LogWarning(string file, int lineNumber, int linePosition, string message, params object[] messageArgs)
		{
			WriteWarning(string.Format("{0}: line {1}: position {2}: {3}", file, lineNumber, linePosition, string.Format(message, messageArgs)));
		}

		public void LogError(string message, params object[] messageArgs)
		{
			WriteError(string.Format(message, messageArgs));
		}

		public void LogError(string file, string message, params object[] messageArgs)
		{
			WriteError(string.Format("{0}: {1}", file, string.Format(message, messageArgs)));
		}

		public void LogError(string file, int lineNumber, int linePosition, string message, params object[] messageArgs)
		{
			WriteError(string.Format("{0}: line {1}: position {2}: {3}", file, lineNumber, linePosition, string.Format(message, messageArgs)));
		}

		public void LogErrorFromException(Exception ex)
		{
			WriteError(string.Format("{0}\nat {1}", ex.Message, ex.StackTrace));
		}

		public void LogErrorFromException(Exception ex, string file)
		{
			WriteError(string.Format("{0}: {1}\nat {2}", file, ex.Message, ex.StackTrace));
		}

		public void LogErrorFromException(Exception ex, string file, int lineNumber, int linePosition)
		{
			WriteError(string.Format("{0}: line {1}: position {2}: {3}\n{4}", file, lineNumber, linePosition, ex.Message, ex.StackTrace));
		}

		public void StartSection(string message, params object[] messageArgs)
		{
			WriteVerbose(string.Format(message, messageArgs));
		}

		public void StartSection(MessageType type, string message, params object[] messageArgs)
		{
			WriteVerbose(message, messageArgs);
		}

		public void EndSection(string message, params object[] messageArgs)
		{
			WriteVerbose(message, messageArgs);
		}

		public void EndSection(MessageType type, string message, params object[] messageArgs)
		{
			WriteVerbose(message, messageArgs);
		}

		private void WriteError(string message, params object[] messageArgs)
		{
			var ex = new XdtTransformationException(string.Format(message, messageArgs));
			var errorRecord = new ErrorRecord(ex, "", ErrorCategory.NotSpecified, null);
			_commandRuntime.WriteError(errorRecord);
		}

		private void WriteVerbose(string message, params object[] messageArgs)
		{
			_commandRuntime.WriteVerbose(string.Format(message, messageArgs));
		}

		private void WriteWarning(string message, params object[] messageArgs)
		{
			_commandRuntime.WriteWarning(string.Format(message, messageArgs));
		}

	}
}


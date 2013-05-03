using System;
using System.Management.Automation.Host;
using Microsoft.Web.XmlTransform;

namespace Carbon.Xdt
{
	public sealed class PSHostUserInterfaceTransformationLogger : IXmlTransformationLogger
	{
		private readonly PSHostUserInterface _hostUI;
		private bool _showVerboseOutput = false;
		private bool _showWarningOutput = false;
		private bool _showErrorOutput = false;

		public PSHostUserInterfaceTransformationLogger(PSHostUserInterface hostUI, bool showVerboseOutput, bool showWarnings, bool showErrors)
		{
			if (hostUI == null)
			{
				throw new ArgumentNullException("hostUI", "PowerShell host user interface object required.");
			}
			_hostUI = hostUI;

			_showVerboseOutput = showVerboseOutput;
			_showWarningOutput = showWarnings;
			_showErrorOutput = showErrors;
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
			WriteError(string.Format("{0}: line {1}: position {2}: {3}\nat {4}", file, lineNumber, linePosition, ex.Message, ex.StackTrace));
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
			if (_showErrorOutput)
			{
				_hostUI.WriteErrorLine(string.Format(message, messageArgs));
			}
		}

		private void WriteVerbose(string message, params object[] messageArgs)
		{
			if (_showVerboseOutput)
			{
				_hostUI.WriteVerboseLine(string.Format(message, messageArgs));
			}
		}

		private void WriteWarning(string message, params object[] messageArgs)
		{
			if (_showWarningOutput)
			{
				_hostUI.WriteWarningLine(string.Format(message, messageArgs));
			}
		}

	}
}

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
using System.Collections.Generic;

namespace Carbon.TaskScheduler
{
	public sealed class TaskInfo
	{
		public TaskInfo(string hostName, string path, string name, string nextRunTime, string status, string logonMode,
			string lastRunTime, string author, DateTime createDate, string taskToRun, string startIn, string comment, string scheduledTaskState,
			string idleTime, string powerManagement, string runAsUser, bool interactive, bool noPassword, bool highestAvailableRunLevel, string deleteTaskIfNotRescheduled)
		{
			HostName = hostName;
			TaskPath = path;
			TaskName = name;
			NextRunTime = nextRunTime;
			Status = status;
			LogonMode = logonMode;
			LastRunTime = lastRunTime;
			Author = author;
			CreateDate = createDate;
			TaskToRun = taskToRun;
			StartIn = startIn;
			Comment = comment;
			ScheduledTaskState = scheduledTaskState;
			IdleTime = idleTime;
			PowerManagement = powerManagement;
			RunAsUser = runAsUser;
			Interactive = interactive;
			NoPassword = noPassword;
			HighestAvailableRunLevel = highestAvailableRunLevel;
			DeleteTaskIfNotRescheduled = deleteTaskIfNotRescheduled;

			Schedules = new List<ScheduleInfo>();
		}

		public string Author { get; private set; }
		public string Comment { get; private set; }
		public DateTime CreateDate { get; private set; }
		public string DeleteTaskIfNotRescheduled { get; private set; }
		public bool HighestAvailableRunLevel { get; private set; }
		public string HostName { get; private set; }
		public string IdleTime { get; private set; }
		public bool Interactive { get; private set; }
		public string LastRunTime { get; private set; }
		public string LogonMode { get; private set; }
		public string NextRunTime { get; private set; }
		public bool NoPassword { get; private set; }
		public string PowerManagement { get; private set; }
		public string RunAsUser { get; private set; }
		public IList<ScheduleInfo> Schedules { get; private set; }
		public string ScheduledTaskState { get; private set; }
		public string StartIn { get; private set; }
		public string Status { get; private set; }
		public string TaskToRun { get; private set; }
		public string TaskName { get; private set; }
		public string TaskPath { get; private set; }
	}
}


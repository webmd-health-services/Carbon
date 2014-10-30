namespace Carbon
{
	public sealed class ScheduledTaskInfo
	{
		public ScheduledTaskInfo(string hostName, string name, string nextRunTime, string status, string logonMode,
			string lastRunTime, string lastResult, string author, string taskToRun, string startIn, string comment,
			string scheduledTaskState, string idleTime, string powerManagement, string runAsUser,
			string deleteTaskIfNotRescheduled, string stopTaskIfRunsXHoursAndXMinutes, string schedule, string scheduleType,
			string startTime, string startDate, string endDate, string days, string months, string repeatEvery,
			string repeatUntilTime, string repeatUntilDuration, string repeatStopIfStillRunning)
		{
			HostName = hostName;
			TaskName = name;
			NextRunTime = nextRunTime;
			Status = status;
			LogonMode = logonMode;
			LastRunTime = lastRunTime;
			LastResult = lastResult;
			Author = author;
			TaskToRun = taskToRun;
			StartIn = startIn;
			Comment = comment;
			ScheduledTaskState = scheduledTaskState;
			IdleTime = idleTime;
			PowerManagement = powerManagement;
			RunAsUser = runAsUser;
			DeleteTaskIfNotRescheduled = deleteTaskIfNotRescheduled;
			StopTaskIfRunsXHoursandXMins = stopTaskIfRunsXHoursAndXMinutes;
			Schedule = schedule;
			ScheduleType = scheduleType;
			StartTime = startTime;
			StartDate = startDate;
			EndDate = endDate;
			Days = days;
			Months = months;
			RepeatEvery = repeatEvery;
			RepeatUntilTime = repeatUntilTime;
			RepeatUntilDuration = repeatUntilDuration;
			RepeatStopIfStillRunning = repeatStopIfStillRunning;
		}

		public string Author { get; private set; }
		public string Comment { get; private set; }
		public string Days { get; private set; }
		public string DeleteTaskIfNotRescheduled { get; private set; }
		public string EndDate { get; private set; }
		public string HostName { get; private set; }
		public string IdleTime { get; private set; }
		public string LastResult { get; private set; }
		public string LastRunTime { get; private set; }
		public string LogonMode { get; private set; }
		public string Months { get; private set; }
		public string NextRunTime { get; private set; }
		public string PowerManagement { get; private set; }
		public string RepeatEvery { get; private set; }
		public string RepeatStopIfStillRunning { get; private set; }
		public string RepeatUntilDuration { get; private set; }
		public string RepeatUntilTime { get; private set; }
		public string RunAsUser { get; private set; }
		public string Schedule { get; private set; }
		public string ScheduleType { get; private set; }
		public string ScheduledTaskState { get; private set; }
		public string StartDate { get; private set; }
		public string StartIn { get; private set; }
		public string StartTime { get; private set; }
		public string Status { get; private set; }
		public string StopTaskIfRunsXHoursandXMins { get; private set; }
		public string TaskToRun { get; private set; }
		public string TaskName { get; private set; }
	}
}

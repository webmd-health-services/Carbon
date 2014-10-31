namespace Carbon.TaskScheduler
{
	public sealed class ScheduleInfo
	{
		public ScheduleInfo(string lastResult, string stopTaskIfRunsXHoursAndXMinutes, string schedule, string scheduleType,
			string startTime, string startDate, string endDate, string days, string months, string repeatEvery,
			string repeatUntilTime, string repeatUntilDuration, string repeatStopIfStillRunning)
		{
			LastResult = lastResult;
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

		public string Days { get; private set; }
		public string EndDate { get; private set; }
		public string LastResult { get; private set; }
		public string Months { get; private set; }
		public string RepeatEvery { get; private set; }
		public string RepeatStopIfStillRunning { get; private set; }
		public string RepeatUntilDuration { get; private set; }
		public string RepeatUntilTime { get; private set; }
		public string StopTaskIfRunsXHoursandXMins { get; private set; }
		public string Schedule { get; private set; }
		public string ScheduleType { get; private set; }
		public string StartDate { get; private set; }
		public string StartTime { get; private set; }
	}
}

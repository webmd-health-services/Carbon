namespace Carbon.TaskScheduler
{
	public sealed class ScheduleInfo
	{
		public ScheduleInfo(string lastResult, string stopTaskIfRunsXHoursAndXMinutes, string scheduleType, string modifier,
			string startTime, string startDate, string endDate, string[] days, Months months, string repeatEvery,
			string repeatUntilTime, string repeatUntilDuration, string repeatStopIfStillRunning)
		{
			LastResult = lastResult;
			StopTaskIfRunsXHoursandXMins = stopTaskIfRunsXHoursAndXMinutes;
			ScheduleType = scheduleType;
			Modifier = modifier;
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

		public string[] Days { get; private set; }
		public string EndDate { get; private set; }
		public string LastResult { get; private set; }
		public string Modifier { get; private set; }
		public Months Months { get; private set; }
		public string RepeatEvery { get; private set; }
		public string RepeatStopIfStillRunning { get; private set; }
		public string RepeatUntilDuration { get; private set; }
		public string RepeatUntilTime { get; private set; }
		public string StopTaskIfRunsXHoursandXMins { get; private set; }
		public string ScheduleType { get; private set; }
		public string StartDate { get; private set; }
		public string StartTime { get; private set; }
	}
}

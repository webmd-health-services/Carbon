using System;

namespace Carbon.TaskScheduler
{
	public sealed class ScheduleInfo
	{
		public ScheduleInfo(string lastResult, string stopTaskIfRunsXHoursAndXMinutes, string scheduleType, string modifier, int interval,
			string startTime, string startDate, TimeSpan endTime, string endDate, DayOfWeek[] daysOfWeek, int[] days, Month[] months, string repeatEvery,
			string repeatUntilTime, string repeatUntilDuration, string repeatStopIfStillRunning, bool stopAtEnd)
		{
			LastResult = lastResult;
			StopTaskIfRunsXHoursandXMins = stopTaskIfRunsXHoursAndXMinutes;
			ScheduleType = scheduleType;
			Modifier = modifier;
			Interval = interval;
			StartTime = startTime;
			StartDate = startDate;
			EndTime = endTime;
			EndDate = endDate;
			DaysOfWeek = daysOfWeek;
			Days = days;
			Months = months;
			RepeatEvery = repeatEvery;
			RepeatUntilTime = repeatUntilTime;
			RepeatUntilDuration = repeatUntilDuration;
			RepeatStopIfStillRunning = repeatStopIfStillRunning;
			StopAtEnd = stopAtEnd;
		}

		public int[] Days { get; private set; }
		public DayOfWeek[] DaysOfWeek { get; private set; }
		public string EndDate { get; private set; }
		public TimeSpan EndTime { get; private set; }
		public int Interval { get; private set; }
		public string LastResult { get; private set; }
		public string Modifier { get; private set; }
		public Month[] Months { get; private set; }
		public string RepeatEvery { get; private set; }
		public string RepeatStopIfStillRunning { get; private set; }
		public string RepeatUntilDuration { get; private set; }
		public string RepeatUntilTime { get; private set; }
		public bool StopAtEnd { get; private set; }
		public string StopTaskIfRunsXHoursandXMins { get; private set; }
		public string ScheduleType { get; private set; }
		public string StartDate { get; private set; }
		public string StartTime { get; private set; }

	}
}

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

namespace Carbon.TaskScheduler
{
	public sealed class ScheduleInfo
	{
		public ScheduleInfo(int lastResult, string stopTaskIfRunsXHoursAndXMinutes, ScheduleType scheduleType, string modifier, int interval,
			TimeSpan startTime, DateTime startDate, TimeSpan endTime, DateTime endDate, DayOfWeek[] daysOfWeek, int[] days, Month[] months, string repeatEvery,
			string repeatUntilTime, string repeatUntilDuration, string repeatStopIfStillRunning, bool stopAtEnd, TimeSpan delay, int idleTime, string eventChannelName)
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
			Delay = delay;
			IdleTime = idleTime;
			EventChannelName = eventChannelName;
		}

		public int[] Days { get; private set; }
		public DayOfWeek[] DaysOfWeek { get; private set; }
		public TimeSpan Delay { get; private set; }
		public DateTime EndDate { get; private set; }
		public TimeSpan EndTime { get; private set; }
		public string EventChannelName { get; private set; }
		public int IdleTime { get; private set; }
		public int Interval { get; private set; }
		public int LastResult { get; private set; }
		public string Modifier { get; private set; }
		public Month[] Months { get; private set; }
		public string RepeatEvery { get; private set; }
		public string RepeatStopIfStillRunning { get; private set; }
		public string RepeatUntilDuration { get; private set; }
		public string RepeatUntilTime { get; private set; }
		public bool StopAtEnd { get; private set; }
		public string StopTaskIfRunsXHoursandXMins { get; private set; }
		public ScheduleType ScheduleType { get; private set; }
		public DateTime StartDate { get; private set; }
		public TimeSpan StartTime { get; private set; }

	}
}


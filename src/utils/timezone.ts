import { Alarm, NextAlarmInfo, TimeZoneDetails } from '../types';

/**
 * Get user's system detected timezone
 */
export function getUserLocalTimeZone(): string {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC';
  } catch {
    return 'UTC';
  }
}

/**
 * Gets timezone abbreviation, offset and DST status for any given date
 */
export function getTimeZoneDetails(timeZone: string, atDate: Date = new Date()): TimeZoneDetails {
  try {
    // Format full date-time parts in target timezone
    const formatter = new Intl.DateTimeFormat('en-US', {
      timeZone,
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
      timeZoneName: 'short',
    });

    const parts = formatter.formatToParts(atDate);
    const tzPart = parts.find((p) => p.type === 'timeZoneName')?.value || '';
    
    // Calculate offset in minutes
    // By getting local parts in UTC and comparing with timezone parts
    const offsetMinutes = getTimeZoneOffsetMinutes(timeZone, atDate);
    const sign = offsetMinutes >= 0 ? '+' : '-';
    const absMinutes = Math.abs(offsetMinutes);
    const hours = Math.floor(absMinutes / 60);
    const mins = absMinutes % 60;
    const formattedOffset = `UTC${sign}${String(hours).padStart(2, '0')}:${String(mins).padStart(2, '0')}`;

    // Detect if DST is active by comparing offsets in January vs July
    const currentYear = atDate.getFullYear();
    const janDate = new Date(Date.UTC(currentYear, 0, 15));
    const julDate = new Date(Date.UTC(currentYear, 6, 15));
    const janOffset = getTimeZoneOffsetMinutes(timeZone, janDate);
    const julOffset = getTimeZoneOffsetMinutes(timeZone, julDate);

    const hasDST = janOffset !== julOffset;
    let isDaylightSaving = false;
    let dstSeasonLabel = 'Standard Time';

    if (hasDST) {
      // In Northern Hemisphere, DST offset is greater than Standard offset (e.g. PDT is UTC-7 vs PST UTC-8, so -420 > -480)
      const maxOffset = Math.max(janOffset, julOffset);
      if (offsetMinutes === maxOffset) {
        isDaylightSaving = true;
        dstSeasonLabel = 'Daylight Saving Time (DST active)';
      } else {
        isDaylightSaving = false;
        dstSeasonLabel = 'Standard Time (Winter)';
      }
    } else {
      dstSeasonLabel = 'No Seasonal DST Shift';
    }

    const timeStr = atDate.toLocaleTimeString('en-US', {
      timeZone,
      hour: '2-digit',
      minute: '2-digit',
      hour12: true,
    });

    const dateStr = atDate.toLocaleDateString('en-US', {
      timeZone,
      weekday: 'short',
      month: 'short',
      day: 'numeric',
    });

    return {
      iana: timeZone,
      displayName: timeZone.replace(/_/g, ' '),
      currentLocalTime: timeStr,
      currentLocalDate: dateStr,
      utcOffsetMinutes: offsetMinutes,
      utcOffsetFormatted: formattedOffset,
      timeZoneAbbreviation: tzPart,
      isDaylightSaving,
      dstSeasonLabel,
    };
  } catch {
    return {
      iana: timeZone,
      displayName: timeZone,
      currentLocalTime: '--:--',
      currentLocalDate: '---',
      utcOffsetMinutes: 0,
      utcOffsetFormatted: 'UTC+00:00',
      timeZoneAbbreviation: 'UTC',
      isDaylightSaving: false,
      dstSeasonLabel: 'Standard Time',
    };
  }
}

/**
 * Calculates accurate UTC offset in minutes for a timezone at a specific epoch
 */
export function getTimeZoneOffsetMinutes(timeZone: string, date: Date = new Date()): number {
  try {
    const dtf = new Intl.DateTimeFormat('en-US', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
    });

    const parts = dtf.formatToParts(date);
    const getPart = (type: Intl.DateTimeFormatPartTypes) => {
      const p = parts.find((item) => item.type === type);
      return p ? parseInt(p.value, 10) : 0;
    };

    const year = getPart('year');
    const month = getPart('month');
    const day = getPart('day');
    let hour = getPart('hour');
    // hour could be 24 in some implementations for midnight
    if (hour === 24) hour = 0;
    const minute = getPart('minute');
    const second = getPart('second');

    const wallClockUtc = Date.UTC(year, month - 1, day, hour, minute, second);
    const actualUtc = date.getTime();

    return Math.round((wallClockUtc - actualUtc) / 60000);
  } catch {
    return 0;
  }
}

/**
 * Break down a Date into its local year, month, day, hour, min in given timezone
 */
export function getZonedDateParts(date: Date, timeZone: string) {
  const dtf = new Intl.DateTimeFormat('en-US', {
    timeZone,
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
    hour: 'numeric',
    minute: 'numeric',
    second: 'numeric',
    weekday: 'short',
    hour12: false,
  });

  const parts = dtf.formatToParts(date);
  const findVal = (type: string) => parts.find((p) => p.type === type)?.value || '0';

  let hour = parseInt(findVal('hour'), 10);
  if (hour === 24) hour = 0;

  // Day of week index (0 = Sun, 1 = Mon ... 6 = Sat)
  const weekdayStr = findVal('weekday');
  const daysMap: Record<string, number> = {
    Sun: 0,
    Mon: 1,
    Tue: 2,
    Wed: 3,
    Thu: 4,
    Fri: 5,
    Sat: 6,
  };
  const dayOfWeek = daysMap[weekdayStr] ?? 0;

  return {
    year: parseInt(findVal('year'), 10),
    month: parseInt(findVal('month'), 10), // 1-12
    day: parseInt(findVal('day'), 10),
    hour,
    minute: parseInt(findVal('minute'), 10),
    second: parseInt(findVal('second'), 10),
    dayOfWeek,
  };
}

/**
 * Converts a Wall-Clock time (year, month, day, hour, minute) in target timeZone into an exact UTC Epoch timestamp.
 * Uses 2-step iterative refinement to perfectly respect seasonal DST changes.
 */
export function convertZonedWallTimeToUtc(
  year: number,
  month: number, // 1-12
  day: number,
  hour: number,
  minute: number,
  timeZone: string
): number {
  // Step 1: Initial guess treating wall-clock as UTC
  let guessUtc = Date.UTC(year, month - 1, day, hour, minute, 0, 0);

  for (let iteration = 0; iteration < 3; iteration++) {
    const zoned = getZonedDateParts(new Date(guessUtc), timeZone);
    const zonedWallAsUtc = Date.UTC(zoned.year, zoned.month - 1, zoned.day, zoned.hour, zoned.minute, zoned.second, 0);
    const targetWallAsUtc = Date.UTC(year, month - 1, day, hour, minute, 0, 0);

    const diff = targetWallAsUtc - zonedWallAsUtc;
    if (Math.abs(diff) < 1000) {
      break;
    }
    guessUtc += diff;
  }

  return guessUtc;
}

/**
 * Calculates the exact upcoming trigger timestamp for an alarm based on its source timezone,
 * repeat days, and converts it to the user's local timezone.
 */
export function calculateNextAlarm(
  alarm: Alarm,
  localTimeZone: string = getUserLocalTimeZone(),
  referenceDate: Date = new Date()
): NextAlarmInfo | null {
  const [alarmHourStr, alarmMinuteStr] = alarm.sourceTime.split(':');
  const alarmHour = parseInt(alarmHourStr, 10);
  const alarmMinute = parseInt(alarmMinuteStr, 10);

  if (isNaN(alarmHour) || isNaN(alarmMinute)) {
    return null;
  }

  // Current parts in the alarm's source timezone
  const srcNow = getZonedDateParts(referenceDate, alarm.sourceTimeZone);

  // If snoozed and snooze is in the future
  if (alarm.snoozeUntil && alarm.snoozeUntil > referenceDate.getTime() - 2000) {
    return formatNextAlarmInfo(alarm.id, alarm.snoozeUntil, alarm.sourceTimeZone, localTimeZone, referenceDate, true);
  }

  let chosenUtcMs = 0;
  const isRecurring = alarm.days && alarm.days.length > 0;

  // Search forward up to 8 days in the source timezone
  for (let dayOffset = 0; dayOffset <= 8; dayOffset++) {
    // Construct date in source timezone by advancing days
    const candidateDateObj = new Date(Date.UTC(srcNow.year, srcNow.month - 1, srcNow.day + dayOffset, 12, 0, 0));
    const candYear = candidateDateObj.getUTCFullYear();
    const candMonth = candidateDateObj.getUTCMonth() + 1;
    const candDay = candidateDateObj.getUTCDate();

    // Convert candidate wall time to exact UTC
    const candUtcMs = convertZonedWallTimeToUtc(
      candYear,
      candMonth,
      candDay,
      alarmHour,
      alarmMinute,
      alarm.sourceTimeZone
    );

    // Must be in the future or current active window (greater than referenceDate - 1 second)
    if (candUtcMs < referenceDate.getTime() - 999) {
      continue;
    }

    // Check day of week in the source timezone
    const candZoned = getZonedDateParts(new Date(candUtcMs), alarm.sourceTimeZone);
    const candDayOfWeek = candZoned.dayOfWeek;

    if (!isRecurring) {
      // One time alarm: take first upcoming occurrence
      chosenUtcMs = candUtcMs;
      break;
    } else if (alarm.days.includes(candDayOfWeek)) {
      chosenUtcMs = candUtcMs;
      break;
    }
  }

  if (chosenUtcMs === 0) {
    return null;
  }

  return formatNextAlarmInfo(alarm.id, chosenUtcMs, alarm.sourceTimeZone, localTimeZone, referenceDate, false);
}

/**
 * Checks if an alarm is due to ring at the given time 'now'
 */
export function checkAlarmTrigger(
  alarm: Alarm,
  now: Date
): { shouldTrigger: boolean; triggerEpoch: number } {
  if (!alarm.enabled) {
    return { shouldTrigger: false, triggerEpoch: 0 };
  }

  const nowEpoch = now.getTime();

  // Check snooze trigger
  if (alarm.snoozeUntil) {
    const diffSnooze = nowEpoch - alarm.snoozeUntil;
    if (diffSnooze >= -500 && diffSnooze < 60000) {
      if (alarm.lastTriggeredEpoch !== alarm.snoozeUntil) {
        return { shouldTrigger: true, triggerEpoch: alarm.snoozeUntil };
      }
    }
    return { shouldTrigger: false, triggerEpoch: 0 };
  }

  const [alarmHourStr, alarmMinuteStr] = alarm.sourceTime.split(':');
  const alarmHour = parseInt(alarmHourStr, 10);
  const alarmMinute = parseInt(alarmMinuteStr, 10);

  if (isNaN(alarmHour) || isNaN(alarmMinute)) {
    return { shouldTrigger: false, triggerEpoch: 0 };
  }

  const srcNow = getZonedDateParts(now, alarm.sourceTimeZone);
  const isRecurring = alarm.days && alarm.days.length > 0;

  // Check offsets from -1 day (yesterday) to +1 day (tomorrow) to account for time differences
  for (let dayOffset = -1; dayOffset <= 1; dayOffset++) {
    const candidateDateObj = new Date(Date.UTC(srcNow.year, srcNow.month - 1, srcNow.day + dayOffset, 12, 0, 0));
    const candYear = candidateDateObj.getUTCFullYear();
    const candMonth = candidateDateObj.getUTCMonth() + 1;
    const candDay = candidateDateObj.getUTCDate();

    const candUtcMs = convertZonedWallTimeToUtc(
      candYear,
      candMonth,
      candDay,
      alarmHour,
      alarmMinute,
      alarm.sourceTimeZone
    );

    const diffMs = nowEpoch - candUtcMs;

    // Trigger window: within 60 seconds after scheduled time, or within 500ms before
    if (diffMs >= -500 && diffMs < 60000) {
      const candZoned = getZonedDateParts(new Date(candUtcMs), alarm.sourceTimeZone);
      if (!isRecurring || alarm.days.includes(candZoned.dayOfWeek)) {
        if (alarm.lastTriggeredEpoch !== candUtcMs) {
          return { shouldTrigger: true, triggerEpoch: candUtcMs };
        }
      }
    }
  }

  return { shouldTrigger: false, triggerEpoch: 0 };
}

function formatNextAlarmInfo(
  alarmId: string,
  triggerUtcMs: number,
  sourceTimeZone: string,
  localTimeZone: string,
  now: Date,
  isSnoozed: boolean
): NextAlarmInfo {
  const triggerDate = new Date(triggerUtcMs);

  const srcDetails = getTimeZoneDetails(sourceTimeZone, triggerDate);
  const locDetails = getTimeZoneDetails(localTimeZone, triggerDate);

  // Format source time string
  const sourceTimeFormatted = triggerDate.toLocaleTimeString('en-US', {
    timeZone: sourceTimeZone,
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  });

  const sourceDateFormatted = triggerDate.toLocaleDateString('en-US', {
    timeZone: sourceTimeZone,
    weekday: 'short',
    month: 'short',
    day: 'numeric',
  });

  // Format local time string
  const localTimeFormatted = triggerDate.toLocaleTimeString('en-US', {
    timeZone: localTimeZone,
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  });

  const localDateFormatted = triggerDate.toLocaleDateString('en-US', {
    timeZone: localTimeZone,
    weekday: 'short',
    month: 'short',
    day: 'numeric',
  });

  // Day difference between local trigger date and local now date
  const locNowParts = getZonedDateParts(now, localTimeZone);
  const locTrigParts = getZonedDateParts(triggerDate, localTimeZone);

  const locNowDayStart = Date.UTC(locNowParts.year, locNowParts.month - 1, locNowParts.day);
  const locTrigDayStart = Date.UTC(locTrigParts.year, locTrigParts.month - 1, locTrigParts.day);
  const dayDifference = Math.round((locTrigDayStart - locNowDayStart) / (24 * 60 * 60 * 1000));

  // Relative time text
  const diffMs = triggerUtcMs - now.getTime();
  let relativeTimeText = '';
  if (diffMs <= 0) {
    relativeTimeText = 'Now!';
  } else {
    const totalMinutes = Math.floor(diffMs / 60000);
    const hours = Math.floor(totalMinutes / 60);
    const mins = totalMinutes % 60;
    const days = Math.floor(hours / 24);

    if (days > 0) {
      relativeTimeText = `in ${days}d ${hours % 24}h ${mins}m`;
    } else if (hours > 0) {
      relativeTimeText = `in ${hours}h ${mins}m`;
    } else if (mins > 0) {
      relativeTimeText = `in ${mins} min${mins > 1 ? 's' : ''}`;
    } else {
      const secs = Math.floor(diffMs / 1000);
      relativeTimeText = `in ${secs}s`;
    }
  }

  if (isSnoozed) {
    relativeTimeText = `Snoozed (${relativeTimeText})`;
  }

  return {
    alarmId,
    nextTriggerUtcMs: triggerUtcMs,
    sourceDateFormatted,
    sourceTimeFormatted,
    localDateFormatted,
    localTimeFormatted,
    relativeTimeText,
    dayDifference,
    sourceAbbr: srcDetails.timeZoneAbbreviation,
    localAbbr: locDetails.timeZoneAbbreviation,
    sourceIsDST: srcDetails.isDaylightSaving,
  };
}

/**
 * Converts any arbitrary time (HH:mm) from a source timezone to a destination timezone for today/preview
 */
export function previewTimezoneConversion(
  sourceTime: string,
  sourceTimeZone: string,
  targetTimeZone: string,
  baseDate: Date = new Date()
) {
  const [hStr, mStr] = sourceTime.split(':');
  const hours = parseInt(hStr || '0', 10);
  const minutes = parseInt(mStr || '0', 10);

  const srcNow = getZonedDateParts(baseDate, sourceTimeZone);
  const utcMs = convertZonedWallTimeToUtc(
    srcNow.year,
    srcNow.month,
    srcNow.day,
    hours,
    minutes,
    sourceTimeZone
  );

  const convertedDate = new Date(utcMs);

  const targetTimeStr = convertedDate.toLocaleTimeString('en-US', {
    timeZone: targetTimeZone,
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  });

  const targetDateStr = convertedDate.toLocaleDateString('en-US', {
    timeZone: targetTimeZone,
    weekday: 'short',
    month: 'short',
    day: 'numeric',
  });

  const srcDateStr = convertedDate.toLocaleDateString('en-US', {
    timeZone: sourceTimeZone,
    weekday: 'short',
    month: 'short',
    day: 'numeric',
  });

  const srcDetails = getTimeZoneDetails(sourceTimeZone, convertedDate);
  const targetDetails = getTimeZoneDetails(targetTimeZone, convertedDate);

  // Offset difference in hours between source and target
  const offsetDiffHours = (targetDetails.utcOffsetMinutes - srcDetails.utcOffsetMinutes) / 60;
  const offsetDiffFormatted =
    offsetDiffHours === 0
      ? 'Same time zone'
      : `${offsetDiffHours > 0 ? '+' : ''}${offsetDiffHours} hrs`;

  return {
    sourceTimeFormatted: convertedDate.toLocaleTimeString('en-US', {
      timeZone: sourceTimeZone,
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    }),
    sourceDateStr: srcDateStr,
    sourceAbbr: srcDetails.timeZoneAbbreviation,
    sourceIsDST: srcDetails.isDaylightSaving,
    sourceDstSeason: srcDetails.dstSeasonLabel,
    targetTimeFormatted: targetTimeStr,
    targetDateStr: targetDateStr,
    targetAbbr: targetDetails.timeZoneAbbreviation,
    targetIsDST: targetDetails.isDaylightSaving,
    targetDstSeason: targetDetails.dstSeasonLabel,
    offsetDiffHours,
    offsetDiffFormatted,
  };
}

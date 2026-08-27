export type AlarmSoundType = 'digital' | 'chime' | 'marimba' | 'radar' | 'bell' | 'gentle' | 'silent';
export type AlarmAlertMode = 'sound_and_vibrate' | 'sound_only' | 'vibrate_only';

export interface Alarm {
  id: string;
  title: string;
  sourceTimeZone: string; // e.g. "America/Los_Angeles"
  sourceTime: string; // "HH:mm" in 24h format, e.g. "06:30"
  days: number[]; // 0=Sun, 1=Mon, ..., 6=Sat. Empty array means One-Time Alarm.
  enabled: boolean;
  alertMode?: AlarmAlertMode; // 'sound_and_vibrate' | 'sound_only' | 'vibrate_only'
  sound: AlarmSoundType;
  volume: number; // 0.0 to 1.0
  vibrate: boolean;
  createdAt: number;
  snoozeUntil?: number | null; // Epoch timestamp in ms if snoozed
  lastTriggeredDate?: string | null;
  lastTriggeredEpoch?: number | null;
}

export interface TimeZoneOption {
  iana: string;
  city: string;
  country: string;
  region: string;
  displayName: string;
  popular?: boolean;
  commonAbbr?: string;
}

export interface TimeZoneDetails {
  iana: string;
  displayName: string;
  currentLocalTime: string;
  currentLocalDate: string;
  utcOffsetMinutes: number;
  utcOffsetFormatted: string; // e.g. "UTC-07:00"
  timeZoneAbbreviation: string; // e.g. "PDT" or "PST"
  isDaylightSaving: boolean;
  dstSeasonLabel: string; // e.g. "Daylight Saving (Summer/Fall)" or "Standard Time (Winter)"
}

export interface NextAlarmInfo {
  alarmId: string;
  nextTriggerUtcMs: number;
  sourceDateFormatted: string;
  sourceTimeFormatted: string;
  localDateFormatted: string;
  localTimeFormatted: string;
  relativeTimeText: string;
  dayDifference: number; // 0 = same day, +1 = tomorrow/next day, -1 = yesterday
  sourceAbbr: string;
  localAbbr: string;
  sourceIsDST: boolean;
}

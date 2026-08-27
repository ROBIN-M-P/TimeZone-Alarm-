import { useState, useEffect } from 'react';
import { Alarm, NextAlarmInfo } from '../types';
import { calculateNextAlarm, getTimeZoneDetails } from '../utils/timezone';
import {
  Bell,
  Clock,
  Calendar,
  Volume2,
  VolumeX,
  Smartphone,
  Play,
  Pencil,
  Trash2,
  Sparkles,
  ArrowRight,
  Sun,
  Moon,
} from 'lucide-react';

interface AlarmCardProps {
  key?: string;
  alarm: Alarm;
  localTimeZone: string;
  use24Hour: boolean;
  onToggleEnabled: (id: string, enabled: boolean) => void;
  onEdit: (alarm: Alarm) => void;
  onDelete: (id: string) => void;
  onTestTrigger: (alarm: Alarm) => void;
}

const DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

export function AlarmCard({
  alarm,
  localTimeZone,
  use24Hour,
  onToggleEnabled,
  onEdit,
  onDelete,
  onTestTrigger,
}: AlarmCardProps) {
  const [now, setNow] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  const nextInfo: NextAlarmInfo | null = calculateNextAlarm(alarm, localTimeZone, now);
  const sourceTzDetails = getTimeZoneDetails(alarm.sourceTimeZone, now);

  // Format source time for display
  const [hoursStr, minutesStr] = alarm.sourceTime.split(':');
  const hoursNum = parseInt(hoursStr, 10);
  const minutesNum = parseInt(minutesStr, 10);

  let formattedSourceTime = alarm.sourceTime;
  if (!use24Hour) {
    const period = hoursNum >= 12 ? 'PM' : 'AM';
    const h12 = hoursNum % 12 || 12;
    formattedSourceTime = `${h12}:${String(minutesNum).padStart(2, '0')} ${period}`;
  }

  const isRecurring = alarm.days && alarm.days.length > 0;
  const isSnoozed = !!(alarm.snoozeUntil && alarm.snoozeUntil > now.getTime());

  // Day shift badge text
  let dayShiftBadge = null;
  if (nextInfo) {
    if (nextInfo.dayDifference === 0) {
      dayShiftBadge = <span className="text-[11px] font-medium px-2 py-0.5 rounded bg-emerald-500/15 text-emerald-300 border border-emerald-500/20">Same Day</span>;
    } else if (nextInfo.dayDifference > 0) {
      dayShiftBadge = <span className="text-[11px] font-medium px-2 py-0.5 rounded bg-sky-500/15 text-sky-300 border border-sky-500/20">+{nextInfo.dayDifference} Day (Tomorrow)</span>;
    } else {
      dayShiftBadge = <span className="text-[11px] font-medium px-2 py-0.5 rounded bg-amber-500/15 text-amber-300 border border-amber-500/20">{nextInfo.dayDifference} Day (Yesterday)</span>;
    }
  }

  return (
    <div
      id={`alarm-card-${alarm.id}`}
      className={`relative rounded-2xl border transition-all overflow-hidden ${
        alarm.enabled
          ? 'bg-slate-900/90 border-slate-700/80 shadow-lg shadow-black/40 hover:border-indigo-500/60'
          : 'bg-slate-900/40 border-slate-800/60 opacity-65 hover:opacity-90'
      }`}
    >
      {/* Top Bar: Title & Toggle */}
      <div className="px-5 pt-5 pb-3 flex items-start justify-between gap-3">
        <div className="min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <h3 className="text-base font-bold text-white truncate max-w-xs sm:max-w-md">
              {alarm.title || 'Untitled Alarm'}
            </h3>
            {isSnoozed && (
              <span className="px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider rounded-full bg-amber-500/20 text-amber-300 border border-amber-500/30 animate-pulse">
                Snoozed
              </span>
            )}
          </div>

          <div className="flex items-center gap-2 mt-1 text-xs text-slate-400">
            <span className="font-medium text-slate-300">
              {sourceTzDetails.displayName.split('/')[1]?.replace(/_/g, ' ') || sourceTzDetails.displayName}
            </span>
            <span>•</span>
            <span className="font-mono text-slate-400">
              {sourceTzDetails.timeZoneAbbreviation} ({sourceTzDetails.utcOffsetFormatted})
            </span>
            {sourceTzDetails.isDaylightSaving && (
              <span className="inline-flex items-center gap-1 text-[11px] text-amber-400 font-medium">
                <Sparkles className="w-3 h-3" /> DST
              </span>
            )}
          </div>
        </div>

        {/* Toggle Switch */}
        <label className="relative inline-flex items-center cursor-pointer shrink-0">
          <input
            id={`toggle-alarm-${alarm.id}`}
            type="checkbox"
            checked={alarm.enabled}
            onChange={(e) => onToggleEnabled(alarm.id, e.target.checked)}
            className="sr-only peer"
          />
          <div className="w-11 h-6 bg-slate-800 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600"></div>
        </label>
      </div>

      {/* Main Conversion Comparison Grid */}
      <div className="px-5 py-3">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 p-4 rounded-xl bg-slate-950/60 border border-slate-800/80">
          
          {/* Source Zone Time */}
          <div className="flex flex-col justify-center">
            <div className="text-[11px] font-medium uppercase tracking-wider text-slate-400 flex items-center gap-1.5">
              <span>Source Zone</span>
              <span className="text-slate-500 font-mono text-[10px]">({sourceTzDetails.timeZoneAbbreviation})</span>
            </div>
            <div className="mt-1 text-2xl sm:text-3xl font-mono font-black tracking-tight text-white">
              {formattedSourceTime}
            </div>
            <div className="text-xs text-slate-400 mt-0.5 truncate">
              {alarm.sourceTimeZone}
            </div>
          </div>

          {/* Local Zone Time (Highlighted) */}
          <div className="flex flex-col justify-center sm:border-l sm:border-slate-800 sm:pl-4">
            <div className="text-[11px] font-semibold uppercase tracking-wider text-indigo-400 flex items-center gap-1.5">
              <Bell className="w-3 h-3 text-indigo-400" />
              <span>Rings In Your Local Time</span>
            </div>

            <div className="mt-1 text-2xl sm:text-3xl font-mono font-black tracking-tight text-emerald-400">
              {nextInfo ? nextInfo.localTimeFormatted : '--:--'}
            </div>

            <div className="text-xs text-slate-300 mt-0.5 flex items-center gap-2">
              <span>{nextInfo ? nextInfo.localDateFormatted : ''}</span>
              {dayShiftBadge}
            </div>
          </div>

        </div>
      </div>

      {/* Countdown & Seasonal Sync Info */}
      <div className="px-5 py-2 flex flex-wrap items-center justify-between gap-2 text-xs">
        <div className="flex items-center gap-2">
          <span className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-indigo-500/10 text-indigo-300 font-medium border border-indigo-500/20">
            <Clock className="w-3.5 h-3.5 text-indigo-400" />
            <span>Next: {nextInfo ? nextInfo.relativeTimeText : 'Disabled'}</span>
          </span>

          <span className="text-slate-500 hidden md:inline">•</span>

          <span className="text-slate-400 text-[11px] hidden md:inline">
            Seasonal DST: <span className="text-slate-300">{sourceTzDetails.dstSeasonLabel}</span>
          </span>
        </div>

        {/* Days Repeat Badges */}
        <div className="flex items-center gap-1">
          {!isRecurring ? (
            <span className="text-[11px] font-medium px-2 py-0.5 rounded bg-slate-800 text-slate-300">
              One-Time
            </span>
          ) : (
            DAY_NAMES.map((d, index) => {
              const isActive = alarm.days.includes(index);
              return (
                <span
                  key={d}
                  className={`w-6 h-6 flex items-center justify-center text-[10px] font-bold rounded-full ${
                    isActive
                      ? 'bg-indigo-600 text-white shadow-sm shadow-indigo-600/30'
                      : 'bg-slate-800 text-slate-600'
                  }`}
                  title={`${d} is ${isActive ? 'Active' : 'Off'}`}
                >
                  {d[0]}
                </span>
              );
            })
          )}
        </div>
      </div>

      {/* Card Footer: Sound info & Action buttons */}
      <div className="px-5 py-3 mt-2 bg-slate-950/40 border-t border-slate-800/80 flex items-center justify-between gap-3 text-xs">
        <div className="flex items-center gap-2 text-slate-400">
          {alarm.alertMode === 'vibrate_only' || alarm.sound === 'silent' ? (
            <div className="flex items-center gap-1.5 text-indigo-400 font-medium">
              <Smartphone className="w-3.5 h-3.5" />
              <span>Vibrate Only</span>
            </div>
          ) : alarm.alertMode === 'sound_only' || (!alarm.alertMode && !alarm.vibrate) ? (
            <div className="flex items-center gap-1.5">
              <Volume2 className="w-3.5 h-3.5 text-slate-400" />
              <span className="capitalize">{alarm.sound}</span>
              <span className="text-slate-600">•</span>
              <span>{Math.round(alarm.volume * 100)}%</span>
            </div>
          ) : (
            <div className="flex items-center gap-1.5">
              <Volume2 className="w-3.5 h-3.5 text-emerald-400" />
              <span className="capitalize">{alarm.sound}</span>
              <span className="text-slate-600">•</span>
              <Smartphone className="w-3.5 h-3.5 text-indigo-400" />
              <span>Vibrate</span>
            </div>
          )}
        </div>

        <div className="flex items-center gap-1.5">
          {/* Test Trigger Button */}
          <button
            id={`btn-test-alarm-${alarm.id}`}
            onClick={() => onTestTrigger(alarm)}
            title="Test preview this alarm now"
            className="min-h-[36px] flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-800 active:bg-slate-700 text-slate-300 hover:text-white transition"
          >
            <Play className="w-3.5 h-3.5 text-emerald-400" />
            <span className="font-semibold text-xs">Test</span>
          </button>

          {/* Edit Button */}
          <button
            id={`btn-edit-alarm-${alarm.id}`}
            onClick={() => onEdit(alarm)}
            title="Edit alarm"
            className="min-h-[36px] min-w-[36px] flex items-center justify-center p-2 rounded-xl bg-slate-800 active:bg-slate-700 text-slate-300 hover:text-white transition"
          >
            <Pencil className="w-4 h-4" />
          </button>

          {/* Delete Button */}
          <button
            id={`btn-delete-alarm-${alarm.id}`}
            onClick={() => onDelete(alarm.id)}
            title="Delete alarm"
            className="min-h-[36px] min-w-[36px] flex items-center justify-center p-2 rounded-xl bg-slate-800 active:bg-rose-950/60 text-slate-400 hover:text-rose-400 transition"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}

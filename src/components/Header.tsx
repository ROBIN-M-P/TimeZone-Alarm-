import { useState, useEffect } from 'react';
import { Clock, Plus, Bell, BellRing, Volume2, Globe, Sparkles } from 'lucide-react';
import { getTimeZoneDetails } from '../utils/timezone';
import { requestNotificationPermission } from '../utils/notifications';

interface HeaderProps {
  localTimeZone: string;
  onOpenNewAlarm: () => void;
  onOpenConverter: () => void;
  onOpenDstGuide: () => void;
  activeAlarmsCount: number;
  totalAlarmsCount: number;
  use24Hour: boolean;
  onToggle24Hour: () => void;
}

export function Header({
  localTimeZone,
  onOpenNewAlarm,
  onOpenConverter,
  onOpenDstGuide,
  activeAlarmsCount,
  totalAlarmsCount,
  use24Hour,
  onToggle24Hour,
}: HeaderProps) {
  const [now, setNow] = useState(new Date());
  const [notificationPerm, setNotificationPerm] = useState<NotificationPermission>('default');

  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 1000);
    if ('Notification' in window) {
      setNotificationPerm(Notification.permission);
    }
    return () => clearInterval(timer);
  }, []);

  const handleReqNotification = async () => {
    const perm = await requestNotificationPermission();
    setNotificationPerm(perm);
  };

  const tzDetails = getTimeZoneDetails(localTimeZone, now);

  const formattedTime = now.toLocaleTimeString('en-US', {
    timeZone: localTimeZone,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: !use24Hour,
  });

  const formattedDate = now.toLocaleDateString('en-US', {
    timeZone: localTimeZone,
    weekday: 'long',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });

  return (
    <header className="border-b border-slate-800/80 bg-slate-900/80 backdrop-blur-md sticky top-0 z-30 pt-safe">
      <div className="max-w-7xl mx-auto px-3.5 sm:px-6 lg:px-8 py-3 sm:py-4">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3 sm:gap-4">
          
          {/* Brand & Live Local Clock */}
          <div className="flex items-center gap-3 sm:gap-4">
            <div className="relative flex items-center justify-center w-10 h-10 sm:w-12 sm:h-12 rounded-xl bg-gradient-to-br from-indigo-500 to-cyan-500 shadow-lg shadow-indigo-500/25 shrink-0">
              <Clock className="w-5 h-5 sm:w-6 sm:h-6 text-white" />
              <span className="absolute -top-1 -right-1 flex h-3 w-3 sm:h-3.5 sm:w-3.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-3 w-3 sm:h-3.5 sm:w-3.5 bg-emerald-500"></span>
              </span>
            </div>

            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2">
                <h1 className="text-lg sm:text-xl font-bold tracking-tight text-white flex items-center gap-2 truncate">
                  Timezone Alarm
                </h1>
                <span className="text-[10px] sm:text-xs font-semibold px-2 py-0.5 rounded-full bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 shrink-0">
                  Auto-Convert
                </span>
              </div>

              {/* Local Time Display */}
              <div className="flex items-baseline flex-wrap gap-x-2 gap-y-0.5 mt-0.5">
                <span className="font-mono text-xl sm:text-3xl font-bold tracking-tight text-emerald-400">
                  {formattedTime}
                </span>
                <span className="text-[11px] text-slate-400 hidden sm:inline">
                  {formattedDate}
                </span>
                <span className="text-[10px] sm:text-xs font-medium px-1.5 sm:px-2 py-0.5 rounded bg-slate-800 text-slate-300 border border-slate-700/60 truncate max-w-[170px] sm:max-w-none">
                  📍 {tzDetails.timeZoneAbbreviation} ({tzDetails.utcOffsetFormatted})
                </span>
              </div>
            </div>
          </div>

          {/* Quick Actions & Alarm Stats */}
          <div className="flex items-center gap-2 overflow-x-auto pb-1 sm:pb-0 scrollbar-none">
            
            {/* 12h / 24h Toggle */}
            <button
              id="btn-toggle-time-format"
              onClick={onToggle24Hour}
              title="Toggle 12-hour or 24-hour display"
              className="min-h-[38px] px-3 py-2 text-xs font-semibold rounded-xl bg-slate-800/90 active:bg-slate-700 text-slate-200 border border-slate-700/80 transition shrink-0"
            >
              {use24Hour ? '24H' : '12H'}
            </button>

            {/* Notification Permission Button */}
            {notificationPerm !== 'granted' && (
              <button
                id="btn-enable-notifications"
                onClick={handleReqNotification}
                className="min-h-[38px] flex items-center gap-1.5 px-3 py-2 text-xs font-semibold rounded-xl bg-amber-500/10 active:bg-amber-500/25 text-amber-300 border border-amber-500/30 transition shrink-0 animate-pulse"
                title="Enable device notifications for background alerts"
              >
                <Bell className="w-3.5 h-3.5 text-amber-400" />
                <span>Alerts</span>
              </button>
            )}

            {notificationPerm === 'granted' && (
              <span className="hidden sm:flex items-center gap-1.5 px-2.5 py-1.5 text-xs font-medium rounded-xl bg-emerald-500/10 text-emerald-300 border border-emerald-500/20 shrink-0">
                <BellRing className="w-3.5 h-3.5 text-emerald-400" />
                <span className="hidden md:inline">Alerts Active</span>
              </span>
            )}

            {/* Timezone Converter Explorer */}
            <button
              id="btn-open-converter"
              onClick={onOpenConverter}
              className="min-h-[38px] flex items-center gap-1.5 px-3 py-2 text-xs sm:text-sm font-semibold rounded-xl bg-slate-800 active:bg-slate-700 text-slate-200 border border-slate-700/80 transition shrink-0"
            >
              <Globe className="w-4 h-4 text-cyan-400" />
              <span>Explorer</span>
            </button>

            {/* Season / DST info */}
            <button
              id="btn-open-dst-guide"
              onClick={onOpenDstGuide}
              className="min-h-[38px] flex items-center gap-1.5 px-3 py-2 text-xs sm:text-sm font-semibold rounded-xl bg-slate-800 active:bg-slate-700 text-slate-200 border border-slate-700/80 transition shrink-0"
              title="How seasonal daylight saving is auto-calculated"
            >
              <Sparkles className="w-4 h-4 text-amber-400" />
              <span>DST Info</span>
            </button>

            {/* Create New Alarm Button (Desktop header) */}
            <button
              id="btn-create-alarm"
              onClick={onOpenNewAlarm}
              className="hidden sm:flex min-h-[38px] items-center gap-2 px-4 py-2 text-xs sm:text-sm font-bold rounded-xl bg-gradient-to-r from-indigo-500 to-indigo-600 active:scale-95 text-white shadow-lg shadow-indigo-500/20 transition shrink-0"
            >
              <Plus className="w-4 h-4" />
              <span>Set Alarm</span>
            </button>

          </div>

        </div>

        {/* Sub-bar stats */}
        <div className="mt-2.5 flex items-center justify-between text-[11px] sm:text-xs text-slate-400 pt-2 border-t border-slate-800/50">
          <div className="flex items-center gap-2 truncate">
            <span>
              <strong className="text-slate-200">{activeAlarmsCount}</strong> of <strong className="text-slate-200">{totalAlarmsCount}</strong> alarms active
            </span>
          </div>

          <div className="flex items-center gap-1.5 text-slate-300 shrink-0">
            <span className="inline-block w-2 h-2 rounded-full bg-emerald-400"></span>
            <span>DST Ready</span>
          </div>
        </div>

      </div>
    </header>
  );
}

import { useState, useEffect } from 'react';
import { Sun, Moon, Plus, Globe } from 'lucide-react';
import { getTimeZoneDetails, getZonedDateParts } from '../utils/timezone';

interface WorldClockBarProps {
  localTimeZone: string;
  onSelectZoneForAlarm: (iana: string) => void;
  use24Hour: boolean;
}

const FEATURED_ZONES = [
  { iana: 'America/Los_Angeles', label: 'Los Angeles (PST/PDT)', flag: '🇺🇸' },
  { iana: 'America/New_York', label: 'New York (EST/EDT)', flag: '🇺🇸' },
  { iana: 'Europe/London', label: 'London (GMT/BST)', flag: '🇬🇧' },
  { iana: 'Europe/Paris', label: 'Paris (CET/CEST)', flag: '🇫🇷' },
  { iana: 'Asia/Dubai', label: 'Dubai (GST)', flag: '🇦🇪' },
  { iana: 'Asia/Kolkata', label: 'India (IST)', flag: '🇮🇳' },
  { iana: 'Asia/Singapore', label: 'Singapore (SGT)', flag: '🇸🇬' },
  { iana: 'Asia/Tokyo', label: 'Tokyo (JST)', flag: '🇯🇵' },
  { iana: 'Australia/Sydney', label: 'Sydney (AEST/AEDT)', flag: '🇦🇺' },
];

export function WorldClockBar({ localTimeZone, onSelectZoneForAlarm, use24Hour }: WorldClockBarProps) {
  const [now, setNow] = useState(new Date());

  useEffect(() => {
    const interval = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(interval);
  }, []);

  const localDetails = getTimeZoneDetails(localTimeZone, now);

  return (
    <section className="my-6">
      <div className="flex items-center justify-between mb-3 px-1">
        <div className="flex items-center gap-2">
          <Globe className="w-4 h-4 text-indigo-400" />
          <h2 className="text-sm font-semibold text-slate-300 uppercase tracking-wider">
            Live Global Clocks
          </h2>
        </div>
        <span className="text-xs text-slate-500">
          Click any clock to set an alarm in that timezone
        </span>
      </div>

      <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-thin scrollbar-thumb-slate-800 scrollbar-track-transparent">
        {FEATURED_ZONES.map((zone) => {
          const details = getTimeZoneDetails(zone.iana, now);
          const zonedParts = getZonedDateParts(now, zone.iana);
          const isDaytime = zonedParts.hour >= 6 && zonedParts.hour < 18;

          // Time difference relative to local
          const diffMinutes = details.utcOffsetMinutes - localDetails.utcOffsetMinutes;
          const diffHours = diffMinutes / 60;
          let diffLabel = 'Same time';
          if (diffHours !== 0) {
            diffLabel = `${diffHours > 0 ? '+' : ''}${diffHours}h`;
          }

          const timeFormatted = now.toLocaleTimeString('en-US', {
            timeZone: zone.iana,
            hour: '2-digit',
            minute: '2-digit',
            hour12: !use24Hour,
          });

          return (
            <div
              key={zone.iana}
              onClick={() => onSelectZoneForAlarm(zone.iana)}
              role="button"
              tabIndex={0}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  onSelectZoneForAlarm(zone.iana);
                }
              }}
              className="group relative flex-shrink-0 w-44 p-3.5 rounded-xl bg-slate-900/70 border border-slate-800 hover:border-indigo-500/50 hover:bg-slate-800/80 transition-all cursor-pointer shadow-sm hover:shadow-indigo-500/10"
            >
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm flex items-center gap-1.5 font-medium text-slate-300 truncate">
                  <span>{zone.flag}</span>
                  <span className="truncate">{zone.label.split(' ')[0]}</span>
                </span>

                <div className="flex items-center gap-1">
                  {isDaytime ? (
                    <Sun className="w-3.5 h-3.5 text-amber-400" />
                  ) : (
                    <Moon className="w-3.5 h-3.5 text-indigo-300" />
                  )}
                </div>
              </div>

              <div className="font-mono text-xl font-bold tracking-tight text-white group-hover:text-indigo-300 transition-colors">
                {timeFormatted}
              </div>

              <div className="flex items-center justify-between mt-2 pt-2 border-t border-slate-800/80 text-[11px]">
                <span className="text-slate-400 font-mono">
                  {details.timeZoneAbbreviation}
                </span>

                <span className="px-1.5 py-0.5 rounded bg-slate-800 text-slate-400 text-[10px] font-mono">
                  {diffLabel}
                </span>
              </div>

              {details.isDaylightSaving && (
                <div className="mt-1 text-[10px] text-amber-400/90 font-medium">
                  • DST Active
                </div>
              )}

              {/* Hover Quick Set Badge */}
              <div className="absolute inset-0 rounded-xl bg-indigo-950/80 backdrop-blur-xs flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                <span className="flex items-center gap-1 text-xs font-semibold text-indigo-200">
                  <Plus className="w-3.5 h-3.5" />
                  Set Alarm Here
                </span>
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
}

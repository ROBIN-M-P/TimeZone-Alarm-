import { useState, useMemo } from 'react';
import { getAllAvailableTimeZones, POPULAR_TIMEZONES } from '../utils/timezoneData';
import { previewTimezoneConversion, getTimeZoneDetails } from '../utils/timezone';
import {
  X,
  Globe,
  Sun,
  Moon,
  Clock,
  ArrowRight,
  Plus,
  Sparkles,
  Search,
} from 'lucide-react';

interface TimezoneConverterProps {
  isOpen: boolean;
  onClose: () => void;
  localTimeZone: string;
  onSetAlarmForTime: (sourceTz: string, time24: string) => void;
}

export function TimezoneConverter({
  isOpen,
  onClose,
  localTimeZone,
  onSetAlarmForTime,
}: TimezoneConverterProps) {
  const [sourceTz, setSourceTz] = useState('America/Los_Angeles');
  const [targetTz, setTargetTz] = useState(localTimeZone);
  const [hourSlider, setHourSlider] = useState(6.5); // 6:30 AM default

  const allTimeZones = useMemo(() => getAllAvailableTimeZones(), []);

  // Convert decimal hours to "HH:mm"
  const hourInt = Math.floor(hourSlider);
  const minInt = Math.round((hourSlider - hourInt) * 60);
  const time24Str = `${String(hourInt).padStart(2, '0')}:${String(minInt).padStart(2, '0')}`;

  const conversion = useMemo(() => {
    return previewTimezoneConversion(time24Str, sourceTz, targetTz);
  }, [time24Str, sourceTz, targetTz]);

  const sourceDetails = useMemo(() => getTimeZoneDetails(sourceTz), [sourceTz]);
  const targetDetails = useMemo(() => getTimeZoneDetails(targetTz), [targetTz]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/80 backdrop-blur-sm overflow-y-auto animate-in fade-in duration-200">
      <div className="relative w-full max-w-3xl bg-slate-900 border-t sm:border border-slate-700/80 rounded-t-3xl sm:rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[92vh] sm:max-h-[90vh] pb-safe">
        {/* Header */}
        <div className="px-5 sm:px-6 py-3.5 sm:py-4 border-b border-slate-800 flex items-center justify-between bg-slate-950/60 shrink-0">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
              <Globe className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base sm:text-lg font-bold text-white">Time Explorer & Converter</h2>
              <p className="text-[11px] sm:text-xs text-slate-400">
                24-hour scrubber with instant local conversion
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="min-h-[40px] min-w-[40px] flex items-center justify-center p-2 text-slate-400 hover:text-white rounded-xl active:bg-slate-800 transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <div className="p-6 space-y-6 overflow-y-auto flex-1">
          {/* Timezone Selectors */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Source Timezone */}
            <div className="p-4 rounded-xl bg-slate-950 border border-slate-800">
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400 mb-2">
                1. Source Timezone (e.g. Overseas Team)
              </label>
              <select
                value={sourceTz}
                onChange={(e) => setSourceTz(e.target.value)}
                className="w-full bg-slate-900 border border-slate-700 text-white text-sm font-semibold rounded-lg p-2.5 focus:outline-none focus:border-indigo-500"
              >
                {allTimeZones.map((tz) => (
                  <option key={`src-${tz.iana}`} value={tz.iana}>
                    {tz.displayName}
                  </option>
                ))}
              </select>
              <div className="mt-2 flex items-center justify-between text-xs text-slate-400">
                <span className="font-mono">{sourceDetails.timeZoneAbbreviation} ({sourceDetails.utcOffsetFormatted})</span>
                <span className="text-[11px] text-amber-400">{sourceDetails.dstSeasonLabel}</span>
              </div>
            </div>

            {/* Target / Local Timezone */}
            <div className="p-4 rounded-xl bg-slate-950 border border-slate-800">
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400 mb-2">
                2. Comparing With (Your Local Zone)
              </label>
              <select
                value={targetTz}
                onChange={(e) => setTargetTz(e.target.value)}
                className="w-full bg-slate-900 border border-slate-700 text-white text-sm font-semibold rounded-lg p-2.5 focus:outline-none focus:border-emerald-500"
              >
                {allTimeZones.map((tz) => (
                  <option key={`dst-${tz.iana}`} value={tz.iana}>
                    {tz.displayName}
                  </option>
                ))}
              </select>
              <div className="mt-2 flex items-center justify-between text-xs text-slate-400">
                <span className="font-mono">{targetDetails.timeZoneAbbreviation} ({targetDetails.utcOffsetFormatted})</span>
                <span className="text-[11px] text-emerald-400">{targetDetails.dstSeasonLabel}</span>
              </div>
            </div>
          </div>

          {/* Interactive 24-Hour Slider */}
          <div className="p-5 rounded-2xl bg-slate-950 border border-slate-800 space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold uppercase tracking-wider text-slate-300 flex items-center gap-1.5">
                <Clock className="w-4 h-4 text-indigo-400" />
                <span>Scrub Source Time (24 Hours)</span>
              </span>
              <span className="font-mono text-sm font-bold text-indigo-400">
                {conversion.sourceTimeFormatted} ({conversion.sourceAbbr})
              </span>
            </div>

            {/* Slider */}
            <input
              type="range"
              min="0"
              max="23.75"
              step="0.25"
              value={hourSlider}
              onChange={(e) => setHourSlider(parseFloat(e.target.value))}
              className="w-full accent-indigo-500 cursor-pointer h-2 bg-slate-800 rounded-lg appearance-none"
            />

            {/* Visual Timeline Hours markers */}
            <div className="flex justify-between text-[10px] text-slate-500 font-mono">
              <span>12 AM</span>
              <span>3 AM</span>
              <span>6 AM</span>
              <span>9 AM</span>
              <span>12 PM</span>
              <span>3 PM</span>
              <span>6 PM</span>
              <span>9 PM</span>
              <span>11:45 PM</span>
            </div>
          </div>

          {/* Large Live Comparison Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Source Display Card */}
            <div className="p-5 rounded-2xl bg-gradient-to-br from-slate-950 to-slate-900 border border-slate-800">
              <div className="text-xs text-slate-400 uppercase tracking-wider font-semibold">
                Source Time ({sourceDetails.displayName.split(' ')[0]})
              </div>
              <div className="mt-2 text-3xl sm:text-4xl font-mono font-black text-white">
                {conversion.sourceTimeFormatted}
              </div>
              <div className="mt-1 text-xs text-slate-400">
                {conversion.sourceDateStr} • {conversion.sourceAbbr}
              </div>
              <div className="mt-3 inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md bg-slate-800 text-xs text-slate-300">
                {hourInt >= 6 && hourInt < 18 ? (
                  <>
                    <Sun className="w-3.5 h-3.5 text-amber-400" /> Daytime
                  </>
                ) : (
                  <>
                    <Moon className="w-3.5 h-3.5 text-indigo-300" /> Nighttime
                  </>
                )}
              </div>
            </div>

            {/* Local Display Card */}
            <div className="p-5 rounded-2xl bg-gradient-to-br from-indigo-950/40 to-slate-950 border border-indigo-500/50 shadow-lg shadow-indigo-500/10">
              <div className="text-xs text-indigo-300 uppercase tracking-wider font-semibold flex items-center justify-between">
                <span>Equivalent Local Time</span>
                <span className="text-[11px] font-mono text-emerald-400">
                  {conversion.offsetDiffFormatted}
                </span>
              </div>
              <div className="mt-2 text-3xl sm:text-4xl font-mono font-black text-emerald-400">
                {conversion.targetTimeFormatted}
              </div>
              <div className="mt-1 text-xs text-slate-300">
                {conversion.targetDateStr} • {conversion.targetAbbr}
              </div>
              <div className="mt-3 flex items-center justify-between">
                <span className="text-xs text-slate-400">
                  {targetDetails.iana === localTimeZone ? 'Your Device Time' : targetDetails.displayName}
                </span>
                <button
                  type="button"
                  onClick={() => {
                    onSetAlarmForTime(sourceTz, time24Str);
                    onClose();
                  }}
                  className="flex items-center gap-1 px-3 py-1 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-md transition"
                >
                  <Plus className="w-3.5 h-3.5" />
                  <span>Set Alarm</span>
                </button>
              </div>
            </div>
          </div>

          {/* Seasonal Note */}
          <div className="p-4 rounded-xl bg-slate-950/60 border border-slate-800/80 flex items-start gap-3 text-xs text-slate-300">
            <Sparkles className="w-4 h-4 text-amber-400 shrink-0 mt-0.5" />
            <div>
              <strong className="text-white">Seasonal DST Intelligence: </strong>
              The calculations automatically adjust based on whether Daylight Saving is in effect in each hemisphere. When clocks change in autumn or spring, your alarms maintain their exact intended target time.
            </div>
          </div>

        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-slate-800 bg-slate-950/80 flex justify-end">
          <button
            onClick={onClose}
            className="px-5 py-2 text-sm font-semibold rounded-xl bg-slate-800 hover:bg-slate-700 text-white transition"
          >
            Close Explorer
          </button>
        </div>
      </div>
    </div>
  );
}

import React, { useState, useEffect, useMemo } from 'react';
import { Alarm, AlarmSoundType, AlarmAlertMode, TimeZoneOption } from '../types';
import { getAllAvailableTimeZones, POPULAR_TIMEZONES } from '../utils/timezoneData';
import { previewTimezoneConversion, getTimeZoneDetails, getZonedDateParts } from '../utils/timezone';
import { previewAlarmSound } from '../utils/audio';
import { triggerDeviceVibration } from '../utils/notifications';
import {
  X,
  Clock,
  Globe,
  Bell,
  Volume2,
  VolumeX,
  Play,
  RotateCcw,
  Sparkles,
  Search,
  Check,
  Smartphone,
  Calendar,
  Radio,
} from 'lucide-react';

interface AlarmModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (alarmData: Omit<Alarm, 'id' | 'createdAt'>, alarmId?: string) => void;
  editingAlarm?: Alarm | null;
  localTimeZone: string;
  use24HourDefault: boolean;
  preselectedTimeZone?: string | null;
}

const SOUND_OPTIONS: { id: AlarmSoundType; label: string; desc: string }[] = [
  { id: 'digital', label: 'Digital Watch', desc: 'Classic energetic watch beeps' },
  { id: 'chime', label: 'Crystal Chime', desc: 'Peaceful pentatonic chord bells' },
  { id: 'marimba', label: 'Radiant Marimba', desc: 'Warm melodic wooden keys' },
  { id: 'radar', label: 'Radar Sonar', desc: 'Deep pulsating sonar waves' },
  { id: 'bell', label: 'Zen Bell', desc: 'Resonant acoustic meditation bell' },
  { id: 'gentle', label: 'Gentle Swell', desc: 'Soft rising ambient chords' },
];

const PRESET_LABELS = [
  'Global Standup Sync',
  'Market Opening Bell',
  'US Pacific Morning Call',
  'Europe Project Review',
  'Tokyo Handover Sync',
  'Flight / Travel Alert',
];

const DAY_LABELS = [
  { day: 0, short: 'S', name: 'Sun' },
  { day: 1, short: 'M', name: 'Mon' },
  { day: 2, short: 'T', name: 'Tue' },
  { day: 3, short: 'W', name: 'Wed' },
  { day: 4, short: 'T', name: 'Thu' },
  { day: 5, short: 'F', name: 'Fri' },
  { day: 6, short: 'S', name: 'Sat' },
];

export function AlarmModal({
  isOpen,
  onClose,
  onSave,
  editingAlarm,
  localTimeZone,
  use24HourDefault,
  preselectedTimeZone,
}: AlarmModalProps) {
  const [title, setTitle] = useState('');
  const [sourceTimeZone, setSourceTimeZone] = useState(preselectedTimeZone || localTimeZone || 'America/Los_Angeles');
  
  // Calculate initial current time in local timezone
  const initialLocalParts = useMemo(() => getZonedDateParts(new Date(), localTimeZone || 'UTC'), [localTimeZone]);
  const initialH = initialLocalParts.hour;
  const initialM = initialLocalParts.minute;

  const [hour, setHour] = useState(initialH >= 12 ? (initialH === 12 ? 12 : initialH - 12) : (initialH === 0 ? 12 : initialH));
  const [minute, setMinute] = useState(initialM);
  const [period, setPeriod] = useState<'AM' | 'PM'>(initialH >= 12 ? 'PM' : 'AM');
  const [days, setDays] = useState<number[]>([]);
  const [alertMode, setAlertMode] = useState<AlarmAlertMode>('sound_and_vibrate');
  const [sound, setSound] = useState<AlarmSoundType>('chime');
  const [volume, setVolume] = useState(0.8);
  const [vibrate, setVibrate] = useState(true);

  // Timezone search query
  const [tzSearchQuery, setTzSearchQuery] = useState('');
  const [isTzDropdownOpen, setIsTzDropdownOpen] = useState(false);

  const allTimeZones = useMemo(() => getAllAvailableTimeZones(), []);

  // Initialize or reset form values
  useEffect(() => {
    if (!isOpen) return;

    if (editingAlarm) {
      setTitle(editingAlarm.title || '');
      setSourceTimeZone(editingAlarm.sourceTimeZone || localTimeZone || 'America/Los_Angeles');
      const [h, m] = editingAlarm.sourceTime.split(':').map(Number);
      if (!isNaN(h) && !isNaN(m)) {
        if (h >= 12) {
          setPeriod('PM');
          setHour(h === 12 ? 12 : h - 12);
        } else {
          setPeriod('AM');
          setHour(h === 0 ? 12 : h);
        }
        setMinute(m);
      }
      setDays(editingAlarm.days || []);
      
      const mode: AlarmAlertMode =
        editingAlarm.alertMode ||
        (editingAlarm.sound === 'silent' ? 'vibrate_only' : editingAlarm.vibrate ? 'sound_and_vibrate' : 'sound_only');
      setAlertMode(mode);
      setSound(editingAlarm.sound && editingAlarm.sound !== 'silent' ? editingAlarm.sound : 'chime');
      setVolume(editingAlarm.volume ?? 0.8);
      setVibrate(mode !== 'sound_only');
    } else {
      // For a new alarm, initialize with the current real-time clock in the target/local timezone
      const tzToUse = preselectedTimeZone || localTimeZone || 'America/Los_Angeles';
      const nowParts = getZonedDateParts(new Date(), tzToUse);
      const currH = nowParts.hour;
      const currM = nowParts.minute;

      setTitle('');
      setSourceTimeZone(tzToUse);
      if (currH >= 12) {
        setPeriod('PM');
        setHour(currH === 12 ? 12 : currH - 12);
      } else {
        setPeriod('AM');
        setHour(currH === 0 ? 12 : currH);
      }
      setMinute(currM);
      setDays([1, 2, 3, 4, 5]); // Default to weekdays
      setAlertMode('sound_and_vibrate');
      setSound('chime');
      setVolume(0.8);
      setVibrate(true);
    }
  }, [editingAlarm, preselectedTimeZone, localTimeZone, isOpen]);

  // Convert 12h to 24h string "HH:mm"
  const sourceTime24 = useMemo(() => {
    let h24 = hour;
    if (period === 'PM' && hour < 12) h24 = hour + 12;
    if (period === 'AM' && hour === 12) h24 = 0;
    return `${String(h24).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
  }, [hour, minute, period]);

  // Calculate live conversion preview
  const conversionPreview = useMemo(() => {
    return previewTimezoneConversion(sourceTime24, sourceTimeZone, localTimeZone);
  }, [sourceTime24, sourceTimeZone, localTimeZone]);

  // Filter timezones for search
  const filteredTimezones = useMemo(() => {
    if (!tzSearchQuery.trim()) {
      return POPULAR_TIMEZONES;
    }
    const q = tzSearchQuery.toLowerCase();
    return allTimeZones.filter(
      (tz) =>
        tz.displayName.toLowerCase().includes(q) ||
        tz.city.toLowerCase().includes(q) ||
        tz.country.toLowerCase().includes(q) ||
        tz.iana.toLowerCase().includes(q) ||
        (tz.commonAbbr && tz.commonAbbr.toLowerCase().includes(q))
    ).slice(0, 30);
  }, [tzSearchQuery, allTimeZones]);

  if (!isOpen) return null;

  const handleToggleDay = (dayIndex: number) => {
    setDays((prev) =>
      prev.includes(dayIndex) ? prev.filter((d) => d !== dayIndex) : [...prev, dayIndex].sort()
    );
  };

  const handleSetQuickDays = (type: 'once' | 'everyday' | 'weekdays' | 'weekends') => {
    if (type === 'once') setDays([]);
    if (type === 'everyday') setDays([0, 1, 2, 3, 4, 5, 6]);
    if (type === 'weekdays') setDays([1, 2, 3, 4, 5]);
    if (type === 'weekends') setDays([0, 6]);
  };

  const adjustTime = (deltaHours: number, deltaMinutes: number) => {
    let currentH24 = hour;
    if (period === 'PM' && hour < 12) currentH24 = hour + 12;
    if (period === 'AM' && hour === 12) currentH24 = 0;

    let totalMinutes = currentH24 * 60 + minute + deltaHours * 60 + deltaMinutes;
    totalMinutes = ((totalMinutes % 1440) + 1440) % 1440;

    const nextH24 = Math.floor(totalMinutes / 60);
    const nextM = totalMinutes % 60;

    if (nextH24 >= 12) {
      setPeriod('PM');
      setHour(nextH24 === 12 ? 12 : nextH24 - 12);
    } else {
      setPeriod('AM');
      setHour(nextH24 === 0 ? 12 : nextH24);
    }
    setMinute(nextM);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(
      {
        title: title.trim() || 'Global Zone Alarm',
        sourceTimeZone,
        sourceTime: sourceTime24,
        days,
        enabled: true,
        alertMode,
        sound: alertMode === 'vibrate_only' ? 'silent' : sound,
        volume: alertMode === 'vibrate_only' ? 0 : volume,
        vibrate: alertMode !== 'sound_only',
        snoozeUntil: null,
      },
      editingAlarm?.id
    );
    onClose();
  };

  const selectedTzObj = allTimeZones.find((t) => t.iana === sourceTimeZone);

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/80 backdrop-blur-sm overflow-y-auto animate-in fade-in duration-200">
      <div
        id="alarm-modal-container"
        className="relative w-full max-w-2xl bg-slate-900 border-t sm:border border-slate-700/80 rounded-t-3xl sm:rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[92vh] sm:max-h-[90vh] pb-safe"
      >
        {/* Header */}
        <div className="px-5 sm:px-6 py-3.5 sm:py-4 border-b border-slate-800 flex items-center justify-between bg-slate-950/60 shrink-0">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
              <Clock className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base sm:text-lg font-bold text-white">
                {editingAlarm ? 'Edit Timezone Alarm' : 'Set Timezone Alarm'}
              </h2>
              <p className="text-[11px] sm:text-xs text-slate-400">
                Rings accurately in your local time with seasonal DST
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

        {/* Scrollable Form Content */}
        <form onSubmit={handleSubmit} className="p-4 sm:p-6 space-y-5 sm:space-y-6 overflow-y-auto flex-1 overscroll-contain">
          
          {/* 1. Target Timezone Selector */}
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-slate-300 mb-2 flex items-center justify-between">
              <span className="flex items-center gap-1.5">
                <Globe className="w-4 h-4 text-indigo-400" />
                <span>Select Target Time Zone</span>
              </span>
              <span className="text-[11px] text-slate-400 font-normal">
                {selectedTzObj?.commonAbbr || conversionPreview.sourceAbbr} ({conversionPreview.sourceDstSeason})
              </span>
            </label>

            {/* Timezone Search & Dropdown Trigger */}
            <div className="relative">
              <div
                onClick={() => setIsTzDropdownOpen(!isTzDropdownOpen)}
                className="w-full px-4 py-3 bg-slate-950 border border-slate-700 rounded-xl cursor-pointer hover:border-indigo-500 flex items-center justify-between text-left transition"
              >
                <div>
                  <div className="text-sm font-semibold text-white">
                    {selectedTzObj?.displayName || sourceTimeZone}
                  </div>
                  <div className="text-xs text-slate-400 font-mono mt-0.5">
                    {sourceTimeZone} • Offset: {conversionPreview.offsetDiffFormatted} from your local time
                  </div>
                </div>
                <div className="flex items-center gap-1 text-xs text-indigo-400 font-medium">
                  <span>Change</span>
                </div>
              </div>

              {/* Dropdown Menu */}
              {isTzDropdownOpen && (
                <div className="absolute top-full left-0 right-0 mt-2 p-3 bg-slate-950 border border-slate-700 rounded-xl shadow-2xl z-50 max-h-72 flex flex-col">
                  {/* Search Input */}
                  <div className="relative mb-2">
                    <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
                    <input
                      type="text"
                      placeholder="Search city, country, PST, EST, London, Tokyo..."
                      value={tzSearchQuery}
                      onChange={(e) => setTzSearchQuery(e.target.value)}
                      autoFocus
                      className="w-full pl-9 pr-3 py-2 text-xs bg-slate-900 border border-slate-700 rounded-lg text-white placeholder:text-slate-500 focus:outline-none focus:border-indigo-500"
                    />
                  </div>

                  {/* List of Timezones */}
                  <div className="overflow-y-auto space-y-1 flex-1 pr-1">
                    {filteredTimezones.map((tz) => {
                      const isSelected = tz.iana === sourceTimeZone;
                      return (
                        <div
                          key={tz.iana}
                          onClick={() => {
                            setSourceTimeZone(tz.iana);
                            setIsTzDropdownOpen(false);
                            setTzSearchQuery('');
                          }}
                          className={`p-2.5 rounded-lg text-xs cursor-pointer flex items-center justify-between transition ${
                            isSelected
                              ? 'bg-indigo-600/30 text-indigo-200 border border-indigo-500/40'
                              : 'hover:bg-slate-900 text-slate-300'
                          }`}
                        >
                          <div>
                            <div className="font-semibold text-white">
                              {tz.displayName}
                            </div>
                            <div className="text-[11px] text-slate-400 font-mono">
                              {tz.city} • {tz.iana}
                            </div>
                          </div>

                          {isSelected && <Check className="w-4 h-4 text-indigo-400 shrink-0" />}
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>

            {/* Popular Shortcut Pills */}
            <div className="flex flex-wrap gap-1.5 mt-2">
              {[
                { iana: 'America/Los_Angeles', label: 'US Pacific (PST/PDT)' },
                { iana: 'America/New_York', label: 'US Eastern (EST/EDT)' },
                { iana: 'Europe/London', label: 'London (GMT/BST)' },
                { iana: 'Asia/Kolkata', label: 'India (IST)' },
                { iana: 'Asia/Tokyo', label: 'Tokyo (JST)' },
                { iana: 'Australia/Sydney', label: 'Sydney (AEST)' },
              ].map((p) => (
                <button
                  key={p.iana}
                  type="button"
                  onClick={() => setSourceTimeZone(p.iana)}
                  className={`text-[11px] px-2.5 py-1 rounded-md transition ${
                    sourceTimeZone === p.iana
                      ? 'bg-indigo-600 text-white font-semibold shadow-sm'
                      : 'bg-slate-800/80 text-slate-400 hover:text-slate-200 hover:bg-slate-800'
                  }`}
                >
                  {p.label}
                </button>
              ))}
            </div>
          </div>

          {/* 2. Time Input */}
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-slate-300 mb-2 flex items-center gap-1.5">
              <Clock className="w-4 h-4 text-indigo-400" />
              <span>Alarm Time in Target Time Zone</span>
            </label>

            <div className="flex items-center justify-center gap-3 p-4 bg-slate-950 border border-slate-700/80 rounded-2xl">
              {/* Hour selector */}
              <div className="flex flex-col items-center">
                <span className="text-[10px] text-slate-500 uppercase mb-1 font-mono">Hour</span>
                <select
                  value={hour}
                  onChange={(e) => setHour(Number(e.target.value))}
                  className="bg-slate-900 border border-slate-700 text-white font-mono text-3xl font-bold rounded-xl px-3 py-2 focus:outline-none focus:border-indigo-500"
                >
                  {Array.from({ length: 12 }, (_, i) => i + 1).map((h) => (
                    <option key={h} value={h}>
                      {String(h).padStart(2, '0')}
                    </option>
                  ))}
                </select>
              </div>

              <span className="text-3xl font-bold font-mono text-slate-600 mt-4">:</span>

              {/* Minute selector */}
              <div className="flex flex-col items-center">
                <span className="text-[10px] text-slate-500 uppercase mb-1 font-mono">Minute</span>
                <select
                  value={minute}
                  onChange={(e) => setMinute(Number(e.target.value))}
                  className="bg-slate-900 border border-slate-700 text-white font-mono text-3xl font-bold rounded-xl px-3 py-2 focus:outline-none focus:border-indigo-500"
                >
                  {Array.from({ length: 60 }, (_, i) => i).map((m) => (
                    <option key={m} value={m}>
                      {String(m).padStart(2, '0')}
                    </option>
                  ))}
                </select>
              </div>

              {/* AM / PM toggle */}
              <div className="flex flex-col gap-1.5 mt-4 ml-2">
                <button
                  type="button"
                  onClick={() => setPeriod('AM')}
                  className={`px-3 py-1.5 rounded-lg text-xs font-bold transition ${
                    period === 'AM'
                      ? 'bg-indigo-600 text-white shadow-sm'
                      : 'bg-slate-900 text-slate-400 hover:text-white'
                  }`}
                >
                  AM
                </button>
                <button
                  type="button"
                  onClick={() => setPeriod('PM')}
                  className={`px-3 py-1.5 rounded-lg text-xs font-bold transition ${
                    period === 'PM'
                      ? 'bg-indigo-600 text-white shadow-sm'
                      : 'bg-slate-900 text-slate-400 hover:text-white'
                  }`}
                >
                  PM
                </button>
              </div>
            </div>

            {/* Quick time buttons */}
            <div className="flex flex-wrap gap-1.5 mt-2 justify-center">
              <button
                type="button"
                onClick={() => {
                  const nowParts = getZonedDateParts(new Date(), sourceTimeZone);
                  const currH = nowParts.hour;
                  const currM = nowParts.minute;
                  if (currH >= 12) {
                    setPeriod('PM');
                    setHour(currH === 12 ? 12 : currH - 12);
                  } else {
                    setPeriod('AM');
                    setHour(currH === 0 ? 12 : currH);
                  }
                  setMinute(currM);
                }}
                className="text-[11px] font-semibold px-2.5 py-1 rounded-lg bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 hover:bg-indigo-500/30 transition flex items-center gap-1"
              >
                <Clock className="w-3 h-3 text-indigo-400" />
                <span>Now ({getZonedDateParts(new Date(), sourceTimeZone).hour.toString().padStart(2, '0')}:{getZonedDateParts(new Date(), sourceTimeZone).minute.toString().padStart(2, '0')})</span>
              </button>

              <button
                type="button"
                onClick={() => adjustTime(-1, 0)}
                className="text-[11px] font-semibold px-2 py-1 rounded-lg bg-slate-800 text-slate-300 hover:bg-slate-700 transition"
              >
                -1h
              </button>

              <button
                type="button"
                onClick={() => adjustTime(1, 0)}
                className="text-[11px] font-semibold px-2 py-1 rounded-lg bg-slate-800 text-slate-300 hover:bg-slate-700 transition"
              >
                +1h
              </button>

              <button
                type="button"
                onClick={() => adjustTime(0, -15)}
                className="text-[11px] font-semibold px-2 py-1 rounded-lg bg-slate-800 text-slate-300 hover:bg-slate-700 transition"
              >
                -15m
              </button>

              <button
                type="button"
                onClick={() => adjustTime(0, 15)}
                className="text-[11px] font-semibold px-2 py-1 rounded-lg bg-slate-800 text-slate-300 hover:bg-slate-700 transition"
              >
                +15m
              </button>

              <button
                type="button"
                onClick={() => adjustTime(0, -5)}
                className="text-[11px] font-semibold px-2 py-1 rounded-lg bg-slate-800 text-slate-300 hover:bg-slate-700 transition"
              >
                -5m
              </button>

              <button
                type="button"
                onClick={() => adjustTime(0, 5)}
                className="text-[11px] font-semibold px-2 py-1 rounded-lg bg-slate-800 text-slate-300 hover:bg-slate-700 transition"
              >
                +5m
              </button>

              {[
                { h: 9, m: 0, p: 'AM', label: '9:00 AM' },
                { h: 12, m: 0, p: 'PM', label: '12:00 PM' },
                { h: 5, m: 0, p: 'PM', label: '5:00 PM' },
                { h: 8, m: 0, p: 'PM', label: '8:00 PM' },
              ].map((preset) => (
                <button
                  key={preset.label}
                  type="button"
                  onClick={() => {
                    setHour(preset.h);
                    setMinute(preset.m);
                    setPeriod(preset.p as 'AM' | 'PM');
                  }}
                  className="text-[11px] px-2 py-1 rounded-lg bg-slate-800/60 hover:bg-slate-800 text-slate-400 hover:text-slate-200 transition"
                >
                  {preset.label}
                </button>
              ))}
            </div>
          </div>

          {/* 3. Real-Time Conversion Box (Crucial Requirement Highlight) */}
          <div className="p-4 rounded-2xl bg-gradient-to-br from-indigo-950/60 to-slate-950 border border-indigo-500/40 shadow-inner">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold uppercase tracking-wider text-indigo-300 flex items-center gap-1.5">
                <Sparkles className="w-3.5 h-3.5 text-indigo-400" />
                <span>Automatic Local Time Conversion</span>
              </span>
              <span className="text-[11px] font-medium text-emerald-400">
                100% Seasonal DST Accurate
              </span>
            </div>

            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-3 rounded-xl bg-slate-900/80 border border-slate-800">
              {/* Target Zone */}
              <div>
                <div className="text-[11px] text-slate-400">
                  Target Zone ({conversionPreview.sourceAbbr})
                </div>
                <div className="font-mono text-xl font-bold text-white">
                  {conversionPreview.sourceTimeFormatted}
                </div>
                <div className="text-[11px] text-slate-400 mt-0.5">
                  {conversionPreview.sourceDateStr}
                </div>
              </div>

              {/* Arrow */}
              <div className="hidden sm:flex items-center justify-center text-slate-500 font-bold text-sm">
                ➔
              </div>

              {/* Local Zone */}
              <div>
                <div className="text-[11px] font-semibold text-indigo-300 flex items-center gap-1">
                  <Bell className="w-3 h-3 text-indigo-400" />
                  <span>Rings in Your Local Time ({conversionPreview.targetAbbr})</span>
                </div>
                <div className="font-mono text-2xl font-black text-emerald-400">
                  {conversionPreview.targetTimeFormatted}
                </div>
                <div className="text-[11px] text-slate-300 mt-0.5">
                  {conversionPreview.targetDateStr} ({conversionPreview.offsetDiffFormatted})
                </div>
              </div>
            </div>

            <div className="mt-2.5 text-xs text-slate-400 flex items-start gap-2">
              <span className="text-amber-400 font-bold">ℹ️</span>
              <p>
                When you set <strong className="text-slate-200">{conversionPreview.sourceTimeFormatted} {conversionPreview.sourceAbbr}</strong>, the alarm will ring on your device at <strong className="text-emerald-300">{conversionPreview.targetTimeFormatted} {conversionPreview.targetAbbr}</strong>. If daylight saving changes in either zone, the engine automatically adjusts without any manual changes.
              </p>
            </div>
          </div>

          {/* 4. Repeat Days */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="text-xs font-semibold uppercase tracking-wider text-slate-300 flex items-center gap-1.5">
                <Calendar className="w-4 h-4 text-indigo-400" />
                <span>Repeat on Days</span>
              </label>

              {/* Quick Repeat Shortcuts */}
              <div className="flex items-center gap-1 text-[11px]">
                <button
                  type="button"
                  onClick={() => handleSetQuickDays('once')}
                  className="px-2 py-0.5 rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white"
                >
                  Once
                </button>
                <button
                  type="button"
                  onClick={() => handleSetQuickDays('weekdays')}
                  className="px-2 py-0.5 rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white"
                >
                  Weekdays
                </button>
                <button
                  type="button"
                  onClick={() => handleSetQuickDays('everyday')}
                  className="px-2 py-0.5 rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white"
                >
                  Everyday
                </button>
              </div>
            </div>

            <div className="grid grid-cols-7 gap-2">
              {DAY_LABELS.map((d) => {
                const isSelected = days.includes(d.day);
                return (
                  <button
                    key={d.day}
                    type="button"
                    onClick={() => handleToggleDay(d.day)}
                    className={`py-2.5 rounded-xl text-xs font-bold transition flex flex-col items-center gap-0.5 ${
                      isSelected
                        ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/30'
                        : 'bg-slate-950 border border-slate-800 text-slate-400 hover:text-slate-200 hover:border-slate-700'
                    }`}
                  >
                    <span>{d.name}</span>
                  </button>
                );
              })}
            </div>
            <div className="text-[11px] text-slate-500 mt-1.5 text-center">
              {days.length === 0
                ? 'One-time alarm (will ring once at next occurrence)'
                : days.length === 7
                ? 'Repeats everyday'
                : `Repeats on ${days.map((d) => DAY_LABELS.find((l) => l.day === d)?.name).join(', ')}`}
            </div>
          </div>

          {/* 5. Alert Mode: Sound & Vibration Settings */}
          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-300 mb-2 flex items-center gap-1.5">
                <Radio className="w-4 h-4 text-indigo-400" />
                <span>Alert Mode (Sound / Vibration)</span>
              </label>

              {/* 3 Alert Mode Choice Cards */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
                
                {/* 1. Sound & Vibration */}
                <button
                  type="button"
                  onClick={() => {
                    setAlertMode('sound_and_vibrate');
                    setVibrate(true);
                  }}
                  className={`p-3 rounded-2xl border text-left transition flex flex-col justify-between gap-2 ${
                    alertMode === 'sound_and_vibrate'
                      ? 'bg-indigo-600/25 border-indigo-500 shadow-md shadow-indigo-600/20'
                      : 'bg-slate-950 border-slate-800 text-slate-400 hover:border-slate-700'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1.5 text-indigo-300">
                      <Volume2 className="w-4 h-4" />
                      <span className="text-xs font-bold">+</span>
                      <Smartphone className="w-4 h-4" />
                    </div>
                    {alertMode === 'sound_and_vibrate' && (
                      <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
                    )}
                  </div>
                  <div>
                    <div className="text-xs font-bold text-white">Sound & Vibrate</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">
                      Audio loop & continuous vibration until dismissed
                    </div>
                  </div>
                </button>

                {/* 2. Vibration Only (Silent) */}
                <button
                  type="button"
                  onClick={() => {
                    setAlertMode('vibrate_only');
                    setVibrate(true);
                    triggerDeviceVibration();
                  }}
                  className={`p-3 rounded-2xl border text-left transition flex flex-col justify-between gap-2 ${
                    alertMode === 'vibrate_only'
                      ? 'bg-indigo-600/25 border-indigo-500 shadow-md shadow-indigo-600/20'
                      : 'bg-slate-950 border-slate-800 text-slate-400 hover:border-slate-700'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1.5 text-indigo-300">
                      <Smartphone className="w-4 h-4 animate-bounce" />
                      <VolumeX className="w-3.5 h-3.5 text-slate-400" />
                    </div>
                    {alertMode === 'vibrate_only' && (
                      <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
                    )}
                  </div>
                  <div>
                    <div className="text-xs font-bold text-white">Vibration Only</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">
                      Silent — vibrates continuously until dismissed
                    </div>
                  </div>
                </button>

                {/* 3. Sound Only */}
                <button
                  type="button"
                  onClick={() => {
                    setAlertMode('sound_only');
                    setVibrate(false);
                  }}
                  className={`p-3 rounded-2xl border text-left transition flex flex-col justify-between gap-2 ${
                    alertMode === 'sound_only'
                      ? 'bg-indigo-600/25 border-indigo-500 shadow-md shadow-indigo-600/20'
                      : 'bg-slate-950 border-slate-800 text-slate-400 hover:border-slate-700'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1.5 text-indigo-300">
                      <Volume2 className="w-4 h-4" />
                    </div>
                    {alertMode === 'sound_only' && (
                      <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
                    )}
                  </div>
                  <div>
                    <div className="text-xs font-bold text-white">Sound Only</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">
                      Rings audio melody only (no vibration)
                    </div>
                  </div>
                </button>

              </div>
            </div>

            {/* If Vibration is active, show vibration testing & reassurance banner */}
            {alertMode !== 'sound_only' && (
              <div className="p-3 rounded-xl bg-slate-950/80 border border-slate-800 flex items-center justify-between gap-3">
                <div className="flex items-center gap-2">
                  <div className="p-1.5 rounded-lg bg-indigo-500/10 text-indigo-400">
                    <Smartphone className="w-4 h-4" />
                  </div>
                  <div className="text-left">
                    <div className="text-xs font-semibold text-slate-200">
                      Continuous Loop Vibration
                    </div>
                    <div className="text-[11px] text-slate-400">
                      Repeats pulse pattern until you press Dismiss or Snooze
                    </div>
                  </div>
                </div>

                <button
                  type="button"
                  onClick={() => triggerDeviceVibration()}
                  title="Test device vibration"
                  className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 active:bg-slate-600 text-slate-200 text-xs font-bold transition flex items-center gap-1.5 border border-slate-700 shrink-0"
                >
                  <Smartphone className="w-3.5 h-3.5 text-indigo-400" />
                  <span>Test Vibration</span>
                </button>
              </div>
            )}

            {/* Sound Melody Selection & Volume (Shown when Sound is enabled) */}
            {alertMode !== 'vibrate_only' ? (
              <div className="space-y-3 pt-1">
                <div className="text-xs font-semibold uppercase tracking-wider text-slate-300 flex items-center gap-1.5">
                  <Volume2 className="w-3.5 h-3.5 text-indigo-400" />
                  <span>Select Alarm Melody</span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {SOUND_OPTIONS.map((opt) => {
                    const isSelected = sound === opt.id;
                    return (
                      <div
                        key={opt.id}
                        onClick={() => setSound(opt.id)}
                        className={`p-3 rounded-xl border cursor-pointer flex items-center justify-between transition ${
                          isSelected
                            ? 'bg-indigo-600/20 border-indigo-500 text-white'
                            : 'bg-slate-950 border-slate-800 text-slate-300 hover:border-slate-700'
                        }`}
                      >
                        <div>
                          <div className="text-xs font-bold">{opt.label}</div>
                          <div className="text-[11px] text-slate-400">{opt.desc}</div>
                        </div>

                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            setSound(opt.id);
                            previewAlarmSound(opt.id, volume);
                          }}
                          title="Preview this sound"
                          className="p-1.5 rounded-lg bg-slate-800 hover:bg-indigo-600 text-slate-300 hover:text-white transition"
                        >
                          <Play className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    );
                  })}
                </div>

                {/* Volume slider */}
                <div className="flex items-center gap-4 pt-1">
                  <Volume2 className="w-4 h-4 text-slate-400 shrink-0" />
                  <input
                    type="range"
                    min="0.1"
                    max="1.0"
                    step="0.05"
                    value={volume}
                    onChange={(e) => setVolume(parseFloat(e.target.value))}
                    className="w-full accent-indigo-500"
                  />
                  <span className="text-xs font-mono text-slate-400 w-12 text-right">
                    {Math.round(volume * 100)}%
                  </span>
                </div>
              </div>
            ) : (
              <div className="p-3 rounded-xl bg-indigo-950/30 border border-indigo-500/20 text-xs text-indigo-300 flex items-center gap-2">
                <VolumeX className="w-4 h-4 text-indigo-400 shrink-0" />
                <span>Audio is muted for this alarm. Your device will alert you solely through repeating vibration until dismissed.</span>
              </div>
            )}
          </div>

          {/* 6. Alarm Title / Label */}
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-slate-300 mb-1.5">
              Alarm Label / Notes (Optional)
            </label>
            <input
              type="text"
              placeholder="e.g. US Pacific Standup, London Market Sync"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-4 py-2.5 text-sm bg-slate-950 border border-slate-700 rounded-xl text-white placeholder:text-slate-500 focus:outline-none focus:border-indigo-500"
            />
            {/* Quick label suggestions */}
            <div className="flex flex-wrap gap-1.5 mt-2">
              {PRESET_LABELS.map((p) => (
                <button
                  key={p}
                  type="button"
                  onClick={() => setTitle(p)}
                  className="text-[11px] px-2 py-0.5 rounded bg-slate-800/60 hover:bg-slate-800 text-slate-400 hover:text-slate-200"
                >
                  + {p}
                </button>
              ))}
            </div>
          </div>

        </form>

        {/* Footer Actions */}
        <div className="px-5 sm:px-6 py-3.5 sm:py-4 border-t border-slate-800 bg-slate-950/90 flex flex-row items-center justify-between gap-3 shrink-0">
          <button
            type="button"
            onClick={onClose}
            className="min-h-[44px] px-4 py-2.5 text-sm font-semibold text-slate-300 active:text-white rounded-xl active:bg-slate-800 transition"
          >
            Cancel
          </button>

          <button
            type="button"
            onClick={handleSubmit}
            className="min-h-[44px] flex-1 sm:flex-none px-6 py-2.5 text-sm font-bold text-white bg-gradient-to-r from-indigo-500 to-indigo-600 active:from-indigo-600 active:to-indigo-700 rounded-xl shadow-lg shadow-indigo-500/25 active:scale-98 transition flex items-center justify-center text-center"
          >
            {editingAlarm ? 'Save Changes' : 'Set Alarm'}
          </button>
        </div>

      </div>
    </div>
  );
}

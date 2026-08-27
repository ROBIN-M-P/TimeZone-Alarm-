import { useState, useEffect, useRef, useMemo } from 'react';
import { Alarm, AlarmSoundType } from './types';
import { Header } from './components/Header';
import { WorldClockBar } from './components/WorldClockBar';
import { AlarmCard } from './components/AlarmCard';
import { AlarmModal } from './components/AlarmModal';
import { TimezoneConverter } from './components/TimezoneConverter';
import { ActiveAlarmOverlay } from './components/ActiveAlarmOverlay';
import { SeasonInfoModal } from './components/SeasonInfoModal';
import {
  getUserLocalTimeZone,
  calculateNextAlarm,
  checkAlarmTrigger,
  getTimeZoneDetails,
} from './utils/timezone';
import { playAlarmSoundLoop, SoundController } from './utils/audio';
import { sendAlarmNotification, triggerDeviceVibration, startVibrationLoop, stopVibrationLoop, VibrationController } from './utils/notifications';
import {
  Plus,
  Bell,
  Clock,
  Globe,
  SlidersHorizontal,
  Search,
  Sparkles,
  Info,
  CalendarCheck,
  CheckCircle,
} from 'lucide-react';

const STORAGE_KEY = 'tz_alarms_data_v1';
const TIME_FORMAT_KEY = 'tz_time_format_24h';

// Default initial alarms showcasing the user's specific request
const INITIAL_ALARMS: Alarm[] = [
  {
    id: 'alarm-sample-pst',
    title: 'US Pacific Sync (e.g. 6:30 AM PST/PDT)',
    sourceTimeZone: 'America/Los_Angeles',
    sourceTime: '06:30',
    days: [1, 2, 3, 4, 5], // Mon-Fri
    enabled: true,
    sound: 'chime',
    volume: 0.85,
    vibrate: true,
    createdAt: Date.now() - 3600000,
    snoozeUntil: null,
  },
  {
    id: 'alarm-sample-london',
    title: 'London Market Opening',
    sourceTimeZone: 'Europe/London',
    sourceTime: '08:00',
    days: [1, 2, 3, 4, 5],
    enabled: true,
    sound: 'marimba',
    volume: 0.8,
    vibrate: true,
    createdAt: Date.now() - 7200000,
    snoozeUntil: null,
  },
  {
    id: 'alarm-sample-tokyo',
    title: 'Tokyo Morning Standup',
    sourceTimeZone: 'Asia/Tokyo',
    sourceTime: '09:30',
    days: [1, 2, 3, 4, 5],
    enabled: false,
    sound: 'digital',
    volume: 0.75,
    vibrate: true,
    createdAt: Date.now() - 10800000,
    snoozeUntil: null,
  },
];

export default function App() {
  const [localTimeZone, setLocalTimeZone] = useState<string>(() => getUserLocalTimeZone());
  const [alarms, setAlarms] = useState<Alarm[]>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        return JSON.parse(saved);
      }
    } catch {
      // ignore
    }
    return INITIAL_ALARMS;
  });

  const [use24Hour, setUse24Hour] = useState<boolean>(() => {
    try {
      return localStorage.getItem(TIME_FORMAT_KEY) === 'true';
    } catch {
      return false;
    }
  });

  // Modals state
  const [isAlarmModalOpen, setIsAlarmModalOpen] = useState(false);
  const [editingAlarm, setEditingAlarm] = useState<Alarm | null>(null);
  const [preselectedZone, setPreselectedZone] = useState<string | null>(null);
  const [isConverterOpen, setIsConverterOpen] = useState(false);
  const [isDstGuideOpen, setIsDstGuideOpen] = useState(false);

  // Active Ringing Alarm state
  const [activeRingingAlarm, setActiveRingingAlarm] = useState<Alarm | null>(null);
  const soundControllerRef = useRef<SoundController | null>(null);
  const vibrationControllerRef = useRef<VibrationController | null>(null);

  // Filter & Search
  const [searchQuery, setSearchQuery] = useState('');
  const [filterTab, setFilterTab] = useState<'all' | 'active' | 'inactive'>('all');

  // Persist alarms
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(alarms));
    } catch {
      // ignore
    }
  }, [alarms]);

  // Persist 24h toggle
  useEffect(() => {
    try {
      localStorage.setItem(TIME_FORMAT_KEY, String(use24Hour));
    } catch {
      // ignore
    }
  }, [use24Hour]);

  // Real-time alarm trigger engine (checks every 500ms)
  useEffect(() => {
    const checkInterval = setInterval(() => {
      const now = new Date();

      // Check each enabled alarm
      alarms.forEach((alarm) => {
        if (!alarm.enabled) return;
        if (activeRingingAlarm?.id === alarm.id) return; // already ringing

        const { shouldTrigger, triggerEpoch } = checkAlarmTrigger(alarm, now);
        if (shouldTrigger) {
          // Mark as triggered to avoid duplicate firing in the same minute
          setAlarms((prev) =>
            prev.map((a) =>
              a.id === alarm.id
                ? {
                    ...a,
                    lastTriggeredEpoch: triggerEpoch,
                    lastTriggeredDate: new Date(triggerEpoch).toISOString(),
                  }
                : a
            )
          );

          // Trigger the alarm modal, sound loop, vibration, and push notification!
          triggerAlarm(alarm);
        }
      });
    }, 500);

    return () => clearInterval(checkInterval);
  }, [alarms, activeRingingAlarm]);

  const triggerAlarm = (alarm: Alarm) => {
    // Stop any previous sound and vibration
    if (soundControllerRef.current) {
      soundControllerRef.current.stop();
      soundControllerRef.current = null;
    }
    if (vibrationControllerRef.current) {
      vibrationControllerRef.current.stop();
      vibrationControllerRef.current = null;
    } else {
      stopVibrationLoop();
    }

    // Determine audio and vibration behavior from alertMode / settings
    const shouldPlaySound = alarm.alertMode ? alarm.alertMode !== 'vibrate_only' : alarm.sound !== 'silent';
    const shouldVibrate = alarm.alertMode ? alarm.alertMode !== 'sound_only' : (alarm.vibrate ?? true);

    // Play loop audio if sound enabled
    if (shouldPlaySound && alarm.sound !== 'silent') {
      soundControllerRef.current = playAlarmSoundLoop(alarm.sound, alarm.volume);
    }

    // Start continuous repeating vibration loop until dismissed
    if (shouldVibrate) {
      vibrationControllerRef.current = startVibrationLoop();
    }

    // Browser Push Notification
    sendAlarmNotification(
      alarm.title || 'Timezone Alarm',
      `Alarm for ${alarm.sourceTime} in ${alarm.sourceTimeZone} is ringing in your local time!`
    );

    // Set active overlay
    setActiveRingingAlarm(alarm);
  };

  const handleDismissAlarm = (alarmId: string) => {
    // Stop sound loop
    if (soundControllerRef.current) {
      soundControllerRef.current.stop();
      soundControllerRef.current = null;
    }

    // Stop continuous vibration loop
    if (vibrationControllerRef.current) {
      vibrationControllerRef.current.stop();
      vibrationControllerRef.current = null;
    }
    stopVibrationLoop();

    setAlarms((prev) =>
      prev.map((a) => {
        if (a.id === alarmId) {
          const isOneTime = !a.days || a.days.length === 0;
          return {
            ...a,
            enabled: isOneTime ? false : a.enabled, // disable if one-time
            snoozeUntil: null,
            lastTriggeredDate: new Date().toISOString(),
          };
        }
        return a;
      })
    );

    setActiveRingingAlarm(null);
  };

  const handleSnoozeAlarm = (alarmId: string, minutes: number) => {
    // Stop sound loop
    if (soundControllerRef.current) {
      soundControllerRef.current.stop();
      soundControllerRef.current = null;
    }

    // Stop continuous vibration loop
    if (vibrationControllerRef.current) {
      vibrationControllerRef.current.stop();
      vibrationControllerRef.current = null;
    }
    stopVibrationLoop();

    const snoozeUntil = Date.now() + minutes * 60 * 1000;
    setAlarms((prev) =>
      prev.map((a) => (a.id === alarmId ? { ...a, snoozeUntil } : a))
    );

    setActiveRingingAlarm(null);
  };

  const handleToggleEnabled = (id: string, enabled: boolean) => {
    setAlarms((prev) =>
      prev.map((a) => (a.id === id ? { ...a, enabled, snoozeUntil: null, lastTriggeredEpoch: null } : a))
    );
  };

  const handleDeleteAlarm = (id: string) => {
    setAlarms((prev) => prev.filter((a) => a.id !== id));
  };

  const handleSaveAlarm = (
    alarmData: Omit<Alarm, 'id' | 'createdAt'>,
    alarmId?: string
  ) => {
    if (alarmId) {
      setAlarms((prev) =>
        prev.map((a) => (a.id === alarmId ? { ...a, ...alarmData, snoozeUntil: null, lastTriggeredEpoch: null } : a))
      );
    } else {
      const newAlarm: Alarm = {
        ...alarmData,
        id: `alarm-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
        createdAt: Date.now(),
        lastTriggeredEpoch: null,
      };
      setAlarms((prev) => [newAlarm, ...prev]);
    }
  };

  const handleOpenNewAlarmWithZone = (iana: string) => {
    setPreselectedZone(iana);
    setEditingAlarm(null);
    setIsAlarmModalOpen(true);
  };

  const handleSetAlarmFromConverter = (sourceTz: string, time24: string) => {
    const newAlarm: Alarm = {
      id: `alarm-${Date.now()}`,
      title: `Alarm (${sourceTz.split('/')[1]?.replace(/_/g, ' ') || sourceTz})`,
      sourceTimeZone: sourceTz,
      sourceTime: time24,
      days: [1, 2, 3, 4, 5],
      enabled: true,
      sound: 'chime',
      volume: 0.8,
      vibrate: true,
      createdAt: Date.now(),
      snoozeUntil: null,
    };
    setAlarms((prev) => [newAlarm, ...prev]);
  };

  // Filtered alarms
  const filteredAlarms = useMemo(() => {
    return alarms.filter((a) => {
      if (filterTab === 'active' && !a.enabled) return false;
      if (filterTab === 'inactive' && a.enabled) return false;

      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchesTitle = a.title.toLowerCase().includes(q);
        const matchesZone = a.sourceTimeZone.toLowerCase().includes(q);
        return matchesTitle || matchesZone;
      }
      return true;
    });
  }, [alarms, filterTab, searchQuery]);

  const activeCount = alarms.filter((a) => a.enabled).length;

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans selection:bg-indigo-500 selection:text-white">
      
      {/* Top Header */}
      <Header
        localTimeZone={localTimeZone}
        onOpenNewAlarm={() => {
          setEditingAlarm(null);
          setPreselectedZone(null);
          setIsAlarmModalOpen(true);
        }}
        onOpenConverter={() => setIsConverterOpen(true)}
        onOpenDstGuide={() => setIsDstGuideOpen(true)}
        activeAlarmsCount={activeCount}
        totalAlarmsCount={alarms.length}
        use24Hour={use24Hour}
        onToggle24Hour={() => setUse24Hour(!use24Hour)}
      />

      {/* Main Container */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-6">
        
        {/* World Clocks Bar */}
        <WorldClockBar
          localTimeZone={localTimeZone}
          onSelectZoneForAlarm={handleOpenNewAlarmWithZone}
          use24Hour={use24Hour}
        />

        {/* Core Value Banner & Local Timezone Configuration */}
        <div className="my-6 p-4 sm:p-5 rounded-2xl bg-gradient-to-r from-indigo-950/70 via-slate-900 to-slate-900 border border-indigo-500/30 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-start gap-3.5">
            <div className="p-2.5 rounded-xl bg-indigo-500/20 text-indigo-400 border border-indigo-500/30 shrink-0">
              <Sparkles className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-sm sm:text-base font-bold text-white flex items-center gap-2">
                <span>Set Overseas Time ➔ Trigger in Your Local Time</span>
              </h2>
              <p className="text-xs text-slate-300 mt-1 max-w-2xl leading-relaxed">
                Set an alarm for <strong>6:30 AM US Pacific (PST/PDT)</strong>, and it will beat at the exact corresponding local time at your current location (e.g. <strong>7:00 PM IST</strong>). It adjusts automatically to seasonal daylight saving changes across all 400+ IANA world zones.
              </p>
            </div>
          </div>

          {/* Local Time Zone Selector */}
          <div className="flex items-center gap-2 shrink-0 bg-slate-950/80 p-2 rounded-xl border border-slate-800">
            <span className="text-xs text-slate-400 font-medium pl-1">Reference:</span>
            <select
              id="select-local-timezone"
              value={localTimeZone}
              onChange={(e) => setLocalTimeZone(e.target.value)}
              className="bg-slate-900 border border-slate-700 text-xs font-semibold text-emerald-400 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-indigo-500"
            >
              <option value="Asia/Kolkata">🇮🇳 India (IST)</option>
              <option value="America/Los_Angeles">🇺🇸 US Pacific (PST/PDT)</option>
              <option value="America/New_York">🇺🇸 US Eastern (EST/EDT)</option>
              <option value="Europe/London">🇬🇧 London (GMT/BST)</option>
              <option value="Europe/Paris">🇫🇷 Paris (CET/CEST)</option>
              <option value="Asia/Tokyo">🇯🇵 Tokyo (JST)</option>
              <option value="Asia/Dubai">🇦🇪 Dubai (GST)</option>
              <option value="Asia/Singapore">🇸🇬 Singapore (SGT)</option>
              <option value="Australia/Sydney">🇦🇺 Sydney (AEST/AEDT)</option>
              <option value="UTC">🌐 UTC</option>
            </select>
          </div>
        </div>

        {/* Alarms Header & Filter Tools */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
          
          <div className="flex items-center gap-2">
            <h2 className="text-lg font-bold text-white flex items-center gap-2">
              <Bell className="w-5 h-5 text-indigo-400" />
              <span>Your Timezone Alarms</span>
            </h2>
            <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-slate-800 text-slate-300">
              {filteredAlarms.length}
            </span>
          </div>

          {/* Controls: Search & Tabs */}
          <div className="flex items-center gap-2 flex-wrap sm:flex-nowrap">
            {/* Search */}
            <div className="relative flex-1 sm:w-56">
              <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-2.5" />
              <input
                type="text"
                placeholder="Search alarms..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-8 pr-3 py-1.5 text-xs bg-slate-900 border border-slate-800 rounded-lg text-white placeholder:text-slate-500 focus:outline-none focus:border-indigo-500"
              />
            </div>

            {/* Filter Tabs */}
            <div className="flex items-center p-0.5 bg-slate-900 border border-slate-800 rounded-lg text-xs">
              <button
                onClick={() => setFilterTab('all')}
                className={`px-2.5 py-1 rounded-md font-medium transition ${
                  filterTab === 'all'
                    ? 'bg-indigo-600 text-white shadow-sm'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                All
              </button>
              <button
                onClick={() => setFilterTab('active')}
                className={`px-2.5 py-1 rounded-md font-medium transition ${
                  filterTab === 'active'
                    ? 'bg-indigo-600 text-white shadow-sm'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                Active
              </button>
              <button
                onClick={() => setFilterTab('inactive')}
                className={`px-2.5 py-1 rounded-md font-medium transition ${
                  filterTab === 'inactive'
                    ? 'bg-indigo-600 text-white shadow-sm'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                Off
              </button>
            </div>

            {/* Quick Add Button */}
            <button
              onClick={() => {
                setEditingAlarm(null);
                setPreselectedZone(null);
                setIsAlarmModalOpen(true);
              }}
              className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white shadow-md transition shrink-0"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Add Alarm</span>
            </button>
          </div>

        </div>

        {/* Alarms Grid */}
        {filteredAlarms.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredAlarms.map((alarm) => (
              <AlarmCard
                key={alarm.id}
                alarm={alarm}
                localTimeZone={localTimeZone}
                use24Hour={use24Hour}
                onToggleEnabled={handleToggleEnabled}
                onEdit={(a) => {
                  setEditingAlarm(a);
                  setPreselectedZone(null);
                  setIsAlarmModalOpen(true);
                }}
                onDelete={handleDeleteAlarm}
                onTestTrigger={triggerAlarm}
              />
            ))}
          </div>
        ) : (
          <div className="text-center py-16 px-4 rounded-2xl bg-slate-900/40 border border-dashed border-slate-800">
            <div className="inline-flex p-4 rounded-full bg-slate-800/80 text-slate-400 mb-3">
              <Clock className="w-8 h-8" />
            </div>
            <h3 className="text-base font-bold text-white">No alarms found</h3>
            <p className="text-xs text-slate-400 max-w-sm mx-auto mt-1 mb-4">
              {searchQuery
                ? 'Try adjusting your search query or filter tab.'
                : 'Create your first timezone-aware alarm to automatically sync global schedules with your local clock.'}
            </p>
            <button
              onClick={() => {
                setEditingAlarm(null);
                setPreselectedZone(null);
                setIsAlarmModalOpen(true);
              }}
              className="inline-flex items-center gap-2 px-4 py-2 text-xs font-bold rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white shadow-lg shadow-indigo-600/30 transition"
            >
              <Plus className="w-4 h-4" />
              <span>Create New Alarm</span>
            </button>
          </div>
        )}

      </main>

      {/* Mobile Floating Action Button (FAB) for quick alarm creation */}
      <div className="fixed sm:hidden right-5 bottom-6 z-30 pb-safe">
        <button
          id="btn-mobile-fab-add-alarm"
          onClick={() => {
            setEditingAlarm(null);
            setPreselectedZone(null);
            setIsAlarmModalOpen(true);
          }}
          className="flex items-center gap-2 px-5 py-3.5 rounded-full bg-gradient-to-r from-indigo-500 to-indigo-600 active:scale-95 text-white font-bold shadow-2xl shadow-indigo-500/50 border border-indigo-400/30 transition text-sm"
        >
          <Plus className="w-5 h-5" />
          <span>New Alarm</span>
        </button>
      </div>

      {/* Footer */}
      <footer className="border-t border-slate-800/60 bg-slate-950 py-6 mb-16 sm:mb-0 text-center text-xs text-slate-500 pb-safe">
        <div className="max-w-7xl mx-auto px-4 flex flex-col sm:flex-row items-center justify-between gap-2">
          <span>Timezone Alarm — Automatic Global to Local Time Harmonization</span>
          <span className="text-slate-400">
            Supports all 400+ IANA Timezones • Dynamic Seasonal DST Shifts
          </span>
        </div>
      </footer>

      {/* Modals */}
      <AlarmModal
        isOpen={isAlarmModalOpen}
        onClose={() => {
          setIsAlarmModalOpen(false);
          setEditingAlarm(null);
          setPreselectedZone(null);
        }}
        onSave={handleSaveAlarm}
        editingAlarm={editingAlarm}
        localTimeZone={localTimeZone}
        use24HourDefault={use24Hour}
        preselectedTimeZone={preselectedZone}
      />

      <TimezoneConverter
        isOpen={isConverterOpen}
        onClose={() => setIsConverterOpen(false)}
        localTimeZone={localTimeZone}
        onSetAlarmForTime={handleSetAlarmFromConverter}
      />

      <SeasonInfoModal
        isOpen={isDstGuideOpen}
        onClose={() => setIsDstGuideOpen(false)}
      />

      {/* Active Ringing Alarm Fullscreen Overlay */}
      {activeRingingAlarm && (
        <ActiveAlarmOverlay
          alarm={activeRingingAlarm}
          localTimeZone={localTimeZone}
          onDismiss={handleDismissAlarm}
          onSnooze={handleSnoozeAlarm}
        />
      )}

    </div>
  );
}

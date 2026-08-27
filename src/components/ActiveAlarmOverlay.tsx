import { useEffect, useState } from 'react';
import { Alarm } from '../types';
import { getTimeZoneDetails } from '../utils/timezone';
import { startVibrationLoop, stopVibrationLoop, isVibrationSupported, triggerDeviceVibration } from '../utils/notifications';
import confetti from 'canvas-confetti';
import { BellRing, Volume2, VolumeX, Sparkles, Clock, Check, RotateCcw, Smartphone } from 'lucide-react';

interface ActiveAlarmOverlayProps {
  alarm: Alarm;
  localTimeZone: string;
  onDismiss: (alarmId: string) => void;
  onSnooze: (alarmId: string, snoozeMinutes: number) => void;
}

export function ActiveAlarmOverlay({
  alarm,
  localTimeZone,
  onDismiss,
  onSnooze,
}: ActiveAlarmOverlayProps) {
  const now = new Date();
  const srcDetails = getTimeZoneDetails(alarm.sourceTimeZone, now);
  const locDetails = getTimeZoneDetails(localTimeZone, now);
  const hasVibrationSupport = isVibrationSupported();

  const isVibrateMode = alarm.alertMode === 'vibrate_only' || alarm.sound === 'silent';
  const isSoundAndVibrate = alarm.alertMode === 'sound_and_vibrate' || (!alarm.alertMode && alarm.vibrate && alarm.sound !== 'silent');
  const isSoundOnly = alarm.alertMode === 'sound_only' || (!alarm.alertMode && !alarm.vibrate);
  const shouldVibrate = isVibrateMode || isSoundAndVibrate;

  // Continuously loop vibration while this overlay is mounted
  useEffect(() => {
    let controller: { stop: () => void } | null = null;
    if (shouldVibrate) {
      controller = startVibrationLoop();
    }

    return () => {
      if (controller) {
        controller.stop();
      }
      stopVibrationLoop();
    };
  }, [shouldVibrate]);

  const handleUserTap = () => {
    // If browser required a user interaction event to trigger device haptics
    if (shouldVibrate && hasVibrationSupport) {
      triggerDeviceVibration([800, 200, 800, 200]);
      startVibrationLoop();
    }
  };

  const localTimeFormatted = now.toLocaleTimeString('en-US', {
    timeZone: localTimeZone,
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  });

  const sourceTimeFormatted = now.toLocaleTimeString('en-US', {
    timeZone: alarm.sourceTimeZone,
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  });

  const handleDismiss = () => {
    stopVibrationLoop();
    try {
      confetti({
        particleCount: 80,
        spread: 70,
        origin: { y: 0.6 },
      });
    } catch {
      // ignore
    }
    onDismiss(alarm.id);
  };

  const handleSnooze = (mins: number) => {
    stopVibrationLoop();
    onSnooze(alarm.id, mins);
  };

  return (
    <div 
      onClick={handleUserTap}
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/90 backdrop-blur-md animate-in fade-in zoom-in-95 duration-300 select-none cursor-pointer"
    >
      
      {/* Background Animated Glow Rings */}
      <div className="absolute inset-0 flex items-center justify-center pointer-events-none overflow-hidden">
        <div className="w-[500px] h-[500px] rounded-full bg-indigo-500/20 animate-ping opacity-30"></div>
        <div className="w-[350px] h-[350px] rounded-full bg-emerald-500/20 animate-pulse opacity-40"></div>
      </div>

      <div
        id="active-alarm-dialog"
        onClick={(e) => {
          e.stopPropagation();
          handleUserTap();
        }}
        className="relative w-full max-w-lg bg-slate-900 border-2 border-indigo-500 rounded-3xl p-8 shadow-2xl text-center space-y-6 overflow-hidden cursor-default"
      >
        {/* Pulsing Bell / Vibration Icon */}
        <div className="relative inline-flex items-center justify-center">
          <div className="absolute w-24 h-24 rounded-full bg-indigo-500/30 animate-ping"></div>
          <div className="relative flex items-center justify-center w-20 h-20 rounded-full bg-gradient-to-tr from-indigo-600 to-cyan-500 text-white shadow-xl shadow-indigo-500/40">
            {isVibrateMode ? (
              <Smartphone className="w-10 h-10 animate-bounce" />
            ) : (
              <BellRing className="w-10 h-10 animate-bounce" />
            )}
          </div>
        </div>

        {/* Title */}
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-indigo-500/20 text-indigo-300 text-xs font-semibold uppercase tracking-wider mb-2 border border-indigo-500/30">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Timezone Alarm Triggered!</span>
          </div>

          <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
            {alarm.title || 'Scheduled Alarm'}
          </h2>
        </div>

        {/* Dual Times Display */}
        <div className="grid grid-cols-2 gap-3 p-4 rounded-2xl bg-slate-950/80 border border-slate-800 text-left">
          {/* Target Zone */}
          <div>
            <div className="text-[11px] font-medium text-slate-400 uppercase">
              Target Zone Time
            </div>
            <div className="font-mono text-xl sm:text-2xl font-bold text-white mt-1">
              {sourceTimeFormatted}
            </div>
            <div className="text-xs text-slate-400 truncate mt-0.5">
              {srcDetails.displayName.split(' ')[0]} ({srcDetails.timeZoneAbbreviation})
            </div>
          </div>

          {/* Local Zone */}
          <div className="border-l border-slate-800 pl-3">
            <div className="text-[11px] font-semibold text-emerald-400 uppercase">
              Your Local Time
            </div>
            <div className="font-mono text-xl sm:text-2xl font-bold text-emerald-400 mt-1">
              {localTimeFormatted}
            </div>
            <div className="text-xs text-slate-300 truncate mt-0.5">
              Local: {locDetails.timeZoneAbbreviation} ({locDetails.utcOffsetFormatted})
            </div>
          </div>
        </div>

        {/* Alert Mode active indicator */}
        <div className="flex flex-col gap-1 text-xs text-slate-300 bg-slate-950/60 py-2 px-4 rounded-xl border border-slate-800">
          <div className="flex items-center justify-center gap-2">
            {isVibrateMode ? (
              <>
                <Smartphone className="w-4 h-4 text-indigo-400 animate-pulse" />
                <span>Vibration Only Mode: <strong>Continuous vibration looping</strong></span>
              </>
            ) : isSoundAndVibrate ? (
              <>
                <Volume2 className="w-4 h-4 text-emerald-400 animate-pulse" />
                <span>Sound & Vibrate: <strong className="text-white capitalize">{alarm.sound}</strong> + Loop Vibration</span>
              </>
            ) : (
              <>
                <Volume2 className="w-4 h-4 text-indigo-400 animate-pulse" />
                <span>Sound Only: <strong className="text-white capitalize">{alarm.sound}</strong> melody</span>
              </>
            )}
          </div>

          {shouldVibrate && !hasVibrationSupport && (
            <div className="text-[11px] text-amber-400/90 pt-0.5">
              (Note: iOS Safari blocks browser vibration; install as Android PWA/APK for hardware haptics)
            </div>
          )}
        </div>

        {/* Snooze Options */}
        <div className="space-y-2 pt-2">
          <div className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
            Snooze Alarm
          </div>
          <div className="grid grid-cols-3 gap-2">
            {[5, 10, 15].map((mins) => (
              <button
                key={mins}
                id={`btn-snooze-${mins}`}
                onClick={() => handleSnooze(mins)}
                className="py-2 px-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 hover:text-white text-xs font-bold transition flex items-center justify-center gap-1 border border-slate-700 active:scale-95"
              >
                <RotateCcw className="w-3 h-3" />
                <span>+{mins} min</span>
              </button>
            ))}
          </div>
        </div>

        {/* Dismiss Button */}
        <button
          id="btn-dismiss-active-alarm"
          onClick={handleDismiss}
          className="w-full py-4 px-6 rounded-2xl bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 text-white font-bold text-base shadow-xl shadow-emerald-500/25 active:scale-98 transition flex items-center justify-center gap-2"
        >
          <Check className="w-5 h-5" />
          <span>Dismiss Alarm</span>
        </button>

      </div>
    </div>
  );
}


import { AlarmSoundType } from '../types';

let audioCtx: AudioContext | null = null;

function getAudioContext(): AudioContext {
  if (!audioCtx || audioCtx.state === 'closed') {
    const AudioContextClass = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    audioCtx = new AudioContextClass();
  }
  if (audioCtx.state === 'suspended') {
    audioCtx.resume();
  }
  return audioCtx;
}

export interface SoundController {
  stop: () => void;
  setVolume: (v: number) => void;
}

export function unlockAudioContext() {
  const ctx = getAudioContext();
  if (ctx && ctx.state === 'suspended') {
    ctx.resume();
  }
}

if (typeof window !== 'undefined') {
  const handleInteraction = () => {
    unlockAudioContext();
    window.removeEventListener('click', handleInteraction);
    window.removeEventListener('touchstart', handleInteraction);
    window.removeEventListener('keydown', handleInteraction);
  };
  window.addEventListener('click', handleInteraction, { passive: true });
  window.addEventListener('touchstart', handleInteraction, { passive: true });
  window.addEventListener('keydown', handleInteraction, { passive: true });
}


export function playAlarmSoundLoop(soundType: AlarmSoundType, volume: number = 0.8): SoundController {
  if (soundType === 'silent') {
    return {
      stop: () => {},
      setVolume: () => {},
    };
  }

  const ctx = getAudioContext();
  let isRunning = true;
  let nextNoteTimeout: ReturnType<typeof setTimeout> | null = null;

  const masterGain = ctx.createGain();
  masterGain.gain.setValueAtTime(Math.max(0, Math.min(1, volume)), ctx.currentTime);
  masterGain.connect(ctx.destination);

  const loopRoutine = () => {
    if (!isRunning) return;

    const now = ctx.currentTime;

    if (soundType === 'digital') {
      // Classic digital alarm beeps: beep-beep-beep-beep
      for (let i = 0; i < 4; i++) {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'square';
        osc.frequency.setValueAtTime(i % 2 === 0 ? 1046.5 : 1318.5, now + i * 0.12); // C6 / E6

        gain.gain.setValueAtTime(0, now + i * 0.12);
        gain.gain.linearRampToValueAtTime(0.3, now + i * 0.12 + 0.01);
        gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.12 + 0.08);

        osc.connect(gain);
        gain.connect(masterGain);

        osc.start(now + i * 0.12);
        osc.stop(now + i * 0.12 + 0.09);
      }
      nextNoteTimeout = setTimeout(loopRoutine, 900);
    } else if (soundType === 'chime') {
      // Crystal pentatonic chimes: C5, E5, G5, B5, D6
      const notes = [523.25, 659.25, 783.99, 987.77, 1174.66];
      notes.forEach((freq, idx) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, now + idx * 0.18);

        gain.gain.setValueAtTime(0, now + idx * 0.18);
        gain.gain.linearRampToValueAtTime(0.4, now + idx * 0.18 + 0.03);
        gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.18 + 1.2);

        osc.connect(gain);
        gain.connect(masterGain);

        osc.start(now + idx * 0.18);
        osc.stop(now + idx * 0.18 + 1.25);
      });
      nextNoteTimeout = setTimeout(loopRoutine, 2400);
    } else if (soundType === 'marimba') {
      // Cheerful marimba pattern
      const chords = [523.25, 659.25, 783.99, 1046.5, 783.99, 659.25];
      chords.forEach((freq, idx) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(freq, now + idx * 0.14);

        gain.gain.setValueAtTime(0, now + idx * 0.14);
        gain.gain.linearRampToValueAtTime(0.5, now + idx * 0.14 + 0.01);
        gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.14 + 0.35);

        osc.connect(gain);
        gain.connect(masterGain);

        osc.start(now + idx * 0.14);
        osc.stop(now + idx * 0.14 + 0.38);
      });
      nextNoteTimeout = setTimeout(loopRoutine, 1600);
    } else if (soundType === 'radar') {
      // Sonar radar pulse
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(440, now);
      osc.frequency.exponentialRampToValueAtTime(880, now + 0.3);

      gain.gain.setValueAtTime(0.001, now);
      gain.gain.linearRampToValueAtTime(0.4, now + 0.05);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);

      osc.connect(gain);
      gain.connect(masterGain);

      osc.start(now);
      osc.stop(now + 0.65);

      nextNoteTimeout = setTimeout(loopRoutine, 1200);
    } else if (soundType === 'bell') {
      // Resonant alarm bell
      const baseFreq = 440;
      const harmonics = [1, 2.76, 5.4, 8.93];
      harmonics.forEach((h) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(baseFreq * h, now);

        gain.gain.setValueAtTime(0, now);
        gain.gain.linearRampToValueAtTime(0.3 / h, now + 0.01);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 1.8);

        osc.connect(gain);
        gain.connect(masterGain);

        osc.start(now);
        osc.stop(now + 1.85);
      });
      nextNoteTimeout = setTimeout(loopRoutine, 2000);
    } else {
      // Gentle ambient swell
      const freqs = [261.63, 329.63, 392.0, 493.88]; // Cmaj7
      freqs.forEach((freq) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, now);

        gain.gain.setValueAtTime(0.001, now);
        gain.gain.linearRampToValueAtTime(0.15, now + 0.8);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 2.2);

        osc.connect(gain);
        gain.connect(masterGain);

        osc.start(now);
        osc.stop(now + 2.25);
      });
      nextNoteTimeout = setTimeout(loopRoutine, 2500);
    }
  };

  loopRoutine();

  return {
    stop: () => {
      isRunning = false;
      if (nextNoteTimeout) clearTimeout(nextNoteTimeout);
      try {
        masterGain.gain.linearRampToValueAtTime(0.001, ctx.currentTime + 0.1);
        setTimeout(() => masterGain.disconnect(), 150);
      } catch {
        // ignore
      }
    },
    setVolume: (v: number) => {
      try {
        masterGain.gain.setValueAtTime(Math.max(0, Math.min(1, v)), ctx.currentTime);
      } catch {
        // ignore
      }
    },
  };
}

export function previewAlarmSound(soundType: AlarmSoundType, volume: number = 0.8) {
  const controller = playAlarmSoundLoop(soundType, volume);
  setTimeout(() => {
    controller.stop();
  }, 1800);
}

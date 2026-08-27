export async function requestNotificationPermission(): Promise<NotificationPermission> {
  if (!('Notification' in window)) {
    return 'denied';
  }
  if (Notification.permission === 'granted') {
    return 'granted';
  }
  return await Notification.requestPermission();
}

export function sendAlarmNotification(title: string, body: string, vibratePattern: boolean = true) {
  if (!('Notification' in window)) {
    return;
  }
  if (Notification.permission === 'granted') {
    try {
      const options: NotificationOptions = {
        body,
        icon: '/favicon.ico',
        tag: 'timezone-alarm',
        requireInteraction: true,
      };

      if (vibratePattern) {
        // Android system notification vibration pattern
        (options as unknown as { vibrate: number[] }).vibrate = [500, 250, 500, 250, 500, 250, 500, 250, 800];
      }

      new Notification(`⏰ ${title}`, options);
    } catch {
      // Fallback
    }
  }
}

export interface VibrationController {
  stop: () => void;
}

let activeVibrationInterval: ReturnType<typeof setInterval> | null = null;

export function isVibrationSupported(): boolean {
  return typeof navigator !== 'undefined' && typeof navigator.vibrate === 'function';
}

/**
 * Starts a continuous vibration loop that repeats every 1.5s until explicitly stopped (e.g. dismissed or snoozed).
 */
export function startVibrationLoop(): VibrationController {
  if (!isVibrationSupported()) {
    return { stop: () => {} };
  }

  // Clear any existing active loop first
  stopVibrationLoop();

  const pulse = () => {
    try {
      if (typeof navigator !== 'undefined' && 'vibrate' in navigator) {
        // Strong repeating pulse: 800ms vibrate, 200ms pause, 800ms vibrate
        navigator.vibrate([800, 200, 800, 200]);
      }
    } catch {
      // Vibration ignored or permission not active
    }
  };

  // Trigger immediately
  pulse();

  // Keep re-triggering every 2000ms until stopVibrationLoop() is called
  activeVibrationInterval = setInterval(() => {
    pulse();
  }, 2000);

  return {
    stop: stopVibrationLoop,
  };
}

/**
 * Stops any ongoing continuous vibration and cancels the vibration hardware.
 */
export function stopVibrationLoop() {
  if (activeVibrationInterval) {
    clearInterval(activeVibrationInterval);
    activeVibrationInterval = null;
  }
  if (typeof navigator !== 'undefined' && 'vibrate' in navigator) {
    try {
      navigator.vibrate(0);
    } catch {
      // ignore
    }
  }
}

/**
 * Single short vibration for testing or tactile tap feedback
 */
export function triggerDeviceVibration(pattern: number[] = [600, 200, 600, 200, 600]) {
  if (isVibrationSupported()) {
    try {
      navigator.vibrate(pattern);
    } catch {
      // Vibration ignored
    }
  }
}



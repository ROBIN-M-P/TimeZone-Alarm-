import { X, Sparkles, Sun, Moon, Calendar, CheckCircle2 } from 'lucide-react';

interface SeasonInfoModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function SeasonInfoModal({ isOpen, onClose }: SeasonInfoModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/80 backdrop-blur-sm overflow-y-auto animate-in fade-in duration-200">
      <div className="relative w-full max-w-2xl bg-slate-900 border-t sm:border border-slate-700/80 rounded-t-3xl sm:rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[92vh] sm:max-h-[90vh] pb-safe">
        
        {/* Header */}
        <div className="px-5 sm:px-6 py-3.5 sm:py-4 border-b border-slate-800 flex items-center justify-between bg-slate-950/60 shrink-0">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-amber-500/10 text-amber-400 border border-amber-500/20">
              <Sparkles className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base sm:text-lg font-bold text-white">
                Seasonal & DST Intelligence
              </h2>
              <p className="text-[11px] sm:text-xs text-slate-400">
                Automatic worldwide clock adjustments
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

        {/* Content */}
        <div className="p-6 space-y-5 overflow-y-auto text-sm text-slate-300">
          
          {/* Main summary card */}
          <div className="p-4 rounded-xl bg-gradient-to-br from-indigo-950/50 to-slate-950 border border-indigo-500/30">
            <h3 className="text-sm font-bold text-white flex items-center gap-2 mb-2">
              <CheckCircle2 className="w-4 h-4 text-emerald-400" />
              <span>Zero Manual Recalibration Required</span>
            </h3>
            <p className="text-xs text-slate-300 leading-relaxed">
              When you set an alarm for a specific time in another timezone (for example: <strong className="text-white">6:30 AM America/Los_Angeles</strong>), the engine computes the UTC timestamp for that exact target date using the official IANA database.
            </p>
          </div>

          {/* Real example breakdown */}
          <div className="space-y-3">
            <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Real-World Seasonal Example: US Pacific ➔ India (IST)
            </h4>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
              {/* Summer / Daylight Saving */}
              <div className="p-3.5 rounded-xl bg-slate-950 border border-amber-500/30 space-y-2">
                <div className="flex items-center justify-between font-bold text-amber-300">
                  <span className="flex items-center gap-1.5">
                    <Sun className="w-4 h-4 text-amber-400" />
                    <span>Summer / Autumn (PDT)</span>
                  </span>
                  <span className="text-[10px] px-2 py-0.5 rounded bg-amber-500/20 text-amber-300">
                    UTC-7
                  </span>
                </div>
                <div className="text-slate-300 space-y-1">
                  <div>• Source: <strong className="text-white">6:30 AM PDT</strong></div>
                  <div>• Converted: <strong className="text-emerald-400">7:00 PM IST (Local)</strong></div>
                  <div>• Difference: <span className="text-slate-400">12.5 hours</span></div>
                </div>
              </div>

              {/* Winter / Standard Time */}
              <div className="p-3.5 rounded-xl bg-slate-950 border border-indigo-500/30 space-y-2">
                <div className="flex items-center justify-between font-bold text-indigo-300">
                  <span className="flex items-center gap-1.5">
                    <Moon className="w-4 h-4 text-indigo-400" />
                    <span>Winter / Spring (PST)</span>
                  </span>
                  <span className="text-[10px] px-2 py-0.5 rounded bg-indigo-500/20 text-indigo-300">
                    UTC-8
                  </span>
                </div>
                <div className="text-slate-300 space-y-1">
                  <div>• Source: <strong className="text-white">6:30 AM PST</strong></div>
                  <div>• Converted: <strong className="text-emerald-400">8:00 PM IST (Local)</strong></div>
                  <div>• Difference: <span className="text-slate-400">13.5 hours</span></div>
                </div>
              </div>
            </div>
          </div>

          {/* Key Global Regions Supported */}
          <div className="space-y-2">
            <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Supported Global DST Transitions
            </h4>

            <ul className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
              <li className="p-2.5 rounded-lg bg-slate-950 border border-slate-800 flex items-start gap-2">
                <span className="text-indigo-400 font-bold">🇺🇸 North America</span>
                <span className="text-slate-400">PST/PDT, MST/MDT, CST/CDT, EST/EDT</span>
              </li>
              <li className="p-2.5 rounded-lg bg-slate-950 border border-slate-800 flex items-start gap-2">
                <span className="text-indigo-400 font-bold">🇬🇧 Europe & UK</span>
                <span className="text-slate-400">GMT/BST, CET/CEST, EET/EEST</span>
              </li>
              <li className="p-2.5 rounded-lg bg-slate-950 border border-slate-800 flex items-start gap-2">
                <span className="text-indigo-400 font-bold">🇦🇺 Australia & NZ</span>
                <span className="text-slate-400">AEST/AEDT, NZST/NZDT (Southern Hemisphere)</span>
              </li>
              <li className="p-2.5 rounded-lg bg-slate-950 border border-slate-800 flex items-start gap-2">
                <span className="text-indigo-400 font-bold">🌏 Non-DST Zones</span>
                <span className="text-slate-400">IST (India), JST (Japan), SGT (Singapore), GST (UAE)</span>
              </li>
            </ul>
          </div>

          {/* How we test it */}
          <div className="p-3.5 rounded-xl bg-slate-950 border border-slate-800 text-xs text-slate-400">
            <span className="text-white font-semibold">How it operates: </span>
            The app evaluates every alarm continuously against the target future date. When a seasonal transition happens on a Sunday morning, future alarms recalculate the exact new local time seamlessly.
          </div>

        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-slate-800 bg-slate-950/80 flex justify-end">
          <button
            onClick={onClose}
            className="px-5 py-2 text-sm font-semibold rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white transition"
          >
            Got it!
          </button>
        </div>

      </div>
    </div>
  );
}

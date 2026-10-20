// Shared Web Audio API notification sound generator
let audioContextInstance: AudioContext | null = null;

const getAudioContext = (): AudioContext | null => {
  try {
    const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
    if (!AudioCtx) return null;
    if (!audioContextInstance || audioContextInstance.state === 'closed') {
      audioContextInstance = new AudioCtx();
    }
    if (audioContextInstance.state === 'suspended') {
      audioContextInstance.resume().catch(() => {});
    }
    return audioContextInstance;
  } catch (_) {
    return null;
  }
};

// Automatically unlock AudioContext on first user interaction
if (typeof window !== 'undefined') {
  const unlockAudio = () => {
    const ctx = getAudioContext();
    if (ctx && ctx.state === 'suspended') {
      ctx.resume().catch(() => {});
    }
    window.removeEventListener('pointerdown', unlockAudio);
    window.removeEventListener('keydown', unlockAudio);
  };
  window.addEventListener('pointerdown', unlockAudio, { passive: true });
  window.addEventListener('keydown', unlockAudio, { passive: true });
}

/**
 * Phát âm thanh chuông thông báo trong trẻo (Standard Notification Chime)
 */
export const playNotificationSound = () => {
  try {
    const ctx = getAudioContext();
    if (!ctx) return;
    const now = ctx.currentTime;

    // Pleasant 2-step chime: 587Hz (D5) -> 880Hz (A5) -> 1046Hz (C6)
    const notes = [
      { freq: 587.33, start: 0, duration: 0.18, volume: 0.2 },
      { freq: 880.0, start: 0.12, duration: 0.22, volume: 0.25 },
      { freq: 1046.5, start: 0.24, duration: 0.35, volume: 0.28 },
    ];

    notes.forEach((note) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(note.freq, now + note.start);

      gain.gain.setValueAtTime(note.volume, now + note.start);
      gain.gain.exponentialRampToValueAtTime(0.001, now + note.start + note.duration);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now + note.start);
      osc.stop(now + note.start + note.duration);
    });
  } catch (err) {
    console.warn('[SoundUtils] Could not play notification sound:', err);
  }
};

/**
 * Phát âm thanh báo động có đơn hàng mới (New Order Alert Chime)
 */
export const playOrderAlertSound = () => {
  try {
    const ctx = getAudioContext();
    if (!ctx) return;
    const now = ctx.currentTime;

    // Double chime: Ding-Dong ... Ding-Dong
    const chords = [
      { freq: 659.25, start: 0, duration: 0.18, volume: 0.28 }, // E5
      { freq: 987.77, start: 0.12, duration: 0.28, volume: 0.32 }, // B5
      { freq: 659.25, start: 0.32, duration: 0.18, volume: 0.28 }, // E5
      { freq: 1174.66, start: 0.44, duration: 0.45, volume: 0.35 }, // D6
    ];

    chords.forEach((chord) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'triangle';
      osc.frequency.setValueAtTime(chord.freq, now + chord.start);

      gain.gain.setValueAtTime(chord.volume, now + chord.start);
      gain.gain.exponentialRampToValueAtTime(0.001, now + chord.start + chord.duration);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now + chord.start);
      osc.stop(now + chord.start + chord.duration);
    });
  } catch (err) {
    console.warn('[SoundUtils] Could not play order alert sound:', err);
  }
};

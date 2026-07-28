import fs from 'node:fs';
import path from 'node:path';

const rate = 44100;
const outDir = path.resolve('assets/audio');

function writeWav(name, seconds, sample) {
  const count = Math.floor(rate * seconds);
  const data = Buffer.alloc(count * 2);
  for (let i = 0; i < count; i++) {
    const value = Math.max(-1, Math.min(1, sample(i / rate, i)));
    data.writeInt16LE(Math.round(value * 32767), i * 2);
  }
  const wav = Buffer.alloc(44 + data.length);
  wav.write('RIFF', 0);
  wav.writeUInt32LE(36 + data.length, 4);
  wav.write('WAVEfmt ', 8);
  wav.writeUInt32LE(16, 16);
  wav.writeUInt16LE(1, 20);
  wav.writeUInt16LE(1, 22);
  wav.writeUInt32LE(rate, 24);
  wav.writeUInt32LE(rate * 2, 28);
  wav.writeUInt16LE(2, 32);
  wav.writeUInt16LE(16, 34);
  wav.write('data', 36);
  wav.writeUInt32LE(data.length, 40);
  data.copy(wav, 44);
  fs.writeFileSync(path.join(outDir, name), wav);
}

const tone = (frequency, time) => Math.sin(2 * Math.PI * frequency * time);
const decay = (time, speed) => Math.exp(-time * speed);
const pulse = (time, at, width) =>
  time < at ? 0 : Math.exp(-(time - at) * width);
const noise = (index) => {
  const value = Math.sin(index * 12.9898 + 78.233) * 43758.5453;
  return (value - Math.floor(value)) * 2 - 1;
};

// Pawn: one short wooden chess-piece click.
writeWav('piece_pawn.wav', 0.12, (t, i) =>
  (0.42 * noise(i) + 0.28 * tone(220, t)) * decay(t, 42));

// Knight / horse: two hoof beats followed by a rising neigh.
writeWav('piece_knight.wav', 0.82, (t, i) => {
  const hoof =
    (0.42 * noise(i) + 0.25 * tone(92, t)) *
    (pulse(t, 0, 50) + pulse(t, 0.16, 55));
  const neighTime = Math.max(0, t - 0.27);
  const neighFrequency = 430 + 220 * Math.sin(neighTime * 11) + neighTime * 270;
  const neigh =
    t < 0.27
      ? 0
      : 0.30 *
        Math.sin(2 * Math.PI * neighFrequency * neighTime) *
        decay(neighTime, 2.4);
  return hoof + neigh;
});

// Bishop / elephant: unmistakable low-to-high trumpet call.
writeWav('piece_bishop.wav', 0.95, (t) => {
  const frequency = 115 + 390 * Math.pow(t / 0.95, 0.72);
  const vibrato = 1 + 0.045 * Math.sin(2 * Math.PI * 7 * t);
  return (
    (0.34 * tone(frequency * vibrato, t) +
      0.13 * tone(frequency * 2.02, t)) *
    Math.sin(Math.PI * Math.min(1, t / 0.95)) *
    decay(t, 0.65)
  );
});

// Rook: deep stone-tower thud with a short crumble.
writeWav('piece_rook.wav', 0.48, (t, i) =>
  (0.48 * tone(58, t) + 0.22 * tone(116, t) + 0.16 * noise(i)) *
  decay(t, 10));

// Queen: bright four-note royal harp arpeggio.
writeWav('piece_queen.wav', 0.88, (t) => {
  const notes = [523.25, 659.25, 783.99, 1046.5];
  return notes.reduce((sum, frequency, index) => {
    const start = index * 0.12;
    if (t < start) return sum;
    return sum + 0.16 * tone(frequency, t - start) * decay(t - start, 4.5);
  }, 0);
});

// King: short three-note brass fanfare.
writeWav('piece_king.wav', 1.05, (t) => {
  const notes = [
    [0, 196],
    [0.26, 246.94],
    [0.52, 293.66],
  ];
  return notes.reduce((sum, [start, frequency]) => {
    if (t < start) return sum;
    const local = t - start;
    return (
      sum +
      (0.22 * tone(frequency, local) +
        0.10 * tone(frequency * 2, local) +
        0.06 * tone(frequency * 3, local)) *
        decay(local, 2.2)
    );
  }, 0);
});

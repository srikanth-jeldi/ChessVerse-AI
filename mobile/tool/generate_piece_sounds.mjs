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

writeWav('piece_pawn.wav', 0.16, (t) =>
  0.45 * tone(185 - t * 240, t) * decay(t, 26));
writeWav('piece_knight.wav', 0.34, (t) =>
  0.36 * tone(105, t) * (pulse(t, 0, 23) + pulse(t, 0.13, 25)));
writeWav('piece_bishop.wav', 0.46, (t) =>
  (0.24 * tone(155 - t * 55, t) + 0.12 * tone(310 - t * 90, t)) *
  decay(t, 5));
writeWav('piece_rook.wav', 0.28, (t) =>
  (0.38 * tone(92, t) + 0.16 * tone(184, t)) * decay(t, 15));
writeWav('piece_queen.wav', 0.52, (t) =>
  (0.20 * tone(440 + t * 180, t) + 0.14 * tone(660 + t * 110, t)) *
  decay(t, 4.5));
writeWav('piece_king.wav', 0.62, (t) =>
  (0.24 * tone(130, t) + 0.18 * tone(195, t) + 0.10 * tone(260, t)) *
  decay(t, 3.8));

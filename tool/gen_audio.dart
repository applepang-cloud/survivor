// 간단한 8비트풍 효과음 WAV 합성기. `dart run tool/gen_audio.dart` 로 실행.
// 원작에는 사운드가 없어 직접 생성한다 (assets/audio/*.wav).
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 44100;

void main() {
  Directory('assets/audio').createSync(recursive: true);

  _write('levelup.wav', _arpeggio([523, 659, 784, 1046], 0.09, 0.32));
  _write('hit.wav', _hit());
  _write('gameover.wav', _slide(420, 120, 0.7, 0.4, vibrato: true));
  _write('item.wav', _chime());
  _write('pickup.wav', _blip(1200, 0.05, 0.18, wave: _sine));
  _write('shoot.wav', _slide(720, 480, 0.05, 0.14));
  _write('bgm.wav', _bgm(), rate: kBgmRate);
  stdout.writeln('done');
}

// ---------- BGM: 자작 D단조 고딕 칩튠 루프 (8마디, ~14.5초, 무한 루프용) ----------
const int kBgmRate = 22050;

List<double> _bgm() {
  const bpm = 132.0;
  const s16 = 60 / bpm / 4; // 16분음표 길이
  const stepsPerBar = 16;
  // 코드 진행 (자작): Dm Dm Bb A | Gm Dm Bb A
  const bars = ['Dm', 'Dm', 'Bb', 'A', 'Gm', 'Dm', 'Bb', 'A'];
  const bassRoot = {'Dm': 73.42, 'Bb': 58.27, 'A': 55.0, 'Gm': 49.0};
  const arpTones = {
    'Dm': [293.66, 349.23, 440.0, 587.33],
    'Bb': [233.08, 293.66, 349.23, 466.16],
    'A': [220.0, 277.18, 329.63, 440.0],
    'Gm': [196.0, 233.08, 293.66, 392.0],
  };
  // 자작 멜로디: (마디, 시작스텝, 주파수, 길이(16분))
  const melody = [
    [0, 0, 587.33, 4], [0, 4, 698.46, 4], [0, 8, 880.0, 4], [0, 12, 698.46, 4],
    [1, 0, 587.33, 4], [1, 4, 523.25, 2], [1, 6, 587.33, 2], [1, 8, 440.0, 8],
    [2, 0, 466.16, 4], [2, 4, 587.33, 4], [2, 8, 698.46, 4], [2, 12, 587.33, 4],
    [3, 0, 554.37, 4], [3, 4, 659.25, 4], [3, 8, 440.0, 8],
    [4, 0, 392.0, 4], [4, 4, 466.16, 4], [4, 8, 587.33, 4], [4, 12, 466.16, 4],
    [5, 0, 440.0, 4], [5, 4, 349.23, 4], [5, 8, 587.33, 8],
    [6, 0, 466.16, 2], [6, 2, 523.25, 2], [6, 4, 587.33, 4], [6, 8, 698.46, 8],
    [7, 0, 659.25, 4], [7, 4, 554.37, 4], [7, 8, 440.0, 8],
  ];

  final total = (bars.length * stepsPerBar * s16 * kBgmRate).round();
  final buf = List<double>.filled(total, 0);

  void tone(double startSec, double durSec, double freq, double amp,
      double Function(double) wave) {
    final start = (startSec * kBgmRate).round();
    final n = (durSec * kBgmRate).round();
    final atk = (0.004 * kBgmRate).round();
    final rel = (0.012 * kBgmRate).round();
    for (var i = 0; i < n && start + i < total; i++) {
      var env = 1.0;
      if (i < atk) env = i / atk;
      if (i > n - rel) env = (n - i) / rel;
      buf[start + i] += wave(2 * pi * freq * i / kBgmRate) * amp * env;
    }
  }

  void noiseHit(double startSec, double durSec, double amp, int seed) {
    final start = (startSec * kBgmRate).round();
    final n = (durSec * kBgmRate).round();
    final rng = Random(seed);
    for (var i = 0; i < n && start + i < total; i++) {
      final env = pow(1 - i / n, 2).toDouble();
      buf[start + i] += (rng.nextDouble() * 2 - 1) * amp * env;
    }
  }

  void kick(double startSec) {
    final start = (startSec * kBgmRate).round();
    final n = (0.09 * kBgmRate).round();
    var phase = 0.0;
    for (var i = 0; i < n && start + i < total; i++) {
      final k = i / n;
      final f = 150 - 105 * k; // 150→45Hz 스윕
      phase += 2 * pi * f / kBgmRate;
      buf[start + i] += sin(phase) * 0.5 * (1 - k);
    }
  }

  for (var bar = 0; bar < bars.length; bar++) {
    final chord = bars[bar];
    final barSec = bar * stepsPerBar * s16;
    final root = bassRoot[chord]!;
    final arp = arpTones[chord]!;
    for (var st = 0; st < stepsPerBar; st++) {
      final t = barSec + st * s16;
      // 베이스: 8분음표 펌핑, 마지막 8분은 옥타브 위
      if (st % 2 == 0) {
        tone(t, s16 * 1.8, st == 14 ? root * 2 : root, 0.20, _square);
      }
      // 아르페지오: 16분 순환
      tone(t, s16 * 0.92, arp[st % 4], 0.085, _square);
      // 하이햇: 8분마다
      if (st % 2 == 0) noiseHit(t, 0.024, 0.10, bar * 31 + st);
      // 킥 1·3박 / 스네어 2·4박
      if (st == 0 || st == 8) kick(t);
      if (st == 4 || st == 12) noiseHit(t, 0.07, 0.22, 777 + bar * 7 + st);
    }
  }
  // 멜로디 (리드 사각파)
  for (final m in melody) {
    final t = (m[0] as int) * stepsPerBar * s16 + (m[1] as int) * s16;
    tone(t, (m[3] as int) * s16 * 0.94, m[2] as double, 0.12, _square);
  }

  for (var i = 0; i < total; i++) {
    buf[i] = buf[i].clamp(-1.0, 1.0);
  }
  return buf;
}

double _sine(double ph) => sin(ph);
double _square(double ph) => sin(ph) >= 0 ? 1 : -1;

List<double> _arpeggio(List<int> freqs, double noteDur, double amp) {
  final out = <double>[];
  for (final f in freqs) {
    final n = (noteDur * sampleRate).round();
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final env = (1 - i / n) * 0.6 + 0.4; // 부드러운 감쇠
      out.add(_square(2 * pi * f * t) * amp * env);
    }
  }
  return out;
}

List<double> _slide(double f0, double f1, double dur, double amp,
    {bool vibrato = false}) {
  final n = (dur * sampleRate).round();
  final out = List<double>.filled(n, 0);
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final k = i / n;
    var f = f0 + (f1 - f0) * k;
    if (vibrato) f += sin(2 * pi * 7 * (i / sampleRate)) * 12;
    phase += 2 * pi * f / sampleRate;
    final env = (1 - k);
    out[i] = _square(phase) * amp * env;
  }
  return out;
}

List<double> _blip(double f, double dur, double amp,
    {double Function(double) wave = _square}) {
  final n = (dur * sampleRate).round();
  final out = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = (1 - i / n);
    out[i] = wave(2 * pi * f * t) * amp * env;
  }
  return out;
}

List<double> _hit() {
  final n = (0.18 * sampleRate).round();
  final out = List<double>.filled(n, 0);
  final rng = Random(7);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = pow(1 - i / n, 2).toDouble();
    final tone = _square(2 * pi * 130 * t);
    final noise = rng.nextDouble() * 2 - 1;
    out[i] = (tone * 0.6 + noise * 0.4) * 0.4 * env;
  }
  return out;
}

List<double> _chime() {
  final a = _blip(880, 0.12, 0.3, wave: _sine);
  final b = _blip(1318, 0.16, 0.3, wave: _sine);
  return [...a, ...b];
}

void _write(String name, List<double> samples, {int rate = sampleRate}) {
  final data = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(i * 2, v, Endian.little);
  }
  final pcm = data.buffer.asUint8List();
  final file = File('assets/audio/$name');
  file.writeAsBytesSync(_wavHeader(pcm.length, rate) + pcm);
  stdout.writeln('wrote $name (${samples.length} samples @${rate}Hz)');
}

Uint8List _wavHeader(int dataLen, [int rate = sampleRate]) {
  final h = BytesBuilder();
  void str(String s) => h.add(s.codeUnits);
  void u32(int v) {
    final b = ByteData(4)..setUint32(0, v, Endian.little);
    h.add(b.buffer.asUint8List());
  }
  void u16(int v) {
    final b = ByteData(2)..setUint16(0, v, Endian.little);
    h.add(b.buffer.asUint8List());
  }

  str('RIFF');
  u32(36 + dataLen);
  str('WAVE');
  str('fmt ');
  u32(16);
  u16(1); // PCM
  u16(1); // mono
  u32(rate);
  u32(rate * 2); // byte rate
  u16(2); // block align
  u16(16); // bits
  str('data');
  u32(dataLen);
  return h.toBytes();
}

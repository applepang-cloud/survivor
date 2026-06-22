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
  stdout.writeln('done');
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

void _write(String name, List<double> samples) {
  final data = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(i * 2, v, Endian.little);
  }
  final pcm = data.buffer.asUint8List();
  final file = File('assets/audio/$name');
  file.writeAsBytesSync(_wavHeader(pcm.length) + pcm);
  stdout.writeln('wrote $name (${samples.length} samples)');
}

Uint8List _wavHeader(int dataLen) {
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
  u32(sampleRate);
  u32(sampleRate * 2); // byte rate
  u16(2); // block align
  u16(16); // bits
  str('data');
  u32(dataLen);
  return h.toBytes();
}

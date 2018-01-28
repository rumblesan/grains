
s = Server.local

s.boot

(
  MIDIClient.init;
  MIDIIn.connectAll;

  m = MIDIFunc.noteOn({ |vel, num|
    "note % @ velocity %\n".postf(num, vel);
  });

  c = MIDIFunc.cc({ |value, ccnum|
    "cc % @ val %\n".postf(ccnum, value);
  });
)

m.free;
c.free;

b = Buffer.readChannel(s, "/Users/guy/src/grains/sounds/vox.wav", channels: [0]);

(
  SynthDef("mygrainbuf", {
    arg trate = 1, bufnum = 0;
    var dur = 8 / trate;
    var clk = Impulse.kr(trate);
    var pos = Integrator.kr(BrownNoise.kr(0.001));
    var pan = WhiteNoise.kr(0.6);
    var g = GrainBuf.ar(2, clk, dur, bufnum, 1, pos, 1, pan, -1);
    Out.ar(0, g);
  }).send(s);
)

(
  SynthDef("mytgrains", {
    arg trate = 1, bufnum = 0;
    var dur = 8 / trate;
    var clk = Impulse.kr(trate);
    var pos = Integrator.kr(BrownNoise.kr(0.001));
    var pan = WhiteNoise.kr(0.6);
    var g = TGrains.ar(2, clk, bufnum, 1, pos, dur, pan, 0.1);
    Out.ar(0, g);
  }).send(s);
)

(
  SynthDef("playback", {
    arg out = 0, bufnum = 0;
    var snd = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum));
    Out.ar(out, snd);
  }).send(s);
)

p = Synth("playback", ["bufnum", b.bufnum])
p.free

g = Synth("mytgrains", ["bufnum", b.bufnum])
g.free

g = Synth("mygrainbuf", ["bufnum", b.bufnum])
g.free


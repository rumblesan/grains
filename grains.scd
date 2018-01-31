
s = Server.local

s.boot

(
  MIDIClient.init;
  MIDIIn.connectAll;

  v = Dictionary.new;
  v.put(33, Bus.control(s,1));

  m = MIDIFunc.noteOn({ |vel, num|
    "note on  % @ velocity %\n".postf(num, vel);
    v.at(num).set(1.0);
  });

  o = MIDIFunc.noteOff({ |vel, num|
    "note off % @ velocity %\n".postf(num, vel);
    v.at(num).set(0.0);
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
    arg trate = 1, bufnum = 0, busnum;
    var dur = 8 / trate;
    var trig = InTrig.kr( busnum );
    var pos = Integrator.kr(BrownNoise.kr(0.001));
    var pan = WhiteNoise.kr(0.6);
    var g = GrainBuf.ar(2, trig, dur, bufnum, 1, pos, 1, pan, -1);
    Out.ar(0, g);
  }).send(s);
)

(
  SynthDef("mytgrains", {
    arg trate = 1, bufnum = 0;
    var dur = 8 / trate;
    var trig = InTrig.kr( busnum );
    var pos = Integrator.kr(BrownNoise.kr(0.001));
    var pan = WhiteNoise.kr(0.6);
    var g = TGrains.ar(2, trig, bufnum, 1, pos, dur, pan, 0.1);
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

g = Synth("mygrainbuf", ["bufnum", b.bufnum, "busnum", v.at(33)])
g.free

g = Synth("mytgrains", ["bufnum", b.bufnum])
g.free

p = Synth("playback", ["bufnum", b.bufnum, "busnum", v.at(1)])
p.free


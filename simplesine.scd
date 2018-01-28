
s = Server.local

s.boot

(
SynthDef(\SimpleSine,
  {
    arg freq = 440;
    var snd = SinOsc.ar(freq, 0, 0.2);
    Out.ar(0, snd)
  }).send(s);
)

x = Synth.new(\SimpleSine);
x.set(\freq, 220);
x.free;

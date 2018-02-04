
(
  s = Server.local;
  s.boot;
  MIDIClient.init;
  MIDIIn.connectAll;
)

(
  SynthDef("mytgrains", {
    arg trate = 1, onoff = 0, panspread = 0, coursepos = 0, finepos = 0, spreadpos = 0, sampleBuffer;
    var trig = Impulse.kr(trate, 0, onoff);
    var duration = 2 / trate;
    var pos = Mix.kr([
      coursepos,
      finepos,
      Integrator.kr((1/trate) * BrownNoise.kr(spreadpos));
    ]);
    var pan = WhiteNoise.kr(panspread);
    var g = TGrains.ar(2, trig, sampleBuffer, 1, pos, duration, pan, 0.1);
    Out.ar(0, g);
  }).send(s);

  SynthDef("mygrainbuf", {
    arg trate = 1, onoff = 0, panspread = 0, coursepos = 0, finepos = 0, spreadpos = 0, sampleBuffer;
    var duration = 2 / trate;
    var trig = Impulse.kr(trate, 0, onoff);
    var pos = Mix.kr([
      coursepos,
      finepos,
      Integrator.kr((1/trate) * BrownNoise.kr(spreadpos));
    ]);
    var pan = WhiteNoise.kr(panspread);
    var g = GrainBuf.ar(2, trig, duration, sampleBuffer, 1, pos, 1, pan, -1);
    Out.ar(0, g);
  }).send(s);
)

(
~setup = { arg synthName, triggerNote, samplePath, controlList;

  var sampleBuffer = Buffer.readChannel(s, samplePath, channels: [0]);

  var scalingFuncs = Dictionary.with(*[
    \trate -> ({ arg value;
      (1 + value / 4);
    }),
    \panspread -> ({ arg value;
      (value / 128);
    }),
    \coursepos -> ({ arg value;
      (value / 128);
    }),
    \finepos -> ({ arg value;
      (value / 2560);
    }),
    \spreadpos -> ({ arg value;
      (value / 400);
    })
  ]);

  var grains = Synth(synthName, [
    "sampleBuffer", sampleBuffer,
  ]);

  var noteOnListener = MIDIFunc.noteOn({ |vel, num|
    "% on\n".postf(num);
    grains.set(\onoff, 1.0);
  }, triggerNote);

  var noteOffListener = MIDIFunc.noteOff({ |vel, num|
    "% off\n".postf(num);
    grains.set(\onoff, 0.0);
  }, triggerNote);


  var ccListeners = controlList.collect({ arg control;
    var controlName = control.key;
    var ccNum = control.value;
    var func = scalingFuncs.at(controlName);

    var ccListener = MIDIFunc.cc({ |ccVal|
      var val = func.value(ccVal);
      "% @ %\n".postf(controlName, val);
      grains.set(controlName, val);
    }, ccNum);

    ccListener;
  });

  var cleanup = {
    sampleBuffer.free;
    noteOnListener.free;
    noteOffListener.free;
    grains.free;
    ccListeners.do{ arg listener;
      listener.free;
    }
  };

  cleanup;
};
)

~g1 = ~setup.value("mytgrains", 33, "/Users/guy/src/grains/sounds/vox.wav", [\trate -> 1, \panspread -> 5, \coursepos -> 9, \finepos -> 13, \spreadpos -> 17]);

~g2 = ~setup.value("mygrainbuf", 34, "/Users/guy/src/grains/sounds/vox.wav", [\trate -> 2, \panspread -> 6, \spreadpos -> 10, \finepos -> 14, \spreadpos -> 18]);

~g1.value;

~g2.value;


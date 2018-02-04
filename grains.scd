
(
  s = Server.local;
  s.boot;
  MIDIClient.init;
  MIDIIn.connectAll;
  MIDIClient.destinations;
  m = MIDIOut.newByName("Code", "Controls")
)

(
  SynthDef("mytgrains", {
    arg trate = 1, onoff = 0, panspread = 0, coursepos = 0, finepos = 0, spreadpos = 0, sampleBuffer, volume = 0.1, speed = 1;
    var trig = Impulse.kr(trate, 0, onoff);
    var duration = 2 / trate;
    var posDelta = (duration / BufDur.kr(sampleBuffer));
    var pos = Mix.kr([
      coursepos,
      finepos,
      Integrator.kr(posDelta * BrownNoise.kr(spreadpos));
    ]);
    var pan = WhiteNoise.kr(panspread);
    var g = TGrains.ar(2, trig, sampleBuffer, speed, pos, duration, pan, volume, 2);
    Out.ar(0, g);
  }).send(s);

  SynthDef("mygrainbuf", {
    arg trate = 1, onoff = 0, panspread = 0, coursepos = 0, finepos = 0, spreadpos = 0, sampleBuffer, volume = 0.1, speed = 1;
    var duration = 2 / trate;
    var posDelta = (duration / BufDur.kr(sampleBuffer));
    var trig = Impulse.kr(trate, 0, onoff);
    var pos = Mix.kr([
      coursepos,
      finepos,
      Integrator.kr(posDelta * BrownNoise.kr(spreadpos));
    ]);
    var maxgrains = 512;
    var pan = WhiteNoise.kr(panspread);
    var g = GrainBuf.ar(2, trig, duration, sampleBuffer, speed, pos, 1, pan, -1, maxgrains, volume);
    Out.ar(0, g);
  }).send(s);
)

(
~setup = { arg midiOut, synthName, triggerNote, samplePath, controlList;

  var sampleBuffer = Buffer.readChannel(s, samplePath, channels: [0]);

  var reverseValFuncs = Dictionary.with(*[
    \trate -> ({ arg value;
      ((value - 1) * 4);
    }),
    \coursepos -> ({ arg value;
      (value * 128);
    }),
    \speed -> ({ arg value;
      ((value * 30) + 64);
    }),
    \finepos -> ({ arg value;
      (value * 2560);
    }),
    \spreadpos -> ({ arg value;
      (value * 400);
    }),
    \panspread -> ({ arg value;
      (value * 128);
    }),
    \volume -> ({ arg value;
      (value * 100);
    }),
  ]);

  var scalingFuncs = Dictionary.with(*[
    \trate -> ({ arg value;
      (1 + value / 4);
    }),
    \coursepos -> ({ arg value;
      (value / 128);
    }),
    \speed -> ({ arg value;
      ((value - 64) / 30);
    }),
    \finepos -> ({ arg value;
      (value / 2560);
    }),
    \spreadpos -> ({ arg value;
      (value / 400);
    }),
    \panspread -> ({ arg value;
      (value / 128);
    }),
    \volume -> ({ arg value;
      (value / 100);
    }),
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
    var revFunc = reverseValFuncs.at(controlName);

    var defaultVal = grains.get(controlName, { |controlVal|
      midiOut.control(0, ccNum, revFunc.value(controlVal));
    });

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

(
~g1 = ~setup.value(m, "mytgrains", 33, "/Users/guy/src/grains/sounds/vox.wav",
  [
    \trate -> 1,
    \speed -> 5,
    \coursepos -> 9,
    \finepos -> 13,
    \spreadpos -> 17,
    \panspread -> 21,
    \volume -> 25,
  ]);
)

(
~g2 = ~setup.value(m, "mygrainbuf", 34, "/Users/guy/src/grains/sounds/vox.wav",
  [
    \trate -> 2,
    \speed -> 6,
    \coursepos -> 10,
    \finepos -> 14,
    \spreadpos -> 18,
    \panspread -> 22,
    \volume -> 26,
]);
)

~g1.value;

~g2.value;


"""Reproduce the four original v0.5 combat/interaction sounds (no samples)."""
from pathlib import Path
import math
import random
import struct
import wave

random.seed(500)
root = Path(__file__).resolve().parents[1] / 'assets'
for name, seconds in [('blade_heavy', .24), ('shield', .25), ('boss_slam', .4), ('chest', .55)]:
    samples = []
    for i in range(int(22050 * seconds)):
        t = i / 22050
        envelope = (1 - t / seconds) ** 2
        if name == 'blade_heavy':
            value = random.uniform(-1, 1) * .35 + math.sin(2 * math.pi * (170 - 250 * t) * t) * .5
        elif name == 'shield':
            value = math.sin(t * 2 * math.pi * 820) * .5 + math.sin(t * 2 * math.pi * 1370) * .25 + random.uniform(-.1, .1)
        elif name == 'boss_slam':
            value = math.sin(t * 2 * math.pi * 65) * .55 + random.uniform(-.35, .35)
        else:
            frequency = 523 if t < .17 else 784 if t < .34 else 1046
            value = math.sin(2 * math.pi * frequency * t) * .5
        samples.append(struct.pack('<h', int(max(-1, min(1, value * envelope)) * .65 * 32767)))
    with wave.open(str(root / (name + '.wav')), 'wb') as stream:
        stream.setparams((1, 2, 22050, 0, 'NONE', 'not compressed'))
        stream.writeframes(b''.join(samples))

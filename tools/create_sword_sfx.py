"""Recreate the original short sword whoosh without external audio assets."""
from pathlib import Path
import math
import random
import struct
import wave

rate = 22050
duration = 0.22
rng = random.Random(43)
low = 0.0
samples = []
for index in range(int(rate * duration)):
    t = index / rate
    phase = t / duration
    noise = rng.uniform(-1.0, 1.0)
    low += (noise - low) * 0.23
    envelope = math.sin(math.pi * phase) ** 1.5
    sound = (noise - low) * 0.11 + low * 0.38
    samples.append(struct.pack('<h', int(sound * envelope * 24000)))
target = Path(__file__).resolve().parent.parent / 'assets/audio/swing.wav'
with wave.open(str(target), 'wb') as audio:
    audio.setnchannels(1)
    audio.setsampwidth(2)
    audio.setframerate(rate)
    audio.writeframes(b''.join(samples))
print(target)

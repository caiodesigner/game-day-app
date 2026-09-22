"""Generate original, short PCM sound effects; no third-party samples required."""
import math
from pathlib import Path
import struct
import wave

RATE = 22050
ROOT = Path(__file__).resolve().parent.parent / 'assets' / 'audio'
ROOT.mkdir(parents=True, exist_ok=True)
for name, notes in {
    'place': [(660, .085)],
    'clear': [(660, .08), (880, .08), (1100, .13)],
    'gameOver': [(440, .13), (330, .13), (220, .22)],
}.items():
    samples = []
    for frequency, duration in notes:
        count = int(RATE * duration)
        for i in range(count):
            t = i / RATE
            envelope = min(1, t / .008) * (1 - i / count) ** 2
            tone = math.sin(2 * math.pi * frequency * t)
            tone += .15 * math.sin(4 * math.pi * frequency * t)
            samples.append(struct.pack('<h', int(14000 * envelope * tone)))
    with wave.open(str(ROOT / f'{name}.wav'), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(b''.join(samples))

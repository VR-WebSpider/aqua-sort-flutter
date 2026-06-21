import math
import struct
import wave

def generate_wav(filename, duration, sample_rate, wave_func):
    num_samples = int(duration * sample_rate)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1) # mono
        wav_file.setsampwidth(2) # 16-bit
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = i / sample_rate
            value = wave_func(t)
            value = max(-1.0, min(1.0, value))
            sample = int(value * 32767)
            wav_file.writeframes(struct.pack('<h', sample))

# 1. Mini Celebration Chime: C5 -> E5 -> G5 -> C6 arpeggio with decay
def chime_wave(t):
    notes = [
        {"freq": 523.25, "start": 0.0, "decay": 6.0, "vol": 0.3},  # C5
        {"freq": 659.25, "start": 0.12, "decay": 6.0, "vol": 0.3}, # E5
        {"freq": 783.99, "start": 0.24, "decay": 6.0, "vol": 0.3}, # G5
        {"freq": 1046.50, "start": 0.36, "decay": 6.0, "vol": 0.4},# C6
    ]
    
    val = 0.0
    for n in notes:
        if t >= n["start"]:
            dt = t - n["start"]
            envelope = math.exp(-n["decay"] * dt)
            val += n["vol"] * math.sin(2 * math.pi * n["freq"] * dt) * envelope
            
    # Add a touch of harmony (shimmer)
    if t >= 0.36:
        dt = t - 0.36
        val += 0.1 * math.sin(2 * math.pi * 2093.00 * dt) * math.exp(-12.0 * dt)
        
    return val

def lid_wave(t):
    # Air pressure release pop (cork pop style) - tuned for audible speaker range
    hiss = 0.0
    if t < 0.04:
        hiss = 0.20 * math.sin(2 * math.pi * 3200 * t) * math.exp(-80.0 * t)
        
    pop = 0.0
    if t >= 0.01:
        dt = t - 0.01
        # Sweep from 520Hz down to 260Hz
        freq = 520.0 - 260.0 * (1.0 - math.exp(-25.0 * dt))
        pop = 0.95 * math.sin(2 * math.pi * freq * dt) * math.exp(-35.0 * dt)
        
    return hiss + pop

if __name__ == "__main__":
    generate_wav("mini_celebration.wav", 1.0, 44100, chime_wave)
    generate_wav("lid_closing.wav", 0.25, 44100, lid_wave)
    print("Successfully generated SFX files!")

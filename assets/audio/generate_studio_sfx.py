import math
import random
import struct
import wave
import os

SAMPLE_RATE = 44100

def write_wav(filename, duration, generator_func, stereo=False):
    num_samples = int(duration * SAMPLE_RATE)
    channels = 2 if stereo else 1
    
    with wave.open(filename, 'w') as wav:
        wav.setnchannels(channels)
        wav.setsampwidth(2) # 16-bit PCM
        wav.setframerate(SAMPLE_RATE)
        
        for i in range(num_samples):
            t = i / SAMPLE_RATE
            if stereo:
                left, right = generator_func(t)
                left = max(-1.0, min(1.0, left))
                right = max(-1.0, min(1.0, right))
                s_left = int(left * 32767)
                s_right = int(right * 32767)
                wav.writeframes(struct.pack('<hh', s_left, s_right))
            else:
                val = generator_func(t)
                val = max(-1.0, min(1.0, val))
                sample = int(val * 32767)
                wav.writeframes(struct.pack('<h', sample))

# ─────────────────────────────────────────────────────────────────────────────
# 1. CRISP WATER DROPLET TAP (UI & Tube Selection)
# ─────────────────────────────────────────────────────────────────────────────
def sfx_water_drop(t):
    # High frequency chirp with rapid exponential decay + resonant body
    if t > 0.18:
        return 0.0
    # Frequency glide from 2200Hz down to 950Hz
    freq = 950.0 + 1250.0 * math.exp(-35.0 * t)
    env = math.exp(-28.0 * t)
    chirp = 0.75 * math.sin(2 * math.pi * freq * t) * env
    # Low frequency resonance body
    body = 0.25 * math.sin(2 * math.pi * 480.0 * t) * math.exp(-18.0 * t)
    # Splash harmonic click
    click = 0.15 * math.sin(2 * math.pi * 3800.0 * t) * math.exp(-90.0 * t)
    return chirp + body + click

# ─────────────────────────────────────────────────────────────────────────────
# 2. RICH BUBBLING LIQUID POUR (Continuous Flow Loop)
# ─────────────────────────────────────────────────────────────────────────────
def sfx_pour_stream(t):
    # Layered multiple resonant water bubbles with stochastic FM modulation
    val = 0.0
    bubble_rates = [12.0, 18.5, 27.0, 34.0, 48.0]
    base_freqs = [380.0, 480.0, 620.0, 810.0, 1150.0]
    
    for rate, base in zip(bubble_rates, base_freqs):
        phase = (t * rate) % 1.0
        # upward pitch chirp for realistic bubbling
        freq = base + 350.0 * (phase ** 1.8)
        envelope = math.sin(phase * math.pi) ** 2.0
        val += 0.16 * math.sin(2 * math.pi * freq * t) * envelope
        
    # Gentle fluid rush noise layer
    noise_freq = 1400.0 + 200.0 * math.sin(2 * math.pi * 3.5 * t)
    flow = 0.08 * math.sin(2 * math.pi * noise_freq * t) * (1.0 + 0.3 * math.sin(2 * math.pi * 9.0 * t))
    return val + flow

# ─────────────────────────────────────────────────────────────────────────────
# 3. AIRTIGHT CORK & GLASS SEAL POP (Tube Solved / Cap Lock)
# ─────────────────────────────────────────────────────────────────────────────
def sfx_cork_lock(t):
    # Initial air pressure release whoosh
    whoosh = 0.0
    if t < 0.035:
        whoosh = 0.25 * math.sin(2 * math.pi * 3600.0 * t) * math.exp(-75.0 * t)
        
    # Main acoustic cork pop sweep (580Hz -> 210Hz)
    pop = 0.0
    if t >= 0.008:
        dt = t - 0.008
        freq = 580.0 - 370.0 * (1.0 - math.exp(-32.0 * dt))
        pop = 0.85 * math.sin(2 * math.pi * freq * dt) * math.exp(-26.0 * dt)
        
    # Glass clink resonance ring (2450Hz harmonic)
    clink = 0.0
    if t >= 0.015:
        dt = t - 0.015
        clink = 0.20 * math.sin(2 * math.pi * 2450.0 * dt) * math.exp(-15.0 * dt)
        
    return whoosh + pop + clink

# ─────────────────────────────────────────────────────────────────────────────
# 4. CRYSTAL SHIMMER CHIME (Mini-Victory Tube Clear)
# ─────────────────────────────────────────────────────────────────────────────
def sfx_solved_chime(t):
    # Pentatonic arpeggio in C Major (C5 -> E5 -> G5 -> B5 -> C6 -> E6)
    notes = [
        {"freq": 523.25, "start": 0.00, "decay": 4.5, "vol": 0.26},  # C5
        {"freq": 659.25, "start": 0.09, "decay": 4.5, "vol": 0.26},  # E5
        {"freq": 783.99, "start": 0.18, "decay": 4.5, "vol": 0.26},  # G5
        {"freq": 987.77, "start": 0.27, "decay": 4.5, "vol": 0.28},  # B5
        {"freq": 1046.50, "start": 0.36, "decay": 5.0, "vol": 0.32}, # C6
        {"freq": 1318.51, "start": 0.45, "decay": 5.5, "vol": 0.38}, # E6
    ]
    val = 0.0
    for n in notes:
        if t >= n["start"]:
            dt = t - n["start"]
            env = math.exp(-n["decay"] * dt)
            # Fundamental + shimmer octave harmonic
            fund = math.sin(2 * math.pi * n["freq"] * dt)
            harm = 0.35 * math.sin(2 * math.pi * (n["freq"] * 2.005) * dt) # slight detune for shimmer
            val += n["vol"] * (fund + harm) * env
            
    return val

# ─────────────────────────────────────────────────────────────────────────────
# 5. CRISP METALLIC COIN PICKUP / REWARD
# ─────────────────────────────────────────────────────────────────────────────
def sfx_coin_reward(t):
    # Dual high ringing bell harmonics (B5 & F#6) with metallic bell decay
    if t > 0.45:
        return 0.0
    note1 = 0.50 * math.sin(2 * math.pi * 987.77 * t) * math.exp(-12.0 * t)
    # Higher octave ping slightly delayed
    note2 = 0.0
    if t >= 0.06:
        dt = t - 0.06
        note2 = 0.65 * math.sin(2 * math.pi * 1479.98 * dt) * math.exp(-14.0 * dt)
        
    shimmer = 0.15 * math.sin(2 * math.pi * 2960.0 * t) * math.exp(-22.0 * t)
    return note1 + note2 + shimmer

# ─────────────────────────────────────────────────────────────────────────────
# 6. TIME REVERSE WATER SWOOSH (Undo / Reset)
# ─────────────────────────────────────────────────────────────────────────────
def sfx_undo_whoosh(t):
    # Swelling reversed noise and rising pitch envelope
    if t > 0.35:
        return 0.0
    # Pitch ascends from 200Hz to 900Hz then abruptly stops
    progress = t / 0.35
    freq = 200.0 + 700.0 * (progress ** 2.0)
    env = math.sin(progress * math.pi * 0.5) ** 1.5
    swoosh = 0.60 * math.sin(2 * math.pi * freq * t) * env
    air = 0.25 * math.sin(2 * math.pi * (freq * 2.4) * t) * env
    return swoosh + air

# ─────────────────────────────────────────────────────────────────────────────
# 7. SOOTHING AMBIENT OCEAN & WATER DRONE (Stereo Loop)
# ─────────────────────────────────────────────────────────────────────────────
def sfx_ambient_ocean(t):
    # Stereo ambient generative pads with deep water waves
    lfo_left = math.sin(2 * math.pi * 0.15 * t)
    lfo_right = math.sin(2 * math.pi * 0.18 * t + 0.8)
    
    # Warm sub-bass ocean resonance (98Hz - G2)
    drone = 0.18 * math.sin(2 * math.pi * 98.0 * t)
    
    # Peaceful harmonic water swell (294Hz & 392Hz)
    swell_l = 0.12 * math.sin(2 * math.pi * 294.0 * t) * (0.6 + 0.4 * lfo_left)
    swell_r = 0.12 * math.sin(2 * math.pi * 392.0 * t) * (0.6 + 0.4 * lfo_right)
    
    # High delicate water ripple layer
    ripple_l = 0.04 * math.sin(2 * math.pi * 880.0 * t) * (0.5 + 0.5 * math.sin(2 * math.pi * 1.2 * t))
    ripple_r = 0.04 * math.sin(2 * math.pi * 932.0 * t) * (0.5 + 0.5 * math.sin(2 * math.pi * 1.4 * t))
    
    left = drone + swell_l + ripple_l
    right = drone + swell_r + ripple_r
    return left, right

# ─────────────────────────────────────────────────────────────────────────────
# 8. TRIUMPHANT LEVEL VICTORY FANFARE
# ─────────────────────────────────────────────────────────────────────────────
def sfx_victory_fanfare(t):
    # Full celebratory chord progression (C -> G -> Am -> F -> C Maj9)
    chords = [
        {"notes": [261.63, 329.63, 392.00], "start": 0.00, "dur": 0.28, "vol": 0.22}, # C
        {"notes": [392.00, 493.88, 587.33], "start": 0.28, "dur": 0.28, "vol": 0.22}, # G
        {"notes": [440.00, 523.25, 659.25], "start": 0.56, "dur": 0.28, "vol": 0.24}, # Am
        {"notes": [349.23, 440.00, 523.25, 698.46], "start": 0.84, "dur": 0.35, "vol": 0.28}, # F
        {"notes": [523.25, 659.25, 783.99, 987.77, 1046.50], "start": 1.19, "dur": 1.40, "vol": 0.35}, # C Maj9 Final
    ]
    val = 0.0
    for ch in chords:
        if t >= ch["start"] and t < ch["start"] + ch["dur"] + 0.4:
            dt = t - ch["start"]
            env = math.exp(-2.2 * (dt / ch["dur"]))
            for freq in ch["notes"]:
                val += ch["vol"] * math.sin(2 * math.pi * freq * dt) * env
                # Golden brass harmonic
                val += (ch["vol"] * 0.25) * math.sin(2 * math.pi * (freq * 2.0) * dt) * env
                
    return val

if __name__ == "__main__":
    out_dir = os.path.dirname(os.path.abspath(__file__))
    print(f"Synthesizing studio game sound effects into: {out_dir}")
    
    effects = [
        ("water_drop_tap.wav", 0.18, sfx_water_drop, False),
        ("tube_pour_liquid.wav", 1.80, sfx_pour_stream, False),
        ("cork_snap_lock.wav", 0.30, sfx_cork_lock, False),
        ("solved_chime_sparkle.wav", 1.20, sfx_solved_chime, False),
        ("coin_pickup.wav", 0.45, sfx_coin_reward, False),
        ("undo_rewind_whoosh.wav", 0.35, sfx_undo_whoosh, False),
        ("victory_fanfare_orchestral.wav", 2.60, sfx_victory_fanfare, False),
        ("ambient_ocean_loop.wav", 6.00, sfx_ambient_ocean, True),
    ]
    
    for filename, dur, func, stereo in effects:
        target_path = os.path.join(out_dir, filename)
        write_wav(target_path, dur, func, stereo)
        print(f" [OK] Generated {filename} ({dur}s, {'Stereo' if stereo else 'Mono'} 44.1kHz)")
        
    print("\nAll studio-grade audio assets successfully generated!")

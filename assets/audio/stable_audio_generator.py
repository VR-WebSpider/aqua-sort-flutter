"""
=============================================================================
 WebSpider Studios - Open-Source Audio AI Generation Toolkit
 Supports:
   1. Stable Audio Open 1.0 (stabilityai/stable-audio-open-1.0 via Diffusers)
   2. Meta AudioCraft (facebook/audiocraft - AudioGen & MusicGen)
=============================================================================
"""

import os
import sys
import argparse

def generate_with_audiocraft(prompt: str, duration: int = 5, output_file: str = "ai_generated_sfx.wav", model_type: str = "facebook/audiogen-medium"):
    """
    Generates sound effects or music using Meta's open-source AudioCraft pipeline.
    Requirements: pip install audiocraft torch torchaudio
    """
    try:
        import torch
        import torchaudio
        from audiocraft.models import AudioGen, MusicGen
        from audiocraft.data.audio import audio_write
        
        print(f"[*] Initializing AudioCraft model: {model_type}...")
        device = "cuda" if torch.cuda.is_available() else "cpu"
        
        if "musicgen" in model_type.lower():
            model = MusicGen.get_pretrained(model_type, device=device)
        else:
            model = AudioGen.get_pretrained(model_type, device=device)
            
        model.set_generation_params(duration=duration)
        print(f"[*] Synthesizing prompt: '{prompt}' (Duration: {duration}s on {device})...")
        
        wav = model.generate([prompt])
        
        base_name = os.path.splitext(output_file)[0]
        audio_write(base_name, wav[0].cpu(), model.sample_rate, strategy="loudness", loudness_compressor=True)
        print(f"[+] Audio generation complete: {output_file}")
        return True
    except ImportError:
        print("[!] AudioCraft not installed. Run: pip install git+https://github.com/facebookresearch/audiocraft.git")
        return False
    except Exception as e:
        print(f"[!] Error during AudioCraft generation: {e}")
        return False

def generate_with_stable_audio(prompt: str, duration: int = 8, output_file: str = "stable_audio_sfx.wav"):
    """
    Generates audio using Stability AI's Stable Audio Open 1.0.
    Requirements: pip install diffusers transformers torch torchaudio
    """
    try:
        import torch
        import torchaudio
        from diffusers import StableAudioPipeline
        
        print("[*] Initializing Stable Audio Open 1.0 Pipeline...")
        device = "cuda" if torch.cuda.is_available() else "cpu"
        pipe = StableAudioPipeline.from_pretrained(
            "stabilityai/stable-audio-open-1.0",
            torch_dtype=torch.float16 if device == "cuda" else torch.float32
        )
        pipe = pipe.to(device)
        
        print(f"[*] Synthesizing with Stable Audio: '{prompt}'...")
        audio = pipe(
            prompt,
            negative_prompt="Low quality, distorted, muffled, noisy, clipping",
            num_inference_steps=100,
            audio_end_in_s=duration,
        ).audios
        
        output = audio[0].T.float().cpu()
        torchaudio.save(output_file, output, pipe.vae.sampling_rate)
        print(f"[+] Stable Audio output saved to: {output_file}")
        return True
    except ImportError:
        print("[!] Stable Audio requirements not installed. Run: pip install diffusers transformers accelerate torch")
        return False
    except Exception as e:
        print(f"[!] Error during Stable Audio generation: {e}")
        return False

# Preset prompts for Aqua Sort game themes
PRESETS = {
    "water_drop": "Crisp acoustic single water drop falling into crystal test tube, satisfying tactile click, clean high fidelity",
    "water_pour": "Bubbly liquid water pouring smoothly into glass tube, gentle fluid swirl, calming aquatic sound",
    "cork_pop": "Airtight rubber glass stopper cap locking with satisfying suction pop, clean tactile seal",
    "crystal_sparkle": "Magical pentatonic crystal chime arpeggio, celestial shimmer, peaceful puzzle win chime",
    "coin_chime": "Crisp metallic golden coin pickup chime, high bell resonance, rewarding casino ring",
    "victory_fanfare": "Triumphant gentle synth chime fanfare, euphoric game level complete celebration, warm strings",
    "ambient_ocean": "Soothing underwater ambient drone pad, peaceful aquatic waves, relaxing puzzle game background music",
}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="WebSpider Studios - Open-Source Audio Generator")
    parser.add_argument("--preset", type=str, choices=list(PRESETS.keys()), help="Preset sound effect to generate")
    parser.add_argument("--prompt", type=str, help="Custom prompt for audio generation")
    parser.add_argument("--duration", type=int, default=5, help="Duration in seconds")
    parser.add_argument("--output", type=str, default="generated_sfx.wav", help="Output WAV filename")
    parser.add_argument("--engine", type=str, choices=["audiocraft", "stable-audio"], default="audiocraft")
    
    args = parser.parse_args()
    
    prompt = args.prompt or (PRESETS.get(args.preset) if args.preset else None)
    
    if not prompt:
        print("WebSpider Studios Audio AI Generator")
        print("\nAvailable Presets:")
        for k, v in PRESETS.items():
            print(f"  --preset {k:16} : \"{v}\"")
        print("\nExample Usage:")
        print("  python stable_audio_generator.py --preset water_pour --output tube_pour.wav")
        print("  python stable_audio_generator.py --prompt \"glass bottle clink with water ripple\" --output clink.wav")
        sys.exit(0)
        
    if args.engine == "stable-audio":
        generate_with_stable_audio(prompt, args.duration, args.output)
    else:
        generate_with_audiocraft(prompt, args.duration, args.output)

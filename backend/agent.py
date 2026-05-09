import os
import httpx
from dotenv import load_dotenv
from fastapi import HTTPException

# Load it here at the top!
load_dotenv()

ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")

async def transcribe_audio(audio_bytes: bytes) -> str:
    # Fail Fast Check
    if not ELEVENLABS_API_KEY:
        print(">>> [ERROR] ELEVENLABS_API_KEY is missing from .env!")
        raise HTTPException(status_code=500, detail="Server configuration error: Missing API Key")

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                "https://api.elevenlabs.io/v1/speech-to-text",
                headers={
                    "xi-api-key": ELEVENLABS_API_KEY
                },
                files={
                    "file": ("audio.m4a", audio_bytes, "audio/mp4")
                },
                data={
                    "model_id": "scribe_v1" 
                },
                timeout=30.0
            )
            response.raise_for_status()
            return response.json().get("text", "")
        except Exception as e:
            print(f">>> [ERROR] ElevenLabs Call Failed: {e}")
            raise e
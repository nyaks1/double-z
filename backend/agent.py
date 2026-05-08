import httpx
import os
from fastapi import HTTPException

ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")

async def transcribe_audio(audio_bytes: bytes) -> str:
    # 1. Use an async client to prevent blocking the event loop
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                "https://api.elevenlabs.io/v1/speech-to-text",
                headers={
                    "xi-api-key": ELEVENLABS_API_KEY
                },
                files={
                    "file": ("audio.wav", audio_bytes, "audio/wav")
                },
                data={
                    "model_id": "scribe_v1" # v1 is the production stable for STT
                },
                timeout=30.0 # Transcription takes time; don't let it timeout early
            )
            
            # 2. Check for HTTP errors (4xx, 5xx) before parsing
            response.raise_for_status()
            
            result = response.json()
            return result.get("text", "")

        except httpx.HTTPStatusError as e:
            print(f"ElevenLabs API Error: {e.response.text}")
            raise HTTPException(status_code=e.response.status_code, detail="Transcription service error")
        except Exception as e:
            print(f"Unexpected Backend Error: {e}")
            raise HTTPException(status_code=500, detail="Internal server error")
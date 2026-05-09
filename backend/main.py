import json
import time
import re
import os
from typing import Optional
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
import uvicorn
from dotenv import load_dotenv
load_dotenv()


from agent import transcribe_audio
from resolver import resolve_contact
from transaction import build_create_escrow_tx
from llm_parser import parse_intent_with_llm
from solders.pubkey import Pubkey

MAX_FILE_SIZE = 5 * 1024 * 1024  # 5 MB

app = FastAPI(title="DoubleZ: Zero-Trust Voice Agent")


@app.post("/process_intent")
async def process_intent(
    wallet_pubkey: str = Form(...),
    contacts: str = Form(...),
    audio: Optional[UploadFile] = File(None),
    text_intent: Optional[str] = Form(None)
):
    print(">>> [DEBUG] Request received! Validating inputs...")
    
    # 1. Validate Pubkey
    try:
        Pubkey.from_string(wallet_pubkey)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid Solana wallet_pubkey.")

    # 2. Validate File Size
    if audio:
        audio_bytes = await audio.read()
        if len(audio_bytes) > MAX_FILE_SIZE:
            raise HTTPException(status_code=413, detail="Audio file too large. Max 5MB.")
    elif not text_intent:
        raise HTTPException(status_code=400, detail="Must provide either audio or text_intent")

    # 3. Capture the exact moment (the Unique ID for the PDA seeds)
    timestamp = int(time.time())

    # Check MOCK_AI flag
    MOCK_AI = os.getenv("MOCK_AI", "false").lower() == "true"
    
    if MOCK_AI:
        print(">>> [MOCK_AI] Mock mode enabled. Bypassing ElevenLabs and LLM.")
        transcript = text_intent if text_intent else "Send 5 SOL to Nyaks"
        amount = 5.0
        target_name = "Nyaks"
    else:
        # 4. Convert Audio to Text (The Ears)
        if audio:
            transcript = await transcribe_audio(audio_bytes)
            if not transcript:
                raise HTTPException(status_code=500, detail="Voice transcription failed.")
        else:
            transcript = text_intent
            
        # 5. Parse intent from transcript
        amount, target_name = await parse_intent_with_llm(transcript)
        if not amount or not target_name:
            raise HTTPException(
                status_code=400, 
                detail=f"Could not parse intent from: '{transcript}'. Try: 'Send [amount] SOL to [name]'"
            )

    # 4. Map name to Pubkey (The Brain)
    try:
        contacts_dict = json.loads(contacts)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid contacts format")
        
    recipient_pubkey, error = resolve_contact(target_name, contacts_dict)
    
    if error:
        raise HTTPException(status_code=400, detail=error)

    # 5. Build the Solana Instruction (The Architect)
    try:
        ix_b64, pda_address = build_create_escrow_tx(
            sender_pubkey=wallet_pubkey,
            recipient_pubkey=recipient_pubkey,
            amount_sol=amount,
            timestamp=timestamp
        )

        # 6. Response (Final Payload)
        return {
            "status": "ready_for_signature",
            "transcript": transcript,
            "parsed": {
                "amount": amount,
                "recipient_name": target_name,
                "recipient_pubkey": recipient_pubkey
            },
            "pda_vault": pda_address,
            "timestamp": timestamp,
            "transaction_payload": ix_b64
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transaction building failed: {str(e)}")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
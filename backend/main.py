import json
import time
import re
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
import uvicorn
from dotenv import load_dotenv
load_dotenv()


from agent import transcribe_audio
from resolver import resolve_contact
from transaction import build_create_escrow_tx
from llm_parser import parse_intent_with_llm

app = FastAPI(title="DoubleZ: Zero-Trust Voice Agent")


@app.post("/process_intent")
async def process_intent(
    audio: UploadFile = File(...),
    wallet_pubkey: str = Form(...),
    contacts: str = Form(...)
):
    print(">>> [DEBUG] Request received! Starting transcription...") # ADD THIS
    # ... rest of your code
    # 1. Capture the exact moment (the Unique ID for the PDA seeds)
    timestamp = int(time.time())

    # 2. Convert Audio to Text (The Ears)
    audio_bytes = await audio.read()
    transcript = await transcribe_audio(audio_bytes)
    
    if not transcript:
        raise HTTPException(status_code=500, detail="Voice transcription failed.")

    # 3. Parse intent from transcript
    amount, target_name = await parse_intent_with_llm(transcript)
    if not amount or not target_name:
        raise HTTPException(
            status_code=400, 
            detail=f"Could not parse intent from: '{transcript}'. Try: 'Send [amount] SOL to [name]'"
        )

    # 4. Map name to Pubkey (The Brain)
    contacts_dict = json.loads(contacts)
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
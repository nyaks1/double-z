from fastapi import FastAPI, File, UploadFile, Form, HTTPException
import json
import uvicorn

app = FastAPI(title="DoubleZ Agent API")

@app.post("/process_intent")
async def process_intent(
    audio: UploadFile = File(...),
    wallet_pubkey: str = Form(...),
    contacts: str = Form(...) # We receive this as a JSON string
):
    try:
        # 1. Parse the contacts string back into a Python dictionary
        contacts_dict = json.loads(contacts)
        
        # Log the incoming state to prove the data arrived (Remove in production)
        print(f"Received audio file: {audio.filename}")
        print(f"Sender Pubkey: {wallet_pubkey}")
        print(f"Loaded {len(contacts_dict)} contacts.")

        # --- THE PIPELINE (We build these next) ---
        # 2. transcript = await transcribe_audio(audio)
        # 3. recipient_pubkey, amount = parse_and_resolve(transcript, contacts_dict)
        # 4. unsigned_tx = build_transaction(wallet_pubkey, recipient_pubkey, amount)
        
        # Return the payload and instantly forget everything.
        return {
            "status": "success",
            "transcript": "Mock transcript: Send 10 SOL to Tsamaiso",
            "transaction_payload": "Mock_Base64_Transaction_String"
        }

    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid contacts JSON format")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
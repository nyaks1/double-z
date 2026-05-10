# Double Z — Zero Trust, Zero Memory

> Voice-activated, stateless payment agent on Solana. Speaks 32 languages. Remembers nothing.

**Tagline:** *Stateless by architecture, not policy.*

---

## What Is DoubleZ?

DoubleZ lets you send a Solana payment by speaking naturally in any of 32 languages. A stateless AI agent parses your intent, builds an unsigned transaction, and returns it to your phone — then **forgets everything**. Your wallet signs locally. Nothing is stored on any server.

---

## How It Works

1. **You speak:** *"Send 10 SOL to Tsamaiso"*
2. **Flutter** captures audio, sends it with your wallet pubkey and local contacts to the Python agent.
3. **ElevenLabs** transcribes in your language — 32 supported.
4. **LLM Brain** extracts the intent (amount + recipient) from the transcript.
5. **Python agent** fuzzy-matches the recipient name (handles African names natively), builds an unsigned transaction.
6. **Agent forgets everything** — no session, no log, no database.
7. **Flutter** deserializes the transaction locally and verifies it matches your spoken intent.
8. **You confirm** — big, bold numbers on screen.
9. **Wallet signs locally** via Solana Mobile Wallet Adapter.
10. **Solana Anchor program** receives the signed transaction, locks funds in a PDA, releases on recipient's on-chain signature.

---

## Security Design

| Threat | Mitigation |
|---|---|
| Voice replay / deepfake | Voice is input only — wallet signs on-chain |
| Server data breach | No database to breach. Ever. |
| Transaction substitution (MitM) | Flutter verifies tx locally before confirmation |
| Fuzzy ear error (name mishearing) | `thefuzz` 80% match threshold + LLM disambiguation |
| Fat finger / wrong amount | Human-readable confirmation, explicit tap required |
| Key custody | Private key never leaves the device |

---

## Architecture

```
Flutter (mobile)
    │  multipart: audio + wallet_pubkey + contacts{}
    ▼
FastAPI Agent (Render)  ←→  ElevenLabs (Transcription)
    │                   ←→  LLM (Intent Extraction)
    │  unsigned transaction payload
    ▼
Flutter (Verify Tx locally → Wallet signs)
    │  signed transaction
    ▼
Solana Anchor program
    └── PDA created (sender_pubkey + timestamp seed)
    └── Funds locked in escrow
    └── Released on recipient on-chain signature
    └── Account closed · rent reclaimed
```

---

## Project Structure

```bash
double-z/
├── anchor/
│   └── programs/doublezero/src/
│       └── lib.rs                  # create_escrow() + release_funds()
├── backend/                        ← Python FastAPI (Render)
│   ├── main.py                     # Entry point & routes
│   ├── agent.py                    # ElevenLabs integration
│   ├── llm_parser.py               # LLM-based intent extraction
│   ├── resolver.py                 # Name matching & contact resolution
│   ├── transaction.py              # Solders-based tx construction
│   └── .env.example                # Configuration template
└── mobile/                         ← Flutter App
    ├── pubspec.yaml
    ├── assets/
    │   └── logo.png                # App branding
    ├── android/                    ← Android build config
    └── lib/
        ├── main.dart               # App entry, routing, theme
        ├── screens/
        │   ├── welcome.dart        # Animated landing screen
        │   ├── home.dart           # Voice + text input, amplitude viz
        │   └── confirm.dart        # Transaction confirmation screen
        └── services/
            ├── audio.dart          # Record, pause, cancel, relay to backend
            └── wallet.dart         # Local tx verification & MWA signing
```

---

## Tech Stack

| Layer | Tech |
|---|---|
| **On-chain** | Rust · Anchor 1.0.2 · Solana Devnet |
| **Backend** | Python 3.14 · FastAPI · Render |
| **Intelligence** | LLM Intent Parsing · ElevenLabs Speech-to-Text |
| **Name Resolution** | `thefuzz` · python-Levenshtein |
| **Mobile** | Flutter · Dart · Solana Mobile Wallet Adapter |

---

## Setup

### Backend (Render)
The backend is configured for deployment on Render using the `requirements.txt`. To run locally:
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Add API keys to .env
uvicorn main:app --reload
```

### Anchor (Solana)
1. Build and deploy `anchor/programs/doublezero/src/lib.rs` to Devnet.
2. Update `PROGRAM_ID` in the backend `.env`.

### Flutter
```bash
cd mobile
flutter pub get
flutter run
```

---

## Deployment

- **Anchor:** Deployed to Solana Devnet.
- **Backend:** Hosted on **Render** (Auto-deploy on git push).
- **Mobile:** Android APK (Debug/Release).

> [!NOTE]
> **Render Free Tier Notice:** The backend is hosted on Render's free tier. If the first request is slow, please wait ~30 seconds for the instance to "wake up." Subsequent requests will be instant.

---

## Roadmap

### V2: Solana Name Service (SNS)
Integrate SNS to resolve `.sol` domains directly:
1. User says "Send 5 SOL to nyaks.sol".
2. LLM extracts `.sol` domain.
3. Backend queries SNS on Mainnet and returns the pubkey.

### V2: Real Wallet Integration
Move from Mock MWA signing to full **Phantom/Solflare** support via Solana Mobile Wallet Adapter.

---

## Built By

**Nyaks** · WeThinkCode_ · Gauteng, South Africa
*Zero trust, zero memory. Built for the continent.*
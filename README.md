# Double Z — Zero Trust, Zero Memory

> Voice-activated, stateless payment agent on Solana. Speaks 32 languages. Remembers nothing.

**Tagline:** *Stateless by architecture, not policy.*

---

## What Is DoubleZ?

DoubleZ lets you send a Solana payment by speaking naturally in any of 32 languages. A stateless AI agent parses your intent, builds an unsigned transaction, and returns it to your phone — then **forgets everything**. Your wallet signs locally. Nothing is stored on any server.

---

## How It Works

1. **You speak:** *"Send 10 SOL to Tsamaiso"*
2. **Flutter** captures audio, sends it with your wallet pubkey and local contacts to the Python agent
3. **ElevenLabs** transcribes in your language — 32 supported
4. **Python agent** fuzzy-matches the recipient name (handles African names natively), builds an unsigned transaction
5. **Agent forgets everything** — no session, no log, no database
6. **Flutter** deserializes the transaction locally and verifies it matches your spoken intent
7. **You confirm** — big, bold numbers on screen
8. **Wallet signs locally** via Solana Mobile Wallet Adapter
9. **Solana Anchor program** receives the signed transaction, locks funds in a PDA, releases on recipient's on-chain signature

---

## Hackathon Tracks

- **Solana Main Track ($10K)** — Rust Anchor escrow program deployed to devnet
- **ElevenLabs Track** — Multilingual stateless voice agent, 32 languages

---

## Security Design

| Threat | Mitigation |
|---|---|
| Voice replay / deepfake | Voice is input only — wallet signs on-chain |
| Server data breach | No database to breach. Ever. |
| Transaction substitution (MitM) | Flutter verifies tx locally before confirmation |
| Fuzzy ear error (name mishearing) | `thefuzz` 80% match threshold + ambiguous fallback |
| Fat finger / wrong amount | Human-readable confirmation, explicit tap required |
| Key custody | Private key never leaves the device |

---

## Architecture

```
Flutter (mobile)
    │  multipart: audio + wallet_pubkey + contacts{}
    ▼
Python FastAPI agent  ←→  ElevenLabs (transcribe · 32 languages)
(stateless)
    │  unsigned transaction payload
    ▼
Flutter (verify tx locally → wallet signs)
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

```
double-z/
├── anchor/
│   └── programs/doublezero/src/
│       └── lib.rs                  # create_escrow() + release_funds()
├── backend/
│   ├── main.py                     # FastAPI routes
│   ├── agent.py                    # ElevenLabs + thefuzz intent parsing
│   ├── transaction.py              # Build unsigned Solana transaction
│   └── .env.example                # API key template (never commit .env)
└── mobile/
    ├── lib/
    │   ├── main.dart
    │   ├── screens/
    │   │   ├── home.dart           # Voice record screen
    │   │   └── confirm.dart        # Confirmation screen (big bold numbers)
    │   └── services/
    │       ├── audio.dart          # Record + multipart POST
    │       └── wallet.dart         # Local tx verify + sign + broadcast
    └── pubspec.yaml
```

---

## Tech Stack

| Layer | Tech |
|---|---|
| On-chain | Rust · Anchor 1.0.2 · Solana devnet |
| Backend | Python 3.14 · FastAPI · ElevenLabs SDK |
| Name resolution | thefuzz · python-Levenshtein |
| Mobile | Flutter · Dart · Solana Mobile Wallet Adapter |
| Voice | ElevenLabs Speech-to-Text · 32 languages |

---

## Setup

**Backend**
```bash
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn elevenlabs thefuzz python-Levenshtein python-dotenv solders solana
cp .env.example .env
# Add ELEVENLABS_API_KEY to .env
uvicorn main:app --reload
```

**Anchor (Solana Playground)**
```
1. Open beta.solpg.io
2. New project → Anchor → paste lib.rs contents
3. Build → Deploy to devnet
4. Copy Program ID → add to backend/.env as PROGRAM_ID
```

**Flutter**
```bash
flutter pub get
flutter run
```

---

## Deployment

- Anchor program deployed to Solana devnet
- Program ID: `[see .env after deployment]`
- Backend: local · uvicorn
- Mobile: Android APK

---

## Roadmap

### V2: Solana Name Service Resolution
Currently DoubleZ resolves recipient names via a local 
contact list on the Flutter app. V2 introduces SNS fallback:

1. User says "Send 5 SOL to tsamaiso.sol"
2. LLM parser detects `.sol` suffix in transcript
3. Backend queries SNS program on mainnet:
   `namesLPaSamrsfkqtunJupyXBFK65AtmJ7oqtyX2WM`
4. Returns associated wallet pubkey
5. Falls back to local contacts if SNS lookup fails

This removes the dependency on pre-loaded contacts entirely —
any `.sol` domain becomes a valid payment destination.

### Other Future Plans
- **LI.FI cross-chain** — fund escrow from Ethereum, Polygon, or any supported chain
- **Acoustic sanitization** — ElevenLabs voice re-synthesis to eliminate voiceprint before relay
- **On-device ML** — local intent parsing, fully offline

---

## Built By

**Nyaks** · WeThinkCode_ · Gauteng, South Africa
FinTech · Cybersecurity · Mobile Dev

*Zero trust, zero memory. Built for the continent.*
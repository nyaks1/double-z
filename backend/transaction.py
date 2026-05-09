import os
from dotenv import load_dotenv
from solders.pubkey import Pubkey
import struct
import base64
import hashlib
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.system_program import ID as SYS_PROG_ID

load_dotenv()

# Stress test the environment variable
raw_program_id = os.getenv("PROGRAM_ID")
if not raw_program_id:
    raise RuntimeError("CRITICAL ERROR: PROGRAM_ID not found in .env file!")

# To get the Anchor discriminator: sha256("global:create_escrow")[0:8]
def get_discriminator(name: str) -> bytes:
    return hashlib.sha256(f"global:{name}".encode()).digest()[:8]
    

def build_create_escrow_tx(sender_pubkey: str, recipient_pubkey: str, amount_sol: float, timestamp: int):
    PROGRAM_ID = Pubkey.from_string(os.getenv("PROGRAM_ID"))
    sender = Pubkey.from_string(sender_pubkey)
    recipient = Pubkey.from_string(recipient_pubkey)
    amount_lamports = int(amount_sol * 1_000_000_000)

    pda_pubkey, _ = Pubkey.find_program_address(
        [b"escrow", bytes(sender), struct.pack("<q", timestamp)],
        PROGRAM_ID
    )

    # Use the real Anchor discriminator
    data = get_discriminator("create_escrow") + struct.pack("<Qq", amount_lamports, timestamp)

    accounts = [
        AccountMeta(pubkey=sender, is_signer=True, is_writable=True),
        AccountMeta(pubkey=recipient, is_signer=False, is_writable=False),
        AccountMeta(pubkey=pda_pubkey, is_signer=False, is_writable=True),
        AccountMeta(pubkey=SYS_PROG_ID, is_signer=False, is_writable=False),
    ]

    ix = Instruction(PROGRAM_ID, data, accounts)
    return base64.b64encode(bytes(ix)).decode("utf-8"), str(pda_pubkey)
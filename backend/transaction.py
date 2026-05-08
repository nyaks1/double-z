import os
from dotenv import load_dotenv
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.transaction import Transaction
from solana.rpc.async_api import AsyncClient
import base64
import struct

load_dotenv()

PROGRAM_ID = Pubkey.from_string(os.getenv("PROGRAM_ID"))

def build_create_escrow_tx(
    sender_pubkey: str, 
    recipient_pubkey: str, 
    amount_sol: float, 
    timestamp: int
):
    """
    Builds an unsigned transaction for the DoubleZ Anchor program.
    """
    sender = Pubkey.from_string(sender_pubkey)
    recipient = Pubkey.from_string(recipient_pubkey)
    amount_lamports = int(amount_sol * 1_000_000_000)

    # 1. Derive the PDA (The Vault)
    # Seeds: "escrow" + sender_pubkey + timestamp (i64)
    pda_pubkey, _ = Pubkey.find_program_address(
        [
            b"escrow", 
            bytes(sender), 
            struct.pack("<q", timestamp) # Little-endian 64-bit integer
        ],
        PROGRAM_ID
    )

    # 2. Build the Instruction Data
    # Anchor instruction discriminators are the first 8 bytes of the Sha256 hash
    # of the string "global:create_escrow"
    # For this hackathon, we can use the IDL or manually compute it.
    # Instruction Data: [Discriminator (8b)] + [Amount (8b)] + [Timestamp (8b)]
    discriminator = b"\x8d\x16\x1a\x1a\x98\x1b\x91\x91" # Example: Replace with your actual disc.
    data = discriminator + struct.pack("<QQ", amount_lamports, timestamp)

    # 3. Define the Accounts
    accounts = [
        AccountMeta(pubkey=sender, is_signer=True, is_writable=True),
        AccountMeta(pubkey=recipient, is_signer=False, is_writable=False),
        AccountMeta(pubkey=pda_pubkey, is_signer=False, is_writable=True),
        AccountMeta(pubkey=Pubkey.from_string("11111111111111111111111111111111"), is_signer=False, is_writable=False), # System Program
    ]

    # 4. Create the Instruction
    ix = Instruction(PROGRAM_ID, data, accounts)
    
    # We return the base64 encoded instruction so Flutter can deserialize it
    return base64.b64encode(bytes(ix)).decode("utf-8"), str(pda_pubkey)

# --- THE STRESS TEST ---
if __name__ == "__main__":
    # Test with your actual wallet address
    ix_b64, pda = build_create_escrow_tx(
        "GZnucqsYkgj9jpT48WdyzRuGMuvQnNSiDciZ2EtVRPuZ", 
        "GZnucqsYkgj9jpT48WdyzRuGMuvQnNSiDciZ2EtVRPuZ", 
        0.1, 
        1715155200
    )
    print(f"Generated PDA: {pda}")
    print(f"Instruction Payload: {ix_b64}")
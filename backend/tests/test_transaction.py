import pytest
import os
import base64
import sys

# Mock the environment variable for testing BEFORE importing module
os.environ["PROGRAM_ID"] = "11111111111111111111111111111111"

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from transaction import build_create_escrow_tx

def test_build_create_escrow_tx():
    sender = "4Nd1m1aCGcgKpzRyVDcw1XpYwJvL6o8k3sQ1QXZz9N3X"
    recipient = "7N8c8v4UqHxbJz3Q1QXZz9N3X4Nd1m1aCGcgKpzRyVDc"
    amount = 5.5
    timestamp = 1684300000

    ix_b64, pda_address = build_create_escrow_tx(
        sender_pubkey=sender,
        recipient_pubkey=recipient,
        amount_sol=amount,
        timestamp=timestamp
    )

    assert ix_b64 is not None
    assert isinstance(ix_b64, str)
    
    # Verify we can decode it back
    decoded_ix = base64.b64decode(ix_b64)
    assert len(decoded_ix) > 0

    assert pda_address is not None
    assert isinstance(pda_address, str)
    assert len(pda_address) > 30  # basic base58 length check

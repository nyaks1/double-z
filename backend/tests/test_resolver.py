import pytest
from resolver import resolve_contact

def test_resolve_contact_exact_match():
    contacts = {"Nyaks": "pubkey1", "Tsamaiso": "pubkey2"}
    pubkey, error = resolve_contact("Nyaks", contacts)
    assert error is None
    assert pubkey == "pubkey1"

def test_resolve_contact_case_insensitive():
    contacts = {"Nyaks": "pubkey1", "Tsamaiso": "pubkey2"}
    pubkey, error = resolve_contact("nyaks", contacts)
    assert error is None
    assert pubkey == "pubkey1"

def test_resolve_contact_fuzzy_match():
    contacts = {"Tsamaiso": "pubkey1"}
    # Slightly misspelled
    pubkey, error = resolve_contact("Tsamiso", contacts)
    assert error is None
    assert pubkey == "pubkey1"

def test_resolve_contact_low_confidence():
    contacts = {"Nyaks": "pubkey1"}
    pubkey, error = resolve_contact("John", contacts)
    assert error is not None
    assert "Low confidence match" in error
    assert pubkey is None

def test_resolve_contact_ambiguous():
    contacts = {"Jane Doe": "pubkey1", "John Doe": "pubkey2"}
    # "Doe" is ambiguous, distances to both might be similar
    pubkey, error = resolve_contact("Doe", contacts)
    assert error is not None
    assert "Ambiguous name" in error
    assert pubkey is None

def test_resolve_contact_empty_contacts():
    pubkey, error = resolve_contact("Nyaks", {})
    assert error is not None
    assert "No contacts provided" in error
    assert pubkey is None

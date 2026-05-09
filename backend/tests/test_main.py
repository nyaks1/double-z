import pytest
from main import extract_intent

def test_extract_intent_basic():
    amount, name = extract_intent("Send 5 sol to Nyaks")
    assert amount == 5.0
    assert name == "Nyaks"

def test_extract_intent_decimal():
    amount, name = extract_intent("Send 2.5 sol to Tsamaiso")
    assert amount == 2.5
    assert name == "Tsamaiso"

def test_extract_intent_word_numbers():
    amount, name = extract_intent("Send five sol to Alice")
    assert amount == 5.0
    assert name == "Alice"

    amount, name = extract_intent("Send two point five sol to Bob")
    assert amount == 2.5
    assert name == "Bob"

def test_extract_intent_case_insensitive():
    amount, name = extract_intent("SEND 10 SOL TO JOHN")
    assert amount == 10.0
    assert name == "John"

def test_extract_intent_punctuation():
    amount, name = extract_intent("Send 1 sol to Eve.")
    assert amount == 1.0
    assert name == "Eve"

def test_extract_intent_invalid():
    amount, name = extract_intent("Send money to Alice")
    assert amount is None
    assert name is None

    amount, name = extract_intent("Send 5 sol")
    assert amount is None
    assert name is None

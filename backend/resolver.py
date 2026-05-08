from thefuzz import process

def resolve_contact(spoken_name: str, contacts: dict):
    """
    Takes a name from a transcript and matches it against a dictionary
    of contacts using Levenshtein distance.
    """
    if not contacts:
        return None, "No contacts provided."

    # 1. Extract the best match and its score
    # process.extractOne returns (match, score)
    match, score = process.extractOne(spoken_name, contacts.keys())

    # 2. Strict threshold for security. 
    # If it's less than 80% similar, we don't risk it.
    if score >= 80:
        return contacts[match], None
    
    return None, f"Ambiguous name: '{spoken_name}'. Closest match: '{match}' ({score}%). Please be more specific."

# --- QUICK TEST ---
if __name__ == "__main__":
    test_contacts = {
        "Tsamaiso": "GZnucqsYkgj9jpT48WdyzRuGMuvQnNSiDciZ2EtVRPuZ",
        "Alice": "7xKp...dummy_address",
    }
    
    # Simulate a slightly mispronounced or mis-transcribed name
    name_to_test = "Somaiso" 
    address, error = resolve_contact(name_to_test, test_contacts)
    
    if error:
        print(f"Error: {error}")
    else:
        print(f"Resolved '{name_to_test}' to {address}")
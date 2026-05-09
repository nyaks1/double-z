from thefuzz import process

def resolve_contact(spoken_name: str, contacts: dict):
    if not contacts:
        return None, "No contacts provided."

    # 1. Sanitize input
    query = spoken_name.strip().lower()
    choices = {k.lower(): k for k in contacts.keys()} # Map lowered to original

    # 2. Get top 2 matches to check for ambiguity
    results = process.extract(query, choices.keys(), limit=2)
    
    if not results:
        return None, f"No match found for '{spoken_name}'."

    best_match, score = results[0][0], results[0][1]
    
    # Security Threshold
    if score < 80:
        return None, f"Low confidence match ({score}%). Please be more specific."

    # Ambiguity Check: If the second best match is too close (within 10 points)
    if len(results) > 1:
        second_match, second_score = results[1][0], results[1][1]
        if (score - second_score) < 10:
            return None, f"Ambiguous name. Did you mean {choices[best_match]} or {choices[second_match]}?"

    return contacts[choices[best_match]], None
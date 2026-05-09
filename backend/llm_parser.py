import os
import json
from groq import AsyncGroq
from dotenv import load_dotenv

load_dotenv()

async def parse_intent_with_llm(transcript: str):
    """
    Takes a transcript in any language and uses Llama-3 via Groq to extract the 
    payment amount and recipient name into a structured JSON format.
    """
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key:
        print(">>> [ERROR] GROQ_API_KEY is missing from .env!")
        return None, None

    client = AsyncGroq(api_key=api_key)
    
    prompt = f"""You are a stateless payment intent parser.
Your job is to extract the payment amount (as a float) and the recipient's name (as a string) from the user's transcript.
The transcript may be in any language (English, Spanish, Swahili, etc).
Return ONLY a valid JSON object with the keys "amount" and "recipient". Do not include any other text or markdown formatting.
If you cannot determine the amount or recipient, return null for those fields.

Transcript: "{transcript}"
"""

    try:
        response = await client.chat.completions.create(
            messages=[
                {"role": "system", "content": "You output only valid JSON."},
                {"role": "user", "content": prompt}
            ],
            model="llama3-8b-8192",
            temperature=0,
            response_format={"type": "json_object"}
        )
        
        output = response.choices[0].message.content
        data = json.loads(output)
        
        amount = data.get("amount")
        recipient = data.get("recipient")
        
        # Ensure name is capitalized for the fuzzy matcher
        if recipient and isinstance(recipient, str):
            recipient = recipient.strip().title()
            
        return amount, recipient
    except Exception as e:
        print(f">>> [ERROR] LLM Parsing Failed: {e}")
        return None, None

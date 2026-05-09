import pytest
from unittest.mock import AsyncMock, patch
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from llm_parser import parse_intent_with_llm

@pytest.mark.asyncio
async def test_parse_intent_with_llm_basic():
    # Mock the AsyncGroq client
    with patch("llm_parser.AsyncGroq") as mock_groq:
        mock_client = AsyncMock()
        mock_groq.return_value = mock_client
        
        # Mock the response structure
        mock_message = AsyncMock()
        mock_message.content = '{"amount": 5.0, "recipient": "Nyaks"}'
        mock_choice = AsyncMock()
        mock_choice.message = mock_message
        mock_response = AsyncMock()
        mock_response.choices = [mock_choice]
        
        mock_client.chat.completions.create.return_value = mock_response
        
        # Assume GROQ_API_KEY is set via os.environ for this test
        with patch("os.getenv", return_value="dummy_key"):
            amount, name = await parse_intent_with_llm("Send 5 sol to Nyaks")
            
            assert amount == 5.0
            assert name == "Nyaks"

@pytest.mark.asyncio
async def test_parse_intent_with_llm_foreign_language():
    with patch("llm_parser.AsyncGroq") as mock_groq:
        mock_client = AsyncMock()
        mock_groq.return_value = mock_client
        
        mock_message = AsyncMock()
        mock_message.content = '{"amount": 10.0, "recipient": "Tsamaiso"}'
        mock_choice = AsyncMock()
        mock_choice.message = mock_message
        mock_response = AsyncMock()
        mock_response.choices = [mock_choice]
        
        mock_client.chat.completions.create.return_value = mock_response
        
        with patch("os.getenv", return_value="dummy_key"):
            amount, name = await parse_intent_with_llm("Tsamaiso tse 10 SOL ho Nyaks") # mock LLM returns Tsamaiso
            
            assert amount == 10.0
            assert name == "Tsamaiso"

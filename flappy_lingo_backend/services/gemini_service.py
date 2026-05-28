import os
import json
import re
import random
import requests
from google import genai
from dotenv import load_dotenv


load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
MODEL_NAME = os.getenv("GEMINI_MODEL", "gemini-2.0-flash-lite").strip()
IS_GROK_MODEL = MODEL_NAME.lower().startswith("grok")
XAI_API_KEY = os.getenv("XAI_API_KEY", "").strip()
XAI_BASE_URL = os.getenv("XAI_BASE_URL", "https://api.x.ai/v1").rstrip("/")

if IS_GROK_MODEL:
    if XAI_API_KEY:
        print(f"[xAI] API key loaded: {XAI_API_KEY[:4]}...{'*' * (len(XAI_API_KEY)-8) if len(XAI_API_KEY) > 8 else ''}")
    else:
        print("[xAI] API key NOT FOUND! (Check .env)")
else:
    if api_key:
        print(f"[Gemini] API key loaded: {api_key[:4]}...{'*' * (len(api_key)-8) if len(api_key) > 8 else ''}")
    else:
        print("[Gemini] API key NOT FOUND! (Check .env)")

client = genai.Client(api_key=api_key) if (api_key and not IS_GROK_MODEL) else None

CATEGORIES = ["verbs", "nouns", "adjectives", "phrases", "numbers"]

FALLBACK_QUESTIONS = {
    "verbs": [
        {"word_in_spanish": "Correr", "correct_answer": "To run", "wrong_answer": "To walk", "category": "verbs"},
        {"word_in_spanish": "Comer", "correct_answer": "To eat", "wrong_answer": "To drink", "category": "verbs"},
    ],
    "nouns": [
        {"word_in_spanish": "Casa", "correct_answer": "House", "wrong_answer": "Street", "category": "nouns"},
        {"word_in_spanish": "Libro", "correct_answer": "Book", "wrong_answer": "Pen", "category": "nouns"},
    ],
    "adjectives": [
        {"word_in_spanish": "Feliz", "correct_answer": "Happy", "wrong_answer": "Calm", "category": "adjectives"},
        {"word_in_spanish": "Grande", "correct_answer": "Big", "wrong_answer": "Tall", "category": "adjectives"},
    ],
    "phrases": [
        {"word_in_spanish": "Buenos días", "correct_answer": "Good morning", "wrong_answer": "Good evening", "category": "phrases"},
        {"word_in_spanish": "¿Cómo estás?", "correct_answer": "How are you?", "wrong_answer": "Where are you?", "category": "phrases"},
    ],
    "numbers": [
        {"word_in_spanish": "Uno", "correct_answer": "One", "wrong_answer": "Two", "category": "numbers"},
        {"word_in_spanish": "Diez", "correct_answer": "Ten", "wrong_answer": "Twenty", "category": "numbers"},
    ],
}

FALLBACK_VOCABULARY = {
    "easy": ["cat", "book", "water", "house", "green"],
    "medium": ["journey", "improve", "balance", "support", "measure"],
    "hard": ["meticulous", "resilient", "contemplate", "coherent", "threshold"],
}

TOPIC_WORD_BANK = {
    "food": ["apple", "bread", "rice", "soup", "cheese", "pepper", "salad", "chicken", "orange", "pasta"],
    "travel": ["ticket", "luggage", "flight", "station", "passport", "hotel", "map", "journey", "route", "border"],
    "school": ["notebook", "pencil", "lesson", "teacher", "library", "exam", "project", "classroom", "subject", "homework"],
    "work": ["meeting", "salary", "deadline", "manager", "report", "office", "career", "contract", "schedule", "client"],
    "health": ["doctor", "clinic", "vitamin", "muscle", "energy", "sleep", "diet", "symptom", "balance", "exercise"],
    "technology": ["browser", "server", "update", "battery", "screen", "network", "device", "backup", "software", "keyboard"],
}


def _fallback_question(category: str) -> dict:
    selected_category = category if category in CATEGORIES else random.choice(CATEGORIES)
    if selected_category == "mixed":
        selected_category = random.choice(CATEGORIES)

    options = FALLBACK_QUESTIONS.get(selected_category) or FALLBACK_QUESTIONS["nouns"]
    return random.choice(options)


def _sanitize_question_payload(payload: dict, fallback_category: str) -> dict:
    if not isinstance(payload, dict):
        raise ValueError("Invalid question payload type")

    required = ["word_in_spanish", "correct_answer", "wrong_answer", "category"]
    for key in required:
        if key not in payload:
            raise ValueError(f"Missing key in question payload: {key}")
        if not isinstance(payload[key], str) or not payload[key].strip():
            raise ValueError(f"Invalid value in question payload: {key}")

    if payload["category"] not in CATEGORIES:
        payload["category"] = fallback_category if fallback_category in CATEGORIES else "nouns"

    return payload


def _parse_json_response(raw: str) -> dict:
    cleaned = re.sub(r"```json|```", "", raw).strip()
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        start = cleaned.find("{")
        end = cleaned.rfind("}")
        if start != -1 and end != -1 and end > start:
            return json.loads(cleaned[start:end + 1])
        raise


def _normalize_topic(topic: str) -> str:
    normalized = (topic or "").strip().lower()
    aliases = {
        "comida": "food",
        "alimentos": "food",
        "viaje": "travel",
        "viajes": "travel",
        "escuela": "school",
        "trabajo": "work",
        "salud": "health",
        "tecnologia": "technology",
        "tecnología": "technology",
    }
    return aliases.get(normalized, normalized)


def _ensure_varied_words(words: list, topic: str, difficulty: str, count: int = 5) -> list:
    seen = set()
    unique = []

    for word in words or []:
        cleaned = str(word).strip()
        key = cleaned.lower()
        if cleaned and key not in seen:
            seen.add(key)
            unique.append(cleaned)

    normalized_topic = _normalize_topic(topic)
    topic_bank = TOPIC_WORD_BANK.get(normalized_topic, [])
    for word in topic_bank:
        key = word.lower()
        if len(unique) >= count:
            break
        if key not in seen:
            seen.add(key)
            unique.append(word)

    if len(unique) < count:
        difficulty_bank = FALLBACK_VOCABULARY.get((difficulty or "medium").strip().lower(), FALLBACK_VOCABULARY["medium"])
        for word in difficulty_bank:
            key = word.lower()
            if len(unique) >= count:
                break
            if key not in seen:
                seen.add(key)
                unique.append(word)

    return unique[:count]


def _fallback_vocabulary(topic: str, difficulty: str) -> dict:
    normalized_topic = _normalize_topic(topic)
    if normalized_topic in TOPIC_WORD_BANK:
        return {"words": random.sample(TOPIC_WORD_BANK[normalized_topic], 5)}
    base = FALLBACK_VOCABULARY.get((difficulty or "medium").strip().lower(), FALLBACK_VOCABULARY["medium"])
    return {"words": base[:5]}


def _generate_with_grok(prompt: str) -> str:
    if not XAI_API_KEY:
        raise RuntimeError("XAI_API_KEY is missing")

    url = f"{XAI_BASE_URL}/chat/completions"
    payload = {
        "model": MODEL_NAME,
        "messages": [
            {
                "role": "system",
                "content": "Responde solo JSON valido. Sin explicaciones ni texto extra.",
            },
            {
                "role": "user",
                "content": prompt,
            },
        ],
        "temperature": 0.7,
        "max_tokens": 300,
    }
    headers = {
        "Authorization": f"Bearer {XAI_API_KEY}",
        "Content-Type": "application/json",
    }

    response = requests.post(url, headers=headers, json=payload, timeout=20)
    response.raise_for_status()

    data = response.json()
    choices = data.get("choices", [])
    if not choices:
        raise ValueError("xAI response has no choices")

    message = choices[0].get("message", {})
    content = (message.get("content") or "").strip()
    if not content:
        raise ValueError("xAI response has empty content")

    return content

async def generate_question(category: str = "mixed") -> dict:
    target_category = (
        category if category != "mixed"
        else random.choice(CATEGORIES)
    )

    if target_category not in CATEGORIES:
        target_category = random.choice(CATEGORIES)

    prompt = (
        f"1 pregunta ingles-espanol A2-B1. categoria: {target_category}. "
        "JSON: {word_in_spanish, correct_answer, wrong_answer, category}. "
        "wrong_answer de la misma categoria y longitud similar a correct_answer."
    )

    try:
        if IS_GROK_MODEL:
            raw = _generate_with_grok(prompt)
        else:
            if client is None:
                return _fallback_question(target_category)
            response = client.models.generate_content(model=MODEL_NAME, contents=prompt)
            raw = (response.text or "").strip()

        parsed = _parse_json_response(raw)
        return _sanitize_question_payload(parsed, target_category)
    except Exception as exc:
        provider = "xAI" if IS_GROK_MODEL else "Gemini"
        print(f"[{provider}] generate_question failed, using fallback: {exc}")
        return _fallback_question(target_category)


async def generate_vocabulary(topic: str, difficulty: str) -> dict:
    prompt = (
        f"5 palabras en ingles, tema: {topic}, nivel: {difficulty}. "
        "Deben ser variadas entre si (sin repetidas ni casi sinonimos). "
        "JSON: {words:[w1,w2,w3,w4,w5]}"
    )
    normalized_difficulty = (difficulty or "medium").strip().lower()

    try:
        if IS_GROK_MODEL:
            raw = _generate_with_grok(prompt)
        else:
            if client is None:
                return _fallback_vocabulary(topic, normalized_difficulty)
            response = client.models.generate_content(model=MODEL_NAME, contents=prompt)
            raw = (response.text or "").strip()

        parsed = _parse_json_response(raw)
        words = parsed.get("words") if isinstance(parsed, dict) else None
        if not isinstance(words, list) or len(words) < 3:
            raise ValueError("Invalid vocabulary payload")
        return {"words": _ensure_varied_words(words, topic, normalized_difficulty, count=5)}
    except Exception as exc:
        provider = "xAI" if IS_GROK_MODEL else "Gemini"
        print(f"[{provider}] generate_vocabulary failed, using fallback: {exc}")
        return _fallback_vocabulary(topic, normalized_difficulty)
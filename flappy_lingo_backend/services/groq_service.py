import asyncio
async def generate_questions_batch(category: str = "mixed", count: int = 10) -> dict:
    """
    Genera un lote de preguntas únicas usando una sola llamada eficiente a Groq.
    """
    selected_category = _normalize_category(category)
    target_category = selected_category if selected_category != "mixed" else random.choice(CATEGORIES)
    if target_category not in CATEGORIES:
        target_category = random.choice(CATEGORIES)

    blocked_words = _recent_words(target_category, limit=12)
    blocked_clause = ""
    if blocked_words:
        blocked_clause = (
            "No uses estas palabras en español porque salieron recientemente: "
            + ", ".join(blocked_words)
            + ". "
        )

    prompt = (
        f"Genera {count} pares de vocabulario español-inglés. "
        f"La categoria DEBE ser exactamente: {target_category}. "
        "No cambies de tema ni categoria. "
        + blocked_clause
        + "Devuelve solo JSON con este schema exacto: "
        + "{\"questions\":[{\"word_in_spanish\":\"...\",\"correct_answer\":\"...\",\"wrong_answer\":\"...\",\"category\":\"...\"}, ...]}. "
        + f"El campo category DEBE ser exactamente '{target_category}'. "
        + "wrong_answer debe ser creible pero incorrecta para la misma palabra. "
        + f"Asegúrate de que todas las palabras sean distintas y generadas por IA."
    )

    try:
        raw = _generate_with_groq(
            prompt,
            json_object=True,
            max_tokens=900,
            temperature=0.25,
        )
        parsed = _parse_json_response(raw)
        questions = parsed.get("questions") if isinstance(parsed, dict) else None
        if not isinstance(questions, list) or len(questions) < count:
            raise ValueError("La IA no devolvió suficientes preguntas")

        unique = []
        seen = set()
        for q in questions:
            try:
                q = _sanitize_question_payload(q, target_category)
                key = _word_key(q["word_in_spanish"])
                if key not in seen:
                    seen.add(key)
                    unique.append(q)
                    _remember_word(target_category, q["word_in_spanish"])
            except Exception:
                continue
            if len(unique) >= count:
                break
        if len(unique) < count:
            raise ValueError("No se generaron suficientes preguntas únicas")
        return {"questions": unique, "source": "groq"}
    except Exception as exc:
        print(f"[Groq] generate_questions_batch failed, using fallback: {exc}")
        # Fallback: rellenar con preguntas del pool fijo
        fallback = []
        for _ in range(count):
            fallback.append(_fallback_question(target_category))
        return {"questions": fallback, "source": "fallback"}
import os
import json
import re
import random
from collections import defaultdict, deque
import requests
from dotenv import load_dotenv


load_dotenv()

MODEL_NAME = os.getenv("GROQ_MODEL", "llama-3.1-8b-instant").strip()
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "").strip()
GROQ_BASE_URL = os.getenv("GROQ_BASE_URL", "https://api.groq.com/openai/v1").rstrip("/")

if GROQ_API_KEY:
    print(f"[Groq] API key loaded: {GROQ_API_KEY[:4]}...{'*' * (len(GROQ_API_KEY)-8) if len(GROQ_API_KEY) > 8 else ''}")
else:
    print("[Groq] API key NOT FOUND! (Check .env)")

CATEGORIES = ["verbs", "animals", "travel", "food"]
RECENT_WORDS_BY_CATEGORY = defaultdict(lambda: deque(maxlen=24))

FALLBACK_QUESTIONS = {
    "verbs": [
        {"word_in_spanish": "Correr", "correct_answer": "To run", "wrong_answer": "To walk", "category": "verbs"},
        {"word_in_spanish": "Comer", "correct_answer": "To eat", "wrong_answer": "To drink", "category": "verbs"},
        {"word_in_spanish": "Dormir", "correct_answer": "To sleep", "wrong_answer": "To wake", "category": "verbs"},
        {"word_in_spanish": "Hablar", "correct_answer": "To speak", "wrong_answer": "To listen", "category": "verbs"},
        {"word_in_spanish": "Escribir", "correct_answer": "To write", "wrong_answer": "To read", "category": "verbs"},
        {"word_in_spanish": "Viajar", "correct_answer": "To travel", "wrong_answer": "To stay", "category": "verbs"},
        {"word_in_spanish": "Abrir", "correct_answer": "To open", "wrong_answer": "To close", "category": "verbs"},
        {"word_in_spanish": "Aprender", "correct_answer": "To learn", "wrong_answer": "To forget", "category": "verbs"},
    ],
    "animals": [
        {"word_in_spanish": "Perro", "correct_answer": "Dog", "wrong_answer": "Cat", "category": "animals"},
        {"word_in_spanish": "León", "correct_answer": "Lion", "wrong_answer": "Tiger", "category": "animals"},
        {"word_in_spanish": "Gato", "correct_answer": "Cat", "wrong_answer": "Dog", "category": "animals"},
        {"word_in_spanish": "Caballo", "correct_answer": "Horse", "wrong_answer": "Donkey", "category": "animals"},
        {"word_in_spanish": "Vaca", "correct_answer": "Cow", "wrong_answer": "Goat", "category": "animals"},
        {"word_in_spanish": "Pájaro", "correct_answer": "Bird", "wrong_answer": "Fish", "category": "animals"},
        {"word_in_spanish": "Conejo", "correct_answer": "Rabbit", "wrong_answer": "Mouse", "category": "animals"},
        {"word_in_spanish": "Elefante", "correct_answer": "Elephant", "wrong_answer": "Giraffe", "category": "animals"},
    ],
    "travel": [
        {"word_in_spanish": "Pasaporte", "correct_answer": "Passport", "wrong_answer": "Ticket", "category": "travel"},
        {"word_in_spanish": "Avión", "correct_answer": "Plane", "wrong_answer": "Train", "category": "travel"},
        {"word_in_spanish": "Hotel", "correct_answer": "Hotel", "wrong_answer": "Hospital", "category": "travel"},
        {"word_in_spanish": "Maleta", "correct_answer": "Suitcase", "wrong_answer": "Backpack", "category": "travel"},
        {"word_in_spanish": "Aeropuerto", "correct_answer": "Airport", "wrong_answer": "Port", "category": "travel"},
        {"word_in_spanish": "Boleto", "correct_answer": "Ticket", "wrong_answer": "Invoice", "category": "travel"},
        {"word_in_spanish": "Mapa", "correct_answer": "Map", "wrong_answer": "Compass", "category": "travel"},
        {"word_in_spanish": "Estación", "correct_answer": "Station", "wrong_answer": "Platform", "category": "travel"},
    ],
    "food": [
        {"word_in_spanish": "Pan", "correct_answer": "Bread", "wrong_answer": "Rice", "category": "food"},
        {"word_in_spanish": "Queso", "correct_answer": "Cheese", "wrong_answer": "Butter", "category": "food"},
        {"word_in_spanish": "Sopa", "correct_answer": "Soup", "wrong_answer": "Salad", "category": "food"},
        {"word_in_spanish": "Arroz", "correct_answer": "Rice", "wrong_answer": "Beans", "category": "food"},
        {"word_in_spanish": "Pollo", "correct_answer": "Chicken", "wrong_answer": "Turkey", "category": "food"},
        {"word_in_spanish": "Pescado", "correct_answer": "Fish", "wrong_answer": "Meat", "category": "food"},
        {"word_in_spanish": "Ensalada", "correct_answer": "Salad", "wrong_answer": "Soup", "category": "food"},
        {"word_in_spanish": "Manzana", "correct_answer": "Apple", "wrong_answer": "Pear", "category": "food"},
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


def _word_key(value: str) -> str:
    return (value or "").strip().lower()


def _remember_word(category: str, word_in_spanish: str) -> None:
    if category in CATEGORIES:
        RECENT_WORDS_BY_CATEGORY[category].append(_word_key(word_in_spanish))


def _is_recent_word(category: str, word_in_spanish: str) -> bool:
    return _word_key(word_in_spanish) in RECENT_WORDS_BY_CATEGORY.get(category, ())


def _recent_words(category: str, limit: int = 8) -> list:
    history = list(RECENT_WORDS_BY_CATEGORY.get(category, ()))
    return history[-limit:] if history else []


def _fallback_question(category: str) -> dict:
    selected_category = category if category in CATEGORIES else random.choice(CATEGORIES)
    if selected_category == "mixed":
        selected_category = random.choice(CATEGORIES)

    options = FALLBACK_QUESTIONS.get(selected_category) or FALLBACK_QUESTIONS["verbs"]
    non_repeated = [
        item for item in options if not _is_recent_word(selected_category, item["word_in_spanish"])
    ]
    chosen = random.choice(non_repeated or options)
    _remember_word(selected_category, chosen["word_in_spanish"])
    return chosen


def _normalize_category(category: str) -> str:
    normalized = (category or "mixed").strip().lower()
    aliases = {
        "verbos": "verbs",
        "animales": "animals",
        "viaje": "travel",
        "viajes": "travel",
        "comida": "food",
        "alimentos": "food",
    }
    normalized = aliases.get(normalized, normalized)
    return normalized if normalized in CATEGORIES else "mixed"


def _sanitize_question_payload(payload: dict, fallback_category: str) -> dict:
    if not isinstance(payload, dict):
        raise ValueError("Invalid question payload type")

    required = ["word_in_spanish", "correct_answer", "wrong_answer", "category"]
    for key in required:
        if key not in payload:
            raise ValueError(f"Missing key in question payload: {key}")
        if not isinstance(payload[key], str) or not payload[key].strip():
            raise ValueError(f"Invalid value in question payload: {key}")

    if payload["category"] not in CATEGORIES or payload["category"] != fallback_category:
        payload["category"] = fallback_category if fallback_category in CATEGORIES else "verbs"

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


def _generate_with_groq(
    prompt: str,
    json_object: bool = True,
    max_tokens: int = 120,
    temperature: float = 0.2,
) -> str:
    if not GROQ_API_KEY:
        raise RuntimeError("GROQ_API_KEY is missing")

    url = f"{GROQ_BASE_URL}/chat/completions"
    payload = {
        "model": MODEL_NAME,
        "messages": [
            {
                "role": "system",
                "content": "Return valid JSON only. No markdown. No extra text.",
            },
            {
                "role": "user",
                "content": prompt,
            },
        ],
        "temperature": temperature,
        "max_tokens": max_tokens,
    }
    if json_object:
        payload["response_format"] = {"type": "json_object"}
    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json",
    }

    response = requests.post(url, headers=headers, json=payload, timeout=20)
    try:
        response.raise_for_status()
    except requests.HTTPError as exc:
        body = (response.text or "").strip()
        if len(body) > 500:
            body = body[:500] + "..."
        raise RuntimeError(f"Groq HTTP {response.status_code}: {body}") from exc

    data = response.json()
    choices = data.get("choices", [])
    if not choices:
        raise ValueError("Groq response has no choices")

    message = choices[0].get("message", {})
    content = (message.get("content") or "").strip()
    if not content:
        raise ValueError("Groq response has empty content")

    return content


async def generate_question(category: str = "mixed") -> dict:
    selected_category = _normalize_category(category)
    target_category = selected_category if selected_category != "mixed" else random.choice(CATEGORIES)

    if target_category not in CATEGORIES:
        target_category = random.choice(CATEGORIES)

    try:
        for _ in range(4):
            blocked_words = _recent_words(target_category, limit=8)
            blocked_clause = ""
            if blocked_words:
                blocked_clause = (
                    "No uses estas palabras en español porque salieron recientemente: "
                    + ", ".join(blocked_words)
                    + ". "
                )

            prompt = (
                "Genera 1 par de vocabulario español-inglés. "
                f"La categoria DEBE ser exactamente: {target_category}. "
                "No cambies de tema ni categoria. "
                + blocked_clause
                + "Devuelve solo JSON con este schema exacto: "
                + "{\"word_in_spanish\":\"...\",\"correct_answer\":\"...\",\"wrong_answer\":\"...\",\"category\":\"...\"}. "
                + f"El campo category DEBE ser exactamente '{target_category}'. "
                + "wrong_answer debe ser creible pero incorrecta para la misma palabra."
            )

            raw = _generate_with_groq(
                prompt,
                json_object=True,
                max_tokens=90,
                temperature=0.25,
            )
            parsed = _parse_json_response(raw)
            question = _sanitize_question_payload(parsed, target_category)

            if _is_recent_word(target_category, question["word_in_spanish"]):
                continue

            _remember_word(target_category, question["word_in_spanish"])
            return question

        return _fallback_question(target_category)
    except Exception as exc:
        print(f"[Groq] generate_question failed, using fallback: {exc}")
        return _fallback_question(target_category)


async def generate_vocabulary(topic: str, difficulty: str) -> dict:
    prompt = (
        f"Generate 5 varied English words for topic '{topic}' and difficulty '{difficulty}'. "
        "Return JSON only with schema: {\"words\":[\"w1\",\"w2\",\"w3\",\"w4\",\"w5\"]}. "
        "No repeated words."
    )
    normalized_difficulty = (difficulty or "medium").strip().lower()

    try:
        raw = _generate_with_groq(
            prompt,
            json_object=True,
            max_tokens=100,
            temperature=0.2,
        )
        parsed = _parse_json_response(raw)
        words = parsed.get("words") if isinstance(parsed, dict) else None
        if not isinstance(words, list) or len(words) < 3:
            raise ValueError("Invalid vocabulary payload")
        return {"words": _ensure_varied_words(words, topic, normalized_difficulty, count=5)}
    except Exception as exc:
        print(f"[Groq] generate_vocabulary failed, using fallback: {exc}")
        return _fallback_vocabulary(topic, normalized_difficulty)

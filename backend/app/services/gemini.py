"""Gemini, called only from the server so the API key never ships in the APK."""

import json
import time

import requests

ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
UNITS = ["pcs", "bottles", "bags", "boxes", "packs", "cans", "jars", "kg", "L"]


class GeminiError(Exception):
    pass


# Tried in order after the configured model when Google reports it overloaded.
FALLBACK_MODELS = ["gemini-3.5-flash", "gemini-flash-latest"]
RETRYABLE = {429, 500, 503}


def _call(api_key: str, model: str, parts: list, json_output: bool) -> str:
    body = {"contents": [{"parts": parts}]}
    if json_output:
        body["generationConfig"] = {"responseMimeType": "application/json"}
    last_status = None
    for candidate in [model, *[m for m in FALLBACK_MODELS if m != model]]:
        for attempt in range(2):
            response = requests.post(
                ENDPOINT.format(model=candidate),
                headers={"x-goog-api-key": api_key, "Content-Type": "application/json"},
                json=body,
                timeout=40,
            )
            last_status = response.status_code
            if response.status_code == 200:
                try:
                    return response.json()["candidates"][0]["content"]["parts"][0]["text"]
                except (KeyError, IndexError, ValueError) as exc:
                    raise GeminiError("Unexpected Gemini response") from exc
            if response.status_code not in RETRYABLE:
                break
            time.sleep(1.5 * (attempt + 1))
        if last_status not in RETRYABLE and last_status != 404:
            break
    raise GeminiError(f"Gemini returned {last_status}")


def suggest_product(api_key: str, model: str, image_base64: str, mime_type: str, barcode: str | None) -> dict:
    prompt = (
        "You help a small shop in Algeria register products. Read the product label in the photo "
        "and answer with JSON only: {\"name\": short product name with size, e.g. \"Olive oil 1L\", "
        f"\"unit\": one of {UNITS}, \"category\": one word}}. "
        f"The barcode is {barcode or 'unknown'}. If you cannot read it, use an empty name."
    )
    text = _call(
        api_key,
        model,
        [{"text": prompt}, {"inline_data": {"mime_type": mime_type, "data": image_base64}}],
        json_output=True,
    )
    try:
        data = json.loads(text)
    except json.JSONDecodeError as exc:
        raise GeminiError("Gemini did not return JSON") from exc
    unit = data.get("unit")
    return {
        "name": str(data.get("name") or "").strip()[:120],
        "unit": unit if unit in UNITS else None,
        "category": data.get("category"),
    }


def reorder_suggestions(api_key: str, model: str, lines: list[str], language: str) -> str:
    prompt = (
        f"Answer in {language}. You advise a small shopkeeper. For each product below you get the "
        "current stock, the reorder point and units sold in the last 14 days. Suggest what to "
        "reorder this week and how many, as a short bulleted list, most urgent first. Keep it under "
        "120 words and do not invent products.\n\n" + "\n".join(lines)
    )
    return _call(api_key, model, [{"text": prompt}], json_output=False).strip()

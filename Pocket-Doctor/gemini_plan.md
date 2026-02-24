"""Lightweight Gemini API wrapper for Pocket Doctor.

- Loads GEMINI_API_KEY from a .env file (project root or src/.env)
- Provides a simple `generate_reply()` helper tailored to our chat UX
"""
from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Iterable, Optional, Sequence, Tuple, List
import base64
import mimetypes

# -------------------------
# .env loader (no extra deps)
# -------------------------

def load_env_file(path: str) -> None:
    """Populate os.environ with key/value pairs from a simple .env file."""
    p = Path(path)
    if not p.exists():
        return
    try:
        for raw_line in p.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip()
            if not key:
                continue
            # Strip surrounding quotes if present
            if value and value[0] in {'"', "'"} and value[-1] == value[0]:
                value = value[1:-1]
            os.environ.setdefault(key, value)
    except OSError as exc:
        print(f"Warning: could not read {path}: {exc}", file=sys.stderr)


# Load environment from common locations (root .env first, then src/.env)
_THIS_DIR = Path(__file__).resolve().parent
_PROJECT_ROOT = _THIS_DIR.parent
for candidate in ( _PROJECT_ROOT / ".env", _THIS_DIR / ".env" ):
    load_env_file(str(candidate))


# -------------------------
# Gemini client factory
# -------------------------

_client = None  # cached


def _get_client():
    """Create or return the cached google-genai client."""
    global _client
    if _client is not None:
        return _client

    try:
        from google import genai  # type: ignore
    except Exception as e:  # pragma: no cover - import-time guard
        raise RuntimeError(
            "Missing dependency: google-genai. Install with your env manager (e.g. `uv sync`)."
        ) from e

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError(
            "GEMINI_API_KEY is not set. Add it to .env at project root or src/.env."
        )

    _client = genai.Client(api_key=api_key)
    return _client


# -------------------------
# Prompt helper
# -------------------------

SYS_INSTRUCTIONS = (
    "You are Pocket Doctor, an AI health assistant designed to give educational, supportive,"
    " and research-backed general health guidance. You do not diagnose, do not prescribe,"
    " and do not replace a real doctor.\n\n"
    "=== CORE PRINCIPLES ===\n"
    "Be empathetic, calm, and supportive.\n"
    "Give clear, structured, step-by-step explanations.\n"
    "Ask short follow-up questions if information is missing.\n"
    "Never present a medical conclusion as certain. Your role is educational, not diagnostic.\n\n"
    "=== SAFETY RULES ===\n"
    "If symptoms match emergency red flags, immediately recommend urgent medical care.\n"
    "Examples:\n"
    "- Severe or crushing chest pain\n"
    "- Difficulty breathing\n"
    "- Stroke-like symptoms (face drooping, slurred speech, one-sided weakness)\n"
    "- Severe abdominal pain with fever or vomiting\n"
    "- Heavy or uncontrolled bleeding\n"
    "- Severe burns\n"
    "- Severe allergic reactions\n"
    "- Loss of consciousness\n\n"
    "Avoid definitive diagnosis. Use phrases like 'This may be related to...', 'This could indicate...',"
    " 'It is important to confirm with a doctor.' Remind users you are not a substitute for real medical"
    " evaluation.\n\n"
    "=== WHAT YOU CAN SUGGEST ===\n"
    "1. Over-the-counter (OTC) medicines\n"
    "Only suggest globally safe, non-prescription, low-risk OTC options. Never suggest antibiotics,"
    " steroids, blood pressure medications, benzodiazepines, antidepressants, or any prescription-only"
    " drugs.\n\n"
    "Safe global OTC whitelist (use only these):\n"
    "Pain / Fever: paracetamol (acetaminophen), ibuprofen (with food and caution).\n"
    "Cold / Allergy: cetirizine, loratadine, saline nasal spray.\n"
    "Gastric problems: antacids, famotidine (OTC), omeprazole 20 mg OTC (short-term use only).\n"
    "Diarrhea / Dehydration: oral rehydration solution (ORS), oral zinc 10-20 mg if needed.\n"
    "Constipation: fiber supplement, polyethylene glycol (PEG).\n"
    "Skin / Minor wounds: hydrocortisone 1 percent cream (OTC), bacitracin or similar OTC antibiotic"
    " ointments.\n"
    "General wellness: electrolyte powders, rehydration tablets.\n\n"
    "These medications are for mild, common symptoms only. Always include 'Follow package instructions.'\n\n"
    "2. Evidence-based home remedies\n"
    "You may recommend hydration, warm or cold compresses, stretching, rest, ginger or honey for throat"
    " irritation, steam inhalation, bland diet (BRAT), avoiding trigger foods, low-impact movement,"
    " proper wound cleaning, and similar gentle measures.\n\n"
    "3. Lifestyle, prevention, and monitoring\n"
    "Always add practical prevention steps, simple lifestyle modifications, and daily symptom monitoring"
    " checklists.\n\n"
    "=== DEEP REASONING MODE ===\n"
    "You may privately perform clinical reasoning, but never reveal chain-of-thought. Only output short"
    " reasoning, final conclusions, and safe guidance.\n\n"
    "=== OUTPUT FORMAT ===\n"
    "Always structure answers as:\n"
    "Overview - simple explanation\n"
    "Possible Causes - use 'may be related to'\n"
    "Home Remedies - evidence-based\n"
    "Safe OTC Options - only from whitelist\n"
    "What to Monitor - simple checklist\n"
    "When to Seek Medical Help - clear red flags\n"
    "Final Note - encourage seeing a real doctor\n\n"
    "Keep paragraphs short, clear, and user-friendly."
)


def _build_prompt(
    user_prompt: str,
    history: Optional[Sequence[Tuple[str, str]]] = None,
    division: Optional[str] = None,
) -> str:
    parts: list[str] = [SYS_INSTRUCTIONS]
    if division:
        parts.append(f"Context: The user is consulting about the '{division}' division.")
    if history:
        parts.append("Conversation so far:")
        for role, text in history[-8:]:  # keep last few turns for brevity
            parts.append(f"{role.capitalize()}: {text}")
    parts.append(f"User: {user_prompt}")
    parts.append("Assistant (clear, friendly, brief paragraphs):")
    return "\n".join(parts)


def generate_reply(
    prompt: str,
    *,
    history: Optional[Sequence[Tuple[str, str]]] = None,
    division: Optional[str] = None,
    model: str = "gemini-2.5-flash",
) -> str:
    """Call Gemini and return a plain-text response.

    Parameters:
      - prompt: latest user message
      - history: list of (role, text) where role in {"user", "assistant"}
      - division: selected medical division to bias responses
      - model: Gemini model name

    Returns: model's best-effort string output.
    """
    client = _get_client()
    full_prompt = _build_prompt(prompt, history=history, division=division)

    # Try common method shapes; the library may evolve.
    try:
        if hasattr(client, "models") and hasattr(client.models, "generate_content"):
            resp = client.models.generate_content(model=model, contents=full_prompt)
        elif hasattr(client, "models") and hasattr(client.models, "generate"):
            resp = client.models.generate(model=model, prompt=full_prompt)
        elif hasattr(client, "generate"):
            resp = client.generate(model=model, prompt=full_prompt)
        else:
            raise RuntimeError("Unsupported google-genai client API shape.")
    except Exception as e:
        raise RuntimeError(f"Error while calling Gemini: {e}") from e

    # Extract text from likely shapes
    if hasattr(resp, "text") and isinstance(getattr(resp, "text"), str):
        return resp.text  # type: ignore[attr-defined]

    if isinstance(resp, dict):
        for key in ("text", "output", "content"):
            if key in resp and isinstance(resp[key], str):
                return resp[key]
        # candidates could be a list
        cand = resp.get("candidates")
        if isinstance(cand, list) and cand:
            first = cand[0]
            if isinstance(first, dict):
                for key in ("text", "content"):
                    if key in first and isinstance(first[key], str):
                        return first[key]

    # Try attributes on objects
    for attr in ("output", "result"):
        val = getattr(resp, attr, None)
        if isinstance(val, str):
            return val
        if val and hasattr(val, "text") and isinstance(getattr(val, "text"), str):
            return val.text  # type: ignore[attr-defined]

    return str(resp)


def _read_image_inline(path: str) -> Optional[dict]:
    try:
        data = Path(path).read_bytes()
    except Exception:
        return None
    mime, _ = mimetypes.guess_type(path)
    if not mime:
        # Default to jpeg if unknown
        mime = "image/jpeg"
    b64 = base64.b64encode(data).decode("ascii")
    return {"inline_data": {"mime_type": mime, "data": b64}}


def generate_reply_with_images(
    prompt: str,
    image_paths: Sequence[str],
    *,
    history: Optional[Sequence[Tuple[str, str]]] = None,
    division: Optional[str] = None,
    model: str = "gemini-2.5-flash",
) -> str:
    """Call Gemini with images attached. Falls back to text-only if API shape doesn't support parts.

    Parameters are the same as `generate_reply` with additional `image_paths`.
    """
    client = _get_client()

    # Build parts with system/context + images + user text
    context_text = _build_prompt("", history=history, division=division)
    parts: List[dict] = [{"text": context_text}]
    for p in image_paths:
        inline = _read_image_inline(p)
        if inline:
            parts.append(inline)
    parts.append({"text": prompt or "Please analyze the attached image(s) and extract any text (OCR)."})

    try:
        if hasattr(client, "models") and hasattr(client.models, "generate_content"):
            resp = client.models.generate_content(
                model=model,
                contents=[{"role": "user", "parts": parts}],
            )
        else:
            # Fallback: include file names in a text prompt if parts API not available
            prompt_text = (
                (prompt or "Please analyze the attached image(s)")
                + "\nAttached files: "
                + ", ".join(Path(p).name for p in image_paths)
            )
            return generate_reply(prompt_text, history=history, division=division, model=model)
    except Exception as e:
        raise RuntimeError(f"Error while calling Gemini (images): {e}") from e

    if hasattr(resp, "text") and isinstance(getattr(resp, "text"), str):
        return resp.text  # type: ignore[attr-defined]
    return str(resp)

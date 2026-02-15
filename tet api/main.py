import os
import sys


def load_env_file(path: str = ".env") -> None:
    """Populate os.environ with key/value pairs from a simple .env file."""
    if not os.path.exists(path):
        return

    try:
        with open(path, "r", encoding="utf-8") as env_file:
            for raw_line in env_file:
                line = raw_line.strip()
                if not line or line.startswith("#"):
                    continue
                if "=" not in line:
                    continue

                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip()

                if not key:
                    continue

                if value and value[0] in {'"', "'"} and value[-1] == value[0]:
                    value = value[1:-1]

                os.environ.setdefault(key, value)
    except OSError as exc:
        print(f"Warning: could not read {path}: {exc}", file=sys.stderr)


def main():
    # Import inside main so the file can be syntax-checked/compiled even when
    # the dependency isn't installed. If the import fails we'll show a
    # helpful message and exit.
    try:
        from google import genai
    except Exception as e:
        print("Missing or broken dependency: the `google-genai` package is required.")
        print("Install it with: python -m pip install google-genai")
        print("Import error:", e)
        sys.exit(1)

    load_env_file()

    # Read API key from environment (preferred) and create client.
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("GEMINI_API_KEY is not set. The google-genai client requires an API key.")
        print("Set it in fish:")
        print("  set -x GEMINI_API_KEY 'your_api_key_here'")
        print("Then run: uv run python main.py  (or: python main.py)")
        print("Alternatively you can configure the client to use Google Cloud credentials by passing `vertexai`, `project` and `location`.")
        sys.exit(1)

    client = genai.Client(api_key=api_key)

    prompt = "Explain how AI works in a few words"

    try:
        # Try a couple of common method names the library might expose.
        if hasattr(client, "models") and hasattr(client.models, "generate_content"):
            response = client.models.generate_content(model="gemini-2.5-flash", contents=prompt)
        elif hasattr(client, "models") and hasattr(client.models, "generate"):
            response = client.models.generate(model="gemini-2.5-flash", prompt=prompt)
        elif hasattr(client, "generate"):
            response = client.generate(model="gemini-2.5-flash", prompt=prompt)
        else:
            print("The client object does not expose a known `generate`/`generate_content` method.")
            print("Inspect `dir(client)` to see available methods.")
            sys.exit(1)

        # Extract a human-readable string from several possible response shapes.
        text = None
        if hasattr(response, "text"):
            text = response.text
        elif isinstance(response, dict):
            # common dict keys
            for key in ("text", "output", "content", "candidates"):
                if key in response:
                    text = response.get(key)
                    break
        else:
            # Try some likely attributes on objects the SDK may return.
            for attr in ("output", "candidates", "result"):
                val = getattr(response, attr, None)
                if val:
                    if isinstance(val, (list, tuple)) and len(val) > 0:
                        item = val[0]
                        text = getattr(item, "content", None) or getattr(item, "text", None) or item
                        break
                    # single object
                    text = getattr(val, "text", None) or getattr(val, "content", None)
                    if text:
                        break

        # Fall back to repr if we couldn't find a text field.
        print(text if text is not None else repr(response))
    except Exception as e:
        print("Error while calling the model:", e)
        sys.exit(1)


if __name__ == "__main__":
    main()

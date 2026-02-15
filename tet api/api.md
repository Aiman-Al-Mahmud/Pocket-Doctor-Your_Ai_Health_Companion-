## Setup
- Install Python 3.13+.
- Create and activate a virtual environment (example):
	```bash
	cd "/home/aiman/Desktop/Pocket-Doctor-Your_Ai_Health_Companion-/tet api"
	python -m venv .venv
	source .venv/bin/activate
	pip install -r /dev/null  # placeholder if you keep a requirements file
	pip install google-genai>=1.46.0
	```

## Set the API key
- Add your Gemini API key to `.env` (same folder as [main.py](main.py)):
	```bash
	echo "GEMINI_API_KEY=your_api_key_here" > .env
	```
- The script reads this value at runtime; no further configuration is needed.

## Check the API
- Run the script with the virtualenv Python:
	```bash
	cd "/home/aiman/Desktop/Pocket-Doctor-Your_Ai_Health_Companion-/tet api" && \
	/home/aiman/Desktop/Pocket-Doctor-Your_Ai_Health_Companion-/.venv/bin/python main.py
	```
- Expected behavior (example prompt `"Explain how AI works in a few words"`):
	```
	It learns patterns from data to make decisions.
	```

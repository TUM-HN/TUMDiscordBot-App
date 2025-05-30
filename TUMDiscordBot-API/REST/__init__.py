# REST package initialization
# We'll import the app here after it's fully initialized in app.py
# This avoids circular imports

from .app import app  # Import the Flask app from app.py
from .app import setup_session_logging
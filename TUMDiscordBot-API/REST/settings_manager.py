"""
Settings Manager
~~~~~~~~

Central module for managing application settings.

:copyright: (c) 2023-present Ivan Parmacli
:license: MIT, see LICENSE for more details.
"""

import json
from pathlib import Path
import os
import logging

# Get the logger configured in app.py
logger = logging.getLogger('discord_bot')

# Define the settings path relative to the project root
# Path(__file__).parent is the REST directory, so we need to go one level up to reach the project root
PROJECT_ROOT = Path(__file__).parent.parent.absolute()
SETTINGS_PATH = PROJECT_ROOT / ".secrets.json"

def get_settings():
    """
    Load and return settings from the settings.json file.
    
    Returns:
        dict: Settings dictionary
        
    Raises:
        FileNotFoundError: If settings.json cannot be found
    """
    if not SETTINGS_PATH.exists():
        raise FileNotFoundError(f"Settings file not found at {SETTINGS_PATH}")
    
    with open(SETTINGS_PATH, "r") as f:
        settings = json.load(f)
    
    return settings

def update_settings(settings):
    """
    Update the settings.json file with new settings.
    
    Args:
        settings (dict): Updated settings dictionary
    """
    with open(SETTINGS_PATH, "w") as f:
        json.dump(settings, f, indent=4)

# Load settings once at module import
try:
    SETTINGS = get_settings()
    logger.info(f"Settings loaded from: {SETTINGS_PATH}")
except FileNotFoundError as e:
    logger.warning(f"Warning: {e}")
    SETTINGS = None 
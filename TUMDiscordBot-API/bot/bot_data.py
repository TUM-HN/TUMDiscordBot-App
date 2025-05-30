"""
Bot Data
~~~~~~~~

Contains variables that are used by the bot and other modules.

:copyright: (c) 2023-present Ivan Parmacli
:license: MIT, see LICENSE for more details.
"""

import sys
from pathlib import Path

# Add the project root to Python path to make imports work correctly
sys.path.insert(0, str(Path(__file__).parent.parent))

# Import settings manager
from REST import settings_manager

# Get settings from the central manager
SETTINGS = settings_manager.SETTINGS
if not SETTINGS:
    raise RuntimeError("Settings could not be loaded. Cannot initialize bot data.")

PERMISSION_DENIED = "You lack the permissions to use this command!"
# Used for marking the attendance based on dynamic instructor defined "password" with len <= 10
ATTENDANCE_CODE = ""

# Dynamically create group variables based on settings.json
# Tutor groups attendance lists
for group in SETTINGS["groups"]:
    # Create the variable name using the original group name from settings
    var_name = f"group_{group}"
    globals()[var_name] = []
    globals()[f"{var_name}_status"] = False

# Lectures data
lectures = {}

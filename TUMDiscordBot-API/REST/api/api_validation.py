import json
import sys
from pathlib import Path
import datetime
import functools

from flask import request, jsonify

# Add the project root to Python path to make imports work correctly
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

# Import settings manager
from REST import settings_manager

# Get settings from the central manager
SETTINGS = settings_manager.SETTINGS
if not SETTINGS:
    raise RuntimeError("Settings could not be loaded. Cannot initialize API validation.")

# If API keys are not in settings, create a default one for development
if "api_keys" not in SETTINGS:
    SETTINGS["api_keys"] = {
        "025002": "Master-M"  # Dev mode API key
    }
    # Save the updated settings
    settings_manager.update_settings(SETTINGS)

# Constants
VALID_API_KEYS = SETTINGS["api_keys"]

# Create audit directory if it doesn't exist
audit_dir = Path('../data/audit')
audit_dir.mkdir(exist_ok=True, parents=True)


# Validate API key
def validate_api_key():
    api_key = request.args.get('api_key')
    if not api_key:
        return False, "API key is required"

    if api_key not in VALID_API_KEYS:
        return False, "Invalid API key"

    return True, VALID_API_KEYS[api_key]


# Audit API calls
def audit_api_call():
    api_key = request.args.get('api_key', 'unknown')
    endpoint = request.path
    params = dict(request.args)

    # Remove API key from logged parameters for security
    if 'api_key' in params:
        params['api_key'] = '[REDACTED]'

    timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    client_ip = request.remote_addr

    audit_entry = {
        'timestamp': timestamp,
        'endpoint': endpoint,
        'api_key': api_key,
        'params': params,
        'ip_address': client_ip
    }

    # Create a daily audit file
    audit_file = audit_dir / f"audit_{datetime.datetime.now().strftime('%Y-%m-%d')}.json"

    # Append to existing audit file or create new one
    if audit_file.exists():
        with open(audit_file, 'r') as f:
            try:
                entries = json.load(f)
            except json.JSONDecodeError:
                entries = []
    else:
        entries = []

    entries.append(audit_entry)

    with open(audit_file, 'w') as f:
        json.dump(entries, f, indent=2)


# API validation decorator
def requires_api_key(f):
    @functools.wraps(f)
    def decorated_function(*args, **kwargs):
        # Audit the API call first
        audit_api_call()
        
        # Then validate the API key
        valid, message = validate_api_key()
        if not valid:
            return jsonify({"status": "error", "message": message}), 401
            
        # If valid, proceed with the function
        return f(*args, **kwargs)
    return decorated_function

from flask import Blueprint, jsonify, request
import json
from pathlib import Path

from REST import settings_manager
from REST.api import requires_api_key

# Create a blueprint for settings endpoints
settings_bp = Blueprint('settings', __name__)


@settings_bp.route('/api/settings', methods=['GET'])
@requires_api_key
def get_all_settings():
    """
    Get all settings (except API keys)
    
    Returns:
        JSON response with all settings
    """
    # Get settings from settings manager
    settings = settings_manager.get_settings()

    # Remove API keys for security
    if 'api_keys' in settings:
        response_settings = settings.copy()
        del response_settings['api_keys']
        return jsonify({"status": "success", "data": response_settings}), 200

    return jsonify({"status": "success", "data": settings}), 200


# ================================
# Bot Configuration Endpoints
# ================================

@settings_bp.route('/api/settings/bot', methods=['GET'])
@requires_api_key
def get_bot_settings():
    """
    Get bot settings
    
    Returns:
        JSON response with bot settings
    """
    settings = settings_manager.get_settings()
    if 'bot' in settings:
        return jsonify({"status": "success", "data": settings['bot']}), 200

    return jsonify({"status": "error", "message": "Bot settings not found"}), 404


@settings_bp.route('/api/settings/bot/token', methods=['GET', 'POST'])
@requires_api_key
def bot_token():
    """
    Get or update bot token
    
    Returns:
        JSON response with status
    """
    settings = settings_manager.get_settings()

    if request.method == 'GET':
        if 'bot' in settings and 'token' in settings['bot']:
            return jsonify({"status": "success", "data": {"token": settings['bot']['token']}}), 200
        return jsonify({"status": "error", "message": "Bot token not found"}), 404

    if request.method == 'POST':
        token = request.args.get('token')
        if token is None or token.strip() == "":
            return jsonify({"status": "error", "message": "Token parameter required and cannot be empty"}), 400
            
        if 'bot' not in settings:
            settings['bot'] = {}

        settings['bot']['token'] = token
        settings_manager.update_settings(settings)
        return jsonify({"status": "success", "message": "Bot token updated"}), 200


@settings_bp.route('/api/settings/bot/dev_token', methods=['GET', 'POST'])
@requires_api_key
def bot_dev_token():
    """
    Get or update bot development token
    
    Returns:
        JSON response with status
    """
    settings = settings_manager.get_settings()

    if request.method == 'GET':
        if 'bot' in settings and 'dev_token' in settings['bot']:
            return jsonify({"status": "success", "data": {"dev_token": settings['bot']['dev_token']}}), 200
        return jsonify({"status": "error", "message": "Bot development token not found"}), 404

    if request.method == 'POST':
        dev_token = request.args.get('dev_token')
        if dev_token is None or dev_token.strip() == "":
            return jsonify({"status": "error", "message": "Development token parameter required and cannot be empty"}), 400
            
        if 'bot' not in settings:
            settings['bot'] = {}

        settings['bot']['dev_token'] = dev_token
        settings_manager.update_settings(settings)
        return jsonify({"status": "success", "message": "Bot development token updated"}), 200


@settings_bp.route('/api/settings/bot/development_mode', methods=['GET', 'POST'])
@requires_api_key
def bot_development_mode():
    """
    Get or update bot development mode
    
    Returns:
        JSON response with status
    """
    settings = settings_manager.get_settings()

    if request.method == 'GET':
        if 'bot' in settings and 'development_mode' in settings['bot']:
            return jsonify(
                {"status": "success", "data": {"development_mode": settings['bot']['development_mode']}}), 200
        return jsonify({"status": "error", "message": "Bot development mode not found"}), 404

    if request.method == 'POST':
        development_mode = request.args.get('development_mode')
        if development_mode is None:
            return jsonify({"status": "error", "message": "Development mode parameter required"}), 400

        # Convert string to boolean
        if isinstance(development_mode, str):
            if development_mode.lower() == 'true':
                development_mode = True
            elif development_mode.lower() == 'false':
                development_mode = False
            else:
                return jsonify({"status": "error", "message": "Development mode must be 'true' or 'false'"}), 400

        if not isinstance(development_mode, bool):
            return jsonify({"status": "error", "message": "Development mode must be a boolean"}), 400

        if 'bot' not in settings:
            settings['bot'] = {}

        settings['bot']['development_mode'] = development_mode
        settings_manager.update_settings(settings)
        return jsonify({"status": "success", "message": f"Bot development mode set to {development_mode}"}), 200


# ================================
# Groups Endpoints
# ================================

@settings_bp.route('/api/settings/groups', methods=['GET', 'POST'])
@requires_api_key
def manage_groups():
    """
    Get or update groups
    
    Returns:
        JSON response with status
    """
    settings = settings_manager.get_settings()

    if request.method == 'GET':
        if 'groups' in settings:
            return jsonify({"status": "success", "data": {"groups": settings['groups']}}), 200
        return jsonify({"status": "error", "message": "Groups not found"}), 404
    
    if request.method == 'POST':
        # Update groups based on provided JSON
        groups = request.json.get('groups')
        if groups is None:
            return jsonify({"status": "error", "message": "Groups parameter required in JSON body"}), 400
            
        if not isinstance(groups, list):
            return jsonify({"status": "error", "message": "Groups must be a list"}), 400
        
        # Validate that group names are strings and not empty
        for group in groups:
            if not isinstance(group, str) or group.strip() == "":
                return jsonify({
                    "status": "error", 
                    "message": f"Invalid group format: {group}. Group names must be non-empty strings."
                }), 400
        
        settings['groups'] = groups
        settings_manager.update_settings(settings)
        return jsonify({"status": "success", "message": "Groups updated", "data": {"groups": groups}}), 200


@settings_bp.route('/api/settings/groups/clear', methods=['POST'])
@requires_api_key
def clear_groups():
    """
    Clear all groups
    
    Returns:
        JSON response with status
    """
    settings = settings_manager.get_settings()

    settings['groups'] = []
    settings_manager.update_settings(settings)
    return jsonify({"status": "success", "message": "All groups cleared"}), 200
from flask import Blueprint, jsonify, request
import asyncio
import bot
from REST.api import requires_api_key
# Import from utils package instead of app
import REST.utils.bot_context as bc
from REST.utils import bot_not_running_json_message, bot_mock_ctx_json_message

# Create a blueprint for server endpoints
server_bp = Blueprint('server', __name__)

@server_bp.route('/api/server-info', methods=['GET'])
@requires_api_key
def server_info():
    """Get information about the Discord server (guild)"""
    # Check if bot is running
    if not bc.bot_running or not bc.bot_thread or not bc.bot_thread.is_alive():
        return bot_not_running_json_message()

    # Try to get or create mock context if it doesn't exist
    if not bc.mock_ctx:
        return bot_mock_ctx_json_message()

    try:
        # Get information from the bot
        guild_info = bot.get_guild_info()

        if not guild_info:
            return jsonify({
                "status": "error",
                "message": "Could not fetch guild information, bot may not be connected to a guild"
            }), 404

        return jsonify({
            "status": "success",
            "data": guild_info
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Failed to fetch server information: {str(e)}"
        }), 500


@server_bp.route('/')
def home():
    return "Server is running!"

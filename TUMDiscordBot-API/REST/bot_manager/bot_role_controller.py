from flask import Blueprint, jsonify, request
import asyncio
import bot
from REST.api import requires_api_key
# Import from utils package instead of app
import REST.utils.bot_context as bc
from REST.utils import bot_not_running_json_message, bot_mock_ctx_json_message

# Create a blueprint for role controller endpoints
role_bp = Blueprint('role', __name__)

@role_bp.route('/api/give-member-role', methods=['POST'])
@requires_api_key
def api_give_member_role():
    """Endpoint for the give-member-role command"""
    # Check if bot is running
    if not bc.bot_running:
        return bot_not_running_json_message()

    # Try to get or create mock context if it doesn't exist
    if not bc.mock_ctx:
        return bot_mock_ctx_json_message()

    # Get parameters
    user_id = request.args.get('user_id')
    role_id = request.args.get('role_id')

    if not user_id:
        return jsonify({"status": "error", "message": "Member parameter is required"}), 400

    if not role_id:
        return jsonify({"status": "error", "message": "Role_id parameter is required"}), 400

    try:
        bot.assign_member_role(int(user_id), int(role_id))

        return jsonify({
            "status": "success",
            "message": f"Give member role command executed: Gave {role_id} to {user_id}"
        })

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500



@role_bp.route('/api/roles', methods=['GET'])
@requires_api_key
def roles():
    """Get the list of roles in the server"""
    # Check if bot is running
    if not bc.bot_running or not bc.bot_thread or not bc.bot_thread.is_alive():
        return bot_not_running_json_message()

    # Try to get or create mock context if it doesn't exist
    if not bc.mock_ctx:
        return bot_mock_ctx_json_message()

    try:
        # Get roles from the bot
        roles_list = bot.get_roles()

        if roles_list is None:
            return jsonify({
                "status": "error",
                "message": "Could not fetch roles, bot may not be connected to a guild"
            }), 404

        return jsonify({
            "status": "success",
            "data": roles_list
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Failed to fetch roles: {str(e)}"
        }), 500


@role_bp.route('/api/member-count', methods=['GET'])
@requires_api_key
def member_count():
    """Get the count of online and offline members"""
    # Check if bot is running
    if not bc.bot_running or not bc.bot_thread or not bc.bot_thread.is_alive():
        return bot_not_running_json_message()

    # Try to get or create mock context if it doesn't exist
    if not bc.mock_ctx:
        return bot_mock_ctx_json_message()

    try:
        # Get member counts from the bot
        member_counts = bot.get_member_counts()

        if not member_counts:
            return jsonify({
                "status": "error",
                "message": "Could not fetch member information"
            }), 404

        return jsonify({
            "status": "success",
            "data": {
                "online": member_counts.get("online", None),
                "offline": member_counts.get("offline", None),
                "total": member_counts.get("total", None)
            }
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Failed to fetch member information: {str(e)}"
        }), 500


@role_bp.route('/api/channels', methods=['GET'])
@requires_api_key
def channels():
    """Get the list of channels in the server"""
    # Check if bot is running
    if not bc.bot_running or not bc.bot_thread or not bc.bot_thread.is_alive():
        return bot_not_running_json_message()

    # Try to get or create mock context if it doesn't exist
    if not bc.mock_ctx:
        return bot_mock_ctx_json_message()

    try:
        # Get channels from the bot
        channels_list = bot.get_channels()

        if channels_list is None:
            return jsonify({
                "status": "error",
                "message": "Could not fetch channels, bot may not be connected to a guild"
            }), 404

        return jsonify({
            "status": "success",
            "data": channels_list
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Failed to fetch channels: {str(e)}"
        }), 500


@role_bp.route('/api/members', methods=['GET'])
@requires_api_key
def members():
    """Get the list of members in the server"""
    # Check if bot is running
    if not bc.bot_running or not bc.bot_thread or not bc.bot_thread.is_alive():
        return bot_not_running_json_message()

    # Try to get or create mock context if it doesn't exist
    if not bc.mock_ctx:
        return bot_mock_ctx_json_message()

    try:
        # Get members from the bot
        members_list = bot.get_members()

        if members_list is None:
            return jsonify({
                "status": "error",
                "message": "Could not fetch members, bot may not be connected to a guild"
            }), 404

        return jsonify({
            "status": "success",
            "data": members_list
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Failed to fetch members: {str(e)}"
        }), 500


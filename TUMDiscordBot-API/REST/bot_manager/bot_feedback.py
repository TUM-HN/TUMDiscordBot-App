from flask import Blueprint, jsonify, request
import asyncio
import bot
from REST.api import requires_api_key
# Import from utils package instead of app
import REST.utils.bot_context as bc
from REST.utils import bot_mock_ctx_json_message, bot_not_running_json_message

# Create a blueprint for feedback endpoints
feedback_bp = Blueprint('feedback', __name__)


@feedback_bp.route('/api/tutor-session-feedback', methods=['POST'])
@requires_api_key
def api_tutor_session_feedback():
    """Endpoint for the tutor-session-feedback command"""
    # Check if bot is running
    if not bc.bot_running:
        bot_not_running_json_message()

    # Try to get or create mock context if it doesn't exist
    if not bc.mock_ctx:
        bot_mock_ctx_json_message()

    # Get parameters
    group_id = request.args.get('group_id')
    channel_id = request.args.get('channel_id')
    duration = request.args.get('duration')

    if not group_id:
        return jsonify({"status": "error", "message": "Group ID parameter is required"}), 400
    if not channel_id:
        return jsonify({"status": "error", "message": "Channel ID parameter is required"}), 400
    if not duration:
        return jsonify({"status": "error", "message": "Duration parameter is required"}), 400

    try:
        # Find the target channel
        channel = bc.mock_ctx.guild.get_channel(int(channel_id))
        if not channel:
            return jsonify({"status": "error", "message": f"Channel with ID {channel_id} not found"}), 404

        duration = float(duration)
        async def execute_command():
            await bot.tutor_session_feedback(bc.mock_ctx, group_id, channel, duration)

        # Run the coroutine in the bot's event loop
        loop = bc.get_live_loop()
        future = asyncio.run_coroutine_threadsafe(execute_command(), loop)
        future.result(timeout=30)

        return jsonify({
            "status": "success",
            "message": f"Tutor session feedback command executed for group {group_id}"
        })
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Failed to start feedback: {str(e)}"
        }), 500

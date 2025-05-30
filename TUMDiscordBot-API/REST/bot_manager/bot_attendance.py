from flask import Blueprint, jsonify, request
import asyncio
import bot
from REST.api import requires_api_key
# Import from utils package instead of app

import REST.utils.bot_context as bc
from REST.utils import bot_mock_ctx_json_message
from REST.utils.json_messages import bot_not_running_json_message

# Create a blueprint for attendance endpoints
attendance_bp = Blueprint('attendance', __name__)


@attendance_bp.route('/api/attendance', methods=['POST'])
@requires_api_key
def api_attendance():
    """Endpoint for the attendance command
    
    Parameters:
        status (str): 'start' or 'stop' for attendance
        group_id (str): ID of the group (e.g. 'g1')
        code (str): Attendance code for verification
        api_key (str): Authentication key
        target_user_id (str, optional): Discord user ID to send DMs to. 
                                       If provided, the bot will attempt to send 
                                       actual DMs to this user instead of mocking them.
    """
    # Check if bot is running
    if not bc.bot_running:
        return bot_not_running_json_message()

    # Try to get or create mock context if it doesn't exist
    if not bc.mock_ctx:
        return bot_mock_ctx_json_message()

    # Get parameters
    status = request.args.get('status')
    group_id = request.args.get('group_id')
    code = request.args.get('code')
    target_user_id = request.args.get('target_user_id')  # New parameter for DM target

    if not status:
        return jsonify({"status": "error", "message": "Status parameter is required"}), 400

    if status not in ['start', 'stop']:
        return jsonify({"status": "error", "message": "Status must be 'start' or 'stop'"}), 400

    if not group_id:
        return jsonify({"status": "error", "message": "Group ID parameter is required"}), 400
        
    if not code:
        return jsonify({"status": "error", "message": "Attendance code parameter is required"}), 400

    # This is the user to whom the bot will report
    if not target_user_id:
        return jsonify({"status": "error", "message": "Target User ID parameter is required"}), 400

    try:
        # This adds an attribute to the mock_ctx, which is target_user_id
        bc.mock_ctx.author.target_user_id = target_user_id

        async def execute_command():
            await bot.attendance(bc.mock_ctx, status, code, group_id)
            del bc.mock_ctx.author.target_user_id

        # Run the coroutine in the bot's event loop
        loop = bc.get_live_loop()
        future = asyncio.run_coroutine_threadsafe(execute_command(), loop)
        future.result(timeout=30)  # Wait up to 30 seconds for completion

        return jsonify({
            "status": "success",
            "message": f"Attendance command executed: {status} attendance for group {group_id} with code {code}"
        })
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Failed to process attendance: {str(e)}"
        }), 500

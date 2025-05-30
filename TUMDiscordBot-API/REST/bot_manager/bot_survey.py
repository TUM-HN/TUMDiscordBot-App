from flask import Blueprint, jsonify, request
import asyncio
import bot
from REST.api import requires_api_key
# Import from utils package instead of app
import REST.utils.bot_context as bc
from REST.utils import bot_not_running_json_message, bot_mock_ctx_json_message

# Create a blueprint for survey endpoints
survey_bp = Blueprint('survey', __name__)


@survey_bp.route('/api/create-simple-survey', methods=['POST'])
@requires_api_key
def api_create_simple_survey():
    """Endpoint for creating a simple survey"""
    # Check if bot is running using the check_bot_status function
    if not bc.bot_running:
        return bot_not_running_json_message()

    # Try to get or create mock context if it doesn't exist
    if not bc.mock_ctx:
        return bot_mock_ctx_json_message()

    # Get parameters
    message = request.args.get('message')
    button_type = request.args.get('button_type')
    main_topic = request.args.get('main_topic')
    channel_id = request.args.get('channel_id')
    duration = request.args.get('duration')

    # Validate required parameters
    if not message:
        return jsonify({"status": "error", "message": "Message parameter is required"}), 400
    if not button_type:
        return jsonify({"status": "error", "message": "Button type parameter is required"}), 400
    if not main_topic:
        return jsonify({"status": "error", "message": "Main topic parameter is required"}), 400
    if not channel_id:
        return jsonify({"status": "error", "message": "Channel ID parameter is required"}), 400
    if not duration:
        return jsonify({"status": "error", "message": "Duration parameter is required"}), 400

    # Validate button type
    if button_type.lower() not in ['difficulty', 'score']:
        return jsonify({"status": "error", "message": "Button type must be 'Difficulty' or 'Score'"}), 400

    try:
        # Find the target channel
        channel = bc.mock_ctx.guild.get_channel(int(channel_id))
        if not channel:
            return jsonify({"status": "error", "message": f"Channel with ID {channel_id} not found"}), 404

        duration = float(duration)

        # Call the create_simple_survey function in a coroutine
        async def execute_command():
            # Use the ctx we just retrieved/created
            await bot.create_simple_survey(bc.mock_ctx, message, button_type, main_topic, channel, duration)

        # Run the coroutine in the bot's event loop
        loop = bc.get_live_loop()
        future = asyncio.run_coroutine_threadsafe(execute_command(), loop)
        future.result(timeout=30)  # Wait up to 30 seconds for completion

        return jsonify({
            "status": "success",
            "message": f"Simple survey created in channel {channel.name}"
        })

    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Failed to create survey: {str(e)}"
        }), 500


@survey_bp.route('/api/create-complex-survey', methods=['POST'])
@requires_api_key
def api_create_complex_survey():
    """Endpoint for creating a complex survey"""
    # Check if bot is running using the check_bot_status function
    if not bc.bot_running:
        return bot_not_running_json_message()

    # Try to get or create mock context if it doesn't exist
    if not bc.mock_ctx:
        return bot_mock_ctx_json_message()

    # Get parameters
    message = request.args.get('message')
    main_topic = request.args.get('main_topic')
    channel_id = request.args.get('channel_id')
    duration = request.args.get('duration')

    # Validate required parameters
    if not message:
        return jsonify({"status": "error", "message": "Message parameter is required"}), 400
    if not main_topic:
        return jsonify({"status": "error", "message": "Main topic parameter is required"}), 400
    if not channel_id:
        return jsonify({"status": "error", "message": "Channel ID parameter is required"}), 400
    if not duration:
        return jsonify({"status": "error", "message": "Duration parameter is required"}), 400

    # Get optional question and button type parameters
    questions = {}
    button_types = {}

    # Check for question parameters (question_1, question_2, etc.)
    i = 1
    while f'question_{i}' in request.args:
        questions[f'question_{i}'] = request.args.get(f'question_{i}')
        i += 1

    # Check for button type parameters (button_1, button_2, etc.)
    i = 1
    while f'button_{i}' in request.args:
        button_type = request.args.get(f'button_{i}')
        if button_type.lower() not in ['difficulty', 'score']:
            return jsonify({
                "status": "error",
                "message": f"Button type must be 'Difficulty' or 'Score', got '{button_type}' for button_{i}"
            }), 400
        # Store with proper capitalization for consistency
        button_types[f'button_{i}'] = button_type.capitalize()
        i += 1

    # Validate that we have matching numbers of questions and button types if any are provided
    if (questions and not button_types) or (button_types and not questions):
        return jsonify({
            "status": "error",
            "message": "Both questions and button types must be provided together"
        }), 400

    if questions and button_types and len(questions) != len(button_types):
        return jsonify({
            "status": "error",
            "message": f"Number of questions ({len(questions)}) must match number of button types ({len(button_types)})"
        }), 400

    try:
        # Find the target channel
        channel = bc.mock_ctx.guild.get_channel(int(channel_id))
        if not channel:
            return jsonify({"status": "error", "message": f"Channel with ID {channel_id} not found"}), 404

        # Convert dictionaries to JSON strings if needed
        questions_json = None
        button_types_json = None

        if questions and button_types:
            import json
            questions_json = json.dumps(questions)
            button_types_json = json.dumps(button_types)

        duration = float(duration)

        # Call the create_complex_survey function in a coroutine
        async def execute_command():
            # Use the ctx we just retrieved/created
            # Pass the JSON strings if they're provided
            if questions_json and button_types_json:
                await bot.create_complex_survey(bc.mock_ctx, message, main_topic, channel,
                                                questions_json=questions_json, button_types_json=button_types_json,
                                                duration=duration)
            else:
                await bot.create_complex_survey(bc.mock_ctx, message, main_topic, channel, duration=duration)

        # Run the coroutine in the bot's event loop
        loop = bc.get_live_loop()
        future = asyncio.run_coroutine_threadsafe(execute_command(), loop)
        future.result(timeout=30)  # Wait up to 30 seconds for completion

        return jsonify({
            "status": "success",
            "message": f"Complex survey created in channel {channel.name}"
        })

    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Failed to create complex survey: {str(e)}"
        }), 500

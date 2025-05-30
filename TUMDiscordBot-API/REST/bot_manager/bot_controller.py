from datetime import time
from flask import Blueprint, jsonify, request
import asyncio
import threading
import time
import sys
from pathlib import Path

# Add the project root to Python path to make imports work correctly
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

# Import settings manager
from REST import settings_manager

import bot
from REST.api import requires_api_key
from REST.app import setup_session_logging

import REST.utils.bot_context as bc
from REST.utils import bot_is_running_json_message, bot_not_running_json_message, bot_mock_ctx_json_message

# Get settings from the central manager
SETTINGS = settings_manager.SETTINGS
if not SETTINGS:
    raise RuntimeError("Settings could not be loaded. Cannot initialize bot controller.")

# Create a blueprint for survey endpoints
controller_bp = Blueprint('controller', __name__)

# Global variable to track initialization errors
bot_init_error = None


@controller_bp.route('/api/start-bot', methods=['POST'])
@requires_api_key
def start_bot():
    """Start the Discord bot without requiring API key"""
    # Manually audit the API call for logging purposes
    from REST.api.api_validation import audit_api_call
    audit_api_call()
    
    global bot_init_error
    bot_init_error = None  # Reset error state
    
    # Check if bot is already running
    if bc.bot_running and bc.bot_thread and bc.bot_thread.is_alive():
        return bot_is_running_json_message()

    # Setup logging for this session
    logger = setup_session_logging()
    logger.info("Bot starting up...")
    
    # Purge stale context from previous run
    bc.mock_ctx = None
    
    # Validate token before starting the bot
    settings = settings_manager.get_settings()
    if 'bot' not in settings:
        return jsonify({"status": "error", "message": "Bot configuration not found in settings"}), 500
        
    # Determine which token to use based on development mode
    dev_mode = settings['bot'].get('development_mode', False)
    token_key = 'dev_token' if dev_mode else 'token'
    
    if token_key not in settings['bot'] or not settings['bot'][token_key]:
        return jsonify({
            "status": "error", 
            "message": f"Bot {token_key} is missing or empty in settings"
        }), 500
    
    # Start the bot in a separate thread with error handling
    def bot_thread_with_error_handling():
        global bot_init_error
        try:
            # Create a new event loop for this thread
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            
            # Reload the bot module to ensure we're using a fresh instance
            import importlib
            importlib.reload(bot)
            
            # Start the bot with the new loop
            bot.start(token_key)
        except Exception as e:
            # Capture the error message
            error_msg = f"Bot failed to start: {str(e)}"
            logger.error(error_msg)
            bot_init_error = error_msg
            bc.bot_running = False
    
    # Start the bot thread
    bc.bot_thread = threading.Thread(target=bot_thread_with_error_handling)
    bc.bot_thread.daemon = True
    bc.bot_thread.start()
    bc.bot_running = True
    
    # Wait a bit for the bot to connect or fail
    time.sleep(5)  # Give bot some time to connect or fail
    
    # Check if an error occurred during bot startup
    if bot_init_error:
        bc.bot_running = False
        return jsonify({"status": "error", "message": bot_init_error}), 500

    # Initialize mock context if bot connected to a guild
    def init_mock_context():
        global bot_init_error
        try:
            if not hasattr(bot, 'bot') or not bot.bot:
                raise RuntimeError("Bot instance not available")
                
            if not hasattr(bot.bot, 'guilds') or not bot.bot.guilds:
                raise RuntimeError("Bot not connected to any guilds")
                
            guild = bot.bot.guilds[0]  # Get the first guild
            bc.mock_ctx = bc.MockContext(guild=guild, author=bot.bot.user)
            logger.info(f"Mock context initialized with guild: {guild.name}")
            logger.info(f"Mock context initialized with author: {bot.bot.user.name}")
        except RuntimeError as e:
            # This is a critical error, stop the bot
            logger.error(f"Critical error initializing mock context: {str(e)}")
            logger.error("Stopping bot due to critical initialization error")
            
            # Stop the bot
            try:
                loop = bc.get_live_loop()
                asyncio.run_coroutine_threadsafe(bot.bot.close(), loop)
                bc.bot_running = False
                bc.mock_ctx = None
                
                # Set a global error message that can be checked by the start_bot function
                bot_init_error = f"Bot initialization failed: {str(e)}. Check logs for details."
            except Exception as stop_error:
                logger.error(f"Error stopping bot: {str(stop_error)}")
        except Exception as e:
            logger.error(f"Failed to initialize mock context: {str(e)}")
            bot_init_error = f"Failed to initialize mock context: {str(e)}"
            bc.bot_running = False

    # Start a thread to initialize the mock context after the bot has connected
    init_thread = threading.Thread(target=init_mock_context)
    init_thread.daemon = True
    init_thread.start()
    
    # Wait for the initialization thread to complete
    init_thread.join(timeout=10)
    
    # Check if there was an initialization error
    if bot_init_error:
        bc.bot_running = False
        return jsonify({"status": "error", "message": bot_init_error}), 500

    # Get the development mode status for the response message
    dev_mode = settings["bot"].get("development_mode", False)
    
    logger.info(f"Bot started successfully in {'development' if dev_mode else 'production'} mode")
    return jsonify({
        "status": "success", 
        "message": f"Bot started successfully in {'development' if dev_mode else 'production'} mode"
    }), 200


@controller_bp.route('/api/stop-bot', methods=['POST'])
@requires_api_key
def stop_bot():
    """Stop the Discord bot"""
    # Setup logging for this session
    logger = setup_session_logging()
    
    # Check if bot is running
    if not bc.bot_running:
        return bot_not_running_json_message()

    # Attempt to stop the bot
    try:
        # Get the live loop
        try:
            loop = bc.get_live_loop()
        except RuntimeError as e:
            logger.error(f"Failed to get live loop: {str(e)}")
            # If we can't get the loop, just clean up the state
            bc.bot_running = False
            bc.mock_ctx = None
            return jsonify({"status": "success", "message": "Bot state cleaned up"}), 200
        
        # Close the Discord connection
        try:
            future = asyncio.run_coroutine_threadsafe(bot.bot.close(), loop)
            future.result(timeout=10)  # Wait for the close operation to complete
        except Exception as e:
            logger.error(f"Failed to close Discord connection: {str(e)}")
            # Continue with cleanup even if close fails
        
        # Stop the event loop
        try:
            loop.stop()
            loop.close()
        except Exception as e:
            logger.error(f"Failed to stop/close loop: {str(e)}")
            # Continue with cleanup even if loop stop/close fails
        
        # Wait for the bot thread to exit
        try:
            if bc.bot_thread and bc.bot_thread.is_alive():
                bc.bot_thread.join(timeout=10)
        except Exception as e:
            logger.error(f"Failed to join bot thread: {str(e)}")
        
        # Reset all state
        bc.bot_running = False
        bc.mock_ctx = None
        
        logger.info("Bot stopped successfully")
        return jsonify({"status": "success", "message": "Bot stopped successfully"}), 200
    except Exception as e:
        error_msg = f"Failed to stop bot: {str(e)}"
        logger.error(error_msg)
        return jsonify({"status": "error", "message": error_msg}), 500


@controller_bp.route('/api/bot-status', methods=['GET'])
@requires_api_key
def bot_status():
    """Check if the bot is running"""
    if bc.bot_running:
        return jsonify({"status": "success", "message": "Bot is running"}), 200
    else:
        return jsonify({"status": "Service Unavailable", "message": "Bot is not running"}), 503


@controller_bp.route('/api/ping', methods=['GET'])
@requires_api_key
def api_ping():
    """Endpoint for the ping command"""
    # Check if bot is running
    if not bc.bot_running:
        return bot_not_running_json_message()

    # Try to get or create mock context if it doesn't exist
    if not bc.mock_ctx:
        return bot_mock_ctx_json_message()

    # Return a simple response
    return jsonify({"status": "success", "message": "Pong!", "latency": f"{round(bot.bot.latency * 1000)}ms"})


@controller_bp.route('/api/clear', methods=['POST'])
@requires_api_key
def api_clear():
    """Endpoint for the clear command"""
    # Check if bot is running
    if not bc.bot_running:
        return bot_not_running_json_message()

    # Try to get or create mock context if it doesn't exist
    if not bc.mock_ctx:
        return bot_mock_ctx_json_message()

    # Get parameters
    channel_id = request.args.get('channel_id')
    limit = request.args.get('limit', '10')

    # Validate limit parameter
    try:
        limit = int(limit)
        if limit < 1 or limit > 100:
            return jsonify({"status": "error", "message": "Limit must be between 1 and 100"}), 400
    except ValueError:
        return jsonify({"status": "error", "message": "Limit must be a number"}), 400

    if not channel_id:
        return jsonify({"status": "error", "message": "Channel parameter is required"}), 400
    try:
        # TODO: This adds an attribute to the mock_ctx, which is target_user_i
        channel = bc.mock_ctx.guild.get_channel(int(channel_id))
        
        async def execute_command():
            await bot.clear(bc.mock_ctx, channel, limit)

        # Get a live loop and run the coroutine
        loop = bc.get_live_loop()
        future = asyncio.run_coroutine_threadsafe(execute_command(), loop)
        future.result(timeout=30)  # Wait up to 30 seconds for completion

        return jsonify({
            "status": "success",
            "message": f"Clear command executed: Deleted {limit} messages in {channel}"
        })
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Failed to clear {limit} messages from {channel}: {str(e)}"
        }), 500


@controller_bp.route('/api/hello', methods=['POST'])
@requires_api_key
def api_hello():
    """Endpoint for the hello command"""
    # Setup logging for this session
    logger = setup_session_logging()
    
    # Check if bot is running
    if not bc.bot_running:
        return bot_not_running_json_message()

    # Try to get or create mock context if it doesn't exist
    if not bc.mock_ctx:
        return bot_mock_ctx_json_message()

    # Get parameters
    member = request.args.get('member')
    message = request.args.get('message')

    if not member:
        return jsonify({"status": "error", "message": "Member parameter is required"}), 400

    try:
        # Set the target user ID on the mock context
        bc.mock_ctx.author.target_user_id = member

        async def execute_command():
            try:
                # Get a fresh bot instance and loop
                bot_instance = bc.get_live_bot()
                await bot.hello(bc.mock_ctx, message)
            finally:
                # Clean up the target_user_id
                if hasattr(bc.mock_ctx.author, 'target_user_id'):
                    del bc.mock_ctx.author.target_user_id

        # Get a live loop and run the coroutine
        loop = bc.get_live_loop()
        future = asyncio.run_coroutine_threadsafe(execute_command(), loop)
        future.result(timeout=30)  # Wait up to 30 seconds for completion

        return jsonify({
            "status": "success",
            "message": f"Hello command executed {member} message: {message}"
        })
    except Exception as e:
        error_msg = f"Failed to send {message}: {str(e)}"
        logger.error(error_msg)
        return jsonify({
            "status": "error",
            "message": error_msg
        }), 500


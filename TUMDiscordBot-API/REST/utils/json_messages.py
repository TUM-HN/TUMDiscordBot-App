from flask import jsonify

def bot_mock_ctx_json_message():
    return jsonify({
        "status": "error",
        "message": "Bot context could not be initialized. Make sure the bot is connected to a Discord server."
    }), 400

def bot_not_running_json_message():
    return jsonify({"status": "conflict", "message": "Bot is not running"}), 409

def bot_is_running_json_message():
    return jsonify({"status": "conflict", "message": "Bot is running"}), 409

import datetime
import logging
from pathlib import Path

from flask import Flask

import bot
from bot_manager.bot_data import data_bp

app = Flask(__name__)

# Register blueprints
app.register_blueprint(data_bp)

# Create logs directory if it doesn't exist
logs_dir = Path('../data/logs')
logs_dir.mkdir(exist_ok=True, parents=True)

# Helper function to create session log file
def setup_session_logging():
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d_%H-%M')
    log_file = logs_dir / f"{timestamp}.log"

    # Configure logging for the root logger
    logging.basicConfig(
        level=logging.INFO,  # Set root logger level to INFO
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )

    # Reduce logging level for discord.py loggers to WARNING to suppress INFO logs
    discord_loggers = ['discord', 'discord.client', 'discord.gateway']
    for logger_name in discord_loggers:
        logger = logging.getLogger(logger_name)
        logger.setLevel(logging.WARNING)  # Only log WARNING and above for discord loggers

    return logging.getLogger('discord_bot')

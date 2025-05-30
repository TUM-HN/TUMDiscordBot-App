# First import basic data
from . import bot_data

# Import and initialize the bot instance first
from .discord_bot import bot, start, _verify_author_roles


# Only after bot is fully initialized, import the modules that depend on it
from .discord_bot_functions import *
from .discord_bot_slash_commands import *
from .discord_bot_events import *
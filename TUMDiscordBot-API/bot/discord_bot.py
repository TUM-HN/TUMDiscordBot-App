"""
Discord Bot
~~~~~~~~

A basic bot created for the tutors and instructors of the Introductory Programming course.

:copyright: (c) 2023-present Ivan Parmacli
:license: MIT, see LICENSE for more details.
"""

import asyncio
import discord
import sys
import logging
from pathlib import Path

from bot import bot_data

# Add the project root to Python path to make imports work correctly
sys.path.insert(0, str(Path(__file__).parent.parent))

# Import settings manager
from REST import settings_manager
from discord.ext import commands

# Get the logger configured in app.py
logger = logging.getLogger('discord_bot')

##################################
#              INIT              #
##################################

# Get settings from the central manager
SETTINGS = settings_manager.SETTINGS
if not SETTINGS:
    raise RuntimeError("Settings could not be loaded. Cannot start the bot.")

bot = commands.Bot(
    intents=discord.Intents.all(),
    status=discord.Status.streaming,
    activity=discord.Streaming(
        name="Coding with Jimbo", url="https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    ),
)

###########################################
#              BOT FUNCTIONS              #
###########################################


def start(token_key=None) -> None:
    """
    Startup function.

    Args:
        token_key: Optional key to specify which token to use.
               If None, uses token based on development_mode setting.
    """
    # Update global keyword so it can be accessed.
    global bot
    global _guilds, _channels, _members, _roles, _member_counts

    # Clear any existing data
    _guilds = {}
    _channels = {}
    _members = {}
    _roles = {}
    _member_counts = {"online": 0, "offline": 0, "total": 0}

    # Determine which token to use based on development mode
    if token_key is None:
        # Simply use the appropriate token based on development mode
        # without checking if it's None
        if SETTINGS["bot"]["development_mode"]:
            token = SETTINGS["bot"]["dev_token"]
        else:
            token = SETTINGS["bot"]["token"]
    else:
        # If a specific token key is provided, use that token
        token = SETTINGS["bot"][token_key]

    # Create a new event loop and set it as the current loop
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    
    # Create a new bot instance if needed
    global bot
    recreated = False
    if hasattr(bot, 'is_closed') and bot.is_closed():
        bot = commands.Bot(
            intents=discord.Intents.all(),
            status=discord.Status.streaming,
            activity=discord.Streaming(
                name="Coding with Jimbo", url="https://www.youtube.com/watch?v=dQw4w9WgXcQ"
            ),
        )
        recreated = True
        # Update the bot reference in the top-level bot package so other modules see the new client
        pkg = sys.modules.get('bot')
        if pkg is not None:
            setattr(pkg, 'bot', bot)

    # Reload dependent modules only if the bot instance was recreated.
    if recreated:
        import importlib, sys as _sys
        for mod in ['bot.discord_bot_functions', 'bot.discord_bot_slash_commands', 'bot.discord_bot_events']:
            if mod in _sys.modules:
                importlib.reload(_sys.modules[mod])

    # Run the bot with the selected token
    bot.run(token)



def _verify_author_roles(user: discord.User | discord.Member) -> bool:
    """
    Ensure that the user has the required role to use the command.

    Args:
        user :class:`User` | :class:`Member`: The user whose roles are to be verified.
    """
    for role in user.roles:
        if role.name == "Admin":
            return True
    return False
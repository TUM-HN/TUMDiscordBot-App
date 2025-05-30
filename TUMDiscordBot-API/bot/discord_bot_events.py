import discord
import sys
import asyncio
import time
import logging
from pathlib import Path

import utility
from bot import bot_data, bot
from bot.discord_bot_functions import get_roles

# Add the project root to Python path to make imports work correctly
sys.path.insert(0, str(Path(__file__).parent.parent))
from REST import settings_manager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

########################################
#              BOT EVENTS              #
########################################


@bot.event
async def on_ready() -> None:
    # Sync commands with Discord. Uncomment when done and pre-demo
    await update_roles_in_settings()

    logger.info("Syncing commands...")
    try:
        # To sync to all guilds (global commands - can take up to an hour to register)
        await bot.sync_commands()

        # To sync to specific guilds for immediate testing (faster than global commands)
        # If your bot is only in one guild, sync commands to just that guild for faster updates
        logger.info(f"Synced commands... {bot.all_commands}")
        if len(bot.guilds) > 0:
            logger.info(f"Syncing commands to guild: {bot.guilds[0].name}")
            await bot.sync_commands(guild_ids=[bot.guilds[0].id])
    except Exception as e:
        logger.error(f"Error syncing commands: {e}")

    logger.info(f'-----\nLogged in as {bot.user.name}.\nWith the bot id="{bot.user.id}"\n-----')


async def update_roles_in_settings():
    """
    Fetch roles from the Discord server and update settings.json
    This is run after the bot is fully initialized
    """
    max_retries = 5
    retry_count = 0

    while retry_count < max_retries:
        try:
            logger.info(f"Fetching roles and updating .secrets.json (attempt {retry_count + 1}/{max_retries})...")

            # Make sure the bot is connected to at least one guild
            if not bot.guilds:
                logger.info("Bot not connected to any guilds yet, waiting...")
                await asyncio.sleep(2)
                retry_count += 1
                continue

            # Use the get_roles function to fetch role data
            roles_data = get_roles()

            if not roles_data:
                logger.info("No role data returned, waiting...")
                await asyncio.sleep(2)
                retry_count += 1
                continue

            guild_id = str(bot.guilds[0].id)
            if guild_id not in roles_data:
                logger.info(f"No roles found for guild {guild_id}, waiting...")
                await asyncio.sleep(2)
                retry_count += 1
                continue

            guild_roles = roles_data[guild_id]

            # Get current settings
            settings = settings_manager.get_settings()

            # Store the complete role data in access_roles
            settings["access_roles"] = guild_roles
            settings_manager.update_settings(settings)

            logger.info(f"Successfully updated settings.json with {len(guild_roles)} roles from server")
            return

        except Exception as e:
            logger.error(f"Error updating roles in settings.json: {e}")
            await asyncio.sleep(2)
            retry_count += 1

    logger.error("Failed to update roles in settings.json after multiple attempts")


@bot.event
async def on_message(message: discord.Message) -> None:
    """
    This event is triggered when a message is sent in a channel.

    Args:
        message :class:`discord.Message`: The message that was sent.
    """
    # Ignore messages from the bot itself
    if message.author == bot.user:
        return

    # Process commands first
    await bot.process_commands(message)

    # Get the message content
    message_content = message.content.lower()

    # Check for attendance messages
    # Only check if the message content is a reasonable length for attendance codes
    if len(message_content) <= 10:  # Reasonable limit for attendance codes
        # If there's an active attendance code and the message matches it
        if bot_data.ATTENDANCE_CODE and message_content.lower() == bot_data.ATTENDANCE_CODE.lower():
            logger.info(f"Attendance code matched: {message_content}")
            
            # Find the active group for attendance
            active_group_id = None
            for group_id in bot_data.SETTINGS["groups"]:
                group_status = getattr(bot_data, f"group_{group_id}_status")
                if group_status:
                    active_group_id = group_id
                    break
            
            if active_group_id:
                # Get the active group list
                group_list = getattr(bot_data, f"group_{active_group_id}")
                
                # For debugging purposes
                logger.debug(f"Attendance code received: {message_content}, Active Group: {active_group_id}")
                logger.debug(f"Group Status: True, Channel: {message.channel}")
                
                # Add student to attendance list
                await utility.add_student_to_attendance_list(
                    message=message,
                    group=group_list,
                    status=True,
                    id=bot_data.ATTENDANCE_CODE,  # Pass the attendance code as the ID to match against
                )
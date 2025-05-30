from pathlib import Path
import logging
import sys
import bot as bot_module  # Import the bot module
import threading
import importlib

# Add the project root to Python path to make imports work correctly
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

# Import settings manager
from REST import settings_manager

# Create logs directory if it doesn't exist
logs_dir = Path('../data/logs')
logs_dir.mkdir(exist_ok=True, parents=True)

# Configure logger
logger = logging.getLogger('discord_bot')

# Global variables
bot_thread = None
bot_running = False
mock_ctx = None  # Will store our mock context


def get_live_loop():
    """
    Return the current bot.loop.

    Raise RuntimeError if:
      • bot instance is missing
      • loop is None or already closed
    """
    client = getattr(bot_module, "bot", None)
    if not client:
        raise RuntimeError("Bot instance not available")

    loop = getattr(client, "loop", None)
    if loop is None or loop.is_closed():
        raise RuntimeError("Bot event loop is closed")

    return loop


def get_live_bot():
    """
    Return the current bot instance.

    Raise RuntimeError if bot instance is missing
    """
    client = getattr(bot_module, "bot", None)
    if not client:
        raise RuntimeError("Bot instance not available")

    return client


# Mock Discord ApplicationContext for API interactions
class MockContext:
    def __init__(self, guild, author):
        self.guild = guild
        self.author = MockUser(author)

    async def respond(self, *args, **kwargs):
        # Check if the author has a target_user_id
        if hasattr(self.author, 'target_user_id') and self.author.target_user_id:
            try:
                # Get the live bot instance
                discord_bot = get_live_bot()

                # Find the user using the actual BOT
                user = await discord_bot.get_or_fetch_user(int(self.author.target_user_id))

                if user:
                    # Create an actual DM channel for the actual instance of the BOT with this target user (receiver)
                    dm_channel = await user.create_dm()

                    # Extract embed and view if present
                    embed = kwargs.get('embed')
                    view = kwargs.get('view')

                    # Send the actual message with embed/view if present
                    if embed and view:
                        await dm_channel.send(content=args[0] if args else "", embed=embed, view=view)
                    elif embed:
                        await dm_channel.send(content=args[0] if args else "", embed=embed)
                    elif view:
                        await dm_channel.send(content=args[0] if args else "", view=view)
                    else:
                        await dm_channel.send(content=args[0] if args else "", **kwargs)

                    logger.info(
                        f"Sent message to user [Server name: {user.display_name}] & [Discord name: {user.name}] through respond from {getattr(self.author, 'display_name')}#{getattr(self.author, 'discriminator')}")
                else:
                    logger.warning(f"Could not find user with ID {self.author.target_user_id}")
            except Exception as e:
                logger.error(f"Error sending message to user {self.author.target_user_id}: {str(e)}")

        # No response needed in API context
        pass


# Mock User class that adds the roles attribute
class MockUser:
    def __init__(self, user):
        # Setup logger
        self.logger = logging.getLogger('discord_bot')

        # Copy all attributes from the original user
        counter = 0
        for attr_name in dir(user):
            if not attr_name.startswith('_'):  # Skip private attributes
                try:
                    setattr(self, attr_name, getattr(user, attr_name))

                    # print(attr_name, ": ", getattr(self, attr_name))
                    # counter += 1
                except (AttributeError, TypeError):
                    pass

        # Find the Admin role ID from settings.json
        try:
            settings = settings_manager.get_settings()

            if 'access_roles' not in settings:
                error_msg = "No access_roles found in .secrets.json"
                self.logger.error(error_msg)
                raise RuntimeError(error_msg)

            # Look for a role with name "Admin" in the access_roles list
            admin_role_id = None
            for role in settings['access_roles']:
                if isinstance(role, dict) and 'name' in role and role['name'] == 'Admin' and 'id' in role:
                    admin_role_id = int(role['id'])
                    self.logger.info(f"Found Admin role with ID: {admin_role_id}")
                    break

            if admin_role_id is None:
                error_msg = "Admin role not found in .secrets.json access_roles"
                self.logger.error(error_msg)
                raise RuntimeError(error_msg)

            # Add a roles attribute with the Admin role ID
            self.roles = [MockRole(admin_role_id, "Admin")]
            self.logger.info(f"MockUser initialized with Admin role ID: {admin_role_id}")

        except Exception as e:
            error_msg = f"Failed to initialize MockUser with Admin role: {str(e)}"
            self.logger.error(error_msg)
            # This will be caught by the bot initialization process
            raise RuntimeError(error_msg)

    async def create_dm(self, target_user_id=None):
        # Check if we have a target_user_id attribute set on this instance
        # This would be set by the API endpoint
        if hasattr(self, 'target_user_id'):
            target_user_id = self.target_user_id

        # for attr_name in dir(self):
        #     if not attr_name.startswith('_'):
        #         print(attr_name, ": ", getattr(self, attr_name))

        # Return a mock DM channel that supports the necessary operations
        # If target_user_id is provided, the channel will actually send messages to that user
        return MockDMChannel(target_user_id)


# Mock Role class
class MockRole:
    def __init__(self, role_id, role_name="MockRole"):
        self.id = role_id
        self.name = role_name


class MockDMChannel:
    """A mock DM channel class that can be used for API calls"""

    def __init__(self, target_user_id=None):
        self.target_user_id = target_user_id

    async def send(self, *args, **kwargs):
        # If we have a target user ID, try to actually send the message to that user
        if self.target_user_id:
            try:
                # Get the live bot instance
                discord_bot = get_live_bot()

                # Find the user
                user = await discord_bot.get_or_fetch_user(int(self.target_user_id))

                if user:
                    # Create an actual DM channel, using the actual Bot instance
                    dm_channel = await user.create_dm()

                    # Send the actual message using an actual BOT instance
                    real_message = await dm_channel.send(*args, **kwargs)
                    logger.info(f"Sent DM to user {self.target_user_id}: {args}, {kwargs}")
                    return real_message
                else:
                    logger.warning(f"Could not find user with ID {self.target_user_id}")
            except Exception as e:
                logger.error(f"Error sending DM to user {self.target_user_id}: {str(e)}")

        # Fall back to mock behavior if we can't send a real message
        logger.debug(f"Mock DM would send: {args}, {kwargs}")
        return MockMessage()


class MockMessage:
    """A mock message class that can be returned from send operations"""

    def __init__(self):
        self.id = 0
        self.content = ""

    async def edit(self, *args, **kwargs):
        # Log edit instead of modifying
        logger.debug(f"Mock message would edit: {args}, {kwargs}")
        return self

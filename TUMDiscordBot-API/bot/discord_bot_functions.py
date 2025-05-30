# Global variables to store server information
import json
import asyncio
from os import path

import discord

# Replace direct bot import with live fetch helper
import REST.utils.bot_context as bc

_guilds = {}
_channels = {}
_members = {}
_roles = {}
_member_counts = {"online": 0, "offline": 0, "total": 0}

# Helper: get the current live bot instance
def _bot():
    return bc.get_live_bot()

# Functions to retrieve Discord server information
def get_guild_info():
    """Get information about all guilds the bot is connected to.
    The bot is usually connected to only one, but this is the correct way since bot.guilds returns a list.

    Returns:
        dict: Information about the guilds.
    """
    global _guilds

    try:
        # Collect guild data
        guilds_data = {}
        for guild in _bot().guilds:
            guilds_data[str(guild.id)] = {
                "id": str(guild.id),
                "name": guild.name,
                "member_count": guild.member_count,
                "icon_url": str(guild.icon.url) if guild.icon else None,
                "description": guild.description,
                "created_at": guild.created_at.isoformat() if guild.created_at else None,
                "owner_id": str(guild.owner_id) if guild.owner_id else None
            }

        # Store in global variable for caching
        _guilds = guilds_data
        return guilds_data
    except Exception as e:
        print(f"Error getting guild info: {e}")
        return None

def get_channels():
    """Get information about channels in the guilds.

    Returns:
        dict: Information about the channels.
    """
    global _channels

    try:
        # Collect channel data
        channels_data = {}
        for guild in _bot().guilds:
            guild_channels = []
            for channel in guild.channels:
                channel_data = {
                    "id": str(channel.id),
                    "name": channel.name,
                    "type": str(channel.type),
                    "position": channel.position,
                    "category_id": str(channel.category_id) if channel.category_id else None
                }

                if hasattr(channel, 'topic') and channel.topic:
                    channel_data["topic"] = channel.topic

                guild_channels.append(channel_data)

            channels_data[str(guild.id)] = guild_channels

        # Store in global variable for caching
        _channels = channels_data
        return channels_data
    except Exception as e:
        print(f"Error getting channels: {e}")
        return None

def get_members():
    """Get information about members in the guilds.

    Returns:
        dict: Information about the members.
    """
    global _members, _member_counts

    try:
        # Collect member data
        members_data = {}
        all_online = 0
        all_offline = 0
        all_total = 0

        for guild in _bot().guilds:
            guild_members = []
            online_count = 0
            offline_count = 0

            for member in guild.members:
                # Skip bots
                if member.bot:
                    continue

                member_roles = [str(role.id) for role in member.roles if role.id != guild.id]

                status = "offline"
                if member.status == discord.Status.online or member.status == discord.Status.idle or member.status == discord.Status.dnd:
                    status = "online"
                    online_count += 1
                else:
                   offline_count += 1

                member_data = {
                    "id": str(member.id),
                    "name": member.name,
                    "display_name": member.display_name,
                    "discriminator": member.discriminator,
                    "bot": member.bot,
                    "avatar_url": str(member.avatar.url) if member.avatar else None,
                    "roles": member_roles,
                    "joined_at": member.joined_at.isoformat() if member.joined_at else None,
                    "status": status
                }

                guild_members.append(member_data)

            members_data[str(guild.id)] = guild_members

            all_online += online_count
            all_offline += offline_count
            all_total += len(guild_members)

        # Update member counts
        _member_counts = {
            "online": all_online,
            "offline": all_offline,
            "total": all_total
        }

        # Store in global variable for caching
        _members = members_data
        return members_data
    except Exception as e:
        print(f"Error getting members: {e}")
        return None

def get_roles():
    """Get information about roles in the guilds.

    Returns:
        dict: Information about the roles.
    """
    global _roles

    try:
        # Collect role data
        roles_data = {}
        for guild in _bot().guilds:
            guild_roles = []
            for role in guild.roles:
                # Skip the @everyone role
                if role.name == "@everyone":
                    continue

                role_data = {
                    "id": str(role.id),
                    "name": role.name,
                    "color": str(role.color),
                    "position": role.position,
                    "mentionable": role.mentionable,
                    "permissions": str(role.permissions.value)
                }

                guild_roles.append(role_data)

            roles_data[str(guild.id)] = guild_roles

        # Store in global variable for caching
        _roles = roles_data
        return roles_data
    except Exception as e:
        print(f"Error getting roles: {e}")
        return None


def get_member_counts():
    """Get the count of online and offline members.

    Returns:
        dict: Counts of online and offline members.
    """
    global _member_counts

    try:
        # If member counts are already cached, return them
        if _member_counts["total"] > 0:
            return _member_counts

        # Otherwise, refresh member data to update counts
        get_members()
        return _member_counts
    except Exception as e:
        print(f"Error getting member counts: {e}")
        return {"online": 0, "offline": 0, "total": 0}


def assign_member_role(user_id: int, role_id: int):
    try:
        print(_bot().guilds[0].name)
        role = _bot().guilds[0].get_role(int(role_id))
        member = _bot().guilds[0].get_member(user_id)

        # Create a coroutine for adding roles and run it using asyncio
        async def add_role_coroutine():
            await member.add_roles(role)

        # Run the coroutine in the bot's event loop
        future = asyncio.run_coroutine_threadsafe(add_role_coroutine(), _bot().loop)
        # Wait for the result, with a timeout
        future.result(timeout=10)

        return {"status": "success", "message": "Role assigned successfully"}
    except Exception as e:
        print(f"Error assigning member role: {e}")
        return {"status": "failure", "message": "Error assigning member role: " + str(e)}


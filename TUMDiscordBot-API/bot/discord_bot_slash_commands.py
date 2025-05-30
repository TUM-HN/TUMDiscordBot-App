import discord
import re
import json
import logging

from bot import bot_data, bot
from bot.discord_bot import _verify_author_roles
from bot.ui.view import TutorSessionView, DifficultyView, ScoreView, AnnouncementView
from discord import option

from utility import *

# Get the logger configured in app.py
logger = logging.getLogger('discord_bot')


################################################
#              BOT SLASH COMMANDS              #
################################################


@bot.slash_command(description="Ping-Pong game.")
async def ping(ctx: discord.ApplicationContext) -> None:
    """Simple command to check if the bot is responding."""
    await ctx.respond(f"Pong! Latency: {round(bot.latency * 1000)}ms")


@bot.slash_command(description="Say hello to a member with a custom message.")
@option(
    "member",
    discord.Member,
    description="The member to greet.",
)
@option(
    "message",
    description="Custom greeting message.",
    default="Hello there!",
)
async def hello(ctx: discord.ApplicationContext, message: str) -> None:
    """Greet a member with a custom message."""
    if not _verify_author_roles(ctx.author):
        await ctx.respond("You don't have permission to use this command.")
        return

    await ctx.respond(f"{message}")


@bot.slash_command(description="Deletes the specified amount of messages from channel.")
@option(
    "channel",
    discord.TextChannel,
    description="The channel to clear messages from.",
    default=None,
)
@option(
    "limit",
    description="Enter the number of messages to delete.",
    min_value=1,
    max_value=100,
    default=10,
)
async def clear(ctx: discord.ApplicationContext, channel: discord.TextChannel, limit: int) -> None:
    """Delete a specified number of messages from a channel."""
    if not _verify_author_roles(ctx.author):
        await ctx.respond("You don't have permission to use this command.")
        return

    target_channel = channel or ctx.channel

    try:
        deleted = await target_channel.purge(limit=limit)
        await ctx.respond(f"Deleted {len(deleted)} messages in {target_channel.mention}.", ephemeral=True)
    except discord.Forbidden:
        await ctx.respond("I don't have permission to delete messages in that channel.", ephemeral=True)
    except discord.HTTPException as e:
        await ctx.respond(f"Error deleting messages: {str(e)}", ephemeral=True)


@bot.slash_command(
    description="Gives a specific role to a member.",
)
@option(
    "member",
    discord.Member,
    description="The member to give the role to.",
)
@option(
    "role",
    discord.Role,
    description="The role to give to the member.",
)
async def give_member_role(ctx: discord.ApplicationContext, member: discord.Member, role: discord.Role) -> None:
    """Assign a specific role to a member."""
    if not _verify_author_roles(ctx.author):
        await ctx.respond("You don't have permission to use this command.")
        return

    try:
        await member.add_roles(role)
        await ctx.respond(f"Successfully gave {role.mention} to {member.mention}.")
    except discord.Forbidden:
        await ctx.respond("I don't have permission to manage roles.")
    except discord.HTTPException as e:
        await ctx.respond(f"Error assigning role: {str(e)}")


@bot.slash_command(
    description="Start or stop the attendance check for the specified group.",
)
@option(
    "status",
    description='Enter "start" to begin the check or "stop" to end it.',
    choices=["start", "stop"],
)
@option(
    "group_id",
    description="Enter the group which will be checked.",
)
@option(
    "code",
    description="Enter the attendance code for.",
)

async def attendance(
        ctx: discord.ApplicationContext,
        status: str,
        code: str,
        group_id: str,
) -> None:
    """Start or stop attendance tracking for a specific group."""
    # Convert group_id to lowercase for case-insensitive comparison
    group_id = group_id.lower()
    code = code.lower()

    match status.lower():
        case "start":
            if _verify_author_roles(ctx.author):
                try:
                    update_dm_accept_status(group_id, code)
                    logger.info(f"Started attendance for group {group_id} with code {code}")
                    await ctx.respond(
                        f"{ctx.author.mention}, accepting messages in DM, please send attendance code."
                    )
                except Exception as e:
                    logger.error(f"Error starting attendance: {e}")
                    await ctx.respond(f"Error starting attendance: {str(e)}")
            else:
                await ctx.respond(bot_data.PERMISSION_DENIED)
        case "stop":
            if _verify_author_roles(ctx.author):
                try:
                    # Send confirmation response first
                    await ctx.respond(
                        f"{ctx.author.mention}, messages in DM are no longer accepted for code {code}."
                    )
                    
                    # Get the group list before cleanup
                    group_list_text = prepare_group_list_for_embed(group_id)
                    
                    # Create and send the embed
                    tutor_dm = await ctx.author.create_dm()
                    embed = discord.Embed(
                        title=f"Attendance for group {group_id} with code {code}", colour=ctx.author.colour
                    )
                    embed.add_field(
                        name="Students List",
                        inline=False,
                        value=group_list_text if group_list_text else "No students in attendance."
                    )
                    await tutor_dm.send(embed=embed)
                    
                    # Do the cleanup
                    logger.info(f"Stopping attendance for group {group_id}")
                    success = attendance_cleanup(group_id=group_id)
                    
                    if success:
                        logger.info(f"Successfully stopped attendance for group {group_id}")
                        # Send confirmation of file saving
                        await tutor_dm.send(f"Attendance records have been saved to a CSV file.")
                    else:
                        logger.error(f"Failed to stop attendance for group {group_id}")
                        await tutor_dm.send("⚠️ There was an error saving the attendance records.")
                    
                except Exception as e:
                    logger.error(f"Error stopping attendance: {e}")
                    await ctx.respond(f"Error stopping attendance: {str(e)}")
            else:
                await ctx.respond(bot_data.PERMISSION_DENIED)
        case _:
            await ctx.respond(
                f'{ctx.author.mention}, can not recognize the status argument. Please make sure to use "start" or "stop" for the status argument.'
            )


@bot.slash_command(
    name="tutor-session-feedback",
    description="Allows students to leave feedback on tutor sessions.",
)
@option(
    "group_id",
    description="Enter your group id.",
)
async def tutor_session_feedback(
        ctx: discord.ApplicationContext,
        group_id: str,
        channel: discord.TextChannel,
        duration: float,
) -> None:
    """Collect feedback for a tutor session from a specific group."""
    if _verify_author_roles(ctx.author):
        default_value = "`0 %`"
        embed = discord.Embed(title="Tutor Session Feedback", colour=ctx.author.color)
        embed.add_field(name="Participants: 0", inline=False, value="")
        embed.add_field(name="Good", inline=True, value=default_value)
        embed.add_field(name="Satisfactory", inline=True, value=default_value)
        embed.add_field(name="Poor", inline=True, value=default_value)
        embed.set_author(
            name="Author: " + ctx.author.display_name, icon_url=ctx.author.avatar.url
        )
        view = TutorSessionView(group_id=group_id, duration=duration)
        await channel.send(
            embed=embed,
            view=view,
        )
        await ctx.respond(
            f"Feedback was created in channel {channel}, the timer is set to: " + str(view.timeout) + " seconds.", )
    else:
        logger.warning(bot_data.PERMISSION_DENIED)
        await ctx.respond(bot_data.PERMISSION_DENIED)


@bot.slash_command(
    name="create-complex-survey",
    description="Create a multiple question survey.",
)
@option("message", description="Survey announcement message.")
@option(
    "main_topic",
    description='The main topic of the survey, e.g. "exercise T01E01".',
)
@option(
    "channel", discord.TextChannel, description="The channel to publish the survey."
)
@option(
    "questions_json",
    description='Optional JSON string of questions in format {"question_1": "Q1", "question_2": "Q2", ...}',
    default=None,
    required=False
)
@option(
    "button_types_json",
    description='Optional JSON string of button types in format {"button_1": "score", "button_2": "difficulty", ...}',
    default=None,
    required=False
)
async def create_complex_survey(
        ctx: discord.ApplicationContext,
        message: str,
        main_topic: str,
        channel: discord.TextChannel,
        questions_json: str = None,
        button_types_json: str = None,
        duration: float = 30
) -> None:
    """Create a complex survey with multiple questions."""

    # Convert JSON strings to dictionaries if provided
    questions = None
    button_types = None

    if questions_json and button_types_json:
        try:
            questions = json.loads(questions_json)
            button_types = json.loads(button_types_json)
        except json.JSONDecodeError as e:
            await ctx.respond(f"Error parsing JSON parameters: {str(e)}")
            return

    # Check if questions and button_types are provided as parameters
    if questions and button_types:
        # Extract questions and button types from the dictionaries in order
        ordered_questions = []
        ordered_button_types = []

        # Extract questions in order (question_1, question_2, etc.)
        i = 1
        while f"question_{i}" in questions:
            ordered_questions.append(questions[f"question_{i}"])
            i += 1

        # Extract button types in order (button_1, button_2, etc.)
        i = 1
        while f"button_{i}" in button_types:
            button_type = button_types[f"button_{i}"].capitalize()  # Ensure proper capitalization
            if button_type not in ["Difficulty", "Score"]:
                await ctx.respond(f"Invalid button type: {button_type}. Must be 'Difficulty' or 'Score'.")
                return
            ordered_button_types.append(button_type)
            i += 1

        # Verify we have the same number of questions and button types
        if len(ordered_questions) != len(ordered_button_types):
            await ctx.respond(
                "The number of questions is not equal to the number of button types, interaction aborted."
            )
            return

        if len(ordered_questions) == 0:
            await ctx.respond("No questions provided, interaction aborted.")
            return

        # Inform the user that we're creating the survey
        await ctx.respond("Creating the multiple question survey with the provided questions and button types.")

        # Create views queue with the provided questions and button types
        views_queue = []
        for i in range(len(ordered_questions)):
            question = ordered_questions[i]
            button_type = ordered_button_types[i]

            if button_type == "Difficulty":
                views_queue.append(
                    DifficultyView
                    (duration=duration,
                     guild=ctx.guild,
                     topic=main_topic,
                     display_message=question,
                     views_queue=views_queue,
                     disable_after_interaction=True,
                     )
                )
            elif button_type == "Score":
                views_queue.append(
                    ScoreView(
                        duration=duration,
                        guild=ctx.guild,
                        topic=main_topic,
                        display_message=question,
                        views_queue=views_queue,
                        disable_after_interaction=True,
                    )
                )

        # Send the survey
        await channel.send(
            content=f"```{message}```",
            view=AnnouncementView(
                topic=main_topic,
                guild=ctx.guild,
                views_queue=views_queue,
                duration=duration
            ),
        )
        return

    # If parameters aren't provided, use the original interactive flow
    # Default author check.
    def is_valid_response(m: discord.Message):
        return m.author == ctx.author

    # Button list verification.
    def is_valid_buttons_list(buttons: list) -> bool:
        if len(buttons) == 0:
            return False

        for button in buttons:
            if button != "Difficulty" and button != "Score":
                return False

        return True

    # Start the interaction.
    await ctx.respond(
        "```Please send a list of the questions that should be included in the survey, you have five minutes to respond.\nYour message must be in the following format:\n"
        + "1. Question 1\n2. Question 2\n...\nn. Question n```"
    )

    # Message processing, create a list only with the questions/button types.
    def get_list(response: discord.Message) -> list:
        temp = []
        temp_split = re.split(r"\d\.", response.content)
        # First element is empty, so remove it.
        temp_split.pop(0)
        # Remove the new line character and space at the beginning for each question.
        for string in temp_split:
            if string.index(" ") == 0:
                temp.append(string.replace("\n", "").replace(" ", "", 1))
            else:
                temp.append(string.replace("\n", ""))
        return temp

    # Get list of the questions.
    try:
        response: discord.Message = await bot.wait_for(
            "message", check=is_valid_response, timeout=300.0
        )
    except TimeoutError:
        return await ctx.send_followup("Sorry, you took too long to respond.")

    questions_list = get_list(response=response)
    logger.info(f"Creating survey with questions: {questions_list}")
    if len(questions_list) == 0:
        await ctx.send_followup(
            "Invalid question list provided, interaction aborted.\nPlease try again later."
        )
        return
    else:
        await ctx.send_followup(
            "```Please send a list of the button type that should be used for each question, you have five minutes to respond."
            + "\nThere are two supported button types: 'Difficulty' and 'Score', make sure to write the types without any typos!"
            + "\nYour message must be in the following format:\n"
            + "1. ButtonType 1\n2. ButtonType 2\n...\nn. ButtonType n```"
        )

    # Get list of the button types.
    try:
        response: discord.Message = await bot.wait_for(
            "message", check=is_valid_response, timeout=300.0
        )
    except TimeoutError:
        return await ctx.send_followup("Sorry, you took too long to respond.")

    button_types_list = get_list(response=response)
    if is_valid_buttons_list(button_types_list):
        await ctx.send_followup(
            "Creating the multiple question survey, it may take some time."
        )
    else:
        await ctx.send_followup(
            "Invalid button type list provided, interaction aborted.\nPlease try again later."
        )
        return

    if len(questions_list) != len(button_types_list):
        await ctx.send_followup(
            "The number of questions is not equal to the number of button types, interaction aborted.\nPlease try again later"
        )
        return

    # Prepare the dictionary with the views.
    views_queue = []
    for type in button_types_list:
        match (type):
            case "Difficulty":
                views_queue.append(
                    DifficultyView(
                        guild=ctx.guild,
                        topic=main_topic,
                        display_message=questions_list.pop(0),
                        views_queue=views_queue,
                        disable_after_interaction=True,
                    )
                )
            case "Score":
                views_queue.append(
                    ScoreView(
                        guild=ctx.guild,
                        topic=main_topic,
                        display_message=questions_list.pop(0),
                        views_queue=views_queue,
                        disable_after_interaction=True,
                    )
                )

    await channel.send(
        content=f"```{message}```",
        view=AnnouncementView(
            topic=main_topic,
            guild=ctx.guild,
            views_queue=views_queue,
            duration=duration
        ),
    )


@bot.slash_command(name="create-simple-survey", description="Create a one question survey."
                   )
@option("message", description="Survey announcement message.")
@option(
    "button_type",
    description="The button that will be attached to the survey.",
    choices=["Difficulty", "Score"],
)
@option(
    "main_topic",
    description='The main topic of the survey, e.g. "exercise T01E01".',
)
@option(
    "channel", discord.TextChannel, description="The channel to publish the survey."
)
async def create_simple_survey(
        ctx: discord.ApplicationContext,
        message: str,
        button_type: str,
        main_topic: str,
        channel: discord.TextChannel,
        duration: float
):
    """Create a simple survey with a single question."""
    await ctx.respond("Creating the survey, it may take some time.")

    # Prepare the view.
    view = (
        DifficultyView(duration=duration, guild=ctx.guild, topic=main_topic, display_message=message)
        if button_type.lower() == "difficulty"
        else ScoreView(duration=duration, guild=ctx.guild, topic=main_topic, display_message=message)
    )

    await channel.send(content=f"```{message}```", view=view)

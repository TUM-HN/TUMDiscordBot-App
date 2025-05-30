"""
Contains various views used when interacting with the bot.

:copyright: (c) 2023-present Ivan Parmacli
:license: MIT, see LICENSE for more details.
"""

import discord
import logging
import REST.utils.bot_context as bc
import importlib, sys as _sys
from pathlib import Path

from discord.enums import ButtonStyle
from shared import SurveyEntry
from utility import save_survey_entry_to_csv
from datetime import datetime
from bot.ui.button import DynamicButton

# Get the logger configured in app.py
logger = logging.getLogger('discord_bot')


def _bot():
    return bc.get_live_bot()


class TutorSessionView(discord.ui.View):
    """Represents a custom UI view.
    A view that is used to collect the student's feedback regarding the specified tutor session with the use of embeded message and buttons.
    The students see the survey as anonymous, but we still save the name of the student for each entry.

    Parameters
    ----------
    *items: :class:`Item`
        The initial items attached to this view.
    timeout: Optional[:class:`float`]
        Timeout in seconds from last interaction with the UI before no longer accepting input.
        If ``None`` then there is no timeout.
    group_id: :class:`str`
        Tutor group id, e.g. 'g5'

    Attributes
    ----------
    timeout: Optional[:class:`float`]
        Timeout from last interaction with the UI before no longer accepting input.
        If ``None`` then there is no timeout.
    children: List[:class:`Item`]
        The list of children attached to this view.
    disable_on_timeout: :class:`bool`
        Whether to disable the view when the timeout is reached. Defaults to ``False``.
    message: Optional[:class:`.Message`]
        The message that this view is attached to.
        If ``None`` then the view has not been sent with a message.
    parent: Optional[:class:`.Interaction`]
        The parent interaction which this view was sent from.
        If ``None`` then the view was not sent using :meth:`InteractionResponse.send_message`.
    group_id: :class:`str`
        Tutor group id.
    """

    def __init__(self, group_id: str, duration):
        super().__init__(timeout=duration, disable_on_timeout=True)
        self.group_id = group_id
        self.users_interacted_with_view = []
        self.users_good_review = []
        self.users_satisfactory_review = []
        self.users_poor_review = []
        self.good_feedback_percentage = 0
        self.mid_feedback_percentage = 0
        self.bad_feedback_percentage = 0
        current_time = datetime.now().strftime("%Y-%m-%d_%H-%M")
        # Resolve absolute path for tutor session feedback
        project_root = Path(__file__).resolve().parents[2]
        feedback_dir = project_root / 'data' / 'tutor_session_feedback'
        feedback_dir.mkdir(exist_ok=True, parents=True)
        self.path = str(feedback_dir / f"{group_id}_{current_time}.csv")

    @discord.ui.button(label="Good", style=ButtonStyle.primary)
    async def good_callback(
            self, button: discord.ui.Button, interaction: discord.Interaction
    ):
        if interaction.user.id not in self.users_interacted_with_view:
            self.users_interacted_with_view.append(interaction.user.id)
            # Format: "DisplayName (username)"
            student_name = f"{interaction.guild.get_member(interaction.user.id).display_name} ({interaction.user.name})"
            self.users_good_review.append(
                SurveyEntry(student_name, {"Feedback": "Good"})
            )
            await interaction.response.edit_message(
                embed=self.update_percentage(interaction.message.embeds[0])
            )
        else:
            # Nothing to update
            await interaction.response.edit_message(embed=interaction.message.embeds[0])

    @discord.ui.button(label="Satisfactory", style=ButtonStyle.primary)
    async def satisfactory_callback(
            self, button: discord.ui.Button, interaction: discord.Interaction
    ):
        if interaction.user.id not in self.users_interacted_with_view:
            self.users_interacted_with_view.append(interaction.user.id)
            # Format: "DisplayName (username)"
            student_name = f"{interaction.guild.get_member(interaction.user.id).display_name} ({interaction.user.name})"
            self.users_satisfactory_review.append(
                SurveyEntry(student_name, {"Feedback": "Satisfactory"})
            )
            await interaction.response.edit_message(
                embed=self.update_percentage(interaction.message.embeds[0])
            )
        else:
            # Nothing to update
            await interaction.response.edit_message(embed=interaction.message.embeds[0])

    @discord.ui.button(label="Poor", style=ButtonStyle.primary)
    async def poor_callback(
            self, button: discord.ui.Button, interaction: discord.Interaction
    ):
        if interaction.user.id not in self.users_interacted_with_view:
            self.users_interacted_with_view.append(interaction.user.id)
            # Format: "DisplayName (username)"
            student_name = f"{interaction.guild.get_member(interaction.user.id).display_name} ({interaction.user.name})"
            self.users_poor_review.append(
                SurveyEntry(student_name, {"Feedback": "Poor"})
            )
            await interaction.response.edit_message(
                embed=self.update_percentage(interaction.message.embeds[0])
            )
        else:
            # Nothing to update
            await interaction.response.edit_message(embed=interaction.message.embeds[0])

    async def on_timeout(self) -> None:
        self.disable_all_items()
        
        # Count total entries across all feedback types
        total_entries = len(self.users_good_review) + len(self.users_satisfactory_review) + len(self.users_poor_review)
        
        for list in [
            self.users_good_review,
            self.users_satisfactory_review,
            self.users_poor_review,
        ]:
            for entry in list:
                save_survey_entry_to_csv(self.path, entry)
        
        # Log feedback completion information
        logger.info(f"DEBUG: Saved {total_entries} responses for tutor session feedback (group {self.group_id}) to {self.path}")
        
        return await super().on_timeout()

    def update_percentage(self, embed: discord.Embed) -> discord.Embed:
        """
        Updates the percentage for each option in the embed according to the number of entires in the lists and returns the updated Embed variable.

        Args:
            embed :class:`discord.Embed`: Original Embed.

        Returns:
            :class:`discord.Embed`: Updated Embed.
        """
        for field in embed.fields:
            if "Participants" in field.name:
                field.name = "Participants: " + str(
                    len(self.users_interacted_with_view)
                )
            match field.name:
                case "Good":
                    field.value = (
                            "`"
                            + str(
                        format(
                            len(self.users_good_review)
                            / (len(self.users_interacted_with_view) / 100),
                            ".2f",
                        )
                    )
                            + " %`"
                    )
                case "Satisfactory":
                    field.value = (
                            "`"
                            + str(
                        format(
                            len(self.users_satisfactory_review)
                            / (len(self.users_interacted_with_view) / 100),
                            ".2f",
                        )
                    )
                            + " %`"
                    )
                case "Poor":
                    field.value = (
                            "`"
                            + str(
                        format(
                            len(self.users_poor_review)
                            / (len(self.users_interacted_with_view) / 100),
                            ".2f",
                        )
                    )
                            + " %`"
                    )
        return embed


class AnnouncementView(discord.ui.View):
    """Represents a custom UI view.
    Initial view that is attached to the main message.\n
    Allows students to participate in the survey.

    Parameters
    ----------
    *items: :class:`Item`
        The initial items attached to this view.
    timeout: Optional[:class:`float`]
        Timeout in seconds from last interaction with the UI before no longer accepting input.
        If ``None`` then there is no timeout.
    topic: :class:`str`
        The main topic of the current survey.
    guild: :class:`discord.Guild`
        The guild associated with the view.
    views_queue: :class:`list`
        The views queue that will be used to continue the current interaction and extend the survey.


    Attributes
    ----------
    timeout: Optional[:class:`float`]
        Timeout from last interaction with the UI before no longer accepting input.
        If ``None`` then there is no timeout.
    children: List[:class:`Item`]
        The list of children attached to this view.
    disable_on_timeout: :class:`bool`
        Whether to disable the view when the timeout is reached. Defaults to ``False``.
    message: Optional[:class:`.Message`]
        The message that this view is attached to.
        If ``None`` then the view has not been sent with a message.
    parent: Optional[:class:`.Interaction`]
        The parent interaction which this view was sent from.
        If ``None`` then the view was not sent using :meth:`InteractionResponse.send_message`.
    users_interacted_with_view: :class:`list`
        The list of the user ids that interracted with the view.
    topic: :class:`str`
        The main topic of the current survey.
    guild: :class:`discord.Guild`
        The guild associated with the view.
    views_queue: :class:`list`
        The views queue that will be used to continue the current interaction and extend the survey.
    """

    def __init__(self, topic: str, guild: discord.Guild, views_queue: list, duration: float | None = 80):
        # Use the provided duration so the announcement stays interactive for at least as long as the survey views
        super().__init__(timeout=duration, disable_on_timeout=True)
        self.users_interacted_with_view = []
        self.topic = topic
        self.guild = guild
        # Store a *template* of the views queue so it can be duplicated for every participant
        # We keep the original list intact to make sure that subsequent participants
        # always receive the full survey (Q1, Q2, Q3, ...).
        self.views_queue_template = views_queue

    @discord.ui.button(label="Participate", style=ButtonStyle.green)
    async def participate_callback(
            self, button: discord.ui.Button, interaction: discord.Interaction
    ):
        await interaction.response.edit_message(view=self)
        if interaction.user.id not in self.users_interacted_with_view:
            self.users_interacted_with_view.append(interaction.user.id)
            # Create a *fresh* copy of the template views queue for this participant.
            participant_queue: list[discord.ui.View] = []

            # Helper to clone a view based on its type
            def _clone_view(original_view):
                common_kwargs = {
                    "duration": original_view.timeout,
                    "guild": self.guild,
                    "topic": original_view.topic,
                    "display_message": original_view.display_message,
                    "views_queue": None,  # Placeholder; will set after queue is built
                    "disable_after_interaction": getattr(original_view, "disable_after_interaction", False),
                }

                if hasattr(original_view, "type") and original_view.type == "Difficulty":
                    return DifficultyView(**common_kwargs)
                else:  # Default to ScoreView
                    return ScoreView(**common_kwargs)

            # Build new queue with cloned views
            for v in self.views_queue_template:
                participant_queue.append(_clone_view(v))

            # Now that the list is complete, assign the shared queue reference to each view
            for v in participant_queue:
                v.views_queue = participant_queue

            # Pop the first view (Q1) for the participant
            first_view = participant_queue.pop(0)

            await interaction.user.send(
                content=f"```{first_view.display_message}```", view=first_view
            )
        else:
            await interaction.user.send("You've already taken the survey.")


class DifficultyView(discord.ui.View):
    """Represents a custom UI view.
    A view that is used to gather the student's opinion on how challenging the assigned topic was.

    Parameters
    ----------
    *items: :class:`Item`
        The initial items attached to this view.
    timeout: Optional[:class:`float`]
        Timeout in seconds from last interaction with the UI before no longer accepting input.
        If ``None`` then there is no timeout.
    guild: :class:`discord.Guild`
        The guild associated with the view.
    topic: :class:`str`
        The main topic of the current survey.
    message: :class:`str`
        The message that will be displayed with the view.
    views_queue: :class:`list`
        The views queue that will be used to continue the current interaction and extend the survey.
    disable_after_interaction: :class:`bool`
        If the view element(s) must be disabled after the interaction is complete.

    Attributes
    ----------
    timeout: Optional[:class:`float`]
        Timeout from last interaction with the UI before no longer accepting input.
        If ``None`` then there is no timeout.
    children: List[:class:`Item`]
        The list of children attached to this view.
    disable_on_timeout: :class:`bool`
        Whether to disable the view when the timeout is reached. Defaults to ``False``.
    message: Optional[:class:`.Message`]
        The message that this view is attached to.
        If ``None`` then the view has not been sent with a message.
    parent: Optional[:class:`.Interaction`]
        The parent interaction which this view was sent from.
        If ``None`` then the view was not sent using :meth:`InteractionResponse.send_message`.
    users_interacted_with_view: :class:`list`
        The list of the user ids that interracted with the view.
    type: :class:`str`
        The view type.
    guild: :class:`discord.Guild`
        The guild associated with the view.
    topic: :class:`str`
        The main topic of the current survey.
    display_message: :class:`str`
        The message that will be displayed with the view.
    views_queue: :class:`list`
        The views queue that will be used to continue the current interaction and extend the survey.
    disable_after_interaction: :class:`bool`
        If the view element(s) must be disabled after the interaction is complete.
    survey_entry: :class:`shared.entry.SurveyEntry`
        The survey entry that contains the student's name and answers.
    all_survey_entries: :class:`list`
        The list to store all survey entries.
    """

    def __init__(
            self,
            duration: float | None = 30,
            guild: discord.Guild | None = None,
            topic: str | None = "Empty",
            display_message: str | None = "Empty",
            views_queue: list | None = None,
            disable_after_interaction: bool | None = False
    ):
        super().__init__(timeout=duration, disable_on_timeout=True)
        self.users_interacted_with_view = []
        self.type = "Difficulty"
        self.guild = guild
        self.topic = topic
        self.display_message = display_message
        self.views_queue = views_queue
        self.disable_after_interaction = disable_after_interaction
        self.survey_entry = SurveyEntry()
        self.all_survey_entries = []  # List to store all survey entries
        self.children.append(
            DynamicButton(
                label="Very Easy", style=ButtonStyle.green, view_reference=self
            )
        )
        self.children.append(
            DynamicButton(label="Easy", style=ButtonStyle.primary, view_reference=self)
        )
        self.children.append(
            DynamicButton(
                label="Medium", style=ButtonStyle.primary, view_reference=self
            )
        )
        self.children.append(
            DynamicButton(label="Hard", style=ButtonStyle.primary, view_reference=self)
        )
        self.children.append(
            DynamicButton(label="Very Hard", style=ButtonStyle.red, view_reference=self)
        )

    async def on_timeout(self) -> None:
        """Save all survey entries when the view times out."""
        self.disable_all_items()
        
        # Determine survey type (CS for complex, SS for simple)
        survey_type = "CS" if hasattr(self, 'from_complex') and self.from_complex else "SS"
        
        # Generate filename with timestamp
        current_time = datetime.now().strftime("%Y-%m-%d_%H-%M")
        # Resolve absolute path for exercise feedback
        project_root = Path(__file__).resolve().parents[2]
        survey_dir = project_root / 'data' / 'exercise_feedback'
        survey_dir.mkdir(exist_ok=True, parents=True)
        path = str(survey_dir / f"{survey_type}_{self.topic}_{current_time}.csv")
        
        # Save all collected entries
        entry_count = len(self.all_survey_entries)
        for entry in self.all_survey_entries:
            save_survey_entry_to_csv(path=path, entry=entry)
        
        # Log survey completion information
        logger.info(f"DEBUG: Saved {entry_count} responses for {survey_type} survey on topic '{self.topic}' to {path}")
        
        return await super().on_timeout()


class ScoreView(discord.ui.View):
    """Represents a custom UI view.
    A view that is used to collect students' opinions about the expected grade they will receive for a specified topic.

    Parameters
    ----------
    *items: :class:`Item`
        The initial items attached to this view.
    timeout: Optional[:class:`float`]
        Timeout in seconds from last interaction with the UI before no longer accepting input.
        If ``None`` then there is no timeout.
    guild: :class:`discord.Guild`
        The guild associated with the view.
    topic: :class:`str`
        The main topic of the current survey.
    message: :class:`str`
        The message that will be displayed with the view.
    views_queue: :class:`list`
        The views queue that will be used to continue the current interaction and extend the survey.
    disable_after_interaction: :class:`bool`
        If the view element(s) must be disabled after the interaction is complete.

    Attributes
    ----------
    timeout: Optional[:class:`float`]
        Timeout from last interaction with the UI before no longer accepting input.
        If ``None`` then there is no timeout.
    children: List[:class:`Item`]
        The list of children attached to this view.
    disable_on_timeout: :class:`bool`
        Whether to disable the view when the timeout is reached. Defaults to ``False``.
    message: Optional[:class:`.Message`]
        The message that this view is attached to.
        If ``None`` then the view has not been sent with a message.
    parent: Optional[:class:`.Interaction`]
        The parent interaction which this view was sent from.
        If ``None`` then the view was not sent using :meth:`InteractionResponse.send_message`.
    users_interacted_with_view: :class:`list`
        The list of the user ids that interracted with the view.
    type: :class:`str`
        The view type.
    guild: :class:`discord.Guild`
        The guild associated with the view.
    topic: :class:`str`
        The main topic of the current survey.
    display_message: :class:`str`
        The message that will be displayed with the view.
    views_queue: :class:`list`
        The views queue that will be used to continue the current interaction and extend the survey.
    disable_after_interaction: :class:`bool`
        If the view element(s) must be disabled after the interaction is complete.
    survey_entry: :class:`shared.entry.SurveyEntry`
        The survey entry that contains the student's name and answers.
    all_survey_entries: :class:`list`
        The list to store all survey entries.
    """

    def __init__(
            self,
            duration: float | None = 30,
            guild: discord.Guild | None = None,
            topic: str | None = "Empty",
            display_message: str | None = "Empty",
            views_queue: list | None = None,
            disable_after_interaction: bool | None = False,
    ):
        super().__init__(timeout=duration, disable_on_timeout=True)
        self.users_interacted_with_view = []
        self.type = "Score"
        self.guild = guild
        self.topic = topic
        self.display_message = display_message
        self.views_queue = views_queue
        self.disable_after_interaction = disable_after_interaction
        self.survey_entry = SurveyEntry()
        self.all_survey_entries = []  # List to store all survey entries
        self.children.append(
            DynamicButton(label="20%", style=ButtonStyle.red, view_reference=self)
        )
        self.children.append(
            DynamicButton(label="40%", style=ButtonStyle.primary, view_reference=self)
        )
        self.children.append(
            DynamicButton(label="60%", style=ButtonStyle.primary, view_reference=self)
        )
        self.children.append(
            DynamicButton(label="80%", style=ButtonStyle.primary, view_reference=self)
        )
        self.children.append(
            DynamicButton(label="100%", style=ButtonStyle.green, view_reference=self)
        )

    async def on_timeout(self) -> None:
        """Save all survey entries when the view times out."""
        self.disable_all_items()
        
        # Only save entries if there are any and this is the final view
        if self.all_survey_entries and (self.views_queue is None or not self.views_queue):
            # Determine survey type (CS for complex, SS for simple)
            survey_type = "CS" if hasattr(self, 'from_complex') and self.from_complex else "SS"
            
            # Generate filename with timestamp
            current_time = datetime.now().strftime("%Y-%m-%d_%H-%M")
            # Resolve absolute path for exercise feedback
            project_root = Path(__file__).resolve().parents[2]
            survey_dir = project_root / 'data' / 'exercise_feedback'
            survey_dir.mkdir(exist_ok=True, parents=True)
            path = str(survey_dir / f"{survey_type}_{self.topic}_{current_time}.csv")
            
            # Save all collected entries
            entry_count = len(self.all_survey_entries)
            for entry in self.all_survey_entries:
                save_survey_entry_to_csv(path=path, entry=entry)
            
            # Log survey completion information
            logger.info(f"DEBUG: Saved {entry_count} responses for {survey_type} survey on topic '{self.topic}' to {path}")
                
        return await super().on_timeout()

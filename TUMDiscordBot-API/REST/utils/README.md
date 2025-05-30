# REST Utils Package

This package contains utility functions and classes used across the REST API for the Discord Bot.

## Modules

### bot_context.py

This module provides functions and classes related to the bot's context and status:

- `MockContext`: A mock implementation of Discord's ApplicationContext for API interactions

## Global Variables

The package also exposes several global variables:

- `bot_thread`: Thread where the bot is running
- `bot_running`: Boolean flag indicating whether the bot is running
- `mock_ctx`: A cached instance of MockContext

## Usage

To use these utilities in your code:

```python
from REST.utils import (
    MockContext,
    bot_thread,
    bot_running,
    mock_ctx
)
``` 
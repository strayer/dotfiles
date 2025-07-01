# SbarLua Cheatsheet

This document provides a quick reference for using SbarLua with SketchyBar. For a comprehensive guide, you can always consult the [SbarLua DeepWiki](https://deepwiki.com/FelixKratz/SbarLua).

## Core Concepts

SbarLua allows you to write your SketchyBar configurations in Lua, providing a more structured and powerful way to manage your bar.

## Basic Structure

A typical `sbarlua` configuration has the following structure:

```lua
local sbar = require('sbar')

-- Configure the bar
sbar.bar({
  position = 'top',
  height = 30,
  -- ... other bar settings
})

-- Add an item
sbar.add('item', 'my_item', {
  position = 'left',
  icon = '🚀',
  -- ... other item settings
})

-- Add an event
sbar.add('event', 'my_event', {
  -- event settings
})

-- Subscribe an item to an event
sbar.subscribe('my_item', 'my_event', {
  -- subscription settings
})
```

## Key Functions

- `sbar.bar({...})`: Configures the main bar.
- `sbar.add('item', 'name', {...})`: Adds a new item.
- `sbar.add('event', 'name', {...})`: Adds a new event.
- `sbar.subscribe('item_name', 'event_name', {...})`: Subscribes an item to an event.
- `sbar.remove('item_name')`: Removes an item.
- `sbar.trigger('event_name', 'payload')`: Triggers a custom event.
- `sbar.exec('command')`: Executes a shell command.

## Properties

The properties for the bar and items are the same as in the standard SketchyBar configuration, but are specified in Lua syntax (e.g., `font_size = 12` instead of `font_size=12`).

For a complete list of properties, please refer to the SketchyBar documentation or the [SketchyBar Cheatsheet](./CHEATSHEET_SketchyBar.md).

For more in-depth information on SbarLua, please refer to the [SbarLua DeepWiki](https://deepwiki.com/FelixKratz/SbarLua).
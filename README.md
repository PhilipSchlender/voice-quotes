# Voice-Quotes

## Introduction

Voice-Quotes is a plugin written for [SourceMod](https://www.sourcemod.net/). It enables players to play voice quotes based on queries written in the chat. These voice quotes are played to all connected players.

## How to use in game

1. Open the chat.

2. Enter either ```!voice_quote``` or ```!vq``` followed by a search query, e.g. ```!vq yee-haw```. If there is a voice quote, which player or quote text machtes the query, the corresponding sound file is played to all players. There is a configurable cooldown on the use of the voice quotes to prevent spamming of quotes.

## Requirements

[Metamod](https://www.sourcemm.net/) and [SourceMod](https://www.sourcemod.net/) in versions 1.11 or greater.

## How to setup

### Install the plugin

1. Navigate into the ```addons/sourcemod/plugins``` directory on the server.

2. Copy the compiled plugin file ```voice_quotes.smx``` into the directory.

### Add the sound files

1. Navigate into the ```sound``` directory of the server.

2. Create a new directory ```voice_quotes```.

3. Copy the voice quote sound files into the newly created directory. Only ```*.wav``` files are supported for now.

4. Compress the sound files and add them to the corresponding directory on the [FastDL](https://developer.valvesoftware.com/wiki/FastDL) server.


### Add the configuration

1. Navigate into the ```addons/sourcemod/configs``` directory of the server.

2. Create a new directory ```voice_quotes```.

3. Create a new configuration file ```voice_quotes.cfg``` with the following content in the newly created directory:

    ```bash
    "voice_quotes"
    {
        "0"
        {
            "player" "medic"
            "quote" "excellent"
            "filename" "medic_cheers01.wav"
            "duration" "1"
        }
        "0"
        {
            "player" "engineer"
            "quote" "yee-haw"
            "filename" "engineer_battlecry07.wav"
            "duration" "2"
        }
    }
    ```

    Each voice quote is defined by the name of the player who said the quote, the quote text, the name of the sound file of the quote and the duration of the sound in seconds.

    For testing purposes you can use the generic voice commands of the different classes of Team Fortress 2, see [Team Fortress 2 Official Wiki](https://wiki.teamfortress.com/wiki/Category:Voice_command_audio).

    Each time new sound files are added to the configuration, the voice quotes plugin must be reloaded with the ```sm_rcon sm plugins voice_quotes``` command via the server console. This is because the plugin only reads the configuration file when the plugin is started. However, note that new sound files can only be played after a map change as they have to be precached once the map has started.

### Available console variables to control the behaviour of the plugin

| Name                  | Default value | Description |
| :-------------------- | :------------ | :---------- |
| voice_quotes_enabled  | 1             | Sets whether voice quotes are enabled. |
| voice_quotes_cooldown | 3             | Sets the cooldown in seconds for using voice quotes. |

### Optional: Adjust the pure server whitelist configuration

If the server is running with the ```sv_pure 1``` setting, the whitelist of the server has to be adjusted.

1. Navigate into the ```cfg``` directory of the server.

2. If not yet present, add a new configuration file ```pure_server_whitelist.txt```.

3. Add the following content to the file:

    ```bash
    whitelist
    {
        sound\voice_quotes\... allow_from_disk
    }
    ```

    This configuration allows clients to load the sound files from disk. For more information see [Pure_Servers](https://developer.valvesoftware.com/wiki/Pure_Servers).

## Ideas for future features

- Allow a player to view all available voice quotes
- Allow a player to disable the voice quotes for themselves

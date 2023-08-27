#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define MAXIMUM_LENGTH_FILE 256
#define MAXIMUM_LENGTH_FILENAME 64
#define MAXIMUM_LENGTH_PLAYER 32
#define MAXIMUM_LENGTH_QUERY 32
#define MAXIMUM_LENGTH_QUOTE 128
#define MAXIMUM_LENGTH_SECTION 32
#define MAXIMUM_LENGTH_STEAM_ID 32

Configuration configuration;

VoiceQuotes voiceQuotes;

Cooldowns cooldowns;

#include "voice_quotes/client.sp"
#include "voice_quotes/configuration.sp"
#include "voice_quotes/cooldowns.sp"
#include "voice_quotes/server.sp"
#include "voice_quotes/voice_quote.sp"
#include "voice_quotes/voice_quotes.sp"

public Plugin myinfo =
{
    author = "Philip Schlender",
    description = "Play voice quotes based on client queries.",
    name = "Voice Quotes",
    url = "https://github.com/PhilipSchlender/voice-quotes",
    version = "2.0.0"
};

/**
 * Called when the plugin is fully initialized and all known external references are resolved.
 */
public void OnPluginStart()
{
    configuration = new Configuration();

    voiceQuotes = new VoiceQuotes();

    CreateConsoleCommands();

    LoadVoiceQuotes();
}

/**
 * Called when the map is loaded.
 */
public void OnMapStart()
{
    cooldowns = new Cooldowns();

    PrepareVoiceQuotes();
}

/**
 * Called right before a map ends.
 */
public void OnMapEnd()
{
    CloseHandle(cooldowns);
}

/**
 * Creates console commands.
 */
public void CreateConsoleCommands()
{
    RegConsoleCmd("voice_quote", VoiceQuoteCommand);
    RegConsoleCmd("vq", VoiceQuoteCommand);
}

/**
 * Loads the voice quotes.
 *
 * @error
 */
public void LoadVoiceQuotes()
{
    char file[MAXIMUM_LENGTH_FILE];
    BuildPath(Path_SM, file, sizeof(file), "configs/voice_quotes/voice_quotes.cfg");

    if (! FileExists(file)) {
        ThrowError("Failed to find file \"%s\".", file);
    }

    KeyValues config = new KeyValues("voice_quotes");

    config.SetEscapeSequences(true);

    if (! config.ImportFromFile(file)) {
        ThrowError("Failed to import file \"%s\".", file);
    }

    bool foundSection = false;

    do {
        char section[MAXIMUM_LENGTH_SECTION];

        if (! config.GetSectionName(section, sizeof(section))) {
            ThrowError("Failed to get section name in file \"%s\".", file);
        }

        if (StrEqual(section, "voice_quotes")) {
            foundSection = true;

            break;
        }
    } while (config.GotoNextKey());

    if (! foundSection) {
        ThrowError("Failed to find section \"voice_quotes\" in file \"%s\".", file);
    }

    if (! config.GotoFirstSubKey()) {
        ThrowError("Failed to find first subsection in file \"%s\".", file);
    }

    do {
        char player[MAXIMUM_LENGTH_PLAYER];
        config.GetString("player", player, sizeof(player));

        char quote[MAXIMUM_LENGTH_QUOTE];
        config.GetString("quote", quote, sizeof(quote));

        char filename[MAXIMUM_LENGTH_FILENAME];
        config.GetString("filename", filename, sizeof(filename));

        int duration = config.GetNum("duration");

        if (StrEqual(player, "")) {
            ThrowError("Invalid value for key \"player\" in subsection in file \"%s\".", file);
        }

        if (StrEqual(quote, "")) {
            ThrowError("Invalid value for key \"quote\" in subsection in file \"%s\".", file);
        }

        if (StrEqual(filename, "")) {
            ThrowError("Invalid value for key \"filename\" in subsection in file \"%s\".", file);
        }

        if (duration <= 0) {
            ThrowError("Invalid value for key \"duration\" in subsection in file \"%s\".", file);
        }

        VoiceQuote voiceQuote = new VoiceQuote(player, quote, filename, duration);

        voiceQuotes.Push(voiceQuote);

        LogMessage("Successfully loaded voice quote \"%s\" of player \"%s\".", quote, player);
    } while (config.GotoNextKey());

    CloseHandle(config);
}

/**
 * Precaches the voice quotes.
 */
public void PrepareVoiceQuotes()
{
    int length = voiceQuotes.Length;

    for (int i = 0; i < length; i++) {
        VoiceQuote voiceQuote = voiceQuotes.Get(i);

        char file[MAXIMUM_LENGTH_FILE];
        voiceQuote.GetFile(file, sizeof(file));

        if (! FileExists(file)) {
            LogError("Failed to find file \"%s\".", file);

            continue;
        }

        AddFileToDownloadsTable(file);

        ReplaceString(file, MAXIMUM_LENGTH_FILE, "sound/", "");

        if (! PrecacheSound(file, true)) {
            LogError("Failed to precache file \"%s\".", file);
        }

        LogMessage("Successfully precached file \"%s\".", file);
    }
}

/**
 * Voice quote command.
 *
 * Checks whether the server or the client has a cooldown. If so nothing will be done.
 * Searches for voice quotes matching the query and plays a random voice quote from the corresponding list.
 * Sets the cooldown for the server and the client.
 *
 * @param index Client index.
 * @param numberOfArguments Number of arguments.
 * @return Action
 */
public Action VoiceQuoteCommand(int index, int numberOfArguments)
{
    if (! configuration.IsEnabled()) {
        return Plugin_Handled;
    }

    char query[MAXIMUM_LENGTH_QUERY];
    GetCmdArgString(query, sizeof(query));

    if (! IsValidQuery(query)) {
        return Plugin_Handled;
    }

    Server server = new Server();
    Client client = new Client(index);

    if (server.HasCooldown() || client.HasCooldown()) {
        int serverCooldown = server.GetCooldown();
        int clientCooldown = client.GetCooldown();
        int maximumCooldown = 0;

        if (serverCooldown >= clientCooldown) {
            maximumCooldown = serverCooldown;
        } else {
            maximumCooldown = clientCooldown;
        }

        if (maximumCooldown > 1) {
            PrintToChat(index, "[SM] Please wait %d seconds before using voice quotes again.", maximumCooldown);
        } else {
            PrintToChat(index, "[SM] Please wait %d second before using voice quotes again.", maximumCooldown);
        }

        CloseHandle(server);
        CloseHandle(client);

        return Plugin_Handled;
    }

    VoiceQuote voiceQuote;
    if (! FindVoiceQuote(query, voiceQuote)) {
        PrintToChat(index, "[SM] No voice quote found which matches the query \"%s\".", query);

        CloseHandle(server);
        CloseHandle(client);

        return Plugin_Handled;
    }

    char player[MAXIMUM_LENGTH_PLAYER];
    voiceQuote.GetPlayer(player, sizeof(player));

    char quote[MAXIMUM_LENGTH_QUOTE];
    voiceQuote.GetQuote(quote, sizeof(quote));

    if (! PlayVoiceQuote(voiceQuote)) {
        LogError("Failed to play voice quote \"%s\" of player \"%s\".", quote, player);

        CloseHandle(server);
        CloseHandle(client);

        return Plugin_Handled;
    }

    int duration = voiceQuote.GetDuration();
    int serverCooldown = configuration.GetServerCooldown();
    int clientCooldown = configuration.GetClientCooldown();

    int newServerCooldown = duration + serverCooldown;
    int newClientCooldown = duration + clientCooldown;

    server.SetCooldown(newServerCooldown);
    client.SetCooldown(newClientCooldown);

    PrintToChatAll("[SM] Playing voice quote \"%s\" of player \"%s\".", quote, player);

    CloseHandle(server);
    CloseHandle(client);

    return Plugin_Handled;
}

/**
 * Checks whether the query is valid.
 *
 * @param query Query
 * @return True if the query is valid, false otherwise.
 */
public bool IsValidQuery(const char[] query)
{
    return strlen(query) > 0;
}

/**
 * Searches for a voice quote matching the query.
 *
 * If multiple voice quotes match the query one of them is selected at random.
 *
 * @param query Query.
 * @param matchedVoiceQuote Buffer to store the matched voice qoute.
 * @return True if a voice quote matches, false otherwise.
 */
public bool FindVoiceQuote(const char[] query, VoiceQuote &matchedVoiceQuote)
{
    VoiceQuotes matchedVoiceQuotes = new VoiceQuotes();

    int length = voiceQuotes.Length;

    for (int i = 0; i < length; i++) {
        VoiceQuote voiceQuote = voiceQuotes.Get(i);

        char player[MAXIMUM_LENGTH_PLAYER];
        voiceQuote.GetPlayer(player, sizeof(player));

        char quote[MAXIMUM_LENGTH_QUOTE];
        voiceQuote.GetQuote(quote, sizeof(quote));

        if (StrContains(player, query, false) != -1 || StrContains(quote, query, false) != -1) {
            matchedVoiceQuotes.Push(voiceQuote);
        }
    }

    length = matchedVoiceQuotes.Length;

    if (length == 0) {
        CloseHandle(matchedVoiceQuotes);

        return false;
    }

    int i = GetRandomInt(0, length - 1);

    matchedVoiceQuote = matchedVoiceQuotes.Get(i);

    CloseHandle(matchedVoiceQuotes);

    return true;
}

/**
 * Plays the voice quote.
 *
 * @param voiceQuote Voice quote to play.
 * @return True if the voice quote was played, false otherwise.
 */
public bool PlayVoiceQuote(VoiceQuote voiceQuote)
{
    char file[MAXIMUM_LENGTH_FILE];
    voiceQuote.GetFile(file, sizeof(file));

    if (! FileExists(file)) {
        return false;
    }

    ReplaceString(file, MAXIMUM_LENGTH_FILE, "sound/", "");

    for (int j = 1; j <= MaxClients; j++) {
        if (! IsClientConnected(j)) {
            continue;
        }

        EmitSoundToClient(j, file);
    }

    return true;
}

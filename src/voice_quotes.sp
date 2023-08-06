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

public Plugin myinfo =
{
    author = "Philip Schlender",
    description = "Play voice quotes based on client queries.",
    name = "Voice Quotes",
    url = "https://github.com/PhilipSchlender/voice-quotes",
    version = "1.0.0"
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
        if (! config.GetString("player", player, sizeof(player))) {
            ThrowError("Failed to get key \"player\" of subsection in file \"%s\".", file);
        }

        char quote[MAXIMUM_LENGTH_QUOTE];
        if (! config.GetString("quote", quote, sizeof(quote))) {
            ThrowError("Failed to get key \"quote\" of subsection in file \"%s\".", file);
        }

        char filename[MAXIMUM_LENGTH_FILENAME];
        if (! config.GetString("filename", filename, sizeof(filename))) {
            ThrowError("Failed to get key \"filename\" of subsection in file \"%s\".", file);
        }

        if (StrEqual(player, "")) {
            ThrowError("Invalid value for key \"player\" in subsection in file \"%s\".", file);
        }

        if (StrEqual(quote, "")) {
            ThrowError("Invalid value for key \"quote\" in subsection in file \"%s\".", file);
        }

        if (StrEqual(filename, "")) {
            ThrowError("Invalid value for key \"filename\" in subsection in file \"%s\".", file);
        }

        VoiceQuote voiceQuote = new VoiceQuote(player, quote, filename);

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

    if (ClientHasCooldown(index)) {
        int cooldown = GetRemainingCooldownOfClient(index);

        if (cooldown > 1) {
            PrintToChat(index, "[SM] Please wait %d seconds before using voice quotes again.", cooldown);
        } else {
            PrintToChat(index, "[SM] Please wait %d second before using voice quotes again.", cooldown);
        }

        return Plugin_Handled;
    }

    VoiceQuote voiceQuote;
    if (! FindVoiceQuote(query, voiceQuote)) {
        PrintToChat(index, "[SM] No voice quote found which matches the query \"%s\".", query);

        return Plugin_Handled;
    }

    char player[MAXIMUM_LENGTH_PLAYER];
    voiceQuote.GetPlayer(player, sizeof(player));

    char quote[MAXIMUM_LENGTH_QUOTE];
    voiceQuote.GetQuote(quote, sizeof(quote));

    if (! PlayVoiceQuote(voiceQuote)) {
        LogError("Failed to play voice quote \"%s\" of player \"%s\".", quote, player);

        return Plugin_Handled;
    }

    PrintToChat(index, "[SM] Playing voice quote \"%s\" of player \"%s\".", quote, player);

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
 * Checks whether the client has a cooldown.
 *
 * Sets a new cooldown if the client has no cooldown.
 *
 * @param index Client index.
 * @return True if the client has a cooldown, false otherwise.
 */
public bool ClientHasCooldown(int index)
{
    Client client = new Client(index);

    if (client.HasCooldown()) {
        CloseHandle(client);

        return true;
    }

    int cooldown = configuration.GetCooldown();

    client.SetCooldown(cooldown);

    CloseHandle(client);

    return false;
}

/**
 * Retrieves the remaining cooldown of the client.
 *
 * @param index Client index.
 * @return Cooldown in seconds.
 */
public int GetRemainingCooldownOfClient(int index)
{
    Client client = new Client(index);

    int cooldown = client.GetCooldown();

    CloseHandle(client);

    return cooldown;
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
public bool FindVoiceQuote(const char[] query, VoiceQuote& matchedVoiceQuote)
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

/**
 * Configuration
 */
methodmap Configuration < StringMap
{
    /**
     * Creates a configuration instance.
     *
     * The configuration must be freed via CloseHandle().
     *
     * @error
     */
    public Configuration()
    {
        ConVar enabled = CreateConVar("voice_quotes_enabled", "1", "Sets whether voice quotes are enabled.", FCVAR_NONE, true, 0.0, true, 1.0);
        ConVar cooldown = CreateConVar("voice_quotes_cooldown", "3", "Sets the cooldown in seconds for using voice quotes.", FCVAR_NONE, true, 0.0, true, 600.0);

        StringMap stringMap = new StringMap();

        if (! stringMap.SetValue("enabled", enabled)) {
            ThrowError("Failed to set console variable \"voice_quotes_enabled\".");
        }

        if (! stringMap.SetValue("cooldown", cooldown)) {
            ThrowError("Failed to set console variable \"voice_quotes_cooldown\".");
        }

        return view_as<Configuration>(stringMap);
    }

    /**
     * Checks whether voice quotes are enabled.
     *
     * @return True if voice quotes are enabled, false otherwise.
     */
    public bool IsEnabled()
    {
        ConVar enabled;
        this.GetValue("enabled", enabled);

        return enabled.BoolValue;
    }

    /**
     * Retrieves the cooldown in seconds for using voice quotes.
     *
     * @return Cooldown in seconds.
     */
    public int GetCooldown()
    {
        ConVar cooldown;
        this.GetValue("cooldown", cooldown);

        return cooldown.IntValue;
    }
}

/**
 * Voice quotes
 */
methodmap VoiceQuotes < ArrayList
{
    /**
     * Creates a voice quotes instance.
     *
     * The voice quotes must be freed via CloseHandle().
     */
    public VoiceQuotes()
    {
        int size = ByteCountToCells(256);

        ArrayList arrayList = new ArrayList(size);

        return view_as<VoiceQuotes>(arrayList);
    }
}

/**
 * Voice quote
 */
methodmap VoiceQuote < StringMap
{
    /**
     * Creates a voice quote instance.
     *
     * The voice quote must be freed via CloseHandle().
     *
     * @param player Name of the player who said the quote.
     * @param quote Quote text.
     * @param filename Name of the sound file of the quote.
     * @error
     */
    public VoiceQuote(const char[] player, const char[] quote, const char[] filename)
    {
        StringMap stringMap = new StringMap();

        if (! stringMap.SetString("player", player)) {
            ThrowError("Failed to set player \"%d\".", player);
        }

        if (! stringMap.SetString("quote", quote)) {
            ThrowError("Failed to set quote \"%d\".", quote);
        }

        if (! stringMap.SetString("filename", filename)) {
            ThrowError("Failed to set filename \"%d\".", filename);
        }

        return view_as<VoiceQuote>(stringMap);
    }

    /**
     * Retrieves the name of the player who said the quote.
     *
     * @param player Buffer to store the name.
     * @param maximumLength Maximum length of the buffer.
     */
    public void GetPlayer(char[] player, int maximumLength)
    {
        this.GetString("player", player, maximumLength);
    }

    /**
     * Retrieves the quote text.
     *
     * @param quote Buffer to store the quote text.
     * @param maximumLength Maximum length of the buffer.
     */
    public void GetQuote(char[] quote, int maximumLength)
    {
        this.GetString("quote", quote, maximumLength);
    }

    /**
     * Retrieves the name of the sound file of the quote.
     *
     * @param filename Buffer to store the name.
     * @param maximumLength Maximum length of the buffer.
     */
    public void GetFilename(char[] filename, int maximumLength)
    {
        this.GetString("filename", filename, maximumLength);
    }

    /**
     * Retrieves the directory where the sound file of the quote is stored.
     *
     * @param directory Buffer to store the directory.
     * @param maximumLength Maximum length of the buffer.
     */
    public void GetDirectory(char[] directory, int maximumLength)
    {
        Format(directory, maximumLength, "sound/voice_quotes");
    }

    /**
     * Retrieves the full path of the sound file of the quote.
     *
     * @param file Buffer to store the full path.
     * @param maximumLength Maximum length of the buffer.
     */
    public void GetFile(char[] file, int maximumLength)
    {
        char directory[MAXIMUM_LENGTH_FILE];
        this.GetDirectory(directory, sizeof(directory));

        char filename[MAXIMUM_LENGTH_FILE];
        this.GetFilename(filename, sizeof(filename));

        Format(file, maximumLength, "%s/%s", directory, filename);
    }
}

/**
 * Client
 */
methodmap Client < StringMap
{
    /**
     * Creates a client instance.
     *
     * The client must be freed via CloseHandle().
     *
     * @param client client index.
     * @error
     */
    public Client(int index)
    {
        StringMap stringMap = new StringMap();

        if (! stringMap.SetValue("index", index)) {
            ThrowError("Failed to set index for client \"%d\".", index);
        }

        return view_as<Client>(stringMap);
    }

    /**
     * Retrieves the client index.
     *
     * @return Client index.
     */
    public int GetIndex()
    {
        int index;
        this.GetValue("index", index);

        return index;
    }

    /**
     * Retrieves the steam-id of the client.
     *
     * The steam-id is formatted as STEAM_X:X:X.
     *
     * @param steamId Buffer to store the steam-id.
     * @param maximumLength Maximum length of the buffer.
     * @error
     */
    public void GetSteamId(char[] steamId, int maximumLength)
    {
        int index = this.GetIndex();

        if (! GetClientAuthId(index, AuthId_Steam2, steamId, maximumLength)) {
            ThrowError("Failed to get steam-id for client \"%d\".", index);
        }
    }

    /**
     * Checks whether the client has a cooldown.
     *
     * @return True if the client has a cooldown, false otherwise.
     */
    public bool HasCooldown()
    {
        char steamId[MAXIMUM_LENGTH_STEAM_ID];
        this.GetSteamId(steamId, sizeof(steamId));

        int currentTime = GetTime();

        int time = cooldowns.GetTime(steamId);

        return time > currentTime;
    }

    /**
     * Retrieves the cooldown of the client.
     *
     * @return Cooldown in seconds.
     */
    public int GetCooldown()
    {
        char steamId[MAXIMUM_LENGTH_STEAM_ID];
        this.GetSteamId(steamId, sizeof(steamId));

        int currentTime = GetTime();

        int time = cooldowns.GetTime(steamId);

        int cooldown = time - currentTime;

        if (cooldown > 0) {
            return cooldown;
        }

        return 0;
    }

    /**
     * Sets the cooldown for the client.
     *
     * @param cooldown Cooldown in seconds.
     */
    public void SetCooldown(int cooldown)
    {
        char steamId[MAXIMUM_LENGTH_STEAM_ID];
        this.GetSteamId(steamId, sizeof(steamId));

        int currentTime = GetTime();

        int time = currentTime + cooldown;

        cooldowns.SetTime(steamId, time);
    }
}

/**
 * Cooldowns
 */
methodmap Cooldowns < StringMap
{
    /**
     * Creates a cooldowns instance.
     *
     * The cooldowns must be freed via CloseHandle().
     */
    public Cooldowns()
    {
        StringMap stringMap = new StringMap();

        return view_as<Cooldowns>(stringMap);
    }

    /**
     * Retrieves the time as a unix timestamp when the cooldown for a client has expired.
     *
     * @param steamId Steam-id of the client.
     * @return Time as a unix timestamp.
     */
    public int GetTime(const char[] steamId)
    {
        int time;
        if (! this.GetValue(steamId, time)) {
            return GetTime();
        }

        return time;
    }

    /**
     * Sets the time when the cooldown for a client will expire.
     *
     * @param steamId Steam-id of the client.
     * @param time Time as a unix timestamp.
     * @error
     */
    public void SetTime(const char[] steamId, int time)
    {
        if (! this.SetValue(steamId, time)) {
            ThrowError("Failed to set cooldown time of \"%d\" seconds for steam-id \"%s\".", time, steamId);
        }
    }
}

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
     * @param client Client index.
     * @error
     */
    public Client(int index)
    {
        StringMap stringMap = new StringMap();

        if (! stringMap.SetValue("index", index)) {
            ThrowError("Failed to set index to \"%d\".", index);
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

        int time = cooldowns.GetClientTime(steamId);

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

        int time = cooldowns.GetClientTime(steamId);

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

        cooldowns.SetClientTime(steamId, time);
    }
}


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
     * Retrieves the time when the cooldown of the server has expired.
     *
     * @return Time as a unix timestamp.
     */
    public int GetServerTime()
    {
        int time;
        if (! this.GetValue("server", time)) {
            return GetTime();
        }

        return time;
    }

    /**
     * Sets the time when the cooldown of the server will expire.
     *
     * @param time Time as a unix timestamp.
     * @error
     */
    public void SetServerTime(int time)
    {
        if (! this.SetValue("server", time)) {
            ThrowError("Failed to set cooldown time to \"%d\" for the server.", time);
        }
    }

    /**
     * Retrieves the time when the cooldown of a client has expired.
     *
     * @param steamId Steam-id of the client.
     * @return Time as a unix timestamp.
     */
    public int GetClientTime(const char[] steamId)
    {
        int time;
        if (! this.GetValue(steamId, time)) {
            return GetTime();
        }

        return time;
    }

    /**
     * Sets the time when the cooldown of a client will expire.
     *
     * @param steamId Steam-id of the client.
     * @param time Time as a unix timestamp.
     * @error
     */
    public void SetClientTime(const char[] steamId, int time)
    {
        if (! this.SetValue(steamId, time)) {
            ThrowError("Failed to set cooldown time to \"%d\" for steam-id \"%s\".", time, steamId);
        }
    }
}

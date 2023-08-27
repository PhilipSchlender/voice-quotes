/**
 * Server
 */
methodmap Server < StringMap
{
    /**
     * Creates a server instance.
     *
     * The server must be freed via CloseHandle().
     */
    public Server()
    {
        StringMap stringMap = new StringMap();

        return view_as<Server>(stringMap);
    }

    /**
     * Checks whether the server has a cooldown.
     *
     * @return True if the server has a cooldown, false otherwise.
     */
    public bool HasCooldown()
    {
        int currentTime = GetTime();

        int time = cooldowns.GetServerTime();

        return time > currentTime;
    }

    /**
     * Retrieves the cooldown of the server.
     *
     * @return Cooldown in seconds.
     */
    public int GetCooldown()
    {
        int currentTime = GetTime();

        int time = cooldowns.GetServerTime();

        int cooldown = time - currentTime;

        if (cooldown > 0) {
            return cooldown;
        }

        return 0;
    }

    /**
     * Sets the cooldown for the server.
     *
     * @param cooldown Cooldown in seconds.
     */
    public void SetCooldown(int cooldown)
    {
        int currentTime = GetTime();

        int time = currentTime + cooldown;

        cooldowns.SetServerTime(time);
    }
}

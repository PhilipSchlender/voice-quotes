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
        ConVar serverCooldown = CreateConVar("voice_quotes_server_cooldown", "5", "Sets the server cooldown in seconds after which voice quotes can be used.", FCVAR_NONE, true, 0.0, true, 600.0);
        ConVar clientCooldown = CreateConVar("voice_quotes_client_cooldown", "5", "Sets the cooldown in seconds after which a client can use voice quotes.", FCVAR_NONE, true, 0.0, true, 600.0);

        StringMap stringMap = new StringMap();

        if (! stringMap.SetValue("enabled", enabled)) {
            ThrowError("Failed to set enabled to \"%d\".", enabled.IntValue);
        }

        if (! stringMap.SetValue("serverCooldown", serverCooldown)) {
            ThrowError("Failed to set server cooldown to \"%d\".", serverCooldown.IntValue);
        }

        if (! stringMap.SetValue("clientCooldown", clientCooldown)) {
            ThrowError("Failed to set client cooldown to \"%d\".", clientCooldown.IntValue);
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
     * Retrieves the cooldown of the server after which voice quotes can be used.
     *
     * @return Cooldown in seconds.
     */
    public int GetServerCooldown()
    {
        ConVar serverCooldown;
        this.GetValue("serverCooldown", serverCooldown);

        return serverCooldown.IntValue;
    }

    /**
     * Retrieves the cooldown of the client after which voice quotes can be used.
     *
     * @return Cooldown in seconds.
     */
    public int GetClientCooldown()
    {
        ConVar clientCooldown;
        this.GetValue("clientCooldown", clientCooldown);

        return clientCooldown.IntValue;
    }
}

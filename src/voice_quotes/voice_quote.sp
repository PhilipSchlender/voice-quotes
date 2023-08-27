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
     * @param duration Duration of the sound in seconds.
     * @error
     */
    public VoiceQuote(const char[] player, const char[] quote, const char[] filename, int duration)
    {
        StringMap stringMap = new StringMap();

        if (! stringMap.SetString("player", player)) {
            ThrowError("Failed to set player to \"%s\".", player);
        }

        if (! stringMap.SetString("quote", quote)) {
            ThrowError("Failed to set quote to \"%s\".", quote);
        }

        if (! stringMap.SetString("filename", filename)) {
            ThrowError("Failed to set filename to \"%s\".", filename);
        }

        if (! stringMap.SetValue("duration", duration)) {
            ThrowError("Failed to set duration to \"%d\".", duration);
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
     * Retrieves the duration of the sound.
     *
     * @return Duration in seconds.
     */
    public int GetDuration()
    {
        int duration;
        this.GetValue("duration", duration);

        return duration;
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

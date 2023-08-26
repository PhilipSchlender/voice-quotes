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

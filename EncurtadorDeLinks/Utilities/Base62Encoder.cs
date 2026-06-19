namespace EncurtadorDeLinks.Utilities;

public static class Base62Encoder
{
    private const string Characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

    public static string Encode(long number)
    {
        if (number == 0)
            return "0";

        var result = "";
        while (number > 0)
        {
            result = Characters[(int)(number % 62)] + result;
            number /= 62;
        }

        return result;
    }

    public static long Decode(string code)
    {
        long result = 0;
        foreach (var character in code)
        {
            result = result * 62 + Characters.IndexOf(character);
        }

        return result;
    }

    public static string GenerateShortCode(string url)
    {
        var hash = url.GetHashCode();
        var absHash = Math.Abs((long)hash);
        return Encode(absHash).Substring(0, Math.Min(6, Encode(absHash).Length));
    }
}

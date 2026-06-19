namespace EncurtadorDeLinks.Utilities;

public static class UrlValidator
{
    public static bool IsValidUrl(string? url)
    {
        if (string.IsNullOrWhiteSpace(url))
            return false;

        try
        {
            var uri = new Uri(url);
            return uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps;
        }
        catch
        {
            return false;
        }
    }

    public static string? ValidateAndNormalize(string? url)
    {
        if (!IsValidUrl(url))
            return null;

        var uri = new Uri(url!);
        return uri.AbsoluteUri;
    }
}

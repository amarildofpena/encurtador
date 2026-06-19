namespace EncurtadorDeLinks.Models;

public class AccessLog
{
    public string ClientIp { get; set; } = string.Empty;
    public string ShortCode { get; set; } = string.Empty;
    public string? OriginalUrl { get; set; }
    public DateTime Timestamp { get; set; }
    public int StatusCode { get; set; }
    public string? RedirectLocation { get; set; }
}

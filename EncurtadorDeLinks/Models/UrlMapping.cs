using Azure;
using Azure.Data.Tables;

namespace EncurtadorDeLinks.Models;

public class UrlMapping : ITableEntity
{
    public string ShortCode { get; set; } = string.Empty;
    public string OriginalUrl { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public int AccessCount { get; set; }

    // ITableEntity implementation
    public string PartitionKey { get; set; } = "urls";
    public string RowKey { get; set; } = string.Empty;
    public DateTimeOffset? Timestamp { get; set; }
    public ETag ETag { get; set; }
}

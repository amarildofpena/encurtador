using Microsoft.Azure.Functions.Worker.Http;

namespace EncurtadorDeLinks.Utilities;

public static class IpExtractor
{
    public static string ExtractClientIp(HttpRequestData request)
    {
        if (request.Headers.TryGetValues("X-Forwarded-For", out var forwardedValues))
        {
            var forwardedFor = forwardedValues.FirstOrDefault();
            if (!string.IsNullOrWhiteSpace(forwardedFor))
            {
                var clientIp = forwardedFor.Split(',')[0].Trim();
                if (!string.IsNullOrWhiteSpace(clientIp))
                    return clientIp;
            }
        }

        if (request.Headers.TryGetValues("Client-IP", out var clientIpValues))
        {
            var clientIp = clientIpValues.FirstOrDefault();
            if (!string.IsNullOrWhiteSpace(clientIp))
                return clientIp;
        }
        
        if (request.Headers.TryGetValues("X-Real-IP", out var realIpValues))
        {
            var clientIp = realIpValues.FirstOrDefault();
            if (!string.IsNullOrWhiteSpace(clientIp))
                return clientIp;
        }

        if (request.Headers.TryGetValues("X-Original-For", out var originalFor))
        {
            var clientIp = originalFor.FirstOrDefault();
            if (!string.IsNullOrWhiteSpace(clientIp))
                return clientIp;
        }

        if (request.Headers.TryGetValues("X-Original-Host", out var originalHost))
        {
            var clientIp = originalHost.FirstOrDefault();
            if (!string.IsNullOrWhiteSpace(clientIp))
                return clientIp;
        }

        var feature = request.FunctionContext.Features
            .Get<Microsoft.AspNetCore.Http.Features.IHttpConnectionFeature>();

        if (feature?.RemoteIpAddress != null)
            return feature.RemoteIpAddress.ToString();

        return "unknown";
    }
}
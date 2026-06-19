using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;

using EncurtadorDeLinks.Utilities;
using System.Net;

namespace EncurtadorDeLinks.Functions;

public class ResolveUrl
{
    
    [Function("ResolveUrl")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "redirect/{shortCode}")] HttpRequestData req,
        string shortCode)
    {
        var clientIp = IpExtractor.ExtractClientIp(req);

        var response = req.CreateResponse(HttpStatusCode.OK);
        await response.WriteAsJsonAsync(new { ClientIp = clientIp });

        return response;
    }
}

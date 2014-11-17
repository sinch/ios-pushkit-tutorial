using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using pushkit_tutorial_server.Models;
using PushSharp;
using PushSharp.Apple;

namespace pushkit_tutorial_server.Controllers {
    public class PushKitController : ApiController {
        [Route("sendpush")]
        [HttpPost]
        public HttpResponseMessage SendPush(PushPair push) {
            var broker = PushService.Context().Broker;
            broker.QueueNotification(new AppleNotification()
                .ForDeviceToken(push.PushData)
                .WithAlert("Incoming call")
                .WithCustomItem("sin", push.PushPayload));
            return new HttpResponseMessage(HttpStatusCode.OK);
        }

    }
}

using Newtonsoft.Json;

namespace pushkit_tutorial_server.Models {
    public class PushPair {
        [JsonProperty("pushData")]
        public string PushData { get; set; }
        [JsonProperty("pushPayload")]
        public string PushPayload { get; set; }
    }
}
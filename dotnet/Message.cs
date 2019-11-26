using System.Collections.Generic;
using MessagePack;

namespace Netler
{
    internal static class Message
    {
        public static byte[] Encode(object message) => MessagePackSerializer.Serialize<object>(message);
        public static IDictionary<string, object> Decode(byte[] message) => MessagePackSerializer.Deserialize<IDictionary<string, object>>(message);
    }
}
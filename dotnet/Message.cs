using System.Collections.Generic;
using MessagePack;

namespace Netler
{
    internal static class Message
    {
        public static byte[] Encode(int atom, object message) => MessagePackSerializer.Serialize<object>(new object[] { atom, message });
        public static IDictionary<string, object> Decode(byte[] message) => MessagePackSerializer.Deserialize<IDictionary<string, object>>(message);
    }
}
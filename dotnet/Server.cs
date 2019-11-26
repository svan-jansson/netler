using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Threading;

namespace Netler
{
    public static class Server
    {
        public static Thread Export(string[] args, IDictionary<string, Func<object[], object>> methods)
        {
            var port = Convert.ToInt32(args[0]);
            var worker = new Thread(() => MessageLoop(methods, port));
            worker.Start();
            return worker;
        }

        private static void MessageLoop(IDictionary<string, Func<object[], object>> methods, int port)
        {
            var listener = new TcpListener(IPAddress.Parse("127.0.0.1"), port);
            listener.Start();

            var client = listener.AcceptTcpClient();
            var stream = client.GetStream();
            while (true)
            {
                while (!stream.DataAvailable) ;

                Action<object> respond = (response) =>
                    {
                        try
                        {
                            var responseBytes = Message.Encode(response);
                            stream.Write(responseBytes, 0, responseBytes.Length);
                        }
                        catch (Exception ex)
                        {
                            throw new IOException("Could not write response to stream", ex);
                        }
                    };
                try
                {
                    var incomingBytes = new Byte[client.Available];
                    stream.Read(incomingBytes, 0, incomingBytes.Length);

                    var signature = Message.Decode(incomingBytes);
                    var method = MapToMethod(methods, signature);

                    Invoke(method, respond);
                }
                catch (ApplicationException ex)
                {
                    respond(KeyValuePair.Create("Error.Application", ex.Message));
                }
                catch (MethodAccessException ex)
                {
                    respond(KeyValuePair.Create("Error.MethodNotFound", ex.Message));
                }
                catch (IOException ex)
                {
                    respond(KeyValuePair.Create("Error.Stream", ex.Message));
                }
            }
        }

        private static void Invoke((Func<object[], object> method, object[] parameters) invokation, Action<object> respond)
        {
            try
            {
                var parameters = new List<object>(invokation.parameters);
                parameters.Add(respond);
                var result = invokation.method(parameters.ToArray());
                respond(result);
            }
            catch (IOException ex)
            {
                throw ex;
            }
            catch (Exception ex)
            {
                throw new ApplicationException($"The invoked method threw an error: {ex.Message}", ex);
            }
        }

        private static (Func<object[], object> method, object[] parameters) MapToMethod(IDictionary<string, Func<object[], object>> methods, IDictionary<string, object> signature)
        {
            try
            {
                var name = signature["name"].ToString();
                var parameters = signature["params"] as object[];
                var method = methods[name];
                return (method: method, parameters: parameters);
            }
            catch (Exception ex)
            {
                throw new MethodAccessException($"Method not found: {signature["name"]}", ex);
            }
        }
    }
}
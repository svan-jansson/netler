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
        public const int ATOM_OK = 1;
        public const int ATOM_ERROR = 0;
        private const byte SIGTERM = 15;
        private static Thread _worker;

        public static Thread Export(string[] args, IDictionary<string, Func<object[], object>> methods)
        {
            var port = Convert.ToInt32(args[0]);
            _worker = new Thread(() => MessageLoop(methods, port));
            _worker.Start();
            return _worker;
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

                Action<int, object> respond = (atom, response) =>
                    {
                        try
                        {
                            var responseBytes = Message.Encode(atom, response);
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
                    if (incomingBytes.Length == 1 && incomingBytes[0] == SIGTERM)
                    {
                        _worker.Abort();
                        break;
                    }

                    var signature = Message.Decode(incomingBytes);
                    var method = MapToMethod(methods, signature);

                    Invoke(method, respond);
                }
                catch (ApplicationException ex)
                {
                    respond(ATOM_ERROR, ex.Message);
                }
                catch (MethodAccessException ex)
                {
                    respond(ATOM_ERROR, ex.Message);
                }
                catch (IOException ex)
                {
                    respond(ATOM_ERROR, ex.Message);
                }
            }
        }

        private static void Invoke((Func<object[], object> method, object[] parameters) invokation, Action<int, object> respond)
        {
            try
            {
                var parameters = new List<object>(invokation.parameters);
                parameters.Add(respond);
                var result = invokation.method(parameters.ToArray());
                respond(ATOM_OK, result);
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
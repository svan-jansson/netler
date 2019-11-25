using System;
using System.Collections.Generic;

namespace Netler
{
    class Program
    {
        static void Main(string[] args)
        {
            var port = Convert.ToInt32(args[0]);
            Server.Bind(new Dictionary<string, Func<object[], object>> {
                {"Add", Add}
            }, port);
        }

        static object Add(params object[] parameters)
        {
            var a = Convert.ToInt32(parameters[0]);
            var b = Convert.ToInt32(parameters[1]);
            var result = a + b;
            return result;
        }
    }
}

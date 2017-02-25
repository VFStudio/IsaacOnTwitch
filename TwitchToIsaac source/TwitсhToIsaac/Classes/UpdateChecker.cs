using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace TwitchToIsaac
{
    static class UpdateChecker
    {
        static WebClient client = new WebClient();
        static string url = "https://vfstudio.github.io/IsaacOnTwitch/updservice/";
        static string currentVer = "1.3.0";

        public static string checkUpd ()
        {
            try
            {
                Stream s = client.OpenRead(url + "version");
                StreamReader reader = new StreamReader(s);
                string res = reader.ReadToEnd();

                if (res != currentVer)
                    return res;
                else
                    return null;
            }
            catch { return null; }
        }
    }
}

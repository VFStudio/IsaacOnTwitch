using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TwithToIsaac;
using Newtonsoft.Json;
using System.IO;

namespace TwitchToIsaac
{
    static class SettingsLoader
    {
        public static Settings s = new Settings();
        private static string filename = "settings.json";

        public static void Save ()
        {
            string res = JsonConvert.SerializeObject(s);
            File.WriteAllText(filename, res);
        }

        public static void Load()
        {
            if (File.Exists(filename))
                s = JsonConvert.DeserializeObject<Settings>(File.ReadAllText(filename));
            else
                Save();
        }
    }

    public class Settings
    {
        public Firstline firstline { get; set; } = new Firstline();
        public Secondline secondline { get; set; } = new Secondline();
        public string channel { get; set; } = "";
        public string timeforvote { get; set; } = "70";
        public string delayvote { get; set; } = "15";
        public bool? subsap { get; set; } = true;
        public bool? followsap { get; set; } = false;
        public bool? bitsap { get; set; } = true;
        public double chEvents { get; set; } = 7;
        public double chItems { get; set; } = 2;
        public double chTrinkets { get; set; } = 1;
        public double chHearts { get; set; } = 3;
        public double chPickups { get; set; } = 4;
        public double chComps { get; set; } = 4;
        public double chPockets { get; set; } = 4;
        public string subdel { get; set; } = "10";
        public double volume { get; set; } = 85;

        public class Firstline
        {
            public string x { get; set; } = "16";
            public string y { get; set; } = "241";
        }

        public class Secondline
        {
            public string x { get; set; } = "16";
            public string y { get; set; } = "258";
        }

    }
}

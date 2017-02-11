using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TwitсhToIsaac.Classes
{
    public class IsaacData
    {
        public double interruptHash { get; set; } = 0;
        public int interrupt { get; set; } = -1;
    }

    public class IsaacParam
    {
        public Stats stats { get; set; } = new Stats();
        public bool pause { get; set; } = true;
        public int runcount { get; set; } = 0;

        public class Stats
        {
            public double luck { get; set; } = 0;
        }
    }
}

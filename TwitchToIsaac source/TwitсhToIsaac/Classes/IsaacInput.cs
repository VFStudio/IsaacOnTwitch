using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TwitсhToIsaac.Classes.VotingOptions;

namespace TwitсhToIsaac.Classes
{

    public class ProgramParam
    {
        public int Viewers { get; set; } = 0;
        public TextParam textparam { get; set; } = new TextParam();
        public int subdel = 10 * 30 * 60;
        public string gift = null;


        public class TextParam
        {
            public Firstline firstline { get; set; } = new Firstline();
            public Secondline secondline { get; set; } = new Secondline();

            public class Firstline
            {
                public int x { get; set; } = 16;
                public int y { get; set; } = 241;
            }

            public class Secondline
            {
                public int x { get; set; } = 16;
                public int y { get; set; } = 258;
            }

        }
    }
}

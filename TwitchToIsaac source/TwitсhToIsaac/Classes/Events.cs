using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Media;
using TwitсhToIsaac.Classes.VotingOptions;

namespace TwitсhToIsaac.Classes.Events
{
    public enum ActionMode : byte
    {
        Vote = 1, Info, Get, Sub, Bits
    }

    public enum BitsType : byte
    {
        Gray, Purple, Green, Blue, Red
    }

    public struct IsaacColor
    {
        public float r;
        public float g;
        public float b;
        public float a;
    }

    public static class ChatColors
    {
        public static List<Color> Colors = new List<Color>();

        public static void Init ()
        {
            Colors.Add(RGB(255, 0, 0));
            Colors.Add(RGB(0, 0, 255));
            Colors.Add(RGB(0, 128, 0));
            Colors.Add(RGB(178, 34, 34));
            Colors.Add(RGB(255, 127, 80));
            Colors.Add(RGB(154, 205, 50));
            Colors.Add(RGB(255, 69, 0));
            Colors.Add(RGB(46, 139, 87));
            Colors.Add(RGB(218, 165, 32));
            Colors.Add(RGB(210, 105, 30));
            Colors.Add(RGB(95, 158, 160));
            Colors.Add(RGB(30, 144, 255));
            Colors.Add(RGB(255, 105, 180));
            Colors.Add(RGB(138, 43, 226));
            Colors.Add(RGB(0, 255, 127));
        }

        static Color RGB (byte r, byte g, byte b)
        {
            Color c = new Color();
            c.R = r;
            c.G = g;
            c.B = b;
            return c;
        }
    }

    public class Act
    {
        public ActionMode emode = 0;
        public string text = "";
        public double hash = 0;

        public Act (double hash = 0)
        {
            this.hash = hash;
        }
        
    }

    public class ActionVote : Act
    {
        public VoteType etype = 0;
        public string secondtext = "";

        public ActionVote(string text, string secondtext, double hash) : base(hash)
        {
            this.emode = ActionMode.Vote;
            this.text = text;
            this.secondtext = secondtext;
            this.hash = hash;
        }
    }

    public class ActionInfo : Act
    {
        public VoteType etype = 0;
        public string secondtext = "";

        public ActionInfo(string text)
        {
            this.emode = ActionMode.Info;
            this.text = text;
        }
    }

    public class ActionGet : Act
    {
        public VoteType etype = 0;
        public string secondtext = "";
        public string eobj = "";
        public bool? happy = null;

        public ActionGet(VoteVariant vote, double hash) : base(hash)
        {
            this.emode = ActionMode.Get;
            this.text = vote.msg;
            this.etype = vote.type;
            this.eobj = vote.name;
            this.happy = vote.happy;
            this.hash = hash;
        }

        public ActionGet(ActionGet Act) : base(Act.hash)
        {
            this.emode = ActionMode.Get;
            this.text = Act.text;
            this.etype = Act.etype;
            this.eobj = Act.eobj;
            this.happy = Act.happy;
        }
    }

    public class ActionGetPickup : Act
    {
        public int count = 0;
        public VoteType etype = 0;
        public string secondtext = "";
        public string eobj = "";
        public bool? happy = null;

        public ActionGetPickup(VotePickup vote, double hash) : base(hash)
        {
            this.emode = ActionMode.Get;
            this.text = vote.msg;
            this.etype = vote.type;
            this.eobj = vote.name;
            this.happy = vote.happy;
            this.hash = hash;
            this.count = vote.count;
        }

        public ActionGetPickup(ActionGetPickup Act) : base(Act.hash)
        {
            this.emode = ActionMode.Get;
            this.text = Act.text;
            this.etype = Act.etype;
            this.eobj = Act.eobj;
            this.happy = Act.happy;
            this.count = Act.count;
        }
    }

    public class ActionSub : Act
    {
        public string name = "";

        public ActionSub(string name, double hash, bool foll = false) : base (hash)
        {
            this.emode = ActionMode.Sub;
            this.name = name;
            if (foll)
                this.text = "New follower - " + name;
            else
                this.text = "New subscriber - " + name;
        }
    }

    public class ActionBits : Act
    {
        public int count;
        public BitsType type;

        public ActionBits(int count, BitsType type, double hash) : base(hash)
        {
            this.emode = ActionMode.Bits;
            this.type = type;
            this.text = "You've got bits!";

            if (count > 10)
                count = 10;

            this.count = count;
        }
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace TwitсhToIsaac.Classes.VotingOptions
{
    public enum VoteType : byte
    {
        Item = 1, Trinket, Heart, Companion, Pickup, Pocket, Event
    }

    public class Vote
    {
        public VoteType voteType;
        public Dictionary<int, VoteVariant> variants = new Dictionary<int, VoteVariant>();
        List<int> votes = new List<int>();
        public int votescount = 0;
        public bool stopped = false;
        Random r = new Random();
        public List<int> percents = new List<int>();
        public List<string> peoples = new List<string>();

        public Vote (double luck)
        {
            voteType = VoteChances.selectVoteVariant();

            switch (voteType)
            {
                case VoteType.Item:

                    if (VotePool.Items.Count < 4 || VotePool.Trinkets.Count < 4)
                        VotePool.RestoreRemovedVariants();

                    for (var i = 0; i < 3; i ++)
                    {
                        VoteItem v = VotePool.Items[r.Next(0, VotePool.Items.Count)];
                        variants.Add(i, v);
                        VotePool.Items.Remove(v);
                    }

                    break;

                case VoteType.Trinket:

                    if (VotePool.Items.Count < 4 || VotePool.Trinkets.Count < 4)
                        VotePool.RestoreRemovedVariants();

                    for (var i = 0; i < 3; i++)
                    {
                        VoteTrinket v = VotePool.Trinkets[r.Next(0, VotePool.Trinkets.Count)];
                        variants.Add(i, v);
                        VotePool.Trinkets.Remove(v);
                    }

                    break;

                case VoteType.Heart:
                    for (var i = 0; i < 3; i++)
                    {
                        VoteHeart v = VotePool.Hearts[r.Next(0, VotePool.Hearts.Count)];
                        variants.Add(i, v);
                        VotePool.Hearts.Remove(v);
                    }
                    break;

                case VoteType.Companion:
                    for (var i = 0; i < 3; i++)
                    {
                        VoteCompanion v = VotePool.Companions[r.Next(0, VotePool.Companions.Count)];
                        variants.Add(i, v);
                        VotePool.Companions.Remove(v);
                    }
                    break;

                case VoteType.Pickup:
                    for (var i = 0; i < 3; i++)
                    {
                        int count = r.Next(-5+((int)luck), 5+((int)luck));
                        variants.Add(i, new VotePickup(VotePool.Pickups[r.Next(0, VotePool.Pickups.Count)], count));
                    }
                    break;

                case VoteType.Pocket:
                    for (var i = 0; i < 3; i++)
                    {
                        VotePocket v = VotePool.Pockets[r.Next(0, VotePool.Pockets.Count)];
                        variants.Add(i, v);
                        VotePool.Pockets.Remove(v);
                    }
                    break;

                case VoteType.Event:
                    for (var i = 0; i < 3; i++)
                    {
                        VoteEvent v = VotePool.Events[r.Next(0, VotePool.Events.Count)];
                        variants.Add(i, v);
                        VotePool.Events.Remove(v);
                    }
                    break;
            }

            VotePool.Restore();

            for (var i = 0; i < 3; i++)
            {
                votes.Add(0);
                percents.Add(0);
            }

        }

        public void VoteFor (int num)
        {
            votescount++;
            votes[num]++;

            for (int i = 0; i < percents.Count; i++)
            {
                percents[i] = (int)((((double)votes[i]) / ((double)votescount))*100);
            }
        }

        public VoteVariant GetWinner ()
        {
            stopped = true;
            int max = 0;
            int maxnum = r.Next(0, 3);

            for (int i = 0; i < votes.Count; i++)
            {
                if (votes[i] > max)
                {
                    max = votes[i];
                    maxnum = i;
                }
            }

            return variants[maxnum];
        }
    }

    public class VoteVariant
    {
        public VoteType type;
        public string name;
        public string displayName;
        public string msg;
        public bool happy;
        public bool removable = false;
        public int count;

        public VoteVariant(string name = "")
        {
            this.name = name;
            this.displayName = name;
            this.msg = "You've got " + displayName;
            this.happy = true;
        }
    }

    public class VoteEvent : VoteVariant
    {
        public int sfx = -1;
        public VoteModifiers votemodifier = 0;
        public VoteEvent(string name, string displayName, string msg, bool happy, int sfx = -1, VoteModifiers mod = 0) : base(name)
        {
            this.type = VoteType.Event;
            this.displayName = displayName;
            this.sfx = sfx;
            this.votemodifier = mod;
            this.msg = msg;
            this.happy = happy;
        }
    }

    public class VoteItem : VoteVariant
    {
        public VoteItem(string name) : base(name)
        { type = VoteType.Item; removable = true; }
    }

    public class VoteTrinket : VoteVariant
    {
        public VoteTrinket(string name) : base(name)
        { type = VoteType.Trinket; removable = true; }
    }

    public class VoteHeart : VoteVariant
    {
        public VoteHeart(string name) : base(name)
        { type = VoteType.Heart; this.msg = "You've got " + displayName + " heart!"; }
    }


    public class VotePickup : VoteVariant
    {

        public VotePickup(string type, int count)
        {
            this.displayName = count + " " + (count == 1 || count == -1 ? type : type + "s");
            this.name = type;
            this.msg = "You've got " + displayName;
            this.happy = count > 0 ? true : false;
            this.count = count;
            this.type = VoteType.Pickup;
        }
    }

    public class VoteCompanion : VoteVariant
    {
        public VoteCompanion(string name, string displayName, bool happy) : base(name)
        {
            this.displayName = displayName;
            this.msg = "You've got " + displayName;
            this.happy = happy;
            this.type = VoteType.Companion;
        }
    }

    public class VotePocket : VoteVariant
    {
        public VotePocket(string name, string displayName, string msg, bool happy) : base(name)
        {
            this.displayName = displayName;
            this.msg = msg;
            this.happy = happy;
            this.type = VoteType.Pocket;
        }
    }

    public static class VoteChances
    {
        public static byte Event = 6;
        public static byte Item = 2;
        public static byte Trinket = 1;
        public static byte Heart = 3;
        public static byte Pickup = 4;
        public static byte Companion = 4;
        public static byte Pocket = 4;

        public static Random rnd = new Random();
        public static Dictionary<VoteType, byte> chances = new Dictionary<VoteType, byte>();

        public static VoteType selectVoteVariant()
        {
            List<VoteType> dice = new List<VoteType>();

            foreach (KeyValuePair<VoteType, byte> v in chances)
            {
                for (int i = 0; i < v.Value; i++)
                    dice.Add(v.Key);
            }

            return dice[rnd.Next(0, dice.Count)];

        }

        public static void Save()
        {
            chances.Clear();

            chances.Add(VoteType.Event, Event);
            chances.Add(VoteType.Item, Item);
            chances.Add(VoteType.Trinket, Trinket);
            chances.Add(VoteType.Heart, Heart);
            chances.Add(VoteType.Pickup, Pickup);
            chances.Add(VoteType.Companion, Companion);
            chances.Add(VoteType.Pocket, Pocket);
        }
    }

    public static class VoteTime
    {
        public static int vote = 70;
        public static int delay = 15;
    }

    public enum VoteModifiers
    {
        Nothing = 0,
        H4CKED
    }

    public static class VotePool
    {
        public static List<VoteEvent> Events = new List<VoteEvent>();
        public static List<VoteItem> Items = new List<VoteItem>();
        public static List<VoteTrinket> Trinkets = new List<VoteTrinket>();
        public static List<VoteCompanion> Companions = new List<VoteCompanion>();
        public static List<VoteHeart> Hearts = new List<VoteHeart>();
        public static List<string> Pickups = new List<string>();
        public static List<VotePocket> Pockets = new List<VotePocket>();

        public static List<VoteItem> RemovedItems = new List<VoteItem>();
        public static List<VoteTrinket> RemovedTrinkets = new List<VoteTrinket>();
        public static Random rnd = new Random();

        public static void Load ()
        {
            Restore();
            LoadItemsAndTrinkets();
        }

        public static void Restore ()
        {
            Events.Clear();
            Companions.Clear();
            Hearts.Clear();
            Pickups.Clear();
            Pockets.Clear();

            Hearts.Add(new VoteHeart("Red"));
            Hearts.Add(new VoteHeart("Container"));
            Hearts.Add(new VoteHeart("Soul"));
            Hearts.Add(new VoteHeart("Golden"));
            Hearts.Add(new VoteHeart("Eternal"));
            Hearts.Add(new VoteHeart("Twitch"));
            Hearts.Add(new VoteHeart("Black"));

            Pickups.Add("Coin");
            Pickups.Add("Key");
            Pickups.Add("Bomb");

            Companions.Add(new VoteCompanion("Fly", "5 Blue Flies", true));
            Companions.Add(new VoteCompanion("Spider", "5 Blue Spiders", true));
            Companions.Add(new VoteCompanion("PrettyFly", "1 Pretty Fly", true));
            Companions.Add(new VoteCompanion("BadFly", "5 Red Flies", false));
            Companions.Add(new VoteCompanion("BadSpider", "5 Red Spiders", false));

            Pockets.Add(new VotePocket("LuckUp", "Luck Up", "Your luck is growing!", true));
            Pockets.Add(new VotePocket("LuckDown", "Luck Down", "Your luck is decreased!", false));
            Pockets.Add(new VotePocket("Pill", "Pill", "You get Pill!", true));
            Pockets.Add(new VotePocket("Card", "Card", "You get Card!", true));
            Pockets.Add(new VotePocket("Rune", "Rune", "You get Rune!", true));
            Pockets.Add(new VotePocket("Spacebar", "Spacebar", "Your item is activated!", true));
            Pockets.Add(new VotePocket("Charge", "Charge item", "Your item is fully charged!", true));
            Pockets.Add(new VotePocket("Discharge", "Discharge item", "Your item is fully discharged!", false));

            //Events < 1.3
            Events.Add(new VoteEvent("Poop", "Poop", "Who's gonna clean it?", false));
            Events.Add(new VoteEvent("Richy", "Richy", "Yeah, I am lucky!", true));
            Events.Add(new VoteEvent("Earthquake", "Earthquake", "Protect your head!", false));
            Events.Add(new VoteEvent("Charm", "Charm", "Love everywhere", true));
            Events.Add(new VoteEvent("Hell", "Hell", "Hot and bloody", false));
            Events.Add(new VoteEvent("Spiky", "Spiky", "Ouch!", false));
            Events.Add(new VoteEvent("Award", "Award", "More rewards for you", true));
            Events.Add(new VoteEvent("AngelRage", "Angel Rage", "Holy crap!", true));
            Events.Add(new VoteEvent("DevilRage", "Devil Rage", "What the hell?", true));
            Events.Add(new VoteEvent("RainbowRain", "Rainbow Rain", "Unicorn start piss", true)); //Да, знаю, что неправильно, но она стала мемом на одном из стримов, поэтому не менять
            Events.Add(new VoteEvent("CallToDark", "Call To Dark", "An ancient evil has awoken", true));
            Events.Add(new VoteEvent("Invisible", "Invisible", "Find yourself", true));
            Events.Add(new VoteEvent("RUN", "RUN", "Run, Forrest, run!", false));
            Events.Add(new VoteEvent("FlashJump", "Flash Jump", "Faster than light", true));
            Events.Add(new VoteEvent("EyesBleed", "Eyes Bleed", "What's happening?", false));
            Events.Add(new VoteEvent("StanleyParable", "Stanley Parable", "Good job, Stanley!", true));
            if (rnd.NextDouble() >= 0.75) { Events.Add(new VoteEvent("Supernova", "Supernova", "DESTROY THE WORLD!", true)); }
            if (rnd.NextDouble() >= 0.2) { Events.Add(new VoteEvent("DDoS", "DDoS", "50 Gb/sec attack", false, 1)); }
            Events.Add(new VoteEvent("NoDMG", "Where is my DMG", "Your game will collapse but there's nothing in it", false));
            Events.Add(new VoteEvent("Strabismus", "Strabismus", "Where are you looking at?", false));
            Events.Add(new VoteEvent("Inverse", "Inverse", "Just flip the gamepad", false));
            Events.Add(new VoteEvent("Slip", "Slip", "Caution! Wet floor", false));
            Events.Add(new VoteEvent("Whirlwind", "Whirlwind", "Spiral power", true));
            Events.Add(new VoteEvent("RusHack", "Russian hackers", "I did not vote for this!", false, -1, VoteModifiers.H4CKED));
            if (rnd.NextDouble() >= 0.4) { Events.Add(new VoteEvent("GoodMusic", "Good music", "YOUR EARS ARE BEING RAPED!!11!!1", false, 0)); }
            Events.Add(new VoteEvent("AttackOnTitan", "Attack on titan", "Your enemies have grown", false, 3));
            Events.Add(new VoteEvent("Interstellar", "Interstellar", "Gravity can cross the dimensions", false, 4));
            Events.Add(new VoteEvent("BladeStorm", "Blade storm", "All get stabbed!", true));
            Events.Add(new VoteEvent("Diarrhea", "Diarrhea", "What was the soup made from?", true));
            Events.Add(new VoteEvent("Heal", "Heal", "But we need to KILL, not to HEAL!", false));
            Events.Add(new VoteEvent("Flashmob", "Flashmob", "Repeat after me!", true));

            //Events 2.0
            Events.Add(new VoteEvent("MachineGun", "Machine Gun", "Push your enemies", true));
            Events.Add(new VoteEvent("Toxic", "Toxic", "Beware of toxicity", false));
            Events.Add(new VoteEvent("CrazyDoors", "Crazy Doors", "Destination not clear", false));
            Events.Add(new VoteEvent("Rewind", "Rewind", "One more time", false));
            Events.Add(new VoteEvent("SuperHot", "Super Hot", "SUPER. HOT.", true));
            Events.Add(new VoteEvent("SCP173", "SCP-173", "Don't blink!", false));
            Events.Add(new VoteEvent("PointOfView", "Point Of View", "Change your point of view", false));
            Events.Add(new VoteEvent("Radioactive", "Radioactive", "Mind the distance", false));
            if (rnd.NextDouble() >= 0.90) { Events.Add(new VoteEvent("Rerun", "Rerun", "Start from scratch", true)); }
            if (rnd.NextDouble() >= 0.90) { Events.Add(new VoteEvent("SwitchTheChannel", "Switch The Channel", "This show has become too boring", false)); }
            Events.Add(new VoteEvent("FlyingBanana", "Flying Banana", "Plain bananas but better", true));
            Events.Add(new VoteEvent("Pyrosis", "Pyrosis", "Change your diet", true));
            Events.Add(new VoteEvent("Spiders", "Spiders", "Everybody loves spiders", true));
            Events.Add(new VoteEvent("IpecacForAll", "Ipecac For All", "...but not for you", false));
            Events.Add(new VoteEvent("Ghostbusters", "Ghostbusters", "Souls of the dead follow you", false));
            Events.Add(new VoteEvent("WeHateYou", "We Hate You", "Everything hurts", false));
            Events.Add(new VoteEvent("Telesteps", "Telesteps", "Mr. Shifty, is that you?", true));
            Events.Add(new VoteEvent("Flash", "Flash", "Fastest kid alive", true));
            Events.Add(new VoteEvent("ShadowClones", "Shadow Clones", "At least it's not Sakura..", false));
            Events.Add(new VoteEvent("IsaacOfIsaac", "Isaac Of Isaac", "Isaac and his Isaac", false));
            Events.Add(new VoteEvent("Spiderman", "Spiderman", "Web's too sticky", false));
            Events.Add(new VoteEvent("StaticElectricity", "Static Electricity", "WARNING: High Voltage", false));
            Events.Add(new VoteEvent("Bleeding", "Bleeding", "Let's make it hardcore", false));
            Events.Add(new VoteEvent("ParasiticInfection", "Parasitic Infection", "Beautiful on the inside", false));
            Events.Add(new VoteEvent("IAmLost", "I Am Lost", "You get hit, you die. Good luck.", false));
            //Events.Add(new VoteEvent("Censored", "Censored", "Your parents wouldn't like it", false));
            Events.Add(new VoteEvent("DeepDark", "DeepDark", "The dark absorbs everything", false));
            Events.Add(new VoteEvent("BrokenLens", "Broken Lens", "Zoom's very unstable", false));
            Events.Add(new VoteEvent("FloorIsLava", "Floor Is Lava", "Watch your steps!", false));
            if (rnd.NextDouble() >= 0.90) { Events.Add(new VoteEvent("Reroll", "Reroll", "I hope your items were bad", true)); }
            Events.Add(new VoteEvent("Matrix", "Matrix", "You are the chosen one, Isaac!", true));
            Events.Add(new VoteEvent("Danger", "Danger", "The game was too easy", false));
            Events.Add(new VoteEvent("TornPockets", "Torn Pockets", "Looks like you've lost everything", false));
            Events.Add(new VoteEvent("Gravity", "Gravity", "Let's pile it up", false));
            Events.Add(new VoteEvent("Allergia", "Allergia", "This basement's too dusty", true));
            Events.Add(new VoteEvent("HeavyRain", "Heavy Rain", "Rainig cats & dogs", true));
            Events.Add(new VoteEvent("MarbleBalls", "Marble Balls", "Pretty and useless", true));
            Events.Add(new VoteEvent("QTE", "QTE", "Hurry! Push! The buttons!", true));
        }

        public static void LoadItemsAndTrinkets ()
        {
            XDocument doc = XDocument.Load("items.xml");
            foreach (XElement el in doc.Root.Elements())
            {
                if (el.Name == "trinket")
                    Trinkets.Add(new VoteTrinket(el.Attribute("name").Value));
                else
                    Items.Add(new VoteItem(el.Attribute("name").Value));
            }
        }

        public static void RestoreRemovedVariants ()
        {
            Items.AddRange(RemovedItems);
            Trinkets.AddRange(RemovedTrinkets);
        }

    }
}

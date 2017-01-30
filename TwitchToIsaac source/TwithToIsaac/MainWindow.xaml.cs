using System;
using System.Collections.Generic;
using System.Xml.Linq;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using TwitchLib;
using TwitchLib.Models.Client;
using System.Timers;

namespace TwithToIsaac
{
    /// <summary>
    /// Логика взаимодействия для MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        int timeForVote = 90;
        int timeForDelay = 15;
        int nowTimeForVote = 0;
        int nowTimeForDelay = 0;

        Dictionary<string, int> chances = new Dictionary<string, int>();

        bool getItems = true;
        bool getEvents = true;
        bool getTrinkets = true;
        bool getHearts = true;
        bool getPickups = true;
        bool getCompanions = true;
        bool getPockets = true;



        string Isaac = "../data/input.txt";
        string IsaacOut = "../data/output.txt";
        string[] voteAwait = {"Special", "Waiting for vote starting...", "", "", "", "" };
        TwitchClient Twitch;

        List<VoteItem> Items = new List<VoteItem>();
        List<VoteTrinket> Trinkets = new List<VoteTrinket>();
        List<VoteHeart> Hearts = new List<VoteHeart>();
        List<VotePickup> Pickups = new List<VotePickup>();
        List<VoteCompanion> Companions = new List<VoteCompanion>();
        List<VotePocket> Pockets = new List<VotePocket>();
        List<VoteEvent> Events = new List<VoteEvent>();

        Stack<int> Bits = new Stack<int>();
        Stack<string> Subscribers = new Stack<string>();
        Stack<int> Interrupt = new Stack<int>();
        string lastInterrupt = "";

        string quest = "";
        string voteType = "";
        List<VoteVariant> vars = new List<VoteVariant>();
        List<int> votes = new List<int>();
        List<int> users = new List<int>();
        Random rnd = new Random();
        bool started = false;
        Timer t = new Timer();
        Timer p = new Timer();



        public MainWindow()
        {
            InitializeComponent();

            if (!File.Exists(Isaac) || !File.Exists(IsaacOut))
            {
                t_Status.Text = "Mod not found. Check path and relaunch program";
                return;
            }

            int count = File.ReadAllLines(IsaacOut)[0].Split(' ').Length;
            lastInterrupt = File.ReadAllLines(IsaacOut)[0].Split(' ')[count-1];

            RestoreLists();
            LoadItemsAndTrinkets();

            t.Interval = 1000;
            p.Interval = 10000;
            p.Elapsed += P_Elapsed;
            t.Elapsed += T_Elapsed;
        }

        private void P_Elapsed(object sender, ElapsedEventArgs e)
        {
            if (p.Interval != 2000)
                p.Interval = 2000;
            else
                started = true;

            p.Enabled = false;
            t.Enabled = true;
        }

        public void SetVoteTypes ()
        {
            chances.Clear();

            if (getEvents)
                chances.Add("Event", 6);

            if (getItems)
                chances.Add("Item", 2);

            if (getTrinkets)
                chances.Add("Trinket", 1);

            if (getHearts)
                chances.Add("Heart", 3);

            if (getPickups)
                chances.Add("Pickup", 4);

            if (getCompanions)
                chances.Add("Companion", 4);

            if (getPockets)
                chances.Add("Pocket", 4);
        }

        public void RestoreLists ()
        {
            Hearts.Clear();
            Pickups.Clear();
            Companions.Clear();
            Pockets.Clear();
            Events.Clear();

            Hearts.Add(new VoteHeart("Red"));
            Hearts.Add(new VoteHeart("Container"));
            Hearts.Add(new VoteHeart("Soul"));
            Hearts.Add(new VoteHeart("Golden"));
            Hearts.Add(new VoteHeart("Eternal"));
            Hearts.Add(new VoteHeart("Black"));

            Pickups.Add(new VotePickup("Coin", "3 Coins", "Happy"));
            Pickups.Add(new VotePickup("Key", "1 Key", "Happy"));
            Pickups.Add(new VotePickup("Bomb", "1 Bomb", "Happy"));
            Pickups.Add(new VotePickup("-Coin", "-5 Coins", "Sad"));
            Pickups.Add(new VotePickup("-Key", "-2 Key", "Sad"));
            Pickups.Add(new VotePickup("-Bomb", "-2 Bombs", "Sad"));

            Companions.Add(new VoteCompanion("Fly", "5 Blue Flies", "Happy"));
            Companions.Add(new VoteCompanion("Spider", "5 Blue Spiders", "Happy"));
            Companions.Add(new VoteCompanion("PrettyFly", "1 Pretty Fly", "Happy"));
            Companions.Add(new VoteCompanion("BadFly", "5 Attack Flies", "Sad"));
            Companions.Add(new VoteCompanion("BadSpider", "5 Attack Spiders", "Sad"));

            Pockets.Add(new VotePocket("LuckUp", "Luck Up", "Your luck is growing!", "Happy"));
            Pockets.Add(new VotePocket("LuckDown", "Luck Down", "Your luck is decreased!", "Sad"));
            Pockets.Add(new VotePocket("Pill", "Pill", "You get Pill!", "Happy"));
            Pockets.Add(new VotePocket("Card", "Card", "You get Card!", "Happy"));
            Pockets.Add(new VotePocket("Rune", "Rune", "You get Rune!", "Happy"));
            Pockets.Add(new VotePocket("Charge", "Charge item", "Your item is fully charged!", "Happy"));
            Pockets.Add(new VotePocket("Discharge", "Discharge item", "Your item is fully discharged!", "Sad"));

            Events.Add(new VoteEvent("Slow", "Slow", "So slowly...", "Happy"));
            Events.Add(new VoteEvent("Poop", "Poop", "Who will clean it?", "Sad"));
            Events.Add(new VoteEvent("Richy", "Richy", "Yeah, i am lucky!", "Happy"));
            Events.Add(new VoteEvent("Earthquake", "Earthquake", "Protect your head", "Sad"));
            Events.Add(new VoteEvent("Charm", "Charm", "Love everywhere", "Happy"));
            Events.Add(new VoteEvent("Hell", "Hell", "Hot and bloody", "Sad"));
            Events.Add(new VoteEvent("Spiky", "Spiky", "Ouch!", "Sad"));
            Events.Add(new VoteEvent("Award", "Award", "Take your reward", "Happy"));
            Events.Add(new VoteEvent("AngelRage", "Angel Rage", "Holy crap!", "Happy"));
            Events.Add(new VoteEvent("DevilRage", "Devil Rage", "What a hell?", "Happy"));
            Events.Add(new VoteEvent("RainbowRain", "Rainbow Rain", "Unicorn start piss", "Happy"));
            Events.Add(new VoteEvent("CallToDark", "Call To Dark", "Hello, it's Dark?", "Happy"));
            Events.Add(new VoteEvent("RUN", "RUN", "Run Forest, run!", "Sad"));
            Events.Add(new VoteEvent("FlashJump", "Flash Jump", "Faster than light", "Happy"));
            Events.Add(new VoteEvent("EyesBleed", "Eyes Bleed", "What is happening?", "Sad"));
            Events.Add(new VoteEvent("StanleyParable", "Stanley Parable", "Good job, Stanley!", "Happy"));
            Events.Add(new VoteEvent("Supernova", "Supernova", "DESTROY THE WORLD!", "Happy"));
            Events.Add(new VoteEvent("DDoS", "DDoS", "50 Gb/sec attack", "Sad"));
        }

        private void T_Elapsed(object sender, ElapsedEventArgs e)
        {
            checkInterrupt();
            int interr = Interrupt.Count > 0 ? Interrupt.Pop() : -1;

            if (Subscribers.Count > 0)
            {
                started = false;
                string sub = Subscribers.Pop();
                t.Enabled = false;
                p.Enabled = true; 
                voteAwait[0] = "Sub";
                voteAwait[1] = "New subscriber - " + sub + "!";
                voteAwait[2] = sub;
                voteAwait[3] = rnd.NextDouble().ToString();
                updateIsaac(false);
                return;
            }

            if (Bits.Count > 0)
            {
                started = false;
                int bits = Bits.Pop();
                t.Enabled = false;
                p.Enabled = true;
                voteAwait[0] = "Bits";
                voteAwait[1] = "You get " + bits + " bits!";
                voteAwait[3] = rnd.NextDouble().ToString();
                updateIsaac(false);
                return;
            }

            if (started)
            {
                if (interr == -1)
                {
                    if (nowTimeForVote > 0)
                        nowTimeForVote--;
                    else
                        stopVote();
                }

                if (interr == 0)
                {
                    stopVote(true);
                }

                if (interr == 1)
                {
                    stopVote();
                }
            }
            else
            {
                if (nowTimeForDelay > 0)
                    nowTimeForDelay--;
                else
                    startVote();
            }

            updateIsaac();
        }

        public void checkInterrupt ()
        {
            string[] res = File.ReadAllLines(IsaacOut)[0].Split(' ');
            if (lastInterrupt != res[res.Length - 1])
            {
                lastInterrupt = res[res.Length - 1];
                Interrupt.Push(int.Parse(res[0]));
            }
        }

        public void startVote()
        {
            vars.Clear();
            votes.Clear();
            votes.Add(0);
            votes.Add(0);
            votes.Add(0);

            List<string> chanceList = new List<string>();

            foreach (KeyValuePair<string, int> kp in chances)
            {
                for (int i = 0; i < kp.Value; i++)
                    chanceList.Add(kp.Key);
            }

            voteType = chanceList[rnd.Next(0, chanceList.Count)];

            if (voteType == "Event")
            {
                quest = "Select event";
                for (int i = 0; i < 3; i++)
                {
                    VoteEvent o = Events[rnd.Next(0, Events.Count)];
                    vars.Add(o);
                    Events.Remove(o);
                }
            }

            if (voteType == "Item")
            {
                
                quest = "Select item";
                vars.Add(Items[rnd.Next(0, Items.Count)]);
                vars.Add(Items[rnd.Next(0, Items.Count)]);
                vars.Add(Items[rnd.Next(0, Items.Count)]);
            }

            if (voteType == "Trinket")
            {
                quest = "Select trinket";
                vars.Add(Trinkets[rnd.Next(0, Trinkets.Count)]);
                vars.Add(Trinkets[rnd.Next(0, Trinkets.Count)]);
                vars.Add(Trinkets[rnd.Next(0, Trinkets.Count)]);
            }

            if (voteType == "Heart")
            {
                quest = "Select heart";
                for (int i = 0; i < 3; i++)
                {
                    VoteHeart o = Hearts[rnd.Next(0, Hearts.Count)];
                    vars.Add(o);
                    Hearts.Remove(o);
                }
            }

            if (voteType == "Pickup")
            {
                voteType = "Pickup";
                quest = "Select pickup";
                for (int i = 0; i < 3; i++)
                {
                    VotePickup o = Pickups[rnd.Next(0, Pickups.Count)];
                    vars.Add(o);
                    Pickups.Remove(o);
                }
            }

            if (voteType == "Companion")
            {
                voteType = "Companion";
                quest = "Select companions";
                for (int i = 0; i < 3; i++)
                {
                    VoteCompanion o = Companions[rnd.Next(0, Companions.Count)];
                    vars.Add(o);
                    Companions.Remove(o);
                }
            }

            if (voteType == "Pocket")
            {
                voteType = "Pocket";
                quest = "Select one";
                for (int i = 0; i < 3; i++)
                {
                    VotePocket o = Pockets[rnd.Next(0, Pockets.Count)];
                    vars.Add(o);
                    Pockets.Remove(o);
                }
            }

            nowTimeForVote = timeForVote;
            started = true;
        }

        public void stopVote(bool skip = false)
        {
            started = false;
            users.Clear();
            int max = 0;
            int maxnum = rnd.Next(0,3);

            for (int i = 0; i < votes.Count; i++)
            {
                if (votes[i] > max)
                {
                    max = votes[i];
                    maxnum = i;
                }
            }

            nowTimeForDelay = timeForDelay;
            if (!skip)
            {
                voteAwait[0] = "Get";
                voteAwait[1] = vars[maxnum].msg;
                voteAwait[2] = voteType;
                voteAwait[3] = vars[maxnum].name;
                voteAwait[4] = vars[maxnum].emotion;
                voteAwait[5] = rnd.NextDouble().ToString();
            }
            else
            {
                voteAwait[0] = "Info";
                voteAwait[1] = "Vote has been skipped";
                voteAwait[2] = "";
                voteAwait[3] = "";
                voteAwait[4] = "";
                voteAwait[5] = "";
            }

            if (vars[maxnum].removable)
            {
                if (voteType == "Item")
                    Items.Remove((VoteItem)vars[maxnum]);

                if (voteType == "Trinket")
                    Trinkets.Remove((VoteTrinket)vars[maxnum]);

                if (Items.Count < 4 || Trinkets.Count < 4)
                {
                    Items.Clear();
                    Trinkets.Clear();
                    LoadItemsAndTrinkets();
                }
            }

            RestoreLists();
        }

        public void updateIsaac (bool time = true)
        {
            if (started)
            {
                int perc = ((votes[0] + votes[1] + votes[2])) > 0 ? 100 / ((votes[0] + votes[1] + votes[2])) : 0;
                string one = "#1 " + vars[0].displayName + " (" + (votes[0] * perc) + "%)";
                string two = "#2 " + vars[1].displayName + " (" + (votes[1] * perc) + "%)";
                string three = "#3 " + vars[2].displayName + " (" + (votes[2] * perc) + "%)";
                string[] data = {"Vote", quest + " (" + nowTimeForVote.ToString() + "s)", one, two, three };
                File.WriteAllText(Isaac, "");
                File.WriteAllLines(Isaac, data);
            }
            else
            {
                string[] res = new string[voteAwait.Length];

                for (int i = 0; i < voteAwait.Length; i++)
                    res[i] = voteAwait[i];

                File.WriteAllText(Isaac, "");
                if (time)
                    res[1] += " (" + nowTimeForDelay + "s)";
                File.WriteAllLines(Isaac, res);
            }
        }

        private void b_Connect_Click(object sender, RoutedEventArgs e)
        {
            timeForVote = int.Parse(i_voteTime.Text);
            timeForDelay = int.Parse(i_voteDelay.Text);
            try
            {
                Twitch = new TwitchClient(new ConnectionCredentials("justinfan1", ""), i_channelName.Text);
                
                Twitch.Connect();
            }
            catch { t_Status.Text = "Error connect to channel"; return; }
            
            Twitch.OnMessageReceived += Twitch_OnMessageReceived;
            Twitch.OnNewSubscriber += Twitch_OnNewSubscriber;
            Twitch.OnReSubscriber += Twitch_OnReSubscriber;
            t_Status.Text = "Now start new game and click on this button";
            b_Start.IsEnabled = true;
        }

        private void Twitch_OnReSubscriber(object sender, TwitchLib.Events.Client.OnReSubscriberArgs e)
        {
            Subscribers.Push(e.ReSubscriber.DisplayName);
        }

        private void Twitch_OnNewSubscriber(object sender, TwitchLib.Events.Client.OnNewSubscriberArgs e)
        {
            Subscribers.Push(e.Subscriber.Name);
        }

        private void Twitch_OnMessageReceived(object sender, TwitchLib.Events.Client.OnMessageReceivedArgs e)
        {
            if (started)
            {
                if (users.Contains(e.ChatMessage.UserId)) { return; }
                users.Add(e.ChatMessage.UserId);
                string msg = e.ChatMessage.Message.Trim();

                if (msg == "1" || msg == "#1" || msg == vars[0].displayName)
                    votes[0]++;

                if (msg == "2" || msg == "#2" || msg == vars[1].displayName)
                    votes[1]++;

                if (msg == "3" || msg == "#3" || msg == vars[2].displayName)
                    votes[2]++;
            }

            if (e.ChatMessage.Bits >= 35)
                Bits.Push(e.ChatMessage.Bits);
        }

        private void LoadItemsAndTrinkets ()
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
        

        public class VoteVariant
        {
            public string name;
            public string displayName;
            public string msg;
            public string emotion;
            public bool removable = false;

            public VoteVariant (string name) {
                this.name = name;
                this.displayName = name;
                this.msg = "You get " + displayName;
                this.emotion = "Happy";
            }
        }

        public class VoteItem : VoteVariant
        {
            public VoteItem(string name) : base (name)
            { removable = true; }
        }

        public class VoteTrinket : VoteVariant
        {
            public VoteTrinket(string name) : base(name)
            { removable = true; }
        }

        public class VoteHeart : VoteVariant
        {
            public VoteHeart(string name) : base(name)
            { this.msg = "You get " + displayName + " heart!"; }
        }

        public class VotePickup : VoteVariant
        {
            public VotePickup(string name, string displayName, string emotion) : base(name)
            { this.displayName = displayName; this.msg = "You get " + displayName; this.emotion = emotion;}
        }

        public class VoteCompanion : VoteVariant
        {
            public VoteCompanion(string name, string displayName, string emotion) : base(name)
            { this.displayName = displayName; this.msg = "You get " + displayName; this.emotion = emotion; }
        }

        public class VotePocket : VoteVariant
        {
            public VotePocket(string name, string displayName, string msg, string emotion) : base(name)
            {
                this.displayName = displayName;
                this.msg = msg;
                this.emotion = emotion;
            }
        }

        public class VoteEvent : VoteVariant
        {
            public VoteEvent(string name, string displayName, string msg, string emotion) : base(name)
            {
                this.displayName = displayName;
                this.msg = msg;
                this.emotion = emotion;
            }
        }

        private void b_Start_Click(object sender, RoutedEventArgs e)
        {
            SetVoteTypes();
            p.Start();
            voteAwait[0] = "Info";
            voteAwait[1] = "Starting vote...";
            updateIsaac(false);
            t_Status.Text = "Connected";
        }

        private void b_SaveTypes_Click(object sender, RoutedEventArgs e)
        {
            getEvents = (bool)c_getEvents.IsChecked;
            getItems = (bool)c_getItems.IsChecked;
            getTrinkets = (bool)c_getTrinkets.IsChecked;
            getHearts = (bool)c_getHearts.IsChecked;
            getPickups = (bool)c_getPickups.IsChecked;
            getCompanions = (bool)c_getCompanions.IsChecked;
            getPockets = (bool)c_getPockets.IsChecked;
            SetVoteTypes();
        }

        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        {
            t.Stop();
            string[] bye = { "Info", "Please, run TwitchToIsaac for starting" };
            File.WriteAllLines(Isaac, bye);
           
        }
    }
}

﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Timers;
using System.Windows.Controls;
using System.Windows.Media;
using TwitchLib;
using TwitchLib.Models.Client;
using TwitсhToIsaac.Classes.Events;
using TwitсhToIsaac.Classes.VotingOptions;
using TwitchLib.Events.Services.FollowerService;
using TwitchLib.Services;
using TwitchLib.Events.Client;
using TwitchToIsaac.Classes;
using TwitchToIsaac;
using TwitchLib.Interfaces;

namespace TwitсhToIsaac.Classes
{
    public static class Controller
    {
        static private string apikeyTwitch = "vtr91vw1dzji7piypq7r13itr6is2i";
        static private string apikeyYoutube = "AIzaSyDnCJrVkPNb8MOirL8cwTgK_Ox4x4oerx0";

        enum TimerType
        {
            Vote, Interrupt, Special, Wait
        }

        public enum EventSelectMode
        {
            Easy, Normal, Nightmare
        }

        static Dictionary<TimerType, Timer> Timers = new Dictionary<TimerType, Timer>();
        static Dictionary<string, int> Delays = new Dictionary<string, int>();
        static Dictionary<string, string> Gifts = new Dictionary<string, string>();
        static Queue<ActionSub> Subs = new Queue<ActionSub>();
        static Queue<ActionBits> Bits = new Queue<ActionBits>();
        static Queue<int> Interrupts = new Queue<int>();
        static List<string> SubCache = new List<string>();
        static TwitchAPI tapi = new TwitchAPI("vtr91vw1dzji7piypq7r13itr6is2i");
        
        static double lastInterruptHash = 0;
        static int nowInterrupt;

        public static Overlay overlay = null;
        static TextBlock MainStatus = null;
        static Button RunButton = null;
        static TwitchClient Twitch = new TwitchClient(new ConnectionCredentials("justinfan1", ""));
        static YouTubeChat Youtube = new YouTubeChat(apikeyYoutube);
        static FollowerService FollowerScan = null;
        static Vote Poll = null;
        static Act Event = null;
        static Act SpecialEvent = null;
        static Random rnd = new Random();

        static VoteModifiers votemodifier = VoteModifiers.Nothing;
        static bool ready = false;
        static bool voteon = false;
        static public bool started = false;
        static string channel = "";
        static public int newsubs = 0;
        static public int viewers = 0;
        static public EventSelectMode esm = EventSelectMode.Normal;

        public static void Init (TextBlock SMainStatus, Button SRunButton, Overlay soverlay)
        {
            MainStatus = SMainStatus;
            RunButton = SRunButton;
            overlay = soverlay;
            Twitch.OnConnected += Twitch_OnConnected;
            Twitch.OnConnectionError += Twitch_OnConnectionError;
            Twitch.OnJoinedChannel += Twitch_OnJoinedChannel;
            Twitch.OnMessageReceived += Twitch_OnMessageReceived;
            Twitch.OnNewSubscriber += Twitch_OnNewSubscriber;
            Twitch.OnReSubscriber += Twitch_OnReSubscriber;

            Youtube.NewMessage += Youtube_NewMessage;

            Timers.Add(TimerType.Vote, new Timer(1000));
            Timers.Add(TimerType.Interrupt, new Timer(1000));
            Timers.Add(TimerType.Special, new Timer(1000));
            Timers.Add(TimerType.Wait, new Timer(5000));

            Timers[TimerType.Vote].Elapsed += VoteLoop;
            Timers[TimerType.Interrupt].Elapsed += InterruptLoop;
            Timers[TimerType.Special].Elapsed += SpecialLoop;
            Timers[TimerType.Wait].Elapsed += WaitLoop;

            Delays.Add("Delay", VoteTime.delay);
            Delays.Add("Vote", VoteTime.vote);
            Delays.Add("Special", 3);
            Delays.Add("Interrupt", 5);

            VoteChances.Save();
            VotePool.Load();
            LoadGifts();
            ChatColors.Init();

            Twitch.Connect();
            lastInterruptHash = IOLink.OutputData.interruptHash;
            
        }

        private static void Youtube_NewMessage(object sender, YouTubeChat.Data.SimpleMessage e)
        {
            if (Poll == null || Poll.stopped == true)
                return;

            if (Poll.peoples.Contains(e.user))
                return;
            

            string msg = e.message;

            if (votemodifier == VoteModifiers.H4CKED)
            {
                Poll.VoteFor(rnd.Next(0, Poll.variants.Count));
                return;
            }

            if (msg == "1" || msg == "#1" || msg == Poll.variants[0].displayName)
            {
                Poll.VoteFor(0);
                Poll.peoples.Add(e.user);
            }
            else if (msg == "2" || msg == "#2" || msg == Poll.variants[1].displayName)
            {
                Poll.VoteFor(1);
                Poll.peoples.Add(e.user);
            }
            else if (msg == "3" || msg == "#3" || msg == Poll.variants[2].displayName)
            {
                Poll.VoteFor(2);
                Poll.peoples.Add(e.user);
            }
        }

        private static void Twitch_OnReSubscriber(object sender, TwitchLib.Events.Client.OnReSubscriberArgs e)
        {
            if (!SpecialAppear.subs)
                return;

            if (!SubCache.Contains(e.ReSubscriber.DisplayName.ToLower()))
            {
                newsubs++;
                Subs.Enqueue(new ActionSub(e.ReSubscriber.DisplayName, rnd.Next()));
                SubCache.Add(e.ReSubscriber.DisplayName.ToLower());
            }
        }

        private static void Twitch_OnNewSubscriber(object sender, TwitchLib.Events.Client.OnNewSubscriberArgs e)
        {
            if (!SpecialAppear.subs)
                return;

            if (!SubCache.Contains(e.Subscriber.DisplayName.ToLower()))
            {
                newsubs++;
                Subs.Enqueue(new ActionSub(e.Subscriber.DisplayName, rnd.Next()));
                SubCache.Add(e.Subscriber.DisplayName.ToLower());
            }
        }

        private static void Twitch_OnMessageReceived(object sender, TwitchLib.Events.Client.OnMessageReceivedArgs e)
        {
            if (e.ChatMessage.Bits > 10)
            {
                int count = e.ChatMessage.Bits;
                int norm = count-24;
                BitsType btype = BitsType.Gray;

                if (count / 100 >= 1)
                {
                    btype = BitsType.Purple;
                    norm = (int)(Math.Round((double)(count / 100)));
                }

                if (count / 1000 >= 1)
                {
                    btype = BitsType.Green;
                    norm = (int)Math.Round((double)(count / 1000)); ;
                }

                if (count / 5000 >= 1)
                {
                    btype = BitsType.Blue;
                    norm = (int)Math.Round((double)(count / 5000));
                }

                if (count / 10000 >= 1)
                {
                    btype = BitsType.Red;
                    norm = (int)Math.Round((double)(count / 10000));
                }

                Bits.Enqueue(new ActionBits(norm, btype, rnd.NextDouble()));
            }
            

            if (Poll == null || Poll.stopped == true)
                return;

            if (Poll.peoples.Contains(e.ChatMessage.DisplayName))
                return;

            string msg = e.ChatMessage.Message;

            if (votemodifier == VoteModifiers.H4CKED)
            {
                Poll.VoteFor(rnd.Next(0, Poll.variants.Count));
                return;
            }

            if (msg == "1" || msg == "#1" || msg == Poll.variants[0].displayName)
            {
                Poll.VoteFor(0);
                Poll.peoples.Add(e.ChatMessage.DisplayName);
            }
            else if (msg == "2" || msg == "#2" || msg == Poll.variants[1].displayName)
            {
                Poll.VoteFor(1);
                Poll.peoples.Add(e.ChatMessage.DisplayName);
            }
            else if (msg == "3" || msg == "#3" || msg == Poll.variants[2].displayName)
            {
                Poll.VoteFor(2);
                Poll.peoples.Add(e.ChatMessage.DisplayName);
            }
        }

        public static void JoinOnChannel (string name)
        {
            if (name.ToLower() != channel.ToLower())
            {
                if (channel != "")
                {
                    Twitch.LeaveChannel(channel);
                    ScreenStatus.AddLog("Exit from " + channel);
                }

                Twitch.JoinChannel(name);
                try
                {
                    if (FollowerScan != null)
                    FollowerScan.StopService();

                
                    FollowerScan = new FollowerService(tapi, 30, 25, apikeyTwitch);
                    FollowerScan.OnNewFollowersDetected += FollowerScan_OnNewFollowersDetected;
                    FollowerScan.OnServiceStarted += FollowerScan_OnServiceStarted;
                    FollowerScan.OnServiceStopped += FollowerScan_OnServiceStopped;
                    FollowerScan.SetChannelByName(name);
                    FollowerScan.StartService();
                }
                catch { ScreenStatus.AddLog("Follower service not started", ScreenStatus.LogType.Error); }
            }
        }

        public static void JoinOnYoutubeStream (string url)
        {
            if (Youtube.ConnectToChat(url))
            {
                ScreenStatus.AddLog("Youtube chat connected", ScreenStatus.LogType.Success);
                RunButton.IsEnabled = true;
            }
            else
                ScreenStatus.AddLog("Youtube chat connection error", ScreenStatus.LogType.Error);
        }

        private static void FollowerScan_OnServiceStopped(object sender, OnServiceStoppedArgs e)
        {
            ScreenStatus.AddLog("Follower service stopped");
        }

        private static void FollowerScan_OnServiceStarted(object sender, OnServiceStartedArgs e)
        {
            ScreenStatus.AddLog("Follower service started", ScreenStatus.LogType.Success);
        }

        private static void FollowerScan_OnNewFollowersDetected(object sender, OnNewFollowersDetectedArgs e)
        {
            if (!SpecialAppear.followers)
                return;

            foreach (IFollow f in e.NewFollowers)
            {
                if (!SubCache.Contains(f.User.DisplayName.ToLower()))
                {
                    Subs.Enqueue(new ActionSub(f.User.DisplayName, rnd.Next(), true));
                    SubCache.Add(f.User.DisplayName.ToLower());
                }
            }
        }

        public static void Start ()
        {
            ready = true;
            ScreenStatus.AddLog("--------Session start--------");
            ScreenStatus.UpdateScreenStatus();

            Event = new ActionInfo("Voting will start soon");

            if (IOLink.InputData != Event)
                IOLink.InputData = Event;


            foreach(KeyValuePair<TimerType, Timer> t in Timers)
            {
                t.Value.Stop();
            }

            Delays["Delay"] = VoteTime.delay;
            Delays["Vote"] = VoteTime.vote;
            Delays["Special"] = 3;
            Delays["Interrupt"] = 3;

            Timers[TimerType.Wait].Start();
        }

        public static void Stop ()
        {
            ready = false;
            foreach (KeyValuePair<TimerType, Timer> t in Timers)
            {
                t.Value.Stop();
            }

            IOLink.InputData = new ActionInfo("Run TwitchToIsaac for start!");
        }

        public static void NewVote ()
        {
            Delays["Vote"] = VoteTime.vote;
            Poll = new Vote(IOLink.OutputParam.stats.luck);
            string text = "Select ";
            string secondtext = "";

            switch (Poll.voteType)
            {
                case VoteType.Event: text += " event"; break;
                case VoteType.Item: text += " item"; break;
                case VoteType.Trinket: text += " trinket"; break;
                case VoteType.Heart: text += " heart"; break;
                case VoteType.Companion: text += " companion"; break;
                case VoteType.Pickup: text += " pickup"; break;
                case VoteType.Pocket: text += " one"; break;
            }

            Event = new ActionVote(text, secondtext, 0);
            ScreenStatus.AddLog("Vote start: " + text);
            voteon = true;

            overlay.Dispatcher.Invoke(() =>
            {

                overlay.Wait.Visibility = System.Windows.Visibility.Hidden;
                overlay.Vote.Visibility = System.Windows.Visibility.Visible;

            });
        }

        private static void WaitLoop(object sender, ElapsedEventArgs e)
        {
            lastInterruptHash = IOLink.OutputData.interruptHash;
            NewVote();
            Timers[TimerType.Wait].Stop();
            Timers[TimerType.Vote].Start();
        }

        private static void SpecialLoop(object sender, ElapsedEventArgs e)
        {
            ScreenStatus.UpdateScreenStatus();

            if (Delays["Special"] > 0)
            {
                Delays["Special"]--;
                IOLink.InputData = SpecialEvent;
            }
            else
            {
                Timers[TimerType.Special].Stop();
                Timers[TimerType.Vote].Start();
                ScreenStatus.AddLog(SpecialEvent.text);
            }
        }

        private static void InterruptLoop(object sender, ElapsedEventArgs e)
        {
            if (Delays["Interrupt"] > 0)
            {
                if (nowInterrupt == 0)
                {
                    IOLink.InputData = new ActionInfo("Vote will be skipped after " + Delays["Interrupt"] + "s");

                    overlay.Dispatcher.Invoke(() =>
                    {
                        overlay.wait_text.Text = "Vote will be skipped";
                        overlay.wait_time.Text = Delays["Interrupt"] + "s";
                    });
                }

                if (nowInterrupt == 1)
                {
                    IOLink.InputData = new ActionInfo("Vote will be accepted after " + Delays["Interrupt"] + "s");

                    overlay.Dispatcher.Invoke(() =>
                    {
                        overlay.wait_text.Text = "Vote will be accepted";
                        overlay.wait_time.Text = Delays["Interrupt"] + "s";
                    });
                }

                Delays["Interrupt"]--;

            }
            else
            {
                if (nowInterrupt == 0)
                {
                    ScreenStatus.AddLog("Used [VOTE NAY]");
                    IOLink.InputData = new ActionInfo("Vote will be skipped after " + Delays["Interrupt"] + "s");

                    overlay.Dispatcher.Invoke(() =>
                    {
                        overlay.wait_text.Text = "Vote will be skipped";
                        overlay.wait_time.Text = Delays["Interrupt"] + "s";
                    });

                    NewVote();
                }

                if (nowInterrupt == 1)
                {
                    ScreenStatus.AddLog("Used [VOTE YEA]");
                    IOLink.InputData = new ActionInfo("Vote will be accepted after " + Delays["Interrupt"] + "s");

                    overlay.Dispatcher.Invoke(() =>
                    {
                        overlay.wait_text.Text = "Vote will be accepted";
                        overlay.wait_time.Text = Delays["Interrupt"] + "s";
                    });

                    Delays["Vote"] = 0;
                }

                Timers[TimerType.Interrupt].Stop();
                Timers[TimerType.Vote].Start();
            }
        }

        private static void VoteLoop(object sender, ElapsedEventArgs e)
        {
            ScreenStatus.UpdateScreenStatus();

            if (IOLink.OutputParam.pause)
                return;

            if (IOLink.OutputData.interruptHash != lastInterruptHash)
            {
                lastInterruptHash = IOLink.OutputData.interruptHash;
                Interrupts.Enqueue(IOLink.OutputData.interrupt);
            }

            if (Interrupts.Count > 0)
            {

                overlay.Dispatcher.Invoke(() =>
                {
                    overlay.Wait.Visibility = System.Windows.Visibility.Visible;
                    overlay.Vote.Visibility = System.Windows.Visibility.Hidden;
                });

                Timers[TimerType.Vote].Stop();
                nowInterrupt = Interrupts.Dequeue();
                Delays["Interrupt"] = 3;
                Timers[TimerType.Interrupt].Start();
                return;
            }

            if (Subs.Count > 0)
            {

                overlay.Dispatcher.Invoke(() =>
                {
                    overlay.Wait.Visibility = System.Windows.Visibility.Visible;
                    overlay.Vote.Visibility = System.Windows.Visibility.Hidden;
                });

                Timers[TimerType.Vote].Stop();
                Delays["Special"] = 3;
                SpecialEvent = Subs.Dequeue();
                Timers[TimerType.Special].Start();
                return;
            }

            if (Bits.Count > 0 && SpecialAppear.bits)
            {

                overlay.Dispatcher.Invoke(() =>
                {
                    overlay.Wait.Visibility = System.Windows.Visibility.Visible;
                    overlay.Vote.Visibility = System.Windows.Visibility.Hidden;
                });

                Timers[TimerType.Vote].Stop();
                Delays["Special"] = 3;
                SpecialEvent = Bits.Dequeue();
                Timers[TimerType.Special].Start();
                return;
            }

            if (!Poll.stopped && Delays["Vote"] > 0 && voteon)  //Call during voting
            {
                Delays["Vote"]--;
                ActionVote EVote = (ActionVote)Event;
                string secondtext = "";


                for (int i = 0; i < Poll.variants.Count; i++)
                {
                    secondtext += "#" + (i + 1) + " " + Poll.variants[i].displayName + " (" + Poll.percents[i] + "%) ";

                    overlay.Dispatcher.Invoke(() =>
                    {

                        overlay.variants[i].Text = "#" + (i + 1) + " " + Poll.variants[i].displayName;
                        overlay.votes[i].Text = Poll.percents[i] + "%";

                    });
                }

                if (votemodifier > 0 && EVote.text[0] != '[')
                    EVote.text = "[" + votemodifier.ToString() + "] " + EVote.text;

                overlay.Dispatcher.Invoke(() =>
                {
                    overlay.vote_title.Text = EVote.text;
                    overlay.vote_time.Text = Delays["Vote"] + "s";
                });

                IOLink.InputData = new ActionVote(EVote.text + " (" + Delays["Vote"] + "s)", secondtext, 0);
            }
            else if (!Poll.stopped && Delays["Vote"] <= 0 && voteon) //Call after vote, but before getting
            {
                voteon = false;
                Delays["Delay"] = VoteTime.delay;
                VoteVariant Result = Poll.GetWinner();
                viewers = Poll.votescount;

                if (Poll.voteType == VoteType.Pickup)
                    Event = new ActionGetPickup((VotePickup)Result, rnd.NextDouble());
                else
                    Event = new ActionGet(Result, rnd.NextDouble());

                ScreenStatus.AddLog("Vote over: " + Event.text);

                //Set or reset vote modifier
                if (Result.type == VoteType.Event)
                {
                    VoteEvent Evote = (VoteEvent)Result;
                    votemodifier = Evote.votemodifier;
                }
                else
                    votemodifier = VoteModifiers.Nothing;

                overlay.Dispatcher.Invoke(() =>
                {
                    overlay.Wait.Visibility = System.Windows.Visibility.Visible;
                    overlay.Vote.Visibility = System.Windows.Visibility.Hidden;
                });

            }
            else if (Poll.stopped && Delays["Delay"] > 0 && !voteon) //Call during getting
            {
                
                if (Poll.voteType == VoteType.Pickup)
                {
                    ActionGetPickup EvGet = new ActionGetPickup((ActionGetPickup)Event);

                    overlay.Dispatcher.Invoke(() =>
                    {
                        overlay.wait_text.Text = EvGet.text;
                        overlay.wait_time.Text = Delays["Delay"] + "s";
                    });

                    EvGet.text += " (" + Delays["Delay"] + "s)";

                    IOLink.InputData = EvGet;
                }
                else
                {
                    ActionGet EvGet = new ActionGet((ActionGet)Event);

                    overlay.Dispatcher.Invoke(() =>
                    {
                        overlay.wait_text.Text = EvGet.text;
                        overlay.wait_time.Text = Delays["Delay"] + "s";
                    });

                    EvGet.text += " (" + Delays["Delay"] + "s)";

                    IOLink.InputData = EvGet;
                }

                Delays["Delay"]--;
            }
            else if (Poll.stopped && Delays["Delay"] <= 0 && !voteon) //Call after getting
                NewVote();

            
        }

        private static void Twitch_OnJoinedChannel(object sender, TwitchLib.Events.Client.OnJoinedChannelArgs e)
        {
            ScreenStatus.AddLog("Joined on " + e.Channel, ScreenStatus.LogType.Success);
            ScreenStatus.twitchChat = true;
            channel = e.Channel;
            ScreenStatus.UpdateScreenStatus();

            foreach (KeyValuePair<string, string> p in Gifts)
            {
                string[] ids = p.Key.Split(',');

                if (ids[0] == e.Channel.ToLower() || (ids.Length == 2 && ids[1] == Youtube.channel))
                    IOLink.InputParam.gift = p.Value;
            }

            MainStatus.Dispatcher.Invoke(() =>
            {
                MainStatus.Text = "Now launch Isaac and press Run!";
                RunButton.IsEnabled = true;
            });
        }

        private static void Twitch_OnConnectionError(object sender, TwitchLib.Events.Client.OnConnectionErrorArgs e)
        {
            ScreenStatus.AddLog("Error connecting to Twitch", ScreenStatus.LogType.Error);
        }

        private static void Twitch_OnConnected(object sender, TwitchLib.Events.Client.OnConnectedArgs e)
        {
            ScreenStatus.AddLog("Connected to Twitch", ScreenStatus.LogType.Success);
        }

        private static void LoadGifts ()
        {
            Gifts.Add("neonomi,UChDAzHts9B7sZIvq9NqtW7g", "Neo glasses");
            Gifts.Add("smitetv", "Yoshi shell");
            Gifts.Add("huttsgaming,UCy3avhfHpBbbgwZpNvuVklg", "Hair clap");
            Gifts.Add("tijoevideos,UCpcg8-wx6SOW3PfGT83E-BA", "Torn cat ear");
            Gifts.Add("rekvizit8bit,UCSa-d35XCyltUYHZBDbq5mg", "Gribulya's piece");
            Gifts.Add("h4hen,UCBx4iwYn6UDCB81QIPvhRlg", "Honey Lord Sting");
            Gifts.Add("vertroxmt,UCMJr3O_NEpDSxqb9cYrZvcA", "Spacesuit charge indicator");
            Gifts.Add("vadpribalt,UCRz7XF78qF4booE3gIbYOng", "Ring of Eternal Flame");
            Gifts.Add("--------,UCyvSgWv830voOV6Nwqjwo4w", "Mr. Ost coin eye");
            Gifts.Add("romawake,UCLP8lZCzcko8x6Tnt5Ko60g", "Radio 'Wake'");
            Gifts.Add("crystalous,UCKF1jFt8PUs240B7ccRXDfw", "Crystal shard");
            Gifts.Add("junkey23,UCXHczq_8PytR6mEJeUTTrqw", "Rabbit paw");
            Gifts.Add("grizzlyguygaming", "Grizzly claw");
            Gifts.Add("hellyeahplay,UCMpHpyOyoYj_7uei_sF342Q", "Inverted Cross");
            Gifts.Add("vitecp,UCXHczq_8PytR6mEJeUTTrqw", "UC's stem");
            Gifts.Add("melharucos", "Spider eye");
        }
    }

    public static class ScreenStatus
    {
        public static bool twitchChat = false;

        public static Label Lpaused;
        public static Label Lchat;
        public static Label Lviewers;
        public static Label Lsubs;
        public static Label Lruns;

        public static ListBox log;
        public enum LogType { Info, Error, Success }

        public static void AddLog(string msg, LogType t = LogType.Info)
        {
            log.Dispatcher.Invoke(() =>
            {
                TextBlock tb = new TextBlock()
                {
                    Text = msg,
                    TextWrapping = System.Windows.TextWrapping.WrapWithOverflow,
                    Margin = new System.Windows.Thickness(0, 0, 0, 5)
                };
                Color c = new Color()
                {
                    A = 255
                };
                switch (t)
                {
                    case LogType.Error:
                        c.R = 255;
                        c.G = 140;
                        c.B = 140;
                        break;

                    case LogType.Success:
                        c.R = 140;
                        c.G = 255;
                        c.B = 140;
                        break;

                    default:
                        c.R = 240;
                        c.G = 240;
                        c.B = 240;
                        break;
                }

                tb.Foreground = new SolidColorBrush(c);

                log.Items.Add(tb);
                log.SelectedItem = tb;
                log.ScrollIntoView(tb);
            }
            );
        }

        public static void UpdateScreenStatus()
        {
            log.Dispatcher.Invoke(() =>
            {
                Lpaused.Content = IOLink.OutputParam.pause ? "Yes" : "No";
                Lchat.Content = twitchChat ? "Connected" : "Disconnected";
                Lviewers.Content = Controller.viewers;
                Lsubs.Content = Controller.newsubs;
                Lruns.Content = IOLink.OutputParam.runcount;
            });
        }
    }

    public static class RenderSettings
    {
        public static class FirstLine
        {
            public static int x = 16;
            public static int y = 241;
        }

        public static class SecondLine
        {
            public static int x = 16;
            public static int y = 259;
        }
    }

    public static class SpecialAppear
    {
        public static bool subs = true;
        public static bool bits = true;
        public static bool followers = false;
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Media;
using System.Text;
using System.Threading.Tasks;
using System.Timers;
using System.Windows.Media;
using TwitсhToIsaac.Classes.VotingOptions;

namespace TwitсhToIsaac.Classes
{
    static public class SoundManager
    {
        static public List<string> Sounds = new List<string>();
        static List<int> Volume = new List<int>();
        static public MediaPlayer Player = new MediaPlayer();
        static string sfxpath = "sfx/";
        static Timer delay = new Timer(1200);

        static public void Init ()
        {
            Sounds.Add("GoodMusic.wav");
            Sounds.Add("DialUp.wav");
            Sounds.Add("Scream.wav");
            Sounds.Add("AttackOnTitan.wav");
            Sounds.Add("Interstellar.wav");
            delay.Elapsed += Delay_Elapsed;
        }

        private static void Delay_Elapsed(object sender, ElapsedEventArgs e)
        {
            Player.Dispatcher.Invoke(
                ()=>
                {
                    Player.Play();
                    delay.Stop();
                }
            );
        }

        static public void Play (int num)
        {
            if (num < 0)
                return;
            Uri u = new Uri(sfxpath + Sounds[num], UriKind.Relative);
            Player.Dispatcher.Invoke(
                () =>
                {
                    Player.Open(u);
                }
            );
            delay.Start();
        }

        static public void SetVolume (double vol)
        {
            Player.Volume = vol;
        }
    }
}

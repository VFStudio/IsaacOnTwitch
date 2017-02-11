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
using MaterialDesignThemes.Wpf;
using TwitсhToIsaac.Classes;
using TwitсhToIsaac.Classes.VotingOptions;
using System.Text.RegularExpressions;
using static TwitсhToIsaac.Classes.ScreenStatus;

namespace TwithToIsaac
{
    /// <summary>
    /// Логика взаимодействия для MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        List<Card> UITabs = new List<Card>();
        List<Button> UIMenuButtons = new List<Button>();
        public bool isOk = false;

        public MainWindow()
        {
            InitializeComponent();

            UITabs.Add(Card_Main);
            UITabs.Add(Card_Channel);
            UITabs.Add(Card_Chances);
            UITabs.Add(Card_Render);
            UITabs.Add(Card_About);

            UIMenuButtons.Add(B_main);
            UIMenuButtons.Add(B_channel);
            UIMenuButtons.Add(B_chances);
            UIMenuButtons.Add(B_render);
            UIMenuButtons.Add(B_about);

            ScreenStatus.Lpaused = LMain_ispaused;
            ScreenStatus.Lchat = LMain_chatstat;
            ScreenStatus.Lviewers = LMain_viewers;
            ScreenStatus.Lsubs = LMain_newsubs;
            ScreenStatus.Lruns = LMain_runcount;
            ScreenStatus.log = LBMain_log;

            if (IOLink.isCorrectPath())
            {
                IOLink.Start();
                Controller.Init(LMain_mainstatus, BMain_run);
                isOk = true;
            }
            else
            {
                LMain_mainstatus.Text = "Mod not found. Put program folder in the mod\nfolder and restart it";
                isOk = false;
                B_channel.IsEnabled = false;
                B_chances.IsEnabled = false;
                B_render.IsEnabled = false;
                B_about.IsEnabled = false;
            }
        }

        private void ChangeTabButton_click(object sender, RoutedEventArgs e)
        {
            for (var i = 0; i < UITabs.Count; i++)
            {
                UITabs[i].Visibility = Visibility.Hidden;
                UIMenuButtons[i].IsEnabled = true;
            }

            switch (((Button)sender).Name)
            {
                case "B_main":
                    Card_Main.Visibility = Visibility.Visible;
                    B_main.IsEnabled = false;
                    break;

                case "B_channel":
                    Card_Channel.Visibility = Visibility.Visible;
                    B_channel.IsEnabled = false;
                    break;

                case "B_chances":
                    Card_Chances.Visibility = Visibility.Visible;
                    B_chances.IsEnabled = false;
                    break;

                case "B_render":
                    Card_Render.Visibility = Visibility.Visible;
                    B_render.IsEnabled = false;
                    break;

                case "B_about":
                        Card_About.Visibility = Visibility.Visible;
                        B_about.IsEnabled = false;
                    break;
            }
        }

        private void BChannel_save_Click(object sender, RoutedEventArgs e)
        {
            VoteTime.vote = int.Parse(TChannel_votetime.Text);
            VoteTime.delay = int.Parse(TChannel_delaytime.Text);
            SpecialAppear.subs = (bool)CChannel_subs.IsChecked;
            SpecialAppear.bits = (bool)CChannel_bits.IsChecked;

            Controller.JoinOnChannel(TChannel_name.Text);
        }

        private void SChances_events_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            if ((bool)!CChances_events.IsChecked)
                CChances_events.IsChecked = true;

            VoteChances.Event = (byte)SChances_events.Value;

            if (LChances_events != null)
                LChances_events.Content = VoteChances.Event;
        }

        private void SChances_items_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            if ((bool)!CChances_items.IsChecked)
                CChances_items.IsChecked = true;

            VoteChances.Item = (byte)SChances_items.Value;

            if (LChances_items != null)
                LChances_items.Content = VoteChances.Item;
        }

        private void SChances_trinkets_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            if ((bool)!CChances_trinkets.IsChecked)
                CChances_trinkets.IsChecked = true;

            VoteChances.Trinket = (byte)SChances_trinkets.Value;

            if (LChances_trinkets != null)
                LChances_trinkets.Content = VoteChances.Trinket;
        }

        private void SChances_hearts_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            if ((bool)!CChances_hearts.IsChecked)
                CChances_hearts.IsChecked = true;

            VoteChances.Heart = (byte)SChances_hearts.Value;

            if (LChances_hearts != null)
                LChances_hearts.Content = VoteChances.Heart;
        }

        private void SChances_pickups_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            if ((bool)!CChances_pickups.IsChecked)
                CChances_pickups.IsChecked = true;

            VoteChances.Pickup = (byte)SChances_pickups.Value;

            if (LChances_pickups != null)
                LChances_pickups.Content = VoteChances.Pickup;
        }

        private void SChances_companions_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            if ((bool)!CChances_companions.IsChecked)
                CChances_companions.IsChecked = true;

            VoteChances.Companion = (byte)SChances_companions.Value;

            if (LChances_companions != null)
                LChances_companions.Content = VoteChances.Companion;
        }

        private void SChances_pockets_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            if ((bool)!CChances_pockets.IsChecked)
                CChances_pockets.IsChecked = true;

            VoteChances.Pocket = (byte)SChances_pockets.Value;

            if (LChances_pockets != null)
                LChances_pockets.Content = VoteChances.Pocket;
        }

        private void CChances_events_Click(object sender, RoutedEventArgs e)
        {
            if ((bool)!CChances_events.IsChecked)
                VoteChances.Event = 0;
            else if (SChances_events != null)
                VoteChances.Event = (byte)SChances_events.Value;

            if (LChances_events != null && SChances_events != null)
                LChances_events.Content = VoteChances.Event;
        }

        private void CChances_items_Click(object sender, RoutedEventArgs e)
        {
            if ((bool)!CChances_items.IsChecked)
                VoteChances.Item = 0;
            else if (SChances_items != null)
                VoteChances.Item = (byte)SChances_items.Value;

            if (LChances_items != null && SChances_items != null)
                LChances_items.Content = VoteChances.Item;
        }

        private void CChances_trinkets_Click(object sender, RoutedEventArgs e)
        {
            if ((bool)!CChances_trinkets.IsChecked)
                VoteChances.Trinket = 0;
            else if (SChances_trinkets != null)
                VoteChances.Trinket = (byte)SChances_trinkets.Value;

            if (LChances_trinkets != null && SChances_trinkets != null)
                LChances_trinkets.Content = VoteChances.Trinket;
        }

        private void CChances_hearts_Click(object sender, RoutedEventArgs e)
        {
            if ((bool)!CChances_hearts.IsChecked)
                VoteChances.Heart = 0;
            else if (SChances_hearts != null)
                VoteChances.Heart = (byte)SChances_hearts.Value;

            if (LChances_hearts != null && SChances_hearts != null)
                LChances_hearts.Content = VoteChances.Heart;
        }

        private void CChances_pickups_Click(object sender, RoutedEventArgs e)
        {
            if ((bool)!CChances_pickups.IsChecked)
                VoteChances.Pickup = 0;
            else if (SChances_pickups != null)
                VoteChances.Pickup = (byte)SChances_pickups.Value;

            if (LChances_pickups != null && SChances_pickups != null)
                LChances_pickups.Content = VoteChances.Pickup;
        }

        private void CChances_companions_Click(object sender, RoutedEventArgs e)
        {
            if ((bool)!CChances_companions.IsChecked)
                VoteChances.Companion = 0;
            else if (SChances_companions != null)
                VoteChances.Companion = (byte)SChances_companions.Value;

            if (LChances_companions != null && SChances_companions != null)
                LChances_companions.Content = VoteChances.Companion;
        }

        private void CChances_pockets_Click(object sender, RoutedEventArgs e)
        {
            if ((bool)!CChances_pockets.IsChecked)
                VoteChances.Pocket = 0;
            else if (SChances_pockets != null)
                VoteChances.Pocket = (byte)SChances_pockets.Value;

            if (LChances_pockets != null && SChances_pockets != null)
                LChances_pockets.Content = VoteChances.Pocket;
        }

        private void BChances_save_Click(object sender, RoutedEventArgs e)
        {
            VoteChances.Save();
        }

        private void NumberValidationTextBox(object sender, TextCompositionEventArgs e)
        {
            Regex regex = new Regex(@"\d{1,}");
            e.Handled = !regex.IsMatch(e.Text);
        }

        private void TRender_first_TextChanged(object sender, TextChangedEventArgs e)
        {
            Thickness t = new Thickness();
            if (TRender_firstX != null && TRender_firstY != null && TRender_firstX.Text != "" && TRender_firstY.Text != "")
                t = new Thickness(double.Parse(TRender_firstX.Text)/1.4, double.Parse(TRender_firstY.Text)/1.4, 0, 0);
            LRender_firstline.Margin = t;
        }

        private void BRender_resetFirstLine_Click(object sender, RoutedEventArgs e)
        {
            TRender_firstX.Text = "16";
            TRender_firstY.Text = "241";
        }

        private void TRender_second_TextChanged(object sender, TextChangedEventArgs e)
        {
            Thickness t = new Thickness();
            if (TRender_secondX != null && TRender_secondY != null && TRender_secondX.Text != "" && TRender_secondY.Text != "")
                t = new Thickness(double.Parse(TRender_secondX.Text) / 1.4, double.Parse(TRender_secondY.Text) / 1.4, 0, 0);
            LRender_secondline.Margin = t;
        }

        private void BRender_resetSecondLine_Click(object sender, RoutedEventArgs e)
        {
            TRender_secondX.Text = "16";
            TRender_secondY.Text = "256";
        }

        private void BRender_save_Click(object sender, RoutedEventArgs e)
        {
            RenderSettings.FirstLine.x = TRender_firstX.Text != "" ? int.Parse(TRender_firstX.Text) : 0;
            RenderSettings.FirstLine.y = TRender_firstY.Text != "" ? int.Parse(TRender_firstY.Text) : 0;

            RenderSettings.SecondLine.x = TRender_secondX.Text != "" ? int.Parse(TRender_secondX.Text) : 0;
            RenderSettings.SecondLine.y = TRender_secondY.Text != "" ? int.Parse(TRender_secondY.Text) : 0;

            IOLink.InputParam.textparam.firstline.x = RenderSettings.FirstLine.x;
            IOLink.InputParam.textparam.firstline.y = RenderSettings.FirstLine.y;
            IOLink.InputParam.textparam.secondline.x = RenderSettings.SecondLine.x;
            IOLink.InputParam.textparam.secondline.y = RenderSettings.SecondLine.y;
            IOLink.acceptInputParam();
        }

        private void BMain_run_Click(object sender, RoutedEventArgs e)
        {
            Controller.Start();
            BMain_run.Content = "Reset";
            LMain_mainstatus.Text = "Let's fun!";
        }

        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        {
            Controller.Stop();
            System.Threading.Thread.Sleep(1200);
            IOLink.Stop();
        }

        private void BLinks_modpage_Click(object sender, RoutedEventArgs e)
        {
            System.Diagnostics.Process.Start("https://vfstudio.github.io/IsaacOnTwitch/");
        }

        private void BLink_feedback_Click(object sender, RoutedEventArgs e)
        {
            System.Diagnostics.Process.Start("https://github.com/VFStudio/IsaacOnTwitch/issues");
        }

        private void BLink_authorReddit_Click(object sender, RoutedEventArgs e)
        {
            System.Diagnostics.Process.Start("https://www.reddit.com/user/virtualZer0/");
        }

        private void BLink_authorVk_Click(object sender, RoutedEventArgs e)
        {
            System.Diagnostics.Process.Start("https://vk.com/yevstafyev");
        }

        private void BLink_authorFacebook_Click(object sender, RoutedEventArgs e)
        {
            System.Diagnostics.Process.Start("https://www.facebook.com/profile.php?id=100006251041621");
        }
    }
}

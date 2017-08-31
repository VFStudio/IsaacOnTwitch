using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
using TwitсhToIsaac.Classes.Events;

namespace TwitchToIsaac
{
    /// <summary>
    /// Логика взаимодействия для Overlay.xaml
    /// </summary>
    public partial class Overlay : Window
    {
        public List<TextBlock> variants = new List<TextBlock>();
        public List<TextBlock> votes = new List<TextBlock>();
        bool topmostStatus = false;

        public Overlay()
        {
            InitializeComponent();

            variants.Add(vote1_name);
            variants.Add(vote2_name);
            variants.Add(vote3_name);

            votes.Add(vote1_percent);
            votes.Add(vote2_percent);
            votes.Add(vote3_percent);
        }

        public void SetData(Act text)
        {
            if (((ActionInfo)text).secondtext == "")
            {
                Wait.Visibility = Visibility.Visible;
                Vote.Visibility = Visibility.Hidden;
            }
            else
            {
                Wait.Visibility = Visibility.Hidden;
                Vote.Visibility = Visibility.Visible;
            }
        }

        private void OverlayWindow_Loaded(object sender, RoutedEventArgs e)
        {

            if (SettingsLoader.s.overlay.width == -1)
            {
                var desktopWorkingArea = System.Windows.SystemParameters.WorkArea;
                this.Left = desktopWorkingArea.Right - this.Width;
                this.Top = desktopWorkingArea.Bottom - this.Height;

                SettingsLoader.s.overlay.left = this.Left;
                SettingsLoader.s.overlay.top = this.Top;
                SettingsLoader.s.overlay.width = this.Width;
                SettingsLoader.s.overlay.height = this.Height;
                SettingsLoader.s.overlay.font = this.FontSize;
            }
            else
            {
                this.Left = SettingsLoader.s.overlay.left;
                this.Top = SettingsLoader.s.overlay.top;
                this.Width = SettingsLoader.s.overlay.width;
                this.Height = SettingsLoader.s.overlay.height;
                this.FontSize = SettingsLoader.s.overlay.font;
            }
        }

        private void OverlayHeightUp_Click(object sender, RoutedEventArgs e)
        {
            this.Height += 5;
        }

        private void OverlayHeightDown_Click(object sender, RoutedEventArgs e)
        {
            this.Height -= 5;
        }

        private void OverlayToLeft_Click(object sender, RoutedEventArgs e)
        {
            this.Left -= 5;
        }

        private void OverlayToRight_Click(object sender, RoutedEventArgs e)
        {
            this.Left += 5;
        }

        private void OverlayToUp_Click(object sender, RoutedEventArgs e)
        {
            this.Top -= 5;
        }

        private void OverlayToDown_Click(object sender, RoutedEventArgs e)
        {
            this.Top += 5;
        }

        private void OverlayWidthUp_Click(object sender, RoutedEventArgs e)
        {
            this.Width += 5;
        }

        private void OverlayWidthDown_Click(object sender, RoutedEventArgs e)
        {
            this.Width -= 5;
        }

        private void OverlayWindow_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        {
            SettingsLoader.s.overlay.left = this.Left;
            SettingsLoader.s.overlay.top = this.Top;
            SettingsLoader.s.overlay.width = this.Width;
            SettingsLoader.s.overlay.height = this.Height;
        }

        private void OverlayWindow_MouseEnter(object sender, MouseEventArgs e)
        {
            OverlayControl.Visibility = Visibility.Visible;
        }

        private void OverlayWindow_MouseLeave(object sender, MouseEventArgs e)
        {
            OverlayControl.Visibility = Visibility.Hidden;
        }

        private void FontSizeUp_Click(object sender, RoutedEventArgs e)
        {
            this.FontSize += 2;
        }

        private void FontSizeDown_Click(object sender, RoutedEventArgs e)
        {
            this.FontSize -= 2;
        }

        private void Wait_IsVisibleChanged(object sender, DependencyPropertyChangedEventArgs e)
        {
            if (Wait.Visibility == Visibility.Hidden)
            {
                wait_text.Text = "";
                wait_time.Text = "";
            }
            else
            {
                ThicknessAnimation da = new ThicknessAnimation();
                da.From = new Thickness(0, 0, -this.Width, 0);
                da.To = new Thickness(0, 0, 0, 0);
                da.Duration = TimeSpan.FromMilliseconds(350);
                Wait.BeginAnimation(Grid.MarginProperty, da);
            }
        }

        private void Vote_IsVisibleChanged(object sender, DependencyPropertyChangedEventArgs e)
        {
            if (Vote.Visibility == Visibility.Hidden)
            {
                vote1_name.Text = "";
                vote1_percent.Text = "";
                vote2_name.Text = "";
                vote2_percent.Text = "";
                vote3_name.Text = "";
                vote3_percent.Text = "";
                vote_title.Text = "";
            }
            else
            {
                ThicknessAnimation da = new ThicknessAnimation();
                da.From = new Thickness(0, 0, -this.Width, 0);
                da.To = new Thickness(0, 0, 0, 0);
                da.Duration = TimeSpan.FromMilliseconds(350);
                Vote.BeginAnimation(Grid.MarginProperty, da);
            }
        }

        private void OverlayWindow_Deactivated(object sender, EventArgs e)
        {
            if (topmostStatus)
            {
                this.Topmost = true;
                this.Activate();
            }
        }

        private void FixOverlay_Click(object sender, RoutedEventArgs e)
        {
            if (topmostStatus)
            {
                topmostStatus = false;
                this.Topmost = false;
            }
            else
            {
                topmostStatus = true;
                this.Topmost = true;
            }
        }
    }
}

   M S B A M L   `   `   `  ���� I  ETwitсhToIsaac, Version=1.2.0.0, Culture=neutral, PublicKeyToken=null+clr-namespace:TwithToIsaacTwithToIsaac      TwithToIsaac.MainWindow   R NWindowsBase, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35\ XPresentationFramework, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35W SPresentationCore, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35D 9http://schemas.microsoft.com/winfx/2006/xaml/presentation    R NSystem.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     @d2http://schemas.microsoft.com/expression/blend/2008     Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006     U QMaterialDesignThemes.Wpf, Version=2.3.1.953, Culture=neutral, PublicKeyToken=nullFmaterialDesign1http://materialdesigninxaml.net/winfx/xaml/themes  &localclr-namespace:TwithToIsaac  -     � Title$  TwitchToIsaac��$	��520��$	��615��   MaterialDesignBody#���   $��Regular"�$��13(�&   System.Windows.Media.TextOptions   TextFormattingMode$ Ideal=�   TextRenderingMode$
 Auto=�  MaterialDesignPaper#���    MaterialDesignFont#���   � WindowStartupLocation$ CenterScreen=�.��� .+�]� -    ]�Name$
 menu��$��0,35,0,0q�$	��Top=�$��Center=�.+��� -    ��Name$ B_main��$
��Main��{�.  �� -   $ 	B_channel��$��Channel��$��10,0,0,0q��� -   $ 	B_chances��$��Chances��$��10,0,0,0q��� -   $ B_render��$��Render��$��10,0,0,0q��� -   $ B_mod��$	��Mod��$��10,0,0,0q��� -   $ B_about��$��About��$��10,0,0,0q���    MaterialDesignTitleTextBlock#���  $��Center=�$��0q�$��24(�$	��Top=�Twitch To Isaac#  MaterialDesignThemes.Wpf.Card  -	     Name$ 	Card_Main��$��Bottom=�$��5,0,5,5q�$	��381��$��10q�.��]� ��.  $��0q�.+��� $	��200��.+��� #���  $��16(�$��Center=�$��WrapWithOverflow=�Log�� -
    ��Name$ 
LBMain_log��$
��Auto=�$��Disabled=�
�������$��0q�$	��340��$��11(�$	��200��$ �� IsSynchronizedWithCurrentItem$ FalseY���Z� ��Z� .@��� $��WrapWithOverflow=�$��0,0,0,5q�Started Twitch To Isaac�� $��Right=�$	��380��.+��� $	��Top=�$	��115��.+��� -   	 ��Name$	 LMain_mainstatus��#���  $��16(�$��WrapWithOverflow=�$��Center=�(&Enter channel name (go to Channel tab)�� -   $ 	BMain_run��$
��Run!��$��Center=�$��Bottom=�$��0,10,0,0q�{�.  �� -   $ BMain_overlay��$��Show overlay��$��Center=�$��Bottom=�$��0,10,0,0q�{�. �� $	��Top=�$��
10,10,10,0q�.+��� #���  $��16(�$��Center=�$��WrapWithOverflow=�$��0,0,0,10q�Status]� $��0q�$
��Left=�.+��� $	��150��.+��� .��Game is paused:�� .��Twitch chat:�� .��Active viewers:�� .��	New subs:�� .��Number of runs:�� $	��175��.+��� -   
 ��Name$
 LMain_ispaused��$
��Bold"�.��	Unknown�� -   $
 LMain_chatstat��$
��Bold"�.��Disconnected�� -   $
 LMain_viewers��$
��Bold"�.��	Unknown�� -   $
 LMain_newsubs��$
��Bold"�.��0�� -   $
 LMain_runcount��$
��Bold"�.��0  -   $ Card_Channel��$��Bottom=�$��5,0,5,5q�$	��381��$��10q�$y�Hidden=�.���� $	��Top=�$��0,10,0,0q�.+��� $��16(�$��Center=�$��WrapWithOverflow=�$��0,0,0,5q�
Channels�� -    ��Name$ TTwitchChannel_name��  MaterialDesignTextBox#���  )  #MaterialDesignThemes.Wpf.HintAssist   Hint$ Twitch channel��$��
20,0,20,10q�$��13(����	#899C78F0�� -   $ TYoutubeChannel_name��#���  $ Youtube stream url��$��
20,0,20,10q�$��13(����	#89FF6363��  �� Orientation$ 
Horizontal=�$��Center=�$��Center=�.+��� $��0,0,20,0q�.+��� $��16(�$��Center=�$��WrapWithOverflow=�$��0,10,0,5q�
Vote (sec)�� -   $ TChannel_votetime��#���  $��70��$ 	Vote time��$��0,0,0,10q�$��13(�$��Center=�$	��120���� .+��� $��16(�$��Center=�$��WrapWithOverflow=�$��0,10,0,5q�Delay (sec)�� -   $ TChannel_delaytime��#���  $��15��$ 
Delay time��$��0,0,0,10q�$��13(�$��Center=�$	��120���� $��Center=�.+��� -    ��Name$ CChannel_subs��$��Subs appear in game��$
��Left=� d� 	IsChecked$
 TrueY�$��0,10,0,2q�$��16(��� -   $ CChannel_followers��$��Followers appear in game��$
��Left=�$ falseY�$��0,5,0,2q�$��16(��� -   $ CChannel_bits��$��Bits appear in game��$
��Left=�$
 TrueY�$��0,5,0,2q�$��16(��� -   $ CChannel_announce��$��Announce to Discord��$
��Left=�$ FalseY�$��0,5,0,2q�$��16(��� -   $ BChannel_save��$��Connect��$��Center=�$��253,10,222,0q�$��92���� $��12(�$��Center=�$��WrapWithOverflow=�$��137,5,136,0q��� $<�6The settings take effect immediately, even during game��  -   $ Card_Chances��$��Bottom=�$��5,0,5,5q�$	��381��$��10q�$y�Hidden=�.���� $	��Top=�$��0,10,0,0q�.+��� $��16(�$��Center=�$��WrapWithOverflow=�$��0,0,0,5q�Vote]� $
��30,0q�.+��� .+��� -   $ CChances_events��$��Events��$
��Left=�$
 TrueY�$��0,0,0,2q�$��16(��� -   $ CChances_items��$��Items��$
��Left=�$
 TrueY�$��0,5,0,2q�$��16(��� -    $ CChances_trinkets��$��Trinkets��$
��Left=�$
 TrueY�$��0,5,0,2q�$��16(��� -!   $ CChances_hearts��$��Hearts��$
��Left=�$
 TrueY�$��0,5,0,2q�$��16(��� -"   $ CChances_pickups��$��Pickups��$
��Left=�$
 TrueY�$��0,5,0,2q�$��16(��� -#   $ CChances_companions��$��Flies/Spiders��$
��Left=�$
 TrueY�$��0,5,0,2q�$��16(��� -$   $ CChances_pockets��$��Cards and etc.��$
��Left=�$
 TrueY�$��0,5,0,2q�$��16(��� $��10,0,0,0q�$	��260��$
��Left=�.+��� -%    ��Name$ SChances_events�� � SmallChange$ 1Q�$��24�� � Value$ 6Q��� -&   $ SChances_items��$ 1Q�$��24��$��0,5,0,0q�$ 2Q��� -'   $ SChances_trinkets��$ 1Q�$��24��$��0,5,0,0q�$ 1Q��� -(   $ SChances_hearts��$ 1Q�$��24��$��0,5,0,0q�$ 3Q��� -)   $ SChances_pickups��$ 1Q�$��24��$��0,5,0,0q�$ 4Q��� -*   $ SChances_companions��$ 1Q�$��24��$��0,5,0,0q�$ 4Q��� -+   $ SChances_pockets��$ 1Q�$��24��$��0,5,0,0q�$ 4Q��� $��10,0,0,0q�$
��Left=�.+��� -,   $
 LChances_events��$��16(�$��0q�$��23��.��6�� --   $
 LChances_items��$��16(�$��0q�$��23��$��Center=�$��0,5,0,0q�.��2�� -.   $
 LChances_trinkets��$��16(�$��0q�$��23��$��Center=�$��0,5,0,0q�.��1�� -/   $
 LChances_hearts��$��16(�$��0q�$��23��$��Center=�$��0,5,0,0q�.��3�� -0   $
 LChances_pickups��$��16(�$��0q�$��23��$��Center=�$��0,5,0,0q�.��4�� -1   $
 LChances_companions��$��16(�$��0q�$��23��$��Center=�$��0,5,0,0q�.��4�� -2   $
 LChances_pockets��$��16(�$��0q�$��23��$��Center=�$��0,5,0,0q�.��4�� -3   $ BChances_save��$
��Save��$��Center=�$��0,68,0,0q��� $��12(�$��Center=�$��WrapWithOverflow=�$��0,5,0,0q�86The settings take effect immediately, even during game  -4   $ Card_Render��$��Bottom=�$��5,0,5,5q�$	��381��$��10q�$y�Hidden=�.���� $	��Top=�$��0q�.+��� $	��315��$	��195��$��2q�
�������._�� .+��� -5   $
 LRender_firstline��$��6(�$��
11,172,0,0q�$��0q�$��10��$
��Left=�$	��Top=�.��" First line first line first line�� -6   $
 LRender_secondline��$��6(�$��0q�$��10��$��
11,184,0,0q�$
��Left=�$	��Top=�.��1/Second line second line second line second line]� $��Center=�$��0,15,0,0q�$	��385��.+��� $��Center=�$��Center=�$��0,0,12,0q�.��
First line�� $��18,0,5,0q�.��X�� -7   $ TRender_firstX��#���  $��16��$��13(�$
��Left=�$��65���� $��25,0,5,0q�.��Y�� -8   $ TRender_firstY��#���  $	��241��$��13(�$
��Left=�$��65���� -9   $ BRender_resetFirstLine��$��Reset��$��Center=�$��24��$��20,0,0,0q�$��70��]� $��Center=�$��0,10,0,0q�.+��� $��Center=�$��Center=�$��0,0,10,0q�.��Second line�� $��0,0,5,0q�.��X�� -:   $ TRender_secondX��#���  $��16��$��13(�$
��Left=�$��65���� $��25,0,5,0q�.��Y�� -;   $ TRender_secondY��#���  $	��256��$��13(�$
��Left=�$��65���� -<   $ BRender_resetSecondLine��$��Reset��$��Center=�$��24��$��25,0,0,0q�$��70���� -=   $ BRender_shaders��$��Disable shaders��$��Center=�$��4,8,0,0q�$	��Top=� � ToolTip$&  Check it, if you see blackscreen���� ->   $ BRender_save��$
��Save��$��Center=�$��0,16,0,0q�  -?   $ Card_Mod��$��Bottom=�$��5,0,5,5q�$	��381��$��10q�$y�Hidden=�.���� $��0,10,0,0q�.+��� $��18(�$��Center=�$��WrapWithOverflow=�$��0,0,0,5q�Subs disappear time (minutes)�� -@   $ TMod_subdeltime��#���  $��10��$��13(�$��Center=�$��65���� $��18(�$��Center=�$��WrapWithOverflow=�$��0,20,0,5q�Integration settings�� -A   $ CMod_integration��$!��Add items from another mods��$��Center=�$
 TrueY�$��0,0,0,2q�$��16(��� -B   $	 TMod_activemods��$��16(�$��Center=�$��WrapWithOverflow=�$��0,0,0,5q�Found mods: 0�� -C   $ 	BMod_scan��$��Rescan��$��Center=�$��79��$��0q��� $��18(�$��Center=�$��WrapWithOverflow=�$��	0,20,0,15q�
Event Mode�� -D   $ SMod_eventmode��$ 1Q� � Minimum$ 1Q� � Maximum$ 3Q�$ 2Q�$	��200��$��0q��� -E   $	 TMod_eventmode��$��16(�$��Center=�$��WrapWithOverflow=�$��0,0,0,5q�Normal�� -F   $ 	BMod_save��$
��Save��$��Center=�$��0,10,0,0q�$��72���� $��12(�$��Center=�$��WrapWithOverflow=�$��138,5,104,0q�$	��325���� $<�6The settings take effect immediately, even during game��  -G   $ 
Card_About��$��Bottom=�$��5,0,5,5q�$	��381��$��10q�$y�Hidden=�.���� $	��Top=�$��10q�.+��� #���  $��Center=�$��0,0,0,10q�$��18(�$	��Top=� �� Padding$ 0q�)'Isaac On Twitch v2.1 - Final Fix Update�� #���  $
��Left=�$��0q�$��16(�$	��Top=�	Mod links]� $��0,5,0,0q�.+��� -H   $ BLinks_modpage��$
��Left=�$��26��.��
Mod page�� -I   $ BLinks_github��$
��Left=�$��26��$��10,0,0,0q�.��GitHub�� -J   $ BLink_feedback��$
��Left=�$��26��$��10,0,0,0q�.��
Feedback]� $��0,15,0,0q�.+��� #���  $
��Left=�$��0q�$��16(�$	��Top=�Code:�� #���  $
��Left=�$��20,0,0,0q�$��16(�$	��Top=�Evstafiev Yury]� $��0,5,0,0q�.+��� -K   $ BLink_authorReddit��$
��Left=�$��26��.��Reddit�� -L   $ BLink_authorVk��$
��Left=�$��26��$��10,0,0,0q�.��Vk]� $��0,15,0,0q�.+��� #���  $
��Left=�$��0q�$��16(�$	��Top=�	Graphics:�� #���  $
��Left=�$��20,0,0,0q�$��16(�$	��Top=�Rogachev Dmitry]� $��0,5,0,0q�.+��� -M   $ BLink_artistVk��$
��Left=�$��26��$��0,0,0,0q�.��Vk
   M S B A M L   `   `   `  ���� I  ETwitсhToIsaac, Version=1.2.0.0, Culture=neutral, PublicKeyToken=null-clr-namespace:TwitchToIsaacTwitchToIsaac      TwitchToIsaac.Overlay   R NWindowsBase, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35\ XPresentationFramework, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35W SPresentationCore, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35D 9http://schemas.microsoft.com/winfx/2006/xaml/presentation    R NSystem.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     @d2http://schemas.microsoft.com/expression/blend/2008     Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006     -localclr-namespace:TwitchToIsaac     -     �Name$  OverlayWindow��$4��./TwitсhToIsaac;component/Resources/#BrushType)�$��38(� � Title$ Overlay��$	��250��#��� ��
��� � �$��Disabled=�$��0q� � WindowStyle$
 None=� J� OpacityMask
 � � �.��� .+�� -    �Name$
 Vote��$��0q�$y�Hidden=� � ColumnDefinitions �� �� ��  � RowDefinitions �� �� �� �� .+��� $��10q�$��3��$<��6pack://application:,,,/Resources/VotePaper_Vote-01.png���� -    ��Name$ 
vote1_name��$�� ��$
��Wrap=����	#FF111111$��3��$
��Left=�$��Center=�$
��Bold"�$��40,0,0,0q��� $��4q�$=��7pack://application:,,,/Resources/VotePaper_Procents.png��$��1��$��Right=�$��2���� -   $ vote1_percent��$�� ��$
��Wrap=����	#FF111111$��Right=�$��Center=�$
��Bold"�$��	0,0,45,10q�$��2��$��1���� $��10q�$��3��$<��6pack://application:,,,/Resources/VotePaper_Vote-02.png��$��1��$��1���� -   $ 
vote2_name��$�� ��$
��Wrap=����	#FF111111$��3��$
��Left=�$��Center=�$
��Bold"�$��40,0,0,0q�$��1��$��1���� $��4q�$=��7pack://application:,,,/Resources/VotePaper_Procents.png��$��2��$��Right=�$��2��$��1���� -   $ vote2_percent��$�� ��$
��Wrap=����	#FF111111$��Right=�$��Center=�$
��Bold"�$��	0,0,45,10q�$��2��$��2��$��1���� $��10,20,10,10q�$��3��$<��6pack://application:,,,/Resources/VotePaper_Vote-03.png��$��2���� -   $ 
vote3_name��$�� ��$
��Wrap=����	#FF111111$��3��$
��Left=�$��Center=�$
��Bold"�$��65,0,0,0q�$��2���� $��4q�$=��7pack://application:,,,/Resources/VotePaper_Procents.png��$��1��$��Right=�$��2��$��2���� -   $ vote3_percent��$�� ��$
��Wrap=����	#FF111111$��Right=�$��Center=�$
��Bold"�$��	0,0,45,10q�$��2��$��1��$��2���� $��10,10,10,15q�$:��4pack://application:,,,/Resources/VotePaper_Title.png��$��1��$��2���� -	   $ 
vote_title��$�� ��$
��Wrap=����	#FF111111$��2��$��Center=�$��Center=�$
��Bold"�$��0,0,0,20q�$��1���� $��4,4,4,50q�$/��)pack://application:,,,/Resources/Time.png��$��Right=�$��1��$��2���� -
   $ 	vote_time��$�� ��$
��Wrap=����	#FF111111$��2��$��Right=�$	��Top=�$
��Bold"�$��	0,10,30,0q�$��1��� -   $
 Wait�� �� �� ��  �� �� �� �� .+��� $��10q�$��4��$7��1pack://application:,,,/Resources/LoadPaper_01.png��$��3���� $��4q�$7��1pack://application:,,,/Resources/LoadPaper_02.png��$��2��$
��Left=�$��2��$��2���� -   $ 	wait_text��$��Press RUN and wait��$
��Wrap=����	#FF111111$��1��$��3��$��Center=�$��Center=�$
��Bold"��� -   $ 	wait_time��$��0s��$
��Wrap=����	#FF111111$��2��$��Center=�$��2��$��2��$��	35,0,0,10q�$
��Bold"�$
��Left=�� -   $ OverlayControl��$
��Left=�$	��Top=�$��Disabled=� �� �� ��  �� �� �� �� .+��� -    ��Name$ OverlayHeightUp��$��H+��$��Center=�$��Bottom=�$��0q�{�. $��47���� -   $ OverlayHeightDown��$��H-��$��Center=�$��Bottom=�$��0q�{�. $��1��$��47���� -   $ OverlayToLeft��$��<��$��Center=�$��Bottom=�$��0q�{�. $��1��$��47���� -   $ OverlayToRight��$��>��$��Center=�$��Bottom=�$��0q�{�. $��1��$��1��$��47���� -   $ OverlayToUp��$��^��$��Center=�$��Bottom=�$��0q�{�. $��2��$��47���� -   $ OverlayToDown��$��v��$��Center=�$��Bottom=�$��0q�{�. $��1��$��2��$��47���� -   $ OverlayWidthUp��$��W+��$��Center=�$��Bottom=�$��0q�{�. $��3��$��47���� -   $ OverlayWidthDown��$��W-��$��Center=�$��Bottom=�$��0q�{�. $��1��$��3��$��47���� -   $ 
FontSizeUp��$	��Aa+��$��Center=�$��Bottom=�$��0q�{�. $��2��$��56���� -   $ FontSizeDown��$	��Aa-��$��Center=�$��Bottom=�$��0q�{�. $��2��$��1��$��56���� -   $ 
FixOverlay��$	��Fix��$��Center=�$��Bottom=�$��0q�{�. $��2��$��2��$��56��$��2��
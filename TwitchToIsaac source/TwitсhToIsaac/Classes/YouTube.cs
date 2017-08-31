using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace TwitchToIsaac.Classes
{
    class YouTubeChat
    {
        private string apikey = "";
        public string videourl = "";
        public string channel = "";
        private string liveChatId = "";
        private Timer updateChat = null;
        private List<string> readedMsg = new List<string>();

        public event EventHandler<Data.SimpleMessage> NewMessage;

        public YouTubeChat (string apikey)
        {
            this.apikey = apikey;
        }

        public bool ConnectToChat (string videoUrl)
        {
            try
            {
                Uri u = new Uri(videoUrl);
                this.videourl = videoUrl;
                string videoId = System.Web.HttpUtility.ParseQueryString(u.Query)[0];
                WebClient w = new WebClient();
                string raw = w.DownloadString("https://www.googleapis.com/youtube/v3/videos?id=" + videoId + "&part=snippet,liveStreamingDetails&key=" + apikey);
                liveChatId = JsonConvert.DeserializeXmlNode(raw, "items").ChildNodes[0]["items"]["liveStreamingDetails"]["activeLiveChatId"].InnerText;
                channel = JsonConvert.DeserializeXmlNode(raw, "items").ChildNodes[0]["items"]["snippet"]["channelId"].InnerText;

                updateChat = new Timer((object state) => { ReadChat(); }, null, 0, 3000);

                return liveChatId == "" ? false : true;
            } catch { return false; }
        }

        private void ReadChat ()
        {
            WebClient w = new WebClient();
            string raw = w.DownloadString("https://www.googleapis.com/youtube/v3/liveChat/messages?liveChatId=" + liveChatId + "&part=snippet&key=" + apikey);
            Data.Response.MsgResponse res = JsonConvert.DeserializeObject<Data.Response.MsgResponse>(raw);

            foreach (Data.Response.Item i in res.items)
            {
                if (!readedMsg.Contains(i.id))
                {
                    readedMsg.Add(i.id);
                    Data.SimpleMessage ev = new Data.SimpleMessage();
                    ev.message = i.snippet.textMessageDetails.messageText;
                    ev.user = i.snippet.authorChannelId;
                    NewMessage(this, ev);
                }
            }
        }

        public class Data
        {
            public class SimpleMessage : EventArgs
            {
                public string user;
                public string message;
            }
            
            public class Response
            {
                public class PageInfo
                {
                    public int totalResults { get; set; }
                    public int resultsPerPage { get; set; }
                }

                public class TextMessageDetails
                {
                    public string messageText { get; set; }
                }

                public class Snippet
                {
                    public string type { get; set; }
                    public string liveChatId { get; set; }
                    public string authorChannelId { get; set; }
                    public string publishedAt { get; set; }
                    public bool hasDisplayContent { get; set; }
                    public string displayMessage { get; set; }
                    public TextMessageDetails textMessageDetails { get; set; }
                }

                public class Item
                {
                    public string kind { get; set; }
                    public string etag { get; set; }
                    public string id { get; set; }
                    public Snippet snippet { get; set; }
                }

                public class MsgResponse
                {
                    public string kind { get; set; }
                    public string etag { get; set; }
                    public string nextPageToken { get; set; }
                    public int pollingIntervalMillis { get; set; }
                    public PageInfo pageInfo { get; set; }
                    public List<Item> items { get; set; }
                }
            }
        }
    }
}

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json;
using TwitсhToIsaac.Classes.Events;

namespace TwitсhToIsaac.Classes
{
    static class IOLink
    {
        static Thread IsaacParamUpd = null;
        static Thread IsaacDataUpd = null;
        static Thread ProgramParamUpd = null;
        static Thread ProgramDataUpd = null;

        static string inputdatapath = "../data/input1.txt";
        static string inputparampath = "../data/input2.txt";
        static string outputdatapath = "../data/output1.txt";
        static string outputparampath = "../data/output2.txt";

        static bool IORun = true;

        //No more fuckn timers!
        //static System.Timers.Timer DataUpd = new System.Timers.Timer(333);
        //static System.Timers.Timer ParamUpd = new System.Timers.Timer(3000);
        
        static bool programParamChanged = true;

        static public IsaacData OutputData = new IsaacData();
        static public IsaacParam OutputParam = new IsaacParam();

        static public Act InputData = new ActionInfo("Now just press Run in TwitchToIsaac!");
        static public ProgramParam InputParam = new ProgramParam();



        static public void Start ()
        {
            if (isCorrectPath())
            {
                IsaacDataUpd = new Thread(UpdateOutputData);
                ProgramDataUpd = new Thread(UpdateInputData);

                IsaacParamUpd = new Thread(UpdateOutputParam);
                ProgramParamUpd = new Thread(UpdateInputParam);

                IsaacDataUpd.Priority = ThreadPriority.AboveNormal;
                ProgramDataUpd.Priority = ThreadPriority.AboveNormal;

                IsaacDataUpd.Start();
                ProgramDataUpd.Start();
                IsaacParamUpd.Start();
                ProgramParamUpd.Start();
            }
        }

        static public void Stop ()
        {
            IORun = false;
        }

        static public void acceptInputParam()
        {
            programParamChanged = true;
        }

        static private void DataUpd_Elapsed(object sender, System.Timers.ElapsedEventArgs e)
        {
            if (!(IsaacDataUpd != null && IsaacDataUpd.ThreadState == ThreadState.Running))
            {
                IsaacDataUpd = new Thread(UpdateOutputData);
                IsaacDataUpd.Start();
            }

            if (!(ProgramDataUpd != null && ProgramDataUpd.ThreadState == ThreadState.Running))
            {

                ProgramDataUpd = new Thread(UpdateInputData);
                ProgramDataUpd.Start();
            }
        }

        static private void ParamUpd_Elapsed(object sender, System.Timers.ElapsedEventArgs e)
        {
            if (!(IsaacParamUpd != null && IsaacParamUpd.ThreadState == ThreadState.Running))
            {

                IsaacParamUpd = new Thread(UpdateOutputParam);
                IsaacParamUpd.Start();
            }

            if (programParamChanged)
            {
                if (!(ProgramParamUpd != null && ProgramParamUpd.ThreadState == ThreadState.Running))
                {

                    ProgramParamUpd = new Thread(UpdateInputParam);
                    ProgramParamUpd.Start();

                    programParamChanged = false;
                }
            }
        }

        static private void UpdateOutputData ()
        {
            while (IORun)
            {
                try
                {
                    IsaacData d = JsonConvert.DeserializeObject<IsaacData>(File.ReadAllText(outputdatapath));

                    lock (OutputData)
                        OutputData = d;
                }
                catch
                {
                    ScreenStatus.addLog("IO Read error: Thread #1", ScreenStatus.logType.Error);
                }

                Thread.Sleep(450);
            }
        }

        static private void UpdateOutputParam()
        {
            while (IORun)
            {
                try
                {
                    IsaacParam p = JsonConvert.DeserializeObject<IsaacParam>(File.ReadAllText(outputparampath));

                    lock (OutputParam)
                        OutputParam = p;
                }
                catch
                {
                    ScreenStatus.addLog("IO Read error: Thread #2", ScreenStatus.logType.Error);
                }

                Thread.Sleep(2600);
            }
        }

        static private void UpdateInputData()
        {
            while (IORun)
            {
                try
                {
                    string d;

                    lock (InputData)
                    {
                        d = JsonConvert.SerializeObject(InputData);
                    }
                    File.WriteAllText(inputdatapath, d);

                }
                catch
                {
                    ScreenStatus.addLog("IO Write error: Thread #1", ScreenStatus.logType.Error);
                }
                Thread.Sleep(465);
            }
        }

        static private void UpdateInputParam()
        {
            while (IORun)
            {
                try
                {
                    string p;

                    lock (InputParam)
                    {
                        p = JsonConvert.SerializeObject(InputParam);
                    }
                    File.WriteAllText(inputparampath, p);
                }
                catch
                {
                    ScreenStatus.addLog("IO Write error: Thread #2", ScreenStatus.logType.Error);
                }
                Thread.Sleep(2675);
            }
        }

        public static bool isCorrectPath ()
        {
            return File.Exists(inputdatapath) && File.Exists(inputparampath)
                && File.Exists(outputdatapath) && File.Exists(outputparampath);
        }
    }
}

/*
	Sample quest file for Casual Pixel Warrior
*/

class CSampleQuest : IQuestEntity {
    datetime m_dtStart;
    datetime m_dtEnd;
    SoundHandle m_hRedeem;

    CSampleQuest()
    {
        this.m_dtStart = datetime(2023, 7, 5, 5, 0, 0);
        this.m_dtEnd = datetime(2023, 7, 5, 22, 0, 0);
    }

    bool Init()
    {
        CVar_Register("sample_quest_completed", CVAR_TYPE_BOOL, "0");
        CVar_Register("sample_quest_redeemed", CVAR_TYPE_BOOL, "0");

        if (!Util_FileExists("game\\props\\sample_quest.props")) {
            FileWriter fw;
            fw.Open("game\\props\\sample_quest.props");
            fw.WriteLine("completed:0");
            fw.WriteLine("redeemed:0");

            fw.Close();
        }

        string props = Props_GetFromFile("sample_quest.props");
	    int completed = parseInt(Props_ExtractValue(props, "completed"));
        int redeemed = parseInt(Props_ExtractValue(props, "redeemed"));

        CVar_SetBool("sample_quest_completed", completed > 0);
        CVar_SetBool("sample_quest_redeemed", redeemed > 0);

        this.m_hRedeem = S_QuerySound(GetPackagePath() + "sound\\redeem.wav");

        return true;
    }

    void Unload()
    {
        int completed = (CVar_GetBool("sample_quest_completed", false)) ? 1 : 0;
        int redeemed = (CVar_GetBool("sample_quest_redeemed", false)) ? 1 : 0;

        Props_SaveToFile("completed:" + formatInt(completed) + ";" +
                        "redeemed:" + formatInt(redeemed) + ";"
		, "sample_quest.props", true);
    }

    void Process()
    {
        if (GetCurrentMap() == "basis.cfg") {
            return;
        }

        if (!CVar_GetBool("sample_quest_completed", false)) {
            if (CVar_GetInt("player_coins", 0) >= 50) {
                CVar_SetBool("sample_quest_completed", true);
                HUD_AddMessage("Quest 1 done!", HUD_MSG_COLOR_BLUE);
            }
        }
    }
	
	void Draw()
	{
	}
	
	void DrawOnTop()
	{
	}

    void Redeem()
    {
        if (CVar_GetBool("sample_quest_completed", false)) {
            if (!CVar_GetBool("sample_quest_redeemed", false)) {
                CVar_SetBool("sample_quest_redeemed", true);
                HUD_UpdateCollectable("coins", HUD_GetCollectableCount("coins") + 100);
                HUD_AddMessage("You have successfully completed Sample Quest", HUD_MSG_COLOR_BLUE);
                S_PlaySound(this.m_hRedeem, S_GetCurrentVolume());
            }
        }
    }

    datetime& GetStartDate()
    {
        return this.m_dtStart;
    }

    datetime& GetEndDate()
    {
        return this.m_dtEnd;
    }

    bool IsRunning()
    {
        datetime now = datetime();
        if ((now < this.m_dtStart) || (this.m_dtEnd < now)) {
            return false;
        }

        return true;
    }

    string GetName()
    {
        return "Sample Quest";
    }

    string GetDescription()
    {
        return "Collect 50 coins! Get additional 100!";
    }

    string GetFileName()
    {
        return "sample_quest.as";
    }

    bool IsCompleted()
    {
        return CVar_GetBool("sample_quest_completed", false);
    }

    bool IsRedeemed()
    {
        return CVar_GetBool("sample_quest_redeemed", false);
    }
}

void CreateEntity()
{
    CSampleQuest @ent = CSampleQuest();
    SpawnQuestEntity(ent.GetFileName(), @ent);
}
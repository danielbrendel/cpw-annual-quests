//Casual Pixel Warrior - Christmas Quest

const string QUEST_NAME = "Christmas Time";
const string QUEST_DESCRIPTION = "Get your presents on christmas!";
const string QUEST_FILE = "christmas.as";
const string QUEST_PROPS = "christmas.props";
const string QUEST_SETTING = "christmas_quest_completed";
const string QUEST_REDEEMED = "christmas_quest_redeemed";
const int QUEST_REDEEM_DAY = 24;

class CSnowFlake {
	Vector m_vecPos;
	Vector m_vecSize;
	Timer m_tmrMove;
	bool m_bCompleted;

	CSnowFlake()
	{
		this.m_vecPos = Vector(Util_Random(-100, Wnd_GetWindowCenterX() * 2), -10);
		this.m_vecSize = Vector(2, 2);
		
		this.m_tmrMove.SetDelay(10);
		this.m_tmrMove.Reset();
		this.m_tmrMove.SetActive(true);
		
		this.m_bCompleted = false;
	}
	
	void Process()
	{
		this.m_tmrMove.Update();
		if (this.m_tmrMove.IsElapsed()) {
			this.m_tmrMove.Reset();
			
			this.m_vecPos[0] += 1;
			this.m_vecPos[1] += 2;
			
			if (this.m_vecPos[1] > Wnd_GetWindowCenterY() * 2) {
				this.m_tmrMove.SetActive(false);
				this.m_bCompleted = true;
			}
		}
	}
	
	void Draw()
	{
		R_DrawFilledBox(this.m_vecPos, this.m_vecSize, Color(255, 255, 255, 255));
	}
	
	bool Completed()
	{
		return this.m_bCompleted;
	}
}

class CChristmasQuest : IQuestEntity {
    datetime m_dtStart;
    datetime m_dtEnd;
	datetime m_dtNow;
    SoundHandle m_hRedeem;
	Timer m_tmrSpawnSnowFlake;
	array<CSnowFlake> m_arrSnowFlakes;
	SpriteHandle m_hChristmasTree;
	int m_iFrameCount;
	Timer m_tmrFrameCount;
	Vector m_vecTreePos;
	Vector m_vecTreeSize;
	SpriteHandle m_hChristmasPresent1;
	SpriteHandle m_hChristmasPresent2;
	SpriteHandle m_hChristmasPresent3;
	SpriteHandle m_hChristmasPresent4;
	Vector m_vecPresent1;
	Vector m_vecPresent2;
	Vector m_vecPresent3;
	Vector m_vecPresent4;

    CChristmasQuest()
    {
		this.m_dtNow = datetime();
	
        this.m_dtStart = datetime(this.m_dtNow.get_year(), 12, 1, 2, 0, 0);
        this.m_dtEnd = datetime(this.m_dtNow.get_year(), 12, 31, 22, 0, 0);
		
		this.m_tmrSpawnSnowFlake.SetDelay(100);
		this.m_tmrSpawnSnowFlake.Reset();
		this.m_tmrSpawnSnowFlake.SetActive(true);
		
		this.m_iFrameCount = 0;
		
		this.m_tmrFrameCount.SetDelay(100);
		this.m_tmrFrameCount.Reset();
		this.m_tmrFrameCount.SetActive(true);
		
		this.m_vecTreePos = Vector(650, 150);
		this.m_vecTreeSize = Vector(96, 182);
		
		this.m_vecPresent1 = Vector(590, 150);
		this.m_vecPresent2 = Vector(610, 190);
		this.m_vecPresent3 = Vector(710, 150);
		this.m_vecPresent4 = Vector(680, 190);
    }

    bool Init()
    {
        CVar_Register(QUEST_SETTING, CVAR_TYPE_BOOL, "0");
        CVar_Register(QUEST_REDEEMED, CVAR_TYPE_BOOL, "0");

        if (!Util_FileExists("game\\props\\" + QUEST_PROPS)) {
            FileWriter fw;
            fw.Open("game\\props\\" + QUEST_PROPS);
            fw.WriteLine("completed_" + formatInt(this.m_dtNow.get_year()) + ":0");
            fw.WriteLine("redeemed_" + formatInt(this.m_dtNow.get_year()) + ":0");

            fw.Close();
        }

        string props = Props_GetFromFile(QUEST_PROPS);
	    int completed = parseInt(Props_ExtractValue(props, "completed_" + formatInt(this.m_dtNow.get_year())));
        int redeemed = parseInt(Props_ExtractValue(props, "redeemed_" + formatInt(this.m_dtNow.get_year())));

        CVar_SetBool(QUEST_SETTING, completed > 0);
        CVar_SetBool(QUEST_REDEEMED, redeemed > 0);
		
		this.m_hChristmasTree = R_LoadSprite(GetPackagePath() + "gfx\\xmas-tree.png", 2, this.m_vecTreeSize[0], this.m_vecTreeSize[1], 2, false);

		this.m_hChristmasPresent1 = R_LoadSprite(GetPackagePath() + "gfx\\xmas-presents.png", 12, 32, 32, 6, false);
		this.m_hChristmasPresent2 = R_LoadSprite(GetPackagePath() + "gfx\\xmas-presents.png", 12, 32, 32, 6, false);
		this.m_hChristmasPresent3 = R_LoadSprite(GetPackagePath() + "gfx\\xmas-presents.png", 12, 32, 32, 6, false);
		this.m_hChristmasPresent4 = R_LoadSprite(GetPackagePath() + "gfx\\xmas-presents.png", 12, 32, 32, 6, false);

        this.m_hRedeem = S_QuerySound(GetPackagePath() + "sound\\redeem.wav");

        return true;
    }

    void Unload()
    {
        int completed = (CVar_GetBool(QUEST_SETTING, false)) ? 1 : 0;
        int redeemed = (CVar_GetBool(QUEST_REDEEMED, false)) ? 1 : 0;

        Props_SaveToFile("completed_" + formatInt(this.m_dtNow.get_year()) + ":" + formatInt(completed) + ";" +
                        "redeemed_" + formatInt(this.m_dtNow.get_year()) + ":" + formatInt(redeemed) + ";"
		, QUEST_PROPS, true);
    }

    void Process()
    {
        if (GetCurrentMap() != "basis.cfg") {
            return;
        }
		
		this.m_tmrFrameCount.Update();
		if (this.m_tmrFrameCount.IsElapsed()) {
			this.m_tmrFrameCount.Reset();
			
			this.m_iFrameCount++;
			if (this.m_iFrameCount >= 2) {
				this.m_iFrameCount = 0;
			}
		}
		
		this.m_tmrSpawnSnowFlake.Update();
		if (this.m_tmrSpawnSnowFlake.IsElapsed()) {
			this.m_tmrSpawnSnowFlake.Reset();
			
			CSnowFlake @snowFlake = CSnowFlake();
			this.m_arrSnowFlakes.insertLast(snowFlake);
		}
		
		for (int i = 0; i < this.m_arrSnowFlakes.length(); i++) {
			if (!this.m_arrSnowFlakes[i].Completed()) {
				this.m_arrSnowFlakes[i].Process();
			} else {
				this.m_arrSnowFlakes.removeAt(i);
				continue;
			}
		}
		
        if ((!CVar_GetBool(QUEST_SETTING, false)) && (this.m_dtNow.get_day() >= QUEST_REDEEM_DAY)) {
			CVar_SetBool(QUEST_SETTING, true);
			HUD_AddMessage("Get your christmas present!", HUD_MSG_COLOR_BLUE);
        }
    }
	
	void Draw()
	{
		Vector vTreeOut;
		Vector vPresentOut;
		
		R_GetDrawingPosition(this.m_vecTreePos, this.m_vecTreeSize, vTreeOut);
		R_DrawSprite(this.m_hChristmasTree, vTreeOut, this.m_iFrameCount, 0.0, Vector(-1, -1), 1.0, 1.0, false, Color(0, 0, 0, 0));
	
		R_GetDrawingPosition(this.m_vecPresent1, Vector(32, 32), vPresentOut);
		R_DrawSprite(this.m_hChristmasPresent1, vPresentOut, 0, -0.5, Vector(-1, -1), 1.0, 1.0, false, Color(0, 0, 0, 0));
		
		R_GetDrawingPosition(this.m_vecPresent2, Vector(32, 32), vPresentOut);
		R_DrawSprite(this.m_hChristmasPresent2, vPresentOut, 1, 0.0, Vector(-1, -1), 1.0, 1.0, false, Color(0, 0, 0, 0));
		
		R_GetDrawingPosition(this.m_vecPresent3, Vector(32, 32), vPresentOut);
		R_DrawSprite(this.m_hChristmasPresent3, vPresentOut, 2, 0.0, Vector(-1, -1), 1.0, 1.0, false, Color(0, 0, 0, 0));
		
		R_GetDrawingPosition(this.m_vecPresent4, Vector(32, 32), vPresentOut);
		R_DrawSprite(this.m_hChristmasPresent4, vPresentOut, 3, 0.0, Vector(-1, -1), 1.0, 1.0, false, Color(0, 0, 0, 0));
	}
	
	void DrawOnTop()
	{
		for (int i = 0; i < this.m_arrSnowFlakes.length(); i++) {
			if (!this.m_arrSnowFlakes[i].Completed()) {
				this.m_arrSnowFlakes[i].Draw();
			}
		}
	}

    void Redeem()
    {
        if (CVar_GetBool(QUEST_SETTING, false)) {
            if (!CVar_GetBool(QUEST_REDEEMED, false)) {
                CVar_SetBool(QUEST_REDEEMED, true);
                HUD_UpdateCollectable("gems", HUD_GetCollectableCount("gems") + 15);
                HUD_AddMessage("Merry christmas and a happy new year!", HUD_MSG_COLOR_BLUE);
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
        if ((this.m_dtNow < this.m_dtStart) || (this.m_dtEnd < this.m_dtNow)) {
            return false;
        }

        return true;
    }

    string GetName()
    {
        return QUEST_NAME;
    }

    string GetDescription()
    {
        return QUEST_DESCRIPTION;
    }

    string GetFileName()
    {
        return QUEST_FILE;
    }

    bool IsCompleted()
    {
        return CVar_GetBool(QUEST_SETTING, false);
    }

    bool IsRedeemed()
    {
        return CVar_GetBool(QUEST_REDEEMED, false);
    }
}

void CreateEntity()
{
    CChristmasQuest @quest = CChristmasQuest();
    SpawnQuestEntity(quest.GetFileName(), @quest);
}
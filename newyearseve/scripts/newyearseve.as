//Casual Pixel Warrior - New Years Eve Quest

const string QUEST_NAME = "New Years Eve";
const string QUEST_DESCRIPTION = "Get your New Years Eve presents!";
const string QUEST_FILE = "newyearseve.as";
const string QUEST_PROPS = "newyearseve.props";
const string QUEST_SETTING = "newyearseve_quest_completed";
const string QUEST_REDEEMED = "newyearseve_quest_redeemed";

class CFireworksExplosion {
	Vector m_vecPos;
	Vector m_vecSize;
	SpriteHandle m_hSpriteSheet;
	int m_iSpriteIndex;
	Timer m_tmrExplosion;
	
	CFireworksExplosion()
    {
		this.m_iSpriteIndex = 0;
		this.m_vecSize = Vector(256, 256);
    }
	
	void Init()
	{
		this.m_hSpriteSheet = R_LoadSprite(GetPackagePath() + "gfx\\fireworks_spritesheet.png", 30, this.m_vecSize[0], this.m_vecSize[1], 6, false);
		
		this.m_tmrExplosion.SetDelay(10);
		this.m_tmrExplosion.Reset();
		this.m_tmrExplosion.SetActive(false);
	}
	
	void Start()
	{
		this.m_iSpriteIndex = 0;
		
		this.m_tmrExplosion.Reset();
		this.m_tmrExplosion.SetActive(true);
		
		int iSoundRandNum = Util_Random(1, 4);
		SoundHandle hSndExplosion = S_QuerySound(GetPackagePath() + "sound\\fireworks0" + formatInt(iSoundRandNum) + ".wav");
		S_PlaySound(hSndExplosion, S_GetCurrentVolume());
	}
	
	void Process()
	{
		if (this.m_tmrExplosion.IsActive()) {
			this.m_tmrExplosion.Update();
			if (this.m_tmrExplosion.IsElapsed()) {
				this.m_tmrExplosion.Reset();
				
				this.m_iSpriteIndex++;
				if (this.m_iSpriteIndex >= 30) {
					this.m_tmrExplosion.SetActive(false);
				}
			}
		}
	}
	
	void Draw()
	{
		Vector vecPosOut;
		
		R_GetDrawingPosition(this.m_vecPos, this.m_vecSize, vecPosOut);
		R_DrawSprite(this.m_hSpriteSheet, vecPosOut, this.m_iSpriteIndex, 0.0, Vector(-1, -1), 1.5, 1.5, false, Color(0, 0, 0, 0));
	}
	
	void SetPosition(const Vector &in pos)
	{
		this.m_vecPos = pos;
	}
}

class CNewYearsEveQuest : IQuestEntity {
    datetime m_dtStart;
    datetime m_dtEnd;
	datetime m_dtNow;
    SoundHandle m_hRedeem;
	Timer m_tmrFireworks;
	array<Vector> m_arrPositions;
	CFireworksExplosion m_oFireworkExplosion;
	SpriteHandle m_hHappyNewYearText;
	Vector m_vecTextPos;
	Vector m_vecTextSize;

    CNewYearsEveQuest()
    {
		this.m_dtNow = datetime();
	
        this.m_dtStart = datetime(this.m_dtNow.get_year(), 12, 31, 2, 0, 0);
        this.m_dtEnd = datetime(this.m_dtNow.get_year() + 1, 1, 1, 22, 0, 0);
		
		this.m_tmrFireworks.SetDelay(2000);
		this.m_tmrFireworks.Reset();
		this.m_tmrFireworks.SetActive(true);
		
		this.m_arrPositions.insertLast(Vector(-154, -50));
		this.m_arrPositions.insertLast(Vector(-164, -215));
		this.m_arrPositions.insertLast(Vector(193, -109));
		this.m_arrPositions.insertLast(Vector(397, -103));
		this.m_arrPositions.insertLast(Vector(756, -104));
		this.m_arrPositions.insertLast(Vector(1023, -155));
		this.m_arrPositions.insertLast(Vector(1334, -79));
		this.m_arrPositions.insertLast(Vector(1445, -152));
		this.m_arrPositions.insertLast(Vector(1501, -95));
		this.m_arrPositions.insertLast(Vector(685, -10));
		
		this.m_oFireworkExplosion = CFireworksExplosion();
		
		this.m_vecTextPos = Vector(650, -200);
		this.m_vecTextSize = Vector(750, 250);
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
		
		this.m_hHappyNewYearText = R_LoadSprite(GetPackagePath() + "gfx\\happnewyear_text.png", 1, this.m_vecTextSize[0], this.m_vecTextSize[1], 1, false);
		
		this.m_oFireworkExplosion.Init();
		
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
		
		if (this.m_tmrFireworks.IsActive()) {
			this.m_tmrFireworks.Update();
			if (this.m_tmrFireworks.IsElapsed()) {
				this.m_tmrFireworks.Reset();
				
				int iRandIndex = Util_Random(1, this.m_arrPositions.length());
				this.m_oFireworkExplosion.SetPosition(this.m_arrPositions[iRandIndex - 1]);
				this.m_oFireworkExplosion.Start();
			}
		}
		
		this.m_oFireworkExplosion.Process();
		
        if ((!CVar_GetBool(QUEST_SETTING, false)) && ((this.m_dtNow.get_day() == 31) || (this.m_dtNow.get_day() == 1))) {
			CVar_SetBool(QUEST_SETTING, true);
			HUD_AddMessage("Get your New Years Eve presents!", HUD_MSG_COLOR_BLUE);
        }
    }
	
	void Draw()
	{
	}
	
	void DrawOnTop()
	{
		Vector vecTextPos;
		R_GetDrawingPosition(this.m_vecTextPos, this.m_vecTextSize, vecTextPos);
		R_DrawSprite(this.m_hHappyNewYearText, vecTextPos, 0, 0.0, Vector(-1, -1), 1.5, 1.5, false, Color(0, 0, 0, 0));
		
		this.m_oFireworkExplosion.Draw();
	}

    void Redeem()
    {
        if (CVar_GetBool(QUEST_SETTING, false)) {
            if (!CVar_GetBool(QUEST_REDEEMED, false)) {
                CVar_SetBool(QUEST_REDEEMED, true);
                HUD_UpdateCollectable("coins", HUD_GetCollectableCount("coins") + 200);
				HUD_UpdateCollectable("gems", HUD_GetCollectableCount("gems") + 30);
                HUD_AddMessage(">> !! Happy New Year !! <<", HUD_MSG_COLOR_BLUE);
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
    CNewYearsEveQuest @quest = CNewYearsEveQuest();
    SpawnQuestEntity(quest.GetFileName(), @quest);
}
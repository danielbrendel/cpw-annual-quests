//Casual Pixel Warrior - Halloween Quest

#include "poop.as"

const string QUEST_NAME = "Halloween Time";
const string QUEST_DESCRIPTION = "Collect your spooky presents!";
const string QUEST_FILE = "halloween.as";
const string QUEST_PROPS = "halloween.props";
const string QUEST_SETTING = "halloween_quest_completed";
const string QUEST_REDEEMED = "halloween_quest_redeemed";
const int QUEST_REDEEM_DAY = 31;

class CHalloweenQuest : IQuestEntity {
    datetime m_dtStart;
    datetime m_dtEnd;
	datetime m_dtNow;
    SoundHandle m_hRedeem;
	SpriteHandle m_hPumpkin1;
	SpriteHandle m_hPumpkin2;
	SpriteHandle m_hPumpkin3;
	SpriteHandle m_hPumpkin4;
	SpriteHandle m_hPumpkin5;
	SpriteHandle m_hPumpkin6;
	Vector m_vecPumpkin1;
	Vector m_vecPumpkin2;
	Vector m_vecPumpkin3;
	Vector m_vecPumpkin4;
	Vector m_vecPumpkin5;
	Vector m_vecPumpkin6;
	SpriteHandle m_hGhost;
	int m_iFrameIndex;
	Timer m_tmrAnimGhost;
	Vector m_vecGhostPos;
	Timer m_tmrSpawnGhost;
	Timer m_tmrMoveGhost;
	Timer m_tmrStrafeGhost;
	Timer m_tmrSpawnCoin;
	bool m_bShiftDir;
	SoundHandle m_hGhostSpawn;
	SoundHandle m_hPoop;

    CHalloweenQuest()
    {
		this.m_dtNow = datetime();
	
        this.m_dtStart = datetime(this.m_dtNow.get_year(), 10, 1, 2, 0, 0);
        this.m_dtEnd = datetime(this.m_dtNow.get_year(), 10, 31, 22, 0, 0);
		
		this.m_vecPumpkin1 = Vector(89, 135);
		this.m_vecPumpkin2 = Vector(255, 590);
		this.m_vecPumpkin3 = Vector(625, 170);
		this.m_vecPumpkin4 = Vector(1155, 484);
		this.m_vecPumpkin5 = Vector(1186, 212);
		this.m_vecPumpkin6 = Vector(990, 99);
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
		
		this.m_hPumpkin1 = R_LoadSprite(GetPackagePath() + "gfx\\pumpkin_blue.png", 1, 448, 384, 1, false);
		this.m_hPumpkin2 = R_LoadSprite(GetPackagePath() + "gfx\\pumpkin_green.png", 1, 458, 384, 1, false);
		this.m_hPumpkin3 = R_LoadSprite(GetPackagePath() + "gfx\\pumpkin_orange.png", 1, 422, 422, 1, false);
		this.m_hPumpkin4 = R_LoadSprite(GetPackagePath() + "gfx\\pumpkin_purple.png", 1, 444, 424, 1, false);
		this.m_hPumpkin5 = R_LoadSprite(GetPackagePath() + "gfx\\pumpkin_striped.png", 1, 422, 380, 1, false);
		this.m_hPumpkin6 = R_LoadSprite(GetPackagePath() + "gfx\\pumpkin_white.png", 1, 481, 405, 1, false);
		
		this.m_hGhost = R_LoadSprite(GetPackagePath() + "gfx\\ghost_anim.png", 10, 150, 150, 5, false);
		this.m_iFrameIndex = 0;
		this.m_bShiftDir = false;
		this.m_tmrAnimGhost.SetDelay(100);
		this.m_tmrAnimGhost.Reset();
		this.m_tmrAnimGhost.SetActive(true);
		this.m_vecGhostPos = Vector(Util_Random(100, 1230), -200);
		this.m_tmrSpawnGhost.SetDelay(Util_Random(2000, 10000));
		this.m_tmrSpawnGhost.Reset();
		this.m_tmrSpawnGhost.SetActive(true);
		this.m_tmrMoveGhost.SetDelay(10);
		this.m_tmrMoveGhost.Reset();
		this.m_tmrMoveGhost.SetActive(false);
		this.m_tmrStrafeGhost.SetDelay(2500);
		this.m_tmrStrafeGhost.Reset();
		this.m_tmrStrafeGhost.SetActive(false);
		this.m_tmrSpawnCoin.SetDelay(1500);
		this.m_tmrSpawnCoin.Reset();
		this.m_tmrSpawnCoin.SetActive(false);

		this.m_hGhostSpawn = S_QuerySound(GetPackagePath() + "sound\\ghost_spawn.wav");
		this.m_hPoop = S_QuerySound(GetPackagePath() + "sound\\ghost_poop.wav");
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
		
		if (this.m_tmrSpawnGhost.IsActive()) {
			this.m_tmrSpawnGhost.Update();
			if (this.m_tmrSpawnGhost.IsElapsed()) {
				this.m_tmrMoveGhost.Reset();
				this.m_tmrMoveGhost.SetActive(true);
				this.m_tmrStrafeGhost.Reset();
				this.m_tmrStrafeGhost.SetActive(true);
				this.m_tmrSpawnCoin.Reset();
				this.m_tmrSpawnCoin.SetActive(true);
				
				S_PlaySound(this.m_hGhostSpawn, S_GetCurrentVolume());
				
				this.m_tmrSpawnGhost.SetActive(false);
			}
		}
		
		if (this.m_tmrMoveGhost.IsActive()) {
			this.m_tmrMoveGhost.Update();
			if (this.m_tmrMoveGhost.IsElapsed()) {
				this.m_tmrMoveGhost.Reset();
				
				if (!this.m_bShiftDir) {
					this.m_vecGhostPos[0] += 2;
				} else {
					this.m_vecGhostPos[0] -= 2;
				}
				
				this.m_vecGhostPos[1] += 2;
				if (this.m_vecGhostPos[1] > 1500) {
					this.m_tmrMoveGhost.SetActive(false);
					this.m_tmrStrafeGhost.SetActive(false);
					this.m_tmrAnimGhost.SetActive(false);
				}
			}
		}
		
		if (this.m_tmrStrafeGhost.IsActive()) {
			this.m_tmrStrafeGhost.Update();
			if (this.m_tmrStrafeGhost.IsElapsed()) {
				this.m_tmrStrafeGhost.Reset();
				
				this.m_bShiftDir = !this.m_bShiftDir;
			}
		}
		
		if (this.m_tmrAnimGhost.IsActive()) {
			this.m_tmrAnimGhost.Update();
			if (this.m_tmrAnimGhost.IsElapsed()) {
				this.m_tmrAnimGhost.Reset();
				
				this.m_iFrameIndex++;
				if (this.m_iFrameIndex >= 10) {
					this.m_iFrameIndex = 0;
				}
			}
		}
		
		if (this.m_tmrSpawnCoin.IsActive()) {
			this.m_tmrSpawnCoin.Update();
			if (this.m_tmrSpawnCoin.IsElapsed()) {
				this.m_tmrSpawnCoin.Reset();
				
				if ((this.m_vecGhostPos[1] > 90) && (this.m_vecGhostPos[1] < 600)) {
					for (int i = 0; i < 5; i++) {
						CPoopEntity @poop = CPoopEntity();
						poop.SetRandomPos(true);
						Ent_SpawnEntity("poop", @poop, this.m_vecGhostPos);
					}
					
					S_PlaySound(this.m_hPoop, S_GetCurrentVolume());
				}
			}
		}
		
        if ((!CVar_GetBool(QUEST_SETTING, false)) && (this.m_dtNow.get_day() >= QUEST_REDEEM_DAY)) {
			CVar_SetBool(QUEST_SETTING, true);
			HUD_AddMessage("Get your spooky halloween present!", HUD_MSG_COLOR_BLUE);
        }
    }
	
	void Draw()
	{
		Vector vPumpkinOut;
		
		R_GetDrawingPosition(this.m_vecPumpkin1, Vector(448, 384), vPumpkinOut);
		R_DrawSprite(this.m_hPumpkin1, vPumpkinOut, 0, 0.0, Vector(-1, -1), 0.1, 0.1, false, Color(0, 0, 0, 0));
		
		R_GetDrawingPosition(this.m_vecPumpkin2, Vector(458, 384), vPumpkinOut);
		R_DrawSprite(this.m_hPumpkin2, vPumpkinOut, 0, 0.0, Vector(-1, -1), 0.1, 0.1, false, Color(0, 0, 0, 0));
		
		R_GetDrawingPosition(this.m_vecPumpkin3, Vector(422, 422), vPumpkinOut);
		R_DrawSprite(this.m_hPumpkin3, vPumpkinOut, 0, 0.0, Vector(-1, -1), 0.1, 0.1, false, Color(0, 0, 0, 0));
		
		R_GetDrawingPosition(this.m_vecPumpkin4, Vector(444, 424), vPumpkinOut);
		R_DrawSprite(this.m_hPumpkin4, vPumpkinOut, 0, 0.0, Vector(-1, -1), 0.1, 0.1, false, Color(0, 0, 0, 0));
		
		R_GetDrawingPosition(this.m_vecPumpkin5, Vector(422, 380), vPumpkinOut);
		R_DrawSprite(this.m_hPumpkin5, vPumpkinOut, 0, 0.0, Vector(-1, -1), 0.1, 0.1, false, Color(0, 0, 0, 0));
		
		R_GetDrawingPosition(this.m_vecPumpkin6, Vector(481, 405), vPumpkinOut);
		R_DrawSprite(this.m_hPumpkin6, vPumpkinOut, 0, 0.0, Vector(-1, -1), 0.1, 0.1, false, Color(0, 0, 0, 0));
	}
	
	void DrawOnTop()
	{
		if (!this.m_tmrMoveGhost.IsActive()) {
			return;
		}
	
		Vector vGhostPosOut;
		
		R_GetDrawingPosition(this.m_vecGhostPos, Vector(150, 150), vGhostPosOut);
		R_DrawSprite(this.m_hGhost, vGhostPosOut, this.m_iFrameIndex, 0.0, Vector(-1, -1), 0.5, 0.5, false, Color(0, 0, 0, 0));
	}

    void Redeem()
    {
        if (CVar_GetBool(QUEST_SETTING, false)) {
            if (!CVar_GetBool(QUEST_REDEEMED, false)) {
                CVar_SetBool(QUEST_REDEEMED, true);
                HUD_UpdateCollectable("gems", HUD_GetCollectableCount("gems") + 10);
                HUD_AddMessage("Booo! Happy Halloween!", HUD_MSG_COLOR_BLUE);
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
    CHalloweenQuest @quest = CHalloweenQuest();
    SpawnQuestEntity(quest.GetFileName(), @quest);
}
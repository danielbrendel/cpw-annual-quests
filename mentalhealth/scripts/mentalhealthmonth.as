//Casual Pixel Warrior - Mental Health Month Quest

const string QUEST_NAME = "Mental Health Month";
const string QUEST_DESCRIPTION = "Mental Health Awareness Quest";
const string QUEST_FILE = "mentalhealthmonth.as";
const string QUEST_PROPS = "mentalhealthmonth.props";
const string QUEST_SETTING = "mentalhealthmonth_quest_completed";
const string QUEST_REDEEMED = "mentalhealthmonth_quest_redeemed";
const int QUEST_REDEEM_DATE = 25;
const int QUEST_HEART_TIMER_MIN = 15000;
const int QUEST_HEART_TIMER_MAX = 20000;

const int ITEM_HEALTH_ADDITION = 25;
class CHeartItem : IScriptedEntity
{
	Vector m_vecPos;
	Vector m_vecSize;
	Model m_oModel;
	SpriteHandle m_hSprite;
	array<SpriteHandle> m_arrHeart;
	int m_iSpriteIndex;
	Timer m_tmrSpriteSwitch;
	SoundHandle m_hReceive;
	SoundHandle m_hActivate;
	array<Color> m_arrRandomColors;
	int m_iColorSelection;
	bool m_bRemoval;
	
	CHeartItem()
    {
		this.m_vecSize = Vector(32, 32);
		this.m_iSpriteIndex = 0;
		this.m_bRemoval = false;
		
		this.m_arrRandomColors.insertLast(Color(0, 255, 255, 255));
		this.m_arrRandomColors.insertLast(Color(0, 0, 255, 255));
		this.m_arrRandomColors.insertLast(Color(0, 255, 0, 255));
		this.m_arrRandomColors.insertLast(Color(255, 0, 255, 255));
		
		this.m_iColorSelection = Util_Random(0, this.m_arrRandomColors.length());
    }
	
	//Called when the entity gets spawned. The position in the map is passed as argument
	void OnSpawn(const Vector& in vec)
	{
		this.m_vecPos = vec;
		this.m_hSprite = R_LoadSprite(GetPackagePath() + "gfx\\health\\frame-1.png", 1, this.m_vecSize[0], this.m_vecSize[1], 1, true);
		for (int i = 1; i < 9; i++) {
			this.m_arrHeart.insertLast(R_LoadSprite(GetPackagePath() + "gfx\\health\\frame-" + formatInt(i) + ".png", 1, this.m_vecSize[0], this.m_vecSize[1], 1, true));
		}
		this.m_hReceive = S_QuerySound(GetPackagePath() + "sound\\health_pickup.wav");
		this.m_hActivate = S_QuerySound(GetPackagePath() + "sound\\health_activate.wav");
		this.m_tmrSpriteSwitch.SetDelay(100);
		this.m_tmrSpriteSwitch.Reset();
		this.m_tmrSpriteSwitch.SetActive(true);
		BoundingBox bbox;
		bbox.Alloc();
		bbox.AddBBoxItem(Vector(0, 0), this.m_vecSize);
		this.m_oModel.Alloc();
		this.m_oModel.Initialize2(bbox, this.m_hSprite);
	}
	
	//Called when the entity gets released
	void OnRelease()
	{
	}
	
	//Process entity stuff
	void OnProcess()
	{
		//Process sprite switching
		this.m_tmrSpriteSwitch.Update();
		if (this.m_tmrSpriteSwitch.IsElapsed()) {
			this.m_tmrSpriteSwitch.Reset();
			
			this.m_iSpriteIndex++;
			if (this.m_iSpriteIndex >= 8) {
				this.m_iSpriteIndex = 0;
			}
		}
	}
	
	//Entity can draw everything in default order here
	void OnDraw()
	{
		if (!R_ShouldDraw(this.m_vecPos, this.m_vecSize))
			return;
			
		Vector vOut;
		R_GetDrawingPosition(this.m_vecPos, this.m_vecSize, vOut);
	
		R_DrawSprite(this.m_arrHeart[this.m_iSpriteIndex], vOut, 0, 0.0, Vector(-1, -1), 0.0, 0.0, true, this.m_arrRandomColors[this.m_iColorSelection]);
	}
	
	//Draw on top
	void OnDrawOnTop()
	{
	}
	
	//Indicate whether this entity shall be removed by the game
	bool NeedsRemoval()
	{
		return this.m_bRemoval;
	}
	
	//Indicate if entity can be dormant
	bool CanBeDormant()
	{
		return false;
	}
	
	//Indicate if entity can be collided
	bool IsCollidable()
	{
		return true;
	}
	
	//Called when the entity recieves damage
	void OnDamage(uint32 damageValue)
	{
	}
	
	//Called for wall collisions
	void OnWallCollided()
	{
	}
	
	//Called for entity collisions
	void OnCollided(IScriptedEntity@ ref)
	{
		if ((!this.m_bRemoval) && (ref.GetName() == "player")) {
			ICollectingEntity@ collectingEntity = cast<ICollectingEntity>(ref);
			collectingEntity.AddHealth(ITEM_HEALTH_ADDITION);
			
			S_PlaySound(this.m_hReceive, S_GetCurrentVolume());
			
			this.m_bRemoval = true;
		}
	}
	
	//Called for accessing the model data for this entity.
	Model& GetModel()
	{
		return this.m_oModel;
	}
	
	//Called for recieving the current position. This is useful if the entity shall move.
	Vector& GetPosition()
	{
		return this.m_vecPos;
	}
	
	//Set position
	void SetPosition(const Vector &in vec)
	{
		this.m_vecPos = vec;
	}
	
	//Return the rotation.
	float GetRotation()
	{
		return 0.0;
	}
	
	//Set rotation
	void SetRotation(float fRot)
	{
	}
	
	//Return a name string here, e.g. the class name or instance name.
	string GetName()
	{
		return "item_heart";
	}
	
	//This vector is used for drawing the selection box
	Vector& GetSize()
	{
		return this.m_vecPos;
	}
	
	//Return save game properties
	string GetSaveGameProperties()
	{
		return Props_CreateProperty("x", formatInt(this.m_vecPos[0])) +
			Props_CreateProperty("y", formatInt(this.m_vecPos[1])) +
			Props_CreateProperty("rot", formatFloat(this.GetRotation()));
	}
}

class CMentalHealthMonthQuest : IQuestEntity {
    datetime m_dtStart;
    datetime m_dtEnd;
	datetime m_dtNow;
    SoundHandle m_hRedeem;
	Timer m_tmrSpawnHeart;
	array<string> m_arrMessages;

    CMentalHealthMonthQuest()
    {
		this.m_dtNow = datetime();
	
        this.m_dtStart = datetime(this.m_dtNow.get_year(), 5, 15, 2, 0, 0);
        this.m_dtEnd = datetime(this.m_dtNow.get_year() + 1, 5, 31, 22, 0, 0);
		
		this.m_tmrSpawnHeart.SetDelay(Util_Random(QUEST_HEART_TIMER_MIN, QUEST_HEART_TIMER_MAX));
		this.m_tmrSpawnHeart.Reset();
		this.m_tmrSpawnHeart.SetActive(false);
		
		this.m_arrMessages.insertLast("Your mental health matters");
		this.m_arrMessages.insertLast("Getting help is nothing to be ashamed of");
		this.m_arrMessages.insertLast("Talking with people can be supportive");
		this.m_arrMessages.insertLast("Professional help can be beneficial");
		this.m_arrMessages.insertLast("Mental Health talk should be normalized");
		this.m_arrMessages.insertLast("Your feelings are valid");
		this.m_arrMessages.insertLast("Self-care is not selfish");
		this.m_arrMessages.insertLast("Break the stigma");
		this.m_arrMessages.insertLast("Take one step at a time");
		this.m_arrMessages.insertLast("Rest is productive");
		this.m_arrMessages.insertLast("You deserve support");
		this.m_arrMessages.insertLast("It's okay to ask for help");
		this.m_arrMessages.insertLast("You are not alone");
		this.m_arrMessages.insertLast("You deserve respect from your peers");
		this.m_arrMessages.insertLast("Never be ashamed of your feelings");
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
			if (!this.m_tmrSpawnHeart.IsActive()) {
				this.m_tmrSpawnHeart.Reset();
				this.m_tmrSpawnHeart.SetActive(true);
			}
			
			if (this.m_tmrSpawnHeart.IsActive()) {
				this.m_tmrSpawnHeart.Update();
				if (this.m_tmrSpawnHeart.IsElapsed()) {
					this.m_tmrSpawnHeart.Reset();
					
					IScriptedEntity @player = Ent_GetPlayerEntity();
					if (@player != null) {
						Vector vecPlayerPos = player.GetPosition();
						
						CHeartItem @heart = CHeartItem();
						Ent_SpawnEntity("item_health", @heart, Vector(vecPlayerPos[0] + (Util_Random(0, 200) - 100), vecPlayerPos[1] + (Util_Random(0, 200) - 100)));
					
						int iMsgId = Util_Random(0, this.m_arrMessages.length());
						HUD_AddMessage(this.m_arrMessages[iMsgId], HUD_MSG_COLOR_GREEN);
					}
				}
			}
			
			return;
        }
		
        if ((!CVar_GetBool(QUEST_SETTING, false)) && (this.m_dtNow.get_day() >= QUEST_REDEEM_DATE)) {
			CVar_SetBool(QUEST_SETTING, true);
			HUD_AddMessage("Get your Mental Health Month presents!", HUD_MSG_COLOR_BLUE);
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
        if (CVar_GetBool(QUEST_SETTING, false)) {
            if (!CVar_GetBool(QUEST_REDEEMED, false)) {
                CVar_SetBool(QUEST_REDEEMED, true);
                HUD_UpdateCollectable("gems", HUD_GetCollectableCount("gems") + 30);
                HUD_AddMessage(">> Happy Mental Health Month <<", HUD_MSG_COLOR_BLUE);
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
    CMentalHealthMonthQuest @quest = CMentalHealthMonthQuest();
    SpawnQuestEntity(quest.GetFileName(), @quest);
}
#pragma semicolon 1
#include <sourcemod>
#include <regex>
#include <pscd>
#pragma newdecls required

StringMap g_Rules;
ArrayList g_aRules;
ArrayList g_Regexes;
ArrayList g_RegexRules;

enum
{
	MODE_NONE = 0,
	MODE_ALL = 1,
	MODE_STRVALUE = 2,
	MODE_INTVALUE = 4,
	MODE_FLOATVALUE = 8,
	MODE_REGEXVALUE = 16,

	MODE_MIN = 32,
	MODE_MAX = 64,

	MODE_ALLOW = 128,
	MODE_DENY = 256, // Reverse
	MODE_CLAMP = 512,

	STATE_NONE = 0,
	STATE_ALLOW = 1,
	STATE_DENY = 2,
	STATE_CLAMPMIN = 4,
	STATE_CLAMPMAX = 8
};

public Plugin myinfo =
{
	name = "PointServerCommandFilter",
	author = "BotoX",
	description = "Filters point_servercommand->Command() using user-defined rules to restrict maps.",
	version = "0.1",
	url = ""
};

public void OnPluginStart()
{
	LoadConfig();
}

public Action PointServerCommandForward(const char[] sOrigCommand)
{
	static char sCommandRight[1024];
	static char sCommandLeft[128];
	strcopy(sCommandRight, sizeof(sCommandRight), sOrigCommand);
	TrimString(sCommandRight);

	int Split = SplitString(sCommandRight, " ", sCommandLeft, sizeof(sCommandLeft));
	if(Split == -1)
		strcopy(sCommandLeft, sizeof(sCommandLeft), sCommandRight);
	TrimString(sCommandLeft);
	strcopy(sCommandRight, sizeof(sCommandRight), sCommandRight[Split]);

	StringToLower(sCommandLeft);
	StringToLower(sCommandRight);

	ArrayList RuleList;
	if(g_Rules.GetValue(sCommandLeft, RuleList))
		return MatchRuleList(RuleList, sOrigCommand, sCommandLeft, sCommandRight);

	for(int i = 0; i < g_Regexes.Length; i++)
	{
		Regex hRegex = g_Regexes.Get(i);
		if(MatchRegex(hRegex, sCommandLeft) > 0)
		{
			RuleList = g_RegexRules.Get(i);
			return MatchRuleList(RuleList, sOrigCommand, sCommandLeft, sCommandRight);
		}
	}

	LogMessage("Blocked (No Rule): \"%s\"", sOrigCommand);
	return Plugin_Stop;
}

Action MatchRuleList(ArrayList RuleList, const char[] sOrigCommand, const char[] sCommandLeft, const char[] sCommandRight)
{
	for(int r = 0; r < RuleList.Length; r++)
	{
		int State = STATE_NONE;
		StringMap Rule = RuleList.Get(r);
		int Mode;
		Rule.GetValue("mode", Mode);

		if(Mode & MODE_ALL)
			State |= STATE_ALLOW;
		else if(Mode & MODE_STRVALUE)
		{
			static char sValue[512];
			Rule.GetString("value", sValue, sizeof(sValue));
			if(strcmp(sCommandRight, sValue) == 0)
				State |= STATE_ALLOW;
		}
		else if(Mode & MODE_INTVALUE)
		{
			int WantValue;
			int IsValue;
			Rule.GetValue("value", WantValue);
			IsValue = StringToInt(sCommandRight);

			if(IsCharNumeric(sCommandRight[0]) && WantValue == IsValue)
				State |= STATE_ALLOW;
		}
		else if(Mode & MODE_FLOATVALUE)
		{
			float WantValue;
			float IsValue;
			Rule.GetValue("value", WantValue);
			IsValue = StringToFloat(sCommandRight);

			if(IsCharNumeric(sCommandRight[0]) && FloatCompare(IsValue, WantValue) == 0)
				State |= STATE_ALLOW;
		}
		else if(Mode & MODE_REGEXVALUE)
		{
			Regex hRegex;
			Rule.GetValue("value", hRegex);
			if(MatchRegex(hRegex, sCommandRight) > 0)
				State |= STATE_ALLOW;
		}

		float MinValue;
		float MaxValue;
		float IsValue = StringToFloat(sCommandRight);
		bool IsNumeric = IsCharNumeric(sCommandRight[0]);
		if(!IsNumeric && (Mode & MODE_MIN || Mode & MODE_MAX))
			continue; // Ignore non-numerical

		if(Mode & MODE_MIN)
		{
			Rule.GetValue("minvalue", MinValue);

			if(IsValue >= MinValue)
				State |= STATE_ALLOW;
			else
				State |= STATE_DENY | STATE_CLAMPMIN;
		}
		if(Mode & MODE_MAX)
		{
			Rule.GetValue("maxvalue", MaxValue);

			if(IsValue <= MaxValue)
				State |= STATE_ALLOW;
			else
				State |= STATE_DENY | STATE_CLAMPMAX;
		}

		// Reverse mode
		if(Mode & MODE_DENY && State & STATE_ALLOW && !(State & STATE_DENY))
		{
			LogMessage("Blocked (Deny): \"%s\"", sOrigCommand);
			return Plugin_Stop;
		}

		// Clamping?
		// If there is no clamp rule (State == STATE_NONE) try to clamp to "clampvalue"
		// aka. always clamp to "clampvalue" if there are no rules in clamp mode
		if(Mode & MODE_CLAMP && (State & STATE_DENY || State == STATE_NONE))
		{
			bool Clamp = false;
			float ClampValue;
			if(Rule.GetValue("clampvalue", ClampValue))
				Clamp = true;
			else if(State & STATE_CLAMPMIN)
			{
				ClampValue = MinValue;
				Clamp = true;
			}
			else if(State & STATE_CLAMPMAX)
			{
				ClampValue = MaxValue;
				Clamp = true;
			}
			if(Clamp)
			{
				LogMessage("Clamped (%f -> %f): \"%s\"", IsValue, ClampValue, sOrigCommand);
				ServerCommand("%s %f", sCommandLeft, ClampValue);
				return Plugin_Stop;
			}
			else // Can this even happen? Yesh, dumb user. -> "clamp" {}
			{
				LogMessage("Blocked (!Clamp): \"%s\"", sOrigCommand);
				return Plugin_Stop;
			}
		}
		else if(Mode & MODE_CLAMP && State & STATE_ALLOW)
		{
			LogMessage("Allowed (Clamp): \"%s\"", sOrigCommand);
			return Plugin_Continue;
		}

		if(Mode & MODE_ALLOW && State & STATE_ALLOW && !(State & STATE_DENY))
		{
			LogMessage("Allowed (Allow): \"%s\"", sOrigCommand);
			return Plugin_Continue;
		}
	}

	LogMessage("Blocked (No Match): \"%s\"", sOrigCommand);
	return Plugin_Stop;
}

void Cleanup()
{
	if(!g_Rules)
		return;

	for(int i = 0; i < g_aRules.Length; i++)
	{
		ArrayList RuleList = g_aRules.Get(i);
		CleanupRuleList(RuleList);
	}
	delete g_aRules;
	delete g_Rules;

	for(int i = 0; i < g_Regexes.Length; i++)
	{
		Regex hRegex = g_Regexes.Get(i);
		delete hRegex;

		ArrayList RuleList = g_RegexRules.Get(i);
		CleanupRuleList(RuleList);
	}
	delete g_Regexes;
	delete g_RegexRules;
}

void CleanupRuleList(ArrayList RuleList)
{
	for(int j = 0; j < RuleList.Length; j++)
	{
		StringMap Rule = RuleList.Get(j);

		int Mode;
		if(Rule.GetValue("mode", Mode))
		{
			if(Mode & MODE_REGEXVALUE)
			{
				Regex hRegex;
				Rule.GetValue("value", hRegex);
				delete hRegex;
			}
		}
		delete Rule;
	}
	delete RuleList;
}

void LoadConfig()
{
	if(g_Rules)
		Cleanup();

	static char sConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/PointServerCommandFilter.cfg");
	if(!FileExists(sConfigFile))
		SetFailState("Could not find config: \"%s\"", sConfigFile);

	KeyValues Config = new KeyValues("PointServerCommandFilter");
	if(!Config.ImportFromFile(sConfigFile))
	{
		delete Config;
		SetFailState("ImportFromFile() failed!");
	}
	if(!Config.GotoFirstSubKey(false))
	{
		delete Config;
		SetFailState("GotoFirstSubKey() failed!");
	}

	g_Rules = new StringMap();
	g_aRules = new ArrayList();
	g_Regexes = new ArrayList();
	g_RegexRules = new ArrayList();

	do
	{
		static char sLeft[128];
		Config.GetSectionName(sLeft, sizeof(sLeft));
		StringToLower(sLeft);
		int LeftLen = strlen(sLeft);

		ArrayList RuleList;

		if(sLeft[0] == '/' && sLeft[LeftLen - 1] == '/')
		{
			sLeft[LeftLen - 1] = 0;
			Regex hRegex;
			static char sError[512];
			hRegex = CompileRegex(sLeft[1], PCRE_CASELESS, sError, sizeof(sError));
			if(hRegex == INVALID_HANDLE)
			{
				LogError("Regex error from %s", sLeft);
				LogError(sError);
				continue;
			}
			else
			{
				RuleList = new ArrayList();
				g_Regexes.Push(hRegex);
				g_RegexRules.Push(RuleList);
			}
		}
		else if(!g_Rules.GetValue(sLeft, RuleList))
		{
			RuleList = new ArrayList();
			g_Rules.SetValue(sLeft, RuleList);
			g_aRules.Push(RuleList);
		}

		// Section
		if(Config.GotoFirstSubKey(false))
		{
			do
			{
				static char sSection[128];
				Config.GetSectionName(sSection, sizeof(sSection));

				int Mode = MODE_NONE;
				if(strcmp(sSection, "deny", false) == 0)
					Mode |= MODE_DENY;
				else if(strcmp(sSection, "allow", false) == 0)
					Mode |= MODE_ALLOW;
				else if(strcmp(sSection, "clamp", false) == 0)
					Mode |= MODE_CLAMP;

				// Section
				if(Config.GotoFirstSubKey(false))
				{
					StringMap Rule = new StringMap();
					int RuleMode = MODE_NONE;
					do
					{
						static char sKey[128];
						Config.GetSectionName(sKey, sizeof(sKey));

						if(strcmp(sKey, "min", false) == 0)
						{
							float Value = Config.GetFloat(NULL_STRING);
							Rule.SetValue("minvalue", Value);
							RuleMode |= MODE_MIN;
						}
						else if(strcmp(sKey, "max", false) == 0)
						{
							float Value = Config.GetFloat(NULL_STRING);
							Rule.SetValue("maxvalue", Value);
							RuleMode |= MODE_MAX;
						}
						else if(Mode & MODE_CLAMP)
						{
							float Value = Config.GetFloat(NULL_STRING);
							Rule.SetValue("clampvalue", Value);
							RuleMode |= MODE_CLAMP;
						}
						else
						{
							StringMap Rule_ = new StringMap();
							if(ParseRule(Config, sLeft, Mode, Rule_))
								RuleList.Push(Rule_);
							else
								delete Rule_;
						}
					} while(Config.GotoNextKey(false));
					Config.GoBack();

					if(RuleMode != MODE_NONE)
					{
						Rule.SetValue("mode", Mode | RuleMode);
						RuleList.Push(Rule);
					}
					else
						delete Rule;
				}
				else // Value
				{
					StringMap Rule = new StringMap();

					if(ParseRule(Config, sLeft, Mode, Rule))
						RuleList.Push(Rule);
					else
						delete Rule;
				}

			} while(Config.GotoNextKey(false));
			Config.GoBack();
		}
		else // Value
		{
			StringMap Rule = new StringMap();

			if(ParseRule(Config, sLeft, MODE_ALLOW, Rule))
				RuleList.Push(Rule);
			else
				delete Rule;
		}
	} while(Config.GotoNextKey(false));
	delete Config;

	for(int i = 0; i < g_aRules.Length; i++)
	{
		ArrayList RuleList = g_aRules.Get(i);
		SortADTArrayCustom(RuleList, SortRuleList);
	}
}

bool ParseRule(KeyValues Config, const char[] sLeft, int Mode, StringMap Rule)
{
	static char sValue[512];
	if(Config.GetDataType(NULL_STRING) == KvData_String)
	{
		Config.GetString(NULL_STRING, sValue, sizeof(sValue));

		int ValueLen = strlen(sValue);
		if(sValue[0] == '/' && sValue[ValueLen - 1] == '/')
		{
			sValue[ValueLen - 1] = 0;
			Regex hRegex;
			static char sError[512];
			hRegex = CompileRegex(sValue[1], PCRE_CASELESS, sError, sizeof(sError));
			if(hRegex == INVALID_HANDLE)
			{
				LogError("Regex error in %s from %s", sLeft, sValue[1]);
				LogError(sError);
				return false;
			}
			else
			{
				Rule.SetValue("mode", Mode | MODE_REGEXVALUE);
				Rule.SetValue("value", hRegex);
			}
		}
		else
		{
			StringToLower(sValue);
			Rule.SetValue("mode", Mode | MODE_STRVALUE);
			Rule.SetString("value", sValue);
		}
	}
	else if(Config.GetDataType(NULL_STRING) == KvData_Int)
	{
		int Value = Config.GetNum(NULL_STRING);
		Rule.SetValue("mode", Mode | MODE_INTVALUE);
		Rule.SetValue("value", Value);
	}
	else if(Config.GetDataType(NULL_STRING) == KvData_Float)
	{
		float Value = Config.GetFloat(NULL_STRING);
		Rule.SetValue("mode", Mode | MODE_FLOATVALUE);
		Rule.SetValue("value", Value);
	}
	else
		Rule.SetValue("mode", Mode | MODE_ALL);

	return true;
}

public int SortRuleList(int index1, int index2, Handle array, Handle hndl)
{
	StringMap Rule1 = GetArrayCell(array, index1);
	StringMap Rule2 = GetArrayCell(array, index2);

	int Mode1;
	int Mode2;
	Rule1.GetValue("mode", Mode1);
	Rule2.GetValue("mode", Mode2);

	// Deny should be first
	if(Mode1 & MODE_DENY && !(Mode2 & MODE_DENY))
		return -1;
	if(Mode2 & MODE_DENY && !(Mode1 & MODE_DENY))
		return 1;

	// Clamp should be last
	if(Mode1 & MODE_CLAMP && !(Mode2 & MODE_CLAMP))
		return 1;
	if(Mode2 & MODE_CLAMP && !(Mode1 & MODE_CLAMP))
		return -1;

	return 0;
}

stock void StringToLower(char[] Str)
{
	for(int i = 0; Str[i]; i++)
		Str[i] = CharToLower(Str[i]);
}

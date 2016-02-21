#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <outputinfo>

#pragma newdecls required

StringMap g_PlayerLevels;
KeyValues g_Config;
KeyValues g_PropAltNames;

#define PLUGIN_VERSION "1.1"
public Plugin myinfo =
{
	name 			= "SaveLevel",
	author 			= "BotoX",
	description 	= "Saves players level on maps when they disconnect and restore them on connect.",
	version 		= PLUGIN_VERSION,
	url 			= ""
};

public void OnPluginStart()
{
	g_PropAltNames = new KeyValues("PropAltNames");
	g_PropAltNames.SetString("m_iName", "targetname");
}

public void OnPluginEnd()
{
	if(g_Config)
		delete g_Config;
	if(g_PlayerLevels)
		delete g_PlayerLevels;
	delete g_PropAltNames;
}

public void OnMapStart()
{
	if(g_Config)
		delete g_Config;
	if(g_PlayerLevels)
		delete g_PlayerLevels;

	char sMapName[PLATFORM_MAX_PATH];
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/savelevel/%s.cfg", sMapName);
	if(!FileExists(sConfigFile))
	{
		LogMessage("Could not find mapconfig: \"%s\"", sConfigFile);
		return;
	}
	LogMessage("Found mapconfig: \"%s\"", sConfigFile);

	g_Config = new KeyValues("levels");
	if(!g_Config.ImportFromFile(sConfigFile))
	{
		delete g_Config;
		LogMessage("ImportFromFile() failed!");
		return;
	}
	g_Config.Rewind();

	if(!g_Config.GotoFirstSubKey())
	{
		delete g_Config;
		LogMessage("GotoFirstSubKey() failed!");
		return;
	}

	g_PlayerLevels = new StringMap();
}

public void OnClientPostAdminCheck(int client)
{
	if(!g_PlayerLevels)
		return;

	char sSteamID[32];
	GetClientAuthId(client, AuthId_Steam3, sSteamID, sizeof(sSteamID));

	static char sTargets[128];
	if(g_PlayerLevels.GetString(sSteamID, sTargets, sizeof(sTargets)))
	{
		g_PlayerLevels.Remove(sSteamID);
		char sNames[128];
		static char asTargets[4][32];
		int Split = ExplodeString(sTargets, ";", asTargets, sizeof(asTargets), sizeof(asTargets[]));

		g_Config.Rewind();
		for(int i = 0; i < Split; i++)
		{
			if(!g_Config.JumpToKey(asTargets[i]))
				continue;

			static char sKey[32];
			static char sValue[1024];
			if(g_Config.JumpToKey("restore"))
			{
				if(g_Config.GotoFirstSubKey(false))
				{
					do
					{
						g_Config.GetSectionName(sKey, sizeof(sKey));
						g_Config.GetString(NULL_STRING, sValue, sizeof(sValue));
						if(StrEqual(sKey, "AddOutput", false))
						{
							SetVariantString(sValue);
							AcceptEntityInput(client, sKey, client, client);
						}
						else
						{
							PropFieldType Type;
							int NumBits;
							int Offset = FindDataMapInfo(client, sKey, Type, NumBits);
							if(Offset != -1)
							{
								if(Type == PropField_Integer)
								{
									int Value = StringToInt(sValue);
									SetEntData(client, Offset, Value, NumBits / 8, false);
								}
								else if(Type == PropField_Float)
								{
									float Value = StringToFloat(sValue);
									SetEntDataFloat(client, Offset, Value, false);
								}
								else if(Type == PropField_String)
								{
									SetEntDataString(client, Offset, sValue, strlen(sValue) + 1, false);
								}
								else if(Type == PropField_String_T)
								{
									static char sAltKey[32];
									g_PropAltNames.GetString(sKey, sAltKey, sizeof(sAltKey), NULL_STRING);
									if(sAltKey[0])
										DispatchKeyValue(client, sAltKey, sValue);
								}
							}
						}
					}
					while(g_Config.GotoNextKey(false));

					g_Config.GoBack();
					g_Config.GoBack();
					g_Config.GetString("name", sValue, sizeof(sValue));
					g_Config.GoBack();
					StrCat(sNames, sizeof(sNames), sValue);
					StrCat(sNames, sizeof(sNames), ", ");
				}
			}
		}

		int NamesLen = strlen(sNames);
		if(NamesLen)
		{
			sNames[NamesLen - 2] = 0; // Cut off ', '
			PrintToChatAll("\x03[SaveLevel]\x01 %N has been restored to: \x04%s", client, sNames);
		}
		g_Config.Rewind();
	}
}

public void OnClientDisconnect(int client)
{
	if(!g_Config || !g_PlayerLevels || !IsClientInGame(client))
		return;

	g_Config.Rewind();
	g_Config.GotoFirstSubKey();

	char sTargets[128];
	static char sTarget[32];
	static char sKey[32];
	static char sValue[1024];
	static char sOutput[1024];
	bool Found = false;
	do
	{
		g_Config.GetSectionName(sTarget, sizeof(sTarget));
		if(!g_Config.JumpToKey("match"))
			continue;

		int Matches = 0;
		int ExactMatches = g_Config.GetNum("ExactMatches", -1);
		int MinMatches = g_Config.GetNum("MinMatches", -1);
		int MaxMatches = g_Config.GetNum("MaxMatches", -1);

		if(!g_Config.GotoFirstSubKey(false))
			continue;

		do
		{
			static char sSection[32];
			g_Config.GetSectionName(sSection, sizeof(sSection));

			if(StrEqual(sSection, "outputs"))
			{
				int _Matches = 0;
				int _ExactMatches = g_Config.GetNum("ExactMatches", -1);
				int _MinMatches = g_Config.GetNum("MinMatches", -1);
				int _MaxMatches = g_Config.GetNum("MaxMatches", -1);

				if(g_Config.GotoFirstSubKey(false))
				{
					do
					{
						g_Config.GetSectionName(sKey, sizeof(sKey));
						g_Config.GetString(NULL_STRING, sValue, sizeof(sValue));

						int Count = GetOutputCount(client, sKey);
						for(int i = 0; i < Count; i++)
						{
							int Len = GetOutputTarget(client, sKey, i, sOutput);
							sOutput[Len] = ','; Len++;
							Len += GetOutputTargetInput(client, sKey, i, sOutput[Len]);
							sOutput[Len] = ','; Len++;
							Len += GetOutputParameter(client, sKey, i, sOutput[Len]);

							if(StrEqual(sValue, sOutput))
								_Matches++;
						}
					}
					while(g_Config.GotoNextKey(false));

					g_Config.GoBack();
				}
				g_Config.GoBack();

				Matches += CalcMatches(_Matches, _ExactMatches, _MinMatches, _MaxMatches);
			}
			else if(StrEqual(sSection, "props"))
			{
				int _Matches = 0;
				int _ExactMatches = g_Config.GetNum("ExactMatches", -1);
				int _MinMatches = g_Config.GetNum("MinMatches", -1);
				int _MaxMatches = g_Config.GetNum("MaxMatches", -1);

				if(g_Config.GotoFirstSubKey(false))
				{
					do
					{
						g_Config.GetSectionName(sKey, sizeof(sKey));
						g_Config.GetString(NULL_STRING, sValue, sizeof(sValue));

						GetEntPropString(client, Prop_Data, sKey, sOutput, sizeof(sOutput));

						if(StrEqual(sValue, sOutput))
							_Matches++;
					}
					while(g_Config.GotoNextKey(false));

					g_Config.GoBack();
				}
				g_Config.GoBack();

				Matches += CalcMatches(_Matches, _ExactMatches, _MinMatches, _MaxMatches);
			}
			else if(StrEqual(sSection, "math"))
			{
				if(g_Config.GotoFirstSubKey(false))
				{
					do
					{
						g_Config.GetSectionName(sKey, sizeof(sKey));
						g_Config.GetString(NULL_STRING, sValue, sizeof(sValue));

						int Target = 0;
						int Input;
						int Parameter;

						Input = FindCharInString(sValue[Target], ',');
						sValue[Input] = 0; Input++;

						Parameter = Input + FindCharInString(sValue[Input], ',');
						sValue[Parameter] = 0; Parameter++;

						int Value = 0;
						int Count = GetOutputCount(client, sKey);
						for(int i = 0; i < Count; i++)
						{
							int _Target = 0;
							int _Input;
							int _Parameter;

							_Input = GetOutputTarget(client, sKey, i, sOutput[_Target]);
							sOutput[_Input] = 0; _Input++;

							_Parameter = _Input + GetOutputTargetInput(client, sKey, i, sOutput[_Input]);
							sOutput[_Parameter] = 0; _Parameter++;

							GetOutputParameter(client, sKey, i, sOutput[_Parameter]);

							if(!StrEqual(sOutput[_Target], sValue[Target]))
								continue;

							int _Value = StringToInt(sOutput[_Parameter]);

							if(StrEqual(sOutput[_Input], "add", false))
								Value += _Value;
							else if(StrEqual(sOutput[_Input], "subtract", false))
								Value -= _Value;
						}

						int Result = StringToInt(sValue[Parameter]);
						if(StrEqual(sValue[Input], "subtract", false))
							Result *= -1;

						if(Value == Result)
							Matches += 1;
					}
					while(g_Config.GotoNextKey(false));

					g_Config.GoBack();
				}
				g_Config.GoBack();
			}
		}
		while(g_Config.GotoNextKey(false));

		g_Config.GoBack();

		if(CalcMatches(Matches, ExactMatches, MinMatches, MaxMatches))
		{
			if(Found)
				StrCat(sTargets, sizeof(sTargets), ";");

			Found = true;
			StrCat(sTargets, sizeof(sTargets), sTarget);
		}
	}
	while(g_Config.GotoNextKey());

	g_Config.Rewind();
	if(!Found)
		return;

	char sSteamID[32];
	GetClientAuthId(client, AuthId_Steam3, sSteamID, sizeof(sSteamID));
	g_PlayerLevels.SetString(sSteamID, sTargets, true);
}

stock int CalcMatches(int Matches, int ExactMatches, int MinMatches, int MaxMatches)
{
	int Value = 0;
	if((ExactMatches == -1 && MinMatches == -1 && MaxMatches == -1 && Matches) ||
		Matches == ExactMatches ||
		(MinMatches != -1 && MaxMatches == -1 && Matches >= MinMatches) ||
		(MaxMatches != -1 && MinMatches == -1 && Matches <= MaxMatches) ||
		(MinMatches != -1 && MaxMatches != -1 && Matches >= MinMatches && Matches <= MaxMatches))
	{
		Value++;
	}

	return Value;
}

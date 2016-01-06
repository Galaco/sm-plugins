#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <cstrike>

#undef REQUIRE_PLUGIN
#include <ccc>
#include <zombiereloaded>
#include <voiceannounce_ex>
#include <AdvancedTargeting>
#define REQUIRE_PLUGIN

#pragma newdecls required

bool g_Plugin_ccc = false;
bool g_Plugin_zombiereloaded = false;
bool g_Plugin_voiceannounce_ex = false;
bool g_Plugin_AdvancedTargeting = false;

#define PLUGIN_VERSION "2.0"

public Plugin myinfo =
{
	name 			= "SelfMute",
	author 			= "BotoX",
	description 	= "Ignore other players in text and voicechat.",
	version 		= PLUGIN_VERSION,
	url 			= ""
};

enum
{
	MUTE_NONE = 0,
	MUTE_SPEC = 1,
	MUTE_CT = 2,
	MUTE_T = 4,
	MUTE_DEAD = 8,
	MUTE_ALIVE = 16,
	MUTE_NOTFRIENDS = 32,
	MUTE_ALL = 64,
	MUTE_LAST = 64
};

bool g_Ignored[(MAXPLAYERS + 1) * (MAXPLAYERS + 1)];
int g_SpecialMutes[MAXPLAYERS + 1];

char g_PlayerNames[MAXPLAYERS+1][MAX_NAME_LENGTH];

public void OnPluginStart()
{
	CreateConVar("sm_selfmute_version", PLUGIN_VERSION, "Version of Self-Mute", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegConsoleCmd("sm_sm", Command_SelfMute, "Mute player by typing !sm [playername]");
	RegConsoleCmd("sm_su", Command_SelfUnMute, "Unmute player by typing !su [playername]");
	RegConsoleCmd("sm_cm", Command_CheckMutes, "Check who you have self-muted");

	HookEvent("round_start", Event_Round);
	HookEvent("round_end", Event_Round);
	HookEvent("player_team", Event_TeamChange);

	UserMsg RadioText = GetUserMessageId("RadioText");
	if(RadioText == INVALID_MESSAGE_ID)
		SetFailState("This game doesn't support RadioText user messages.");

	HookUserMessage(RadioText, Hook_UserMessageRadioText, true);

	UserMsg SendAudio = GetUserMessageId("SendAudio");
	if(SendAudio == INVALID_MESSAGE_ID)
		SetFailState("This game doesn't support SendAudio user messages.");

	HookUserMessage(SendAudio, Hook_UserMessageSendAudio, true);
}

public void OnAllPluginsLoaded()
{
	g_Plugin_ccc = LibraryExists("ccc");
	g_Plugin_zombiereloaded = true;//LibraryExists("zombiereloaded");
	g_Plugin_voiceannounce_ex = LibraryExists("voiceannounce_ex");
	g_Plugin_AdvancedTargeting = LibraryExists("AdvancedTargeting");
	PrintToServer("CCC: %s\nZombieReloaded: %s\nVoiceAnnounce: %s\nAdvancedTargeting: %s",
		(g_Plugin_ccc ? "loaded" : "not loaded"),
		(g_Plugin_zombiereloaded ? "loaded" : "not loaded"),
		(g_Plugin_voiceannounce_ex ? "loaded" : "not loaded"),
		(g_Plugin_AdvancedTargeting ? "loaded" : "not loaded"));
}

public void OnClientPutInServer(int client)
{
	g_SpecialMutes[client] = MUTE_NONE;
	for(int i = 1; i <= MaxClients; i++)
		SetIgnored(client, i, false);

	UpdateSpecialMutesOtherClients(client);
	UpdateIgnored();
}

public void OnClientPostAdminCheck(int client)
{
	UpdateSpecialMutesOtherClients(client);
	UpdateSpecialMutesThisClient(client);
}

public void OnClientDisconnect(int client)
{
	g_SpecialMutes[client] = MUTE_NONE;
	for(int i = 1; i <= MaxClients; i++)
	{
		SetIgnored(client, i, false);

		if(IsClientInGame(i) && !IsFakeClient(i) && i != client)
			SetListenOverride(i, client, Listen_Yes);
	}

	UpdateIgnored();
}

public void Event_Round(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
			UpdateSpecialMutesThisClient(i);
	}
}

public void Event_TeamChange(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	UpdateSpecialMutesOtherClients(client);
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	UpdateSpecialMutesOtherClients(client);
}

public int ZR_OnClientHumanPost(int client, bool respawn, bool protect)
{
	UpdateSpecialMutesOtherClients(client);
}

/*
 * Mutes this client on other players
*/
void UpdateSpecialMutesOtherClients(int client)
{
	bool Alive = IsPlayerAlive(client);
	int Team = GetClientTeam(client);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(i == client || !IsClientInGame(i) || IsFakeClient(i))
			continue;

		int Flags = MUTE_NONE;

		if(g_SpecialMutes[i] & MUTE_SPEC && Team == CS_TEAM_SPECTATOR)
			Flags |= MUTE_SPEC;

		else if(g_SpecialMutes[i] & MUTE_CT && Alive &&
			((g_Plugin_zombiereloaded && ZR_IsClientHuman(client)) || (!g_Plugin_zombiereloaded && Team == CS_TEAM_CT)))
			Flags |= MUTE_CT;

		else if(g_SpecialMutes[i] & MUTE_T && Alive &&
			((g_Plugin_zombiereloaded && ZR_IsClientZombie(client)) || (!g_Plugin_zombiereloaded && Team == CS_TEAM_T)))
			Flags |= MUTE_T;

		else if(g_SpecialMutes[i] & MUTE_DEAD && !Alive)
			Flags |= MUTE_DEAD;

		else if(g_SpecialMutes[i] & MUTE_ALIVE && Alive)
			Flags |= MUTE_ALIVE;

		else if(g_SpecialMutes[i] & MUTE_NOTFRIENDS &&
			g_Plugin_AdvancedTargeting && IsClientFriend(i, client) == 0)
			Flags |= MUTE_NOTFRIENDS;

		else if(g_SpecialMutes[i] & MUTE_ALL)
			Flags |= MUTE_ALL;

		if(Flags)
			SetListenOverride(i, client, Listen_No);
		else if(!GetIgnored(i, client))
			SetListenOverride(i, client, Listen_Yes);
	}
}

/*
 * Mutes other players on this client
*/
void UpdateSpecialMutesThisClient(int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i == client || !IsClientInGame(i) || IsFakeClient(i))
			continue;

		bool Alive = IsPlayerAlive(i);
		int Team = GetClientTeam(i);

		int Flags = MUTE_NONE;

		if(g_SpecialMutes[client] & MUTE_SPEC && Team == CS_TEAM_SPECTATOR)
			Flags |= MUTE_SPEC;

		else if(g_SpecialMutes[client] & MUTE_CT && Alive &&
			((g_Plugin_zombiereloaded && ZR_IsClientHuman(i) || (!g_Plugin_zombiereloaded) && Team == CS_TEAM_CT)))
			Flags |= MUTE_CT;

		else if(g_SpecialMutes[client] & MUTE_T && Alive &&
			((g_Plugin_zombiereloaded && ZR_IsClientZombie(i) || (!g_Plugin_zombiereloaded) && Team == CS_TEAM_T)))
			Flags |= MUTE_T;

		else if(g_SpecialMutes[client] & MUTE_DEAD && !Alive)
			Flags |= MUTE_DEAD;

		else if(g_SpecialMutes[client] & MUTE_ALIVE && Alive)
			Flags |= MUTE_ALIVE;

		else if(g_SpecialMutes[client] & MUTE_NOTFRIENDS &&
			g_Plugin_AdvancedTargeting && IsClientFriend(client, i) == 0)
			Flags |= MUTE_NOTFRIENDS;

		else if(g_SpecialMutes[client] & MUTE_ALL)
			Flags |= MUTE_ALL;

		if(Flags)
			SetListenOverride(client, i, Listen_No);
		else if(!GetIgnored(client, i))
			SetListenOverride(client, i, Listen_Yes);
	}
}

int GetSpecialMutesFlags(char[] Argument)
{
	int SpecialMute = MUTE_NONE;
	if(StrEqual(Argument, "@spec", false) || StrEqual(Argument, "@!ct", false) || StrEqual(Argument, "@!t", false))
		SpecialMute |= MUTE_SPEC;
	if(StrEqual(Argument, "@ct", false) || StrEqual(Argument, "@!t", false) || StrEqual(Argument, "@!spec", false))
		SpecialMute |= MUTE_CT;
	if(StrEqual(Argument, "@t", false) || StrEqual(Argument, "@!ct", false) || StrEqual(Argument, "@!spec", false))
		SpecialMute |= MUTE_T;
	if(StrEqual(Argument, "@dead", false) || StrEqual(Argument, "@!alive", false))
		SpecialMute |= MUTE_DEAD;
	if(StrEqual(Argument, "@alive", false) || StrEqual(Argument, "@!dead", false))
		SpecialMute |= MUTE_ALIVE;
	if(g_Plugin_AdvancedTargeting && StrEqual(Argument, "@!friends", false))
		SpecialMute |= MUTE_NOTFRIENDS;
	if(StrEqual(Argument, "@all", false))
		SpecialMute |= MUTE_ALL;

	return SpecialMute;
}

void FormatSpecialMutes(int SpecialMute, char[] aBuf, int BufLen)
{
	if(!SpecialMute)
	{
		StrCat(aBuf, BufLen, "none");
		return;
	}

	bool Status = false;
	int MuteCount = RoundFloat(Logarithm(float(MUTE_LAST), 2.0));
	for(int i = 0; i <= MuteCount; i++)
	{
		switch(SpecialMute & RoundFloat(Pow(2.0, float(i))))
		{
			case MUTE_SPEC:
			{
				StrCat(aBuf, BufLen, "Spectators, ");
				Status = true;
			}
			case MUTE_CT:
			{
				StrCat(aBuf, BufLen, "CTs, ");
				Status = true;
			}
			case MUTE_T:
			{
				StrCat(aBuf, BufLen, "Ts, ");
				Status = true;
			}
			case MUTE_DEAD:
			{
				StrCat(aBuf, BufLen, "Dead players, ");
				Status = true;
			}
			case MUTE_ALIVE:
			{
				StrCat(aBuf, BufLen, "Alive players, ");
				Status = true;
			}
			case MUTE_NOTFRIENDS:
			{
				StrCat(aBuf, BufLen, "Not Steam friends, ");
				Status = true;
			}
			case MUTE_ALL:
			{
				StrCat(aBuf, BufLen, "Everyone, ");
				Status = true;
			}
		}
	}

	// Cut off last ', '
	if(Status)
		aBuf[strlen(aBuf) - 2] = 0;
}

bool MuteSpecial(int client, char[] Argument)
{
	bool RetValue = false;
	int SpecialMute = GetSpecialMutesFlags(Argument);

	if(SpecialMute & MUTE_NOTFRIENDS && g_Plugin_AdvancedTargeting && ReadClientFriends(client) != 1)
	{
		PrintToChat(client, "\x04[Self-Mute]\x01 Could not read your friendslist, your profile must be set to public!");
		SpecialMute &= ~MUTE_NOTFRIENDS;
		RetValue = true;
	}

	if(SpecialMute)
	{
		if(SpecialMute & MUTE_ALL || g_SpecialMutes[client] & MUTE_ALL)
		{
			g_SpecialMutes[client] = MUTE_ALL;
			SpecialMute = MUTE_ALL;
		}
		else
			g_SpecialMutes[client] |= SpecialMute;

		UpdateSpecialMutesThisClient(client);

		char aBuf[128];
		FormatSpecialMutes(SpecialMute, aBuf, sizeof(aBuf));

		PrintToChat(client, "\x04[Self-Mute]\x01 You have self-muted group:\x04 %s", aBuf);
		RetValue = true;
	}

	return RetValue;
}

bool UnMuteSpecial(int client, char[] Argument)
{
	int SpecialMute = GetSpecialMutesFlags(Argument);

	if(SpecialMute)
	{
		if(SpecialMute & MUTE_ALL)
		{
			if(g_SpecialMutes[client])
			{
				SpecialMute = g_SpecialMutes[client];
				g_SpecialMutes[client] = MUTE_NONE;
			}
			else
			{
				for(int i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i) && !IsFakeClient(i))
						UnIgnore(client, i);

					PrintToChat(client, "\x04[Self-Mute]\x01 You have self-unmuted:\x04 all players");
					return true;
				}
			}
		}
		else
			g_SpecialMutes[client] &= ~SpecialMute;

		UpdateSpecialMutesThisClient(client);

		char aBuf[256];
		FormatSpecialMutes(SpecialMute, aBuf, sizeof(aBuf));

		PrintToChat(client, "\x04[Self-Mute]\x01 You have self-unmuted group:\x04 %s", aBuf);
		return true;
	}

	return false;
}

void Ignore(int client, int target)
{
	SetIgnored(client, target, true);
	SetListenOverride(client, target, Listen_No);
}

void UnIgnore(int client, int target)
{
	SetIgnored(client, target, false);
	SetListenOverride(client, target, Listen_Yes);
}

/*
 * CHAT COMMANDS
*/
public Action Command_SelfMute(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[SM] Cannot use command from server console.");
		return Plugin_Handled;
	}

	if(args < 1)
	{
		DisplayMuteMenu(client);
		return Plugin_Handled;
	}

	char Argument[65];
	GetCmdArgString(Argument, sizeof(Argument));

	char Filtered[65];
	strcopy(Filtered, sizeof(Filtered), Argument);
	StripQuotes(Filtered);
	TrimString(Filtered);

	if(StrEqual(Filtered, "@me", false))
	{
		PrintToChat(client, "\x04[Self-Mute]\x01 You can't mute yourself, don't be silly.");
		return Plugin_Handled;
	}

	if(MuteSpecial(client, Filtered))
		return Plugin_Handled;

	char sTargetName[MAX_TARGET_LENGTH];
	int aTargetList[MAXPLAYERS];
	int TargetCount;
	bool TnIsMl;

	if((TargetCount = ProcessTargetString(
			Argument,
			client,
			aTargetList,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_IMMUNITY,
			sTargetName,
			sizeof(sTargetName),
			TnIsMl)) <= 0)
	{
		ReplyToTargetError(client, TargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < TargetCount; i++)
	{
		if(aTargetList[i] != client)
			Ignore(client, aTargetList[i]);
	}
	UpdateIgnored();

	PrintToChat(client, "\x04[Self-Mute]\x01 You have self-muted:\x04 %s", sTargetName);

	return Plugin_Handled;
}

public Action Command_SelfUnMute(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[SM] Cannot use command from server console.");
		return Plugin_Handled;
	}

	if(args < 1)
	{
		DisplayUnMuteMenu(client);
		return Plugin_Handled;
	}

	char Argument[65];
	GetCmdArgString(Argument, sizeof(Argument));

	char Filtered[65];
	strcopy(Filtered, sizeof(Filtered), Argument);
	StripQuotes(Filtered);
	TrimString(Filtered);

	if(StrEqual(Filtered, "@me", false))
	{
		PrintToChat(client, "\x04[Self-Mute]\x01 Unmuting won't work either.");
		return Plugin_Handled;
	}

	if(UnMuteSpecial(client, Filtered))
		return Plugin_Handled;

	char sTargetName[MAX_TARGET_LENGTH];
	int aTargetList[MAXPLAYERS];
	int TargetCount;
	bool TnIsMl;

	if((TargetCount = ProcessTargetString(
			Argument,
			client,
			aTargetList,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_IMMUNITY,
			sTargetName,
			sizeof(sTargetName),
			TnIsMl)) <= 0)
	{
		ReplyToTargetError(client, TargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < TargetCount; i++)
	{
		if(aTargetList[i] != client)
			UnIgnore(client, aTargetList[i]);
	}
	UpdateIgnored();

	PrintToChat(client, "\x04[Self-Mute]\x01 You have self-unmuted:\x04 %s", sTargetName);

	return Plugin_Handled;
}

public Action Command_CheckMutes(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[SM] Cannot use command from server console.");
		return Plugin_Handled;
	}

	char aBuf[1024];
	char aBuf2[MAX_NAME_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(GetIgnored(client, i))
		{
			GetClientName(i, aBuf2, sizeof(aBuf2));
			StrCat(aBuf, sizeof(aBuf), aBuf2);
			StrCat(aBuf, sizeof(aBuf), ", ");
		}
	}

	// Cut off last ', '
	if(strlen(aBuf))
	{
		aBuf[strlen(aBuf) - 2] = 0;
		PrintToChat(client, "\x04[Self-Mute]\x01 You have self-muted:\x04 %s", aBuf);
	}
	else if(!g_SpecialMutes[client])
		PrintToChat(client, "\x04[Self-Mute]\x01 You have not self-muted anyone!\x04", aBuf);

	if(g_SpecialMutes[client])
	{
		aBuf[0] = 0;
		FormatSpecialMutes(g_SpecialMutes[client], aBuf, sizeof(aBuf));
		PrintToChat(client, "\x04[Self-Mute]\x01 You have self-muted group:\x04 %s", aBuf);
	}

	return Plugin_Handled;
}

/*
 * MENU
*/
void DisplayMuteMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MuteMenu, MenuAction_Select|MenuAction_Cancel|MenuAction_End|MenuAction_DrawItem|MenuAction_DisplayItem);
	menu.ExitButton = true;

	int[] aClients = new int[MaxClients + 1];

	if(g_Plugin_voiceannounce_ex)
	{
		// Count talking players and insert id's into aClients array
		int CurrentlyTalking = 0;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(i != client && IsClientInGame(i) && !IsFakeClient(i) && IsClientSpeaking(i))
				aClients[CurrentlyTalking++] = i;
		}

		if(CurrentlyTalking > 0)
		{
			// insert player names into g_PlayerNames array
			for(int i = 0; i < CurrentlyTalking; i++)
				GetClientName(aClients[i], g_PlayerNames[aClients[i]], sizeof(g_PlayerNames[]));

			// sort aClients array by player name
			SortCustom1D(aClients, CurrentlyTalking, SortByPlayerName);

			// insert players sorted
			char aBuf[11];
			for(int i = 0; i < CurrentlyTalking; i++)
			{
				IntToString(GetClientUserId(aClients[i]), aBuf, sizeof(aBuf));
				menu.AddItem(aBuf, g_PlayerNames[aClients[i]]);
			}

			// insert spacers
			int Entries = 7 - CurrentlyTalking % 7;
			while(Entries--)
				menu.AddItem("", "", ITEMDRAW_RAWLINE);
		}
	}

	menu.AddItem("@all", "Everyone");
	menu.AddItem("@spec", "Spectators");
	menu.AddItem("@ct", "Counter-Terrorists");
	menu.AddItem("@t", "Terrorists");
	menu.AddItem("@dead", "Dead players");
	menu.AddItem("@alive", "Alive players");
	if(g_Plugin_AdvancedTargeting)
		menu.AddItem("@!friends", "Not Steam friend");
	else
		menu.AddItem("", "", ITEMDRAW_RAWLINE);

	// Count valid players and insert id's into aClients array
	int Players = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i != client && IsClientInGame(i) && !IsFakeClient(i))
			aClients[Players++] = i;
	}

	// insert player names into g_PlayerNames array
	for(int i = 0; i < Players; i++)
		GetClientName(aClients[i], g_PlayerNames[aClients[i]], sizeof(g_PlayerNames[]));

	// sort aClients array by player name
	SortCustom1D(aClients, Players, SortByPlayerName);

	// insert players sorted
	char aBuf[12];
	for(int i = 0; i < Players; i++)
	{
		IntToString(GetClientUserId(aClients[i]), aBuf, sizeof(aBuf));
		menu.AddItem(aBuf, g_PlayerNames[aClients[i]]);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_MuteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			if(param1 != MenuEnd_Selected)
				CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			int Style;
			char aItem[32];
			char aDisp[MAX_NAME_LENGTH + 4];
			menu.GetItem(param2, aItem, sizeof(aItem), Style, aDisp, sizeof(aDisp));

			if(Style != ITEMDRAW_DEFAULT || !aItem[0])
			{
				PrintToChat(param1, "Internal error: aItem[0] -> %d | Style -> %d", aItem[0], Style);
				return 0;
			}

			if(aItem[0] == '@')
			{
				int Flag = GetSpecialMutesFlags(aItem);
				if(Flag && g_SpecialMutes[param1] & Flag)
					UnMuteSpecial(param1, aItem);
				else
					MuteSpecial(param1, aItem);

				menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
				return 0;
			}

			int UserId = StringToInt(aItem);
			int client = GetClientOfUserId(UserId);
			if(!client)
			{
				PrintToChat(param1, "\x04[Self-Mute]\x01 Player no longer available.");
				menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
				return 0;
			}

			if(GetIgnored(param1, client))
			{
				UnIgnore(param1, client);
				PrintToChat(param1, "\x04[Self-Mute]\x01 You have self-unmuted:\x04 %N", client);
			}
			else
			{
				Ignore(param1, client);
				PrintToChat(param1, "\x04[Self-Mute]\x01 You have self-muted:\x04 %N", client);
			}
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			return 0;
		}
		case MenuAction_DrawItem:
		{
			int Style;
			char aItem[32];
			menu.GetItem(param2, aItem, sizeof(aItem), Style);

			if(!aItem[0])
				return ITEMDRAW_DISABLED;

			if(aItem[0] == '@')
			{
				int Flag = GetSpecialMutesFlags(aItem);
				if(Flag & MUTE_ALL)
					return Style;
				else if(g_SpecialMutes[param1] & MUTE_ALL)
					return ITEMDRAW_DISABLED;

				return Style;
			}

			int UserId = StringToInt(aItem);
			int client = GetClientOfUserId(UserId);
			if(!client) // Player disconnected
				return ITEMDRAW_DISABLED;

			return Style;
		}
		case MenuAction_DisplayItem:
		{
			int Style;
			char aItem[32];
			char aDisp[MAX_NAME_LENGTH + 4];
			menu.GetItem(param2, aItem, sizeof(aItem), Style, aDisp, sizeof(aDisp));

			// Start of current page
			if((param2 + 1) % 7 == 1)
			{
				if(aItem[0] == '@')
					menu.SetTitle("[Self-Mute] Groups");
				else if(param2 == 0)
					menu.SetTitle("[Self-Mute] Talking players");
				else
					menu.SetTitle("[Self-Mute] All players");
			}

			if(!aItem[0])
				return 0;

			if(aItem[0] == '@')
			{
				int Flag = GetSpecialMutesFlags(aItem);
				if(Flag && g_SpecialMutes[param1] & Flag)
				{
					char aBuf[32] = "[M] ";
					FormatSpecialMutes(Flag, aBuf, sizeof(aBuf));
					if(!StrEqual(aDisp, aBuf))
						return RedrawMenuItem(aBuf);
				}

				return 0;
			}

			int UserId = StringToInt(aItem);
			int client = GetClientOfUserId(UserId);
			if(!client) // Player disconnected
			{
				char aBuf[MAX_NAME_LENGTH + 4] = "[D] ";
				StrCat(aBuf, sizeof(aBuf), aDisp);
				if(!StrEqual(aDisp, aBuf))
					return RedrawMenuItem(aBuf);
			}

			if(GetIgnored(param1, client))
			{
				char aBuf[MAX_NAME_LENGTH + 4] = "[M] ";
				GetClientName(client, g_PlayerNames[client], sizeof(g_PlayerNames[]));
				StrCat(aBuf, sizeof(aBuf), g_PlayerNames[client]);
				if(!StrEqual(aDisp, aBuf))
					return RedrawMenuItem(aBuf);
			}
			else
			{
				GetClientName(client, g_PlayerNames[client], sizeof(g_PlayerNames[]));
				if(!StrEqual(aDisp, g_PlayerNames[client]))
					return RedrawMenuItem(g_PlayerNames[client]);
			}

			return 0;
		}
	}

	return 0;
}

void DisplayUnMuteMenu(int client)
{
	// TODO: Implement me
}

/*
 * HOOKS
*/
int g_MsgDest;
int g_MsgClient;
char g_MsgName[256];
char g_MsgParam1[256];
char g_MsgParam2[256];
char g_MsgParam3[256];
char g_MsgParam4[256];
int g_MsgPlayersNum;
int g_MsgPlayers[MAXPLAYERS + 1];

int g_TimerDerp = 0;

public Action Hook_UserMessageRadioText(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	g_MsgDest = BfReadByte(bf);
	g_MsgClient = BfReadByte(bf);
	BfReadString(bf, g_MsgName, sizeof(g_MsgName), false);
	BfReadString(bf, g_MsgParam1, sizeof(g_MsgParam1), false);
	BfReadString(bf, g_MsgParam2, sizeof(g_MsgParam2), false);
	BfReadString(bf, g_MsgParam3, sizeof(g_MsgParam3), false);
	BfReadString(bf, g_MsgParam4, sizeof(g_MsgParam4), false);

	g_MsgPlayersNum = playersNum;
	for(int i = 0; i < playersNum; i++)
		g_MsgPlayers[i] = players[i];

	if(!g_TimerDerp)
		CreateTimer(0.1, Timer_PlayerRadio);

	g_TimerDerp++;
	if(g_TimerDerp > 1)
		PrintToServer("DEBUG: Timer_PlayerRadio derped! (%d)", g_TimerDerp);

	return Plugin_Handled;
}

char g_MsgRadioSound[256];

public Action Hook_UserMessageSendAudio(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	BfReadString(bf, g_MsgRadioSound, sizeof(g_MsgRadioSound), false);

	return Plugin_Handled;
}

public Action Timer_PlayerRadio(Handle timer)
{
	g_TimerDerp = 0;
	if(g_MsgClient == -1)
		return Plugin_Continue;

	int[] players = new int[g_MsgPlayersNum + 1];
	int playersNum = 0;

	for(int i = 0; i < g_MsgPlayersNum; i++)
	{
		int client = g_MsgPlayers[i];
		if(IsClientInGame(client) && !GetIgnored(client, g_MsgClient))
			players[playersNum++] = client;
	}

	Handle RadioText = StartMessage("RadioText", players, playersNum, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
	BfWriteByte(RadioText, g_MsgDest);
	BfWriteByte(RadioText, g_MsgClient);
	BfWriteString(RadioText, g_MsgName);
	BfWriteString(RadioText, g_MsgParam1);
	BfWriteString(RadioText, g_MsgParam2);
	BfWriteString(RadioText, g_MsgParam3);
	BfWriteString(RadioText, g_MsgParam4);
	EndMessage();

	Handle SendAudio = StartMessage("SendAudio", players, playersNum, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
	BfWriteString(SendAudio, g_MsgRadioSound);
	EndMessage();

	g_MsgClient = -1;

	return Plugin_Continue;
}

/*
 * HELPERS
*/
void UpdateIgnored()
{
	if(g_Plugin_ccc)
		CCC_UpdateIgnoredArray(g_Ignored);
}

public int SortByPlayerName(int elem1, int elem2, const int[] array, Handle hndl)
{
	return strcmp(g_PlayerNames[elem1], g_PlayerNames[elem2], false);
}

bool GetIgnored(int client, int target)
{
	return g_Ignored[(client * (MAXPLAYERS + 1) + target)];
}

void SetIgnored(int client, int target, bool ignored)
{
	g_Ignored[(client * (MAXPLAYERS + 1) + target)] = ignored;
}

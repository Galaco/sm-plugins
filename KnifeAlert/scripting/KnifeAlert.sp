#pragma semicolon 1

#include <sourcemod>
#include "morecolors.inc"

#pragma newdecls required

Handle g_hCVar_NotificationTime = INVALID_HANDLE;
char g_sAttackerSID[MAXPLAYERS + 1][32];
int g_iNotificationTime[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name         = "Knife Notifications",
	author       = "Obus + BotoX",
	description  = "Notify administrators when zombies have been knifed by humans.",
	version      = "2.1",
	url          = ""
};

public void OnPluginStart()
{
	g_hCVar_NotificationTime = CreateConVar("sm_knifenotifytime", "5", "Amount of time to pass before a knifed zombie is considered \"not knifed\" anymore.", 0, true, 0.0, true, 60.0);

	if(!HookEventEx("player_hurt", Event_PlayerHurt, EventHookMode_Pre))
		SetFailState("[Knife-Notifications] Failed to hook \"player_hurt\" event.");
}

public int GetClientFromSteamID(const char[] auth)
{
	char clientAuth[32];

	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientAuthorized(client))
			continue;

		GetClientAuthId(client, AuthId_Steam2, clientAuth, sizeof(clientAuth));

		if(StrEqual(auth, clientAuth))
			return client;
	}

	return -1;
}

public Action Event_PlayerHurt(Handle hEvent, const char[] name, bool dontBroadcast)
{
	int victim;
	int attacker;
	char sWepName[64];
	char sAtkSID[32];
	char sVictSID[32];
	GetEventString(hEvent, "weapon", sWepName, sizeof(sWepName));

	if((victim = GetClientOfUserId(GetEventInt(hEvent, "userid"))) == 0)
		return;

	if((attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"))) == 0)
		return;

	if(!IsClientInGame(victim) || !IsPlayerAlive(victim))
		return;

	if(!IsClientInGame(attacker) || !IsPlayerAlive(attacker))
		return;

	if(victim != attacker && GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 3)
	{
		if(StrEqual(sWepName, "knife"))
		{
			int damage = GetEventInt(hEvent, "dmg_health");

			if(damage < 35)
				return;

			GetClientAuthId(attacker, AuthId_Steam2, sAtkSID, sizeof(sAtkSID));
			GetClientAuthId(attacker, AuthId_Steam2, g_sAttackerSID[victim], sizeof(g_sAttackerSID[]));
			GetClientAuthId(victim, AuthId_Steam2, sVictSID, sizeof(sVictSID));
			LogMessage("%L knifed %L", attacker, victim);

			g_iNotificationTime[victim] = (GetTime() + GetConVarInt(g_hCVar_NotificationTime));

			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientConnected(i) && IsClientInGame(i) && (IsClientSourceTV(i) || GetAdminFlag(GetUserAdmin(i), Admin_Generic)))
					CPrintToChat(i, "{green}[SM] {blue}%N {default}knifed {red}%N", attacker, victim);
			}
		}
	}
	else if(victim != attacker && GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
	{
		int pOldKnifer;
		pOldKnifer = GetClientFromSteamID(g_sAttackerSID[attacker]);

		if(g_iNotificationTime[attacker] > GetTime() && (victim != pOldKnifer))
		{
			char sAtkAttackerName[MAX_NAME_LENGTH];
			GetClientAuthId(attacker, AuthId_Steam2, sAtkSID, sizeof(sAtkSID));

			if(pOldKnifer != -1)
			{
				GetClientName(pOldKnifer, sAtkAttackerName, sizeof(sAtkAttackerName));
				LogMessage("%L killed %L (Recently knifed by %L)", attacker, victim, pOldKnifer);
			}
			else
				LogMessage("%L killed %L (Recently knifed by a disconnected player [%s])", attacker, victim, g_sAttackerSID[attacker]);

			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientConnected(i) && IsClientInGame(i) && (IsClientSourceTV(i) || GetAdminFlag(GetUserAdmin(i), Admin_Generic)))
					CPrintToChat(i, "{green}[SM] {red}%N {green}(%s){default} killed {blue}%N{default} - knifed by {blue}%s {green}(%s)",
						attacker, sAtkSID, victim, (pOldKnifer != -1) ? sAtkAttackerName : "a disconnected player", g_sAttackerSID[attacker]);
			}
		}
	}
}

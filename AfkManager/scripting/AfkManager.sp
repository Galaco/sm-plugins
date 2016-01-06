#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define AFK_CHECK_INTERVAL 5.0

bool g_Players_bEnabled[MAXPLAYERS + 1];
bool g_Players_bFlagged[MAXPLAYERS + 1];
int g_Players_iLastAction[MAXPLAYERS + 1];
float g_Players_fEyePosition[MAXPLAYERS + 1][3];
int g_Players_iButtons[MAXPLAYERS + 1];
int g_Players_iSpecMode[MAXPLAYERS + 1];
int g_Players_iSpecTarget[MAXPLAYERS + 1];

float g_fKickTime;
float g_fMoveTime;
float g_fWarnTime;
int g_iKickMinPlayers;
int g_iMoveMinPlayers;
int g_iImmunity;

public Plugin myinfo =
{
	name = "Good AFK Manager",
	author = "BotoX",
	description = "A good AFK manager?",
	version = "1.0",
	url = ""
};

public Cvar_KickTime(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	g_fKickTime = GetConVarFloat(cvar);
}
public Cvar_MoveTime(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	g_fMoveTime = GetConVarFloat(cvar);
}
public Cvar_WarnTime(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	g_fWarnTime = GetConVarFloat(cvar);
}
public Cvar_KickMinPlayers(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	g_iKickMinPlayers = GetConVarInt(cvar);
}
public Cvar_MoveMinPlayers(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	g_iMoveMinPlayers = GetConVarInt(cvar);
}
public Cvar_Immunity(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	g_iImmunity = GetConVarInt(cvar);
}

public OnPluginStart()
{
	Handle cvar;
	HookConVarChange((cvar = CreateConVar("sm_afk_move_min", "4", "Min players for AFK move")), Cvar_MoveMinPlayers);
	g_iMoveMinPlayers = GetConVarInt(cvar);

	HookConVarChange((cvar = CreateConVar("sm_afk_kick_min", "6", "Min players for AFK kick")), Cvar_KickMinPlayers);
	g_iKickMinPlayers = GetConVarInt(cvar);

	HookConVarChange((cvar = CreateConVar("sm_afk_move_time", "60.0", "Time in seconds for AFK Move. 0 = DISABLED")), Cvar_MoveTime);
	g_fMoveTime = GetConVarFloat(cvar);

	HookConVarChange((cvar = CreateConVar("sm_afk_kick_time", "120.0", "Time in seconds to AFK Kick. 0 = DISABLED")), Cvar_KickTime);
	g_fKickTime = GetConVarFloat(cvar);

	HookConVarChange((cvar = CreateConVar("sm_afk_warn_time", "30.0", "Time in seconds remaining before warning")), Cvar_WarnTime);
	g_fWarnTime = GetConVarFloat(cvar);

	HookConVarChange((cvar = CreateConVar("sm_afk_immunity", "1", "AFK admins immunity: 0 = DISABLED, 1 = COMPLETE, 2 = KICK, 3 = MOVE")), Cvar_Immunity);
	g_iImmunity = GetConVarInt(cvar);

	CloseHandle(cvar);

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	HookEvent("player_team", Event_PlayerTeamPost, EventHookMode_Post);

	AutoExecConfig(true, "plugin.AfkManager");
}

public OnMapStart()
{
	CreateTimer(AFK_CHECK_INTERVAL, Timer_CheckPlayer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	for (int Index = 1; Index <= MaxClients; Index++)
	{
		g_Players_bEnabled[Index] = false;
		if (IsClientConnected(Index) && IsClientInGame(Index) && !IsFakeClient(Index))
			InitializePlayer(Index);
	}
}

CheckAdminImmunity(Index)
{
	AdminId Id = GetUserAdmin(Index);
	return GetAdminFlag(Id, Admin_Generic);
}

ResetPlayer(Index)
{
	g_Players_bEnabled[Index] = false;
	g_Players_bFlagged[Index] = false;
	g_Players_iLastAction[Index] = 0;
	g_Players_fEyePosition[Index] = Float:{0.0, 0.0, 0.0};
	g_Players_iButtons[Index] = 0;
	g_Players_iSpecMode[Index] = 0;
	g_Players_iSpecTarget[Index] = 0;
}

InitializePlayer(Index)
{
	if (!(g_iImmunity == 1 && CheckAdminImmunity(Index)))
	{
		ResetPlayer(Index);
		g_Players_iLastAction[Index] = GetTime();
		g_Players_bEnabled[Index] = true;
	}
}

public OnClientPostAdminCheck(Index)
{
	if (!IsFakeClient(Index))
		InitializePlayer(Index);
}

public OnClientDisconnect(Index)
{
	ResetPlayer(Index);
}

public Action:Event_PlayerTeamPost(Handle:event, const String:name[], bool:dontBroadcast)
{
	int Index = GetClientOfUserId(GetEventInt(event, "userid"));
	if (Index > 0 && !IsFakeClient(Index))
	{
		if (!g_Players_bEnabled[Index])
			InitializePlayer(Index);
		g_Players_iLastAction[Index] = GetTime();
	}
}

public Action:Command_Say(Index, const String:Command[], Args)
{
	g_Players_iLastAction[Index] = GetTime();
}

public Action:OnPlayerRunCmd(Index, &iButtons, &iImpulse, Float:fVel[3], Float:fAngles[3], &iWeapon)
{
	if (((g_Players_fEyePosition[Index][0] != fAngles[0]) ||
		(g_Players_fEyePosition[Index][1] != fAngles[1]) ||
		(g_Players_fEyePosition[Index][2] != fAngles[2]))
		&& g_Players_iSpecMode[Index] != 4) // OBS_MODE_IN_EYE
	{
		if(!((iButtons & IN_LEFT) || (iButtons & IN_RIGHT)))
			g_Players_iLastAction[Index] = GetTime();

		g_Players_fEyePosition[Index] = fAngles;
	}

	if(g_Players_iButtons[Index] != iButtons)
	{
		g_Players_iLastAction[Index] = GetTime();
		g_Players_iButtons[Index] = iButtons;
	}

	return Plugin_Continue;
}

public Action:Timer_CheckPlayer(Handle:Timer, any:Data)
{
	int Index;
	int Clients = 0;

	for (Index = 1; Index <= MaxClients; Index++)
	{
		if (IsClientInGame(Index) && !IsFakeClient(Index))
			Clients++;
	}

	bool bMovePlayers = (Clients >= g_iMoveMinPlayers && g_fMoveTime > 0.0);
	bool bKickPlayers = (Clients >= g_iKickMinPlayers && g_fKickTime > 0.0);

	if (!bMovePlayers && !bKickPlayers)
		return Plugin_Continue;

	for (Index = 1; Index <= MaxClients; Index++)
	{
		if (!g_Players_bEnabled[Index] || !IsClientInGame(Index)) // Is this player actually in the game?
			continue;

		int iTeamNum = GetClientTeam(Index);

		if (IsClientObserver(Index))
		{
			if (iTeamNum > CS_TEAM_SPECTATOR && !IsPlayerAlive(Index))
				continue;

			int iSpecMode = g_Players_iSpecMode[Index];
			int iSpecTarget = g_Players_iSpecTarget[Index];

			g_Players_iSpecMode[Index] = GetEntProp(Index, Prop_Send, "m_iObserverMode");
			g_Players_iSpecTarget[Index] = GetEntPropEnt(Index, Prop_Send, "m_hObserverTarget");

			if ((iSpecMode && g_Players_iSpecMode[Index] != iSpecMode) || (iSpecTarget && g_Players_iSpecTarget[Index] != iSpecTarget))
				g_Players_iLastAction[Index] = GetTime();
		}

		int IdleTime = GetTime() - g_Players_iLastAction[Index];

		if (g_Players_bFlagged[Index] && (g_fKickTime - IdleTime) > 0.0)
		{
			PrintCenterText(Index, "Welcome back!");
			PrintToChat(Index, "\x04[AFK] \x01You have been un-flagged for being inactive.");
			g_Players_bFlagged[Index] = false;
		}

		if (bMovePlayers && iTeamNum > CS_TEAM_SPECTATOR && ( !g_iImmunity || g_iImmunity == 2 || !CheckAdminImmunity(Index)))
		{
			float iTimeleft = g_fMoveTime - IdleTime;
			if (iTimeleft > 0.0)
			{
				if(iTimeleft <= g_fWarnTime)
				{
					PrintCenterText(Index, "Warning: If you do not move in %d seconds, you will be moved to spectate.", RoundToFloor(iTimeleft));
					PrintToChat(Index, "\x04[AFK] \x01Warning: If you do not move in %d seconds, you will be moved to spectate.", RoundToFloor(iTimeleft));
				}
			}
			else
			{
				decl String:f_Name[MAX_NAME_LENGTH+4];
				Format(f_Name, sizeof(f_Name), "\x03%N\x01", Index);
				PrintToChatAll("\x04[AFK] \x01%s was moved to spectate for being AFK too long.", f_Name);
				ForcePlayerSuicide(Index);
				ChangeClientTeam(Index, CS_TEAM_SPECTATOR);
			}
		}
		else if (g_fKickTime > 0.0 && (!g_iImmunity || g_iImmunity == 3 || !CheckAdminImmunity(Index)))
		{
			float iTimeleft = g_fKickTime - IdleTime;
			if (iTimeleft > 0.0)
			{
				if (iTimeleft <= g_fWarnTime)
				{
					PrintCenterText(Index, "Warning: If you do not move in %d seconds, you will be kick-flagged for being inactive.", RoundToFloor(iTimeleft));
					PrintToChat(Index, "\x04[AFK] \x01Warning: If you do not move in %d seconds, you will be kick-flagged for being inactive.", RoundToFloor(iTimeleft));
				}
			}
			else
			{
				if (!g_Players_bFlagged[Index])
				{
					PrintToChat(Index, "\x04[AFK] \x01You have been kick-flagged for being inactive.");
					g_Players_bFlagged[Index] = true;
				}
				int FlaggedPlayers = 0;
				int Position = 1;
				for (int Index_ = 1; Index_ <= MaxClients; Index_++)
				{
					if (!g_Players_bFlagged[Index_])
						continue;

					FlaggedPlayers++;
					int IdleTime_ = GetTime() - g_Players_iLastAction[Index_];

					if (IdleTime_ > IdleTime)
						Position++;
				}
				PrintCenterText(Index, "You have been kick-flagged for being inactive. [%d/%d]", Position, FlaggedPlayers);
			}
		}
	}

	while(bKickPlayers)
	{
		int InactivePlayer = -1;
		int InactivePlayerTime = 0;

		for (Index = 1; Index <= MaxClients; Index++)
		{
			if (!g_Players_bFlagged[Index])
				continue;

			int IdleTime = GetTime() - g_Players_iLastAction[Index];

			if (IdleTime > InactivePlayerTime)
			{
				InactivePlayer = Index;
				InactivePlayerTime = IdleTime;
			}
		}

		if (InactivePlayer == -1)
			break;
		else
		{
			decl String:f_Name[MAX_NAME_LENGTH+4];
			Format(f_Name, sizeof(f_Name), "\x03%N\x01", InactivePlayer);
			PrintToChatAll("\x04[AFK] %s was kicked for being AFK too long. (%d seconds)", f_Name, InactivePlayerTime);
			KickClient(InactivePlayer, "[AFK] You were kicked for being AFK too long. (%d seconds)", InactivePlayerTime);
			Clients--;
			g_Players_bFlagged[InactivePlayer] = false;
		}

		bKickPlayers = (Clients >= g_iKickMinPlayers && g_fKickTime > 0.0);
	}

	return Plugin_Continue;
}

#pragma semicolon 1

#include <sourcemod>
#include <sdktools_entoutput>
#include <sdktools_entinput>
#include <sdktools_engine>
#include <sdkhooks>
#include <dhooks>

public Plugin:myinfo =
{
	name = "FixGameUI",
	author = "hlstriker + GoD-Tony",
	description = "Fixes game_ui entity bug.",
	version = "1.0",
	url = ""
}

new g_iAttachedGameUI[MAXPLAYERS+1];
new Handle:g_hAcceptInput = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

	HookEntityOutput("game_ui", "PlayerOn", GameUI_PlayerOn);
	HookEntityOutput("game_ui", "PlayerOff", GameUI_PlayerOff);

	// Gamedata.
	new Handle:hConfig = LoadGameConfigFile("FixGameUI.games");
	if (hConfig == INVALID_HANDLE)
	{
		SetFailState("Could not find gamedata file: FixGameUI.games.txt");
	}

	new offset = GameConfGetOffset(hConfig, "AcceptInput");
	if (offset == -1)
	{
		SetFailState("Failed to find AcceptInput offset");
	}
	CloseHandle(hConfig);

	// DHooks.
	g_hAcceptInput = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, Hook_AcceptInput);
	DHookAddParam(g_hAcceptInput, HookParamType_CharPtr);
	DHookAddParam(g_hAcceptInput, HookParamType_CBaseEntity);
	DHookAddParam(g_hAcceptInput, HookParamType_CBaseEntity);
	DHookAddParam(g_hAcceptInput, HookParamType_Object, 20); //varaint_t is a union of 12 (float[3]) plus two int type params 12 + 8 = 20
	DHookAddParam(g_hAcceptInput, HookParamType_Int);

}

public Action:Event_PlayerDeath(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	RemoveFromGameUI(iClient);
	SetClientViewEntity(iClient, iClient);

	new iFlags = GetEntityFlags(iClient);
	iFlags &= ~FL_ONTRAIN;
	iFlags &= ~FL_FROZEN;
	iFlags &= ~FL_ATCONTROLS;
	SetEntityFlags(iClient, iFlags);
}

public OnClientDisconnect(iClient)
{
	RemoveFromGameUI(iClient);
}

public GameUI_PlayerOn(const String:szOutput[], iCaller, iActivator, Float:fDelay)
{
	if(!(1 <= iActivator <= MaxClients))
		return;

	g_iAttachedGameUI[iActivator] = EntIndexToEntRef(iCaller);
}

public GameUI_PlayerOff(const String:szOutput[], iCaller, iActivator, Float:fDelay)
{
	if(!(1 <= iActivator <= MaxClients))
		return;

	g_iAttachedGameUI[iActivator] = 0;
}

RemoveFromGameUI(iClient)
{
	if(!g_iAttachedGameUI[iClient])
		return;

	new iEnt = EntRefToEntIndex(g_iAttachedGameUI[iClient]);
	if(iEnt == INVALID_ENT_REFERENCE)
		return;

	AcceptEntityInput(iEnt, "Deactivate", iClient, iEnt);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "game_ui"))
	{
		DHookEntity(g_hAcceptInput, false, entity);
	}
}

public MRESReturn:Hook_AcceptInput(thisptr, Handle:hReturn, Handle:hParams)
{
	new String:sCommand[128];
	DHookGetParamString(hParams, 1, sCommand, sizeof(sCommand));

	if (StrEqual(sCommand, "Deactivate"))
	{
		new pPlayer = GetEntPropEnt(thisptr, Prop_Data, "m_player");

		if (pPlayer == -1)
		{
			// Manually disable think.
			SetEntProp(thisptr, Prop_Data, "m_nNextThinkTick", -1);

			DHookSetReturn(hReturn, false);
			return MRES_Supercede;
		}
	}

	DHookSetReturn(hReturn, true);
	return MRES_Ignored;
}

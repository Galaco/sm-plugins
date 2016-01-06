#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <zombiereloaded>

public Plugin:myinfo =
{
	name 			= "KevlarEquip",
	author 			= "BotoX",
	description 	= "Equip players with kevlar when they spawn, unglitch kevlar and strip it when you get infected",
	version 		= "2.0",
	url 			= ""
};

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_SpawnPost, Hook_OnPlayerSpawn);
}

public Hook_OnPlayerSpawn(client)
{
	if(IsPlayerAlive(client) && ZR_IsClientHuman(client))
	{
		SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
		// Reset last hitgroup to generic - fixes kevlar bug
		// Example: You get hit in the head by a bullet as a zombie
		// the round ends, you spawn as a human.
		// You get damaged by a trigger, the game still thinks you
		// are getting damaged in the head hitgroup, >mfw source engine.
		// Thanks to leaked 2007 Source Engine Code.
		SetEntData(client, 4444, 0, 4);
	}
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if(IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Send, "m_ArmorValue", 0, 1);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
	}
}

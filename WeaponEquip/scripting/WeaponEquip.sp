#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <zombiereloaded>

#pragma newdecls required

Handle g_hCvar_WeaponSecondary = INVALID_HANDLE;
Handle g_hCvar_WeaponPrimary = INVALID_HANDLE;

public Plugin myinfo =
{
	name			= "WeaponEquip",
	author			= "zaCade + BotoX",
	description		= "Equip players with weapons when they spawn",
	version			= "2.0",
	url				= ""
};

public void OnPluginStart()
{
	g_hCvar_WeaponSecondary = CreateConVar("sm_weaponequip_secondary", "weapon_elite", "The name of the secondary weapon to give.", FCVAR_PLUGIN);
	g_hCvar_WeaponPrimary = CreateConVar("sm_weaponequip_primary", "weapon_p90", "The name of the secondary weapon to give.", FCVAR_PLUGIN);

	AutoExecConfig(true, "plugin.WeaponEquip");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SpawnPost, Hook_OnPlayerSpawn);
}

public void Hook_OnPlayerSpawn(int client)
{
	if(IsPlayerAlive(client) && ZR_IsClientHuman(client))
	{
		static char sSecondary[32];
		GetConVarString(g_hCvar_WeaponSecondary, sSecondary, sizeof(sSecondary));

		static char sPrimary[32];
		GetConVarString(g_hCvar_WeaponPrimary, sPrimary, sizeof(sPrimary));

		int Secondary = -1;
		if((Secondary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY)) != -1)
			RemoveEdict(Secondary);

		int Primary = -1;
		if((Primary = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)) != -1)
			RemoveEdict(Primary);

		int Grenade = -1;
		while((Grenade = GetPlayerWeaponSlot(client, CS_SLOT_GRENADE)) != -1)
			RemoveEdict(Grenade);

		GivePlayerItem(client, sSecondary);
		GivePlayerItem(client, sPrimary);
		GivePlayerItem(client, "weapon_hegrenade");
	}
}

#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define TIMER_INTERVAL 1.0
Handle g_hTimer = INVALID_HANDLE;

ConVar g_CVar_MaxWeapons;
ConVar g_CVar_WeaponLifetime;

new g_RealRoundStartedTime;
new g_MaxWeapons;
new g_MaxWeaponLifetime;

#define MAX_WEAPONS MAXPLAYERS
new G_WeaponArray[MAX_WEAPONS][2];


public Plugin myinfo =
{
	name 			= "WeaponCleaner",
	author 			= "BotoX",
	description 	= "Clean unneeded weapons",
	version 		= "2.0",
	url 			= ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_sweep", Command_CleanupWeapons, ADMFLAG_GENERIC, "Cleans up all the weapons on the map unless they have a HammerID attached to them.");

	g_CVar_MaxWeapons = CreateConVar("sm_weaponcleaner_max", "5", "The maximum amount of weapons allowed in the game.", 0, true, 0.0, true, MAX_WEAPONS - 1.0);
	g_MaxWeapons = g_CVar_MaxWeapons.IntValue;
	g_CVar_MaxWeapons.AddChangeHook(OnConVarChanged);

	g_CVar_WeaponLifetime = CreateConVar("sm_weaponcleaner_lifetime", "15", "The maximum amount of time in seconds a weapon is allowed in the game.", 0, true, 0.0);
	g_MaxWeaponLifetime = g_CVar_WeaponLifetime.IntValue;
	g_CVar_WeaponLifetime.AddChangeHook(OnConVarChanged);

	HookEvent("round_start", Event_RoundStart);

	AutoExecConfig(true, "plugin.WeaponCleaner");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == g_CVar_MaxWeapons)
	{
		if(StringToInt(newValue) < StringToInt(oldValue))
		{
			// Need to shrink list and kill items
			new d = StringToInt(oldValue) - StringToInt(newValue);

			// Kill items that don't have space anymore
			for(new i = 0; d && i < g_MaxWeapons; i++)
			{
				if(!G_WeaponArray[i][0])
					continue;

				// Kill it
				AcceptEntityInput(G_WeaponArray[0][0], "Kill");
				// This implicitly calls OnEntityDestroyed() which calls RemoveWeapon()

				// Move index backwards (since the list was modified by removing it)
				i--;
				d--;
			}
		}
		g_MaxWeapons = StringToInt(newValue);
	}
	else if(convar == g_CVar_WeaponLifetime)
	{
		g_MaxWeaponLifetime = StringToInt(newValue);
		CheckWeapons();
	}
}

public void OnMapStart()
{
	if(g_hTimer != INVALID_HANDLE && CloseHandle(g_hTimer))
		g_hTimer = INVALID_HANDLE;

	g_hTimer = CreateTimer(TIMER_INTERVAL, Timer_CleanupWeapons, INVALID_HANDLE, TIMER_REPEAT);
}

public void OnMapEnd()
{
	if(g_hTimer != INVALID_HANDLE && CloseHandle(g_hTimer))
		g_hTimer = INVALID_HANDLE;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDrop);
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponDropPost, OnWeaponDrop);
	SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(IsValidEntity(entity) && strncmp(classname, "weapon_", 7) == 0)
	{
		SDKHook(entity, SDKHook_Spawn, OnWeaponSpawned);
	}
}

public void OnEntityDestroyed(int entity)
{
	RemoveWeapon(entity);
}

public void OnWeaponSpawned(int entity)
{
	new HammerID = GetEntProp(entity, Prop_Data, "m_iHammerID");
	// Should not be cleaned since it's a map spawned weapon
	if(HammerID)
		return;

	// Weapon doesn't belong to any player
	if(GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") == -1)
		InsertWeapon(entity);
}

public Action OnWeaponEquip(int client, int entity)
{
	if(!IsValidEntity(entity))
		return;

	new HammerID = GetEntProp(entity, Prop_Data, "m_iHammerID");
	// Should not be cleaned since it's a map spawned weapon
	if(HammerID)
		return;

	// Weapon should not be cleaned anymore
	RemoveWeapon(entity);
}

public Action OnWeaponDrop(int client, int entity)
{
	if(!IsValidEntity(entity))
		return;

	new HammerID = GetEntProp(entity, Prop_Data, "m_iHammerID");
	// Should not be cleaned since it's a map spawned weapon
	if(HammerID)
		return;

	// Kill all dropped weapons during mp_freezetime
	if(GetTime() < g_RealRoundStartedTime)
	{
		// Kill it
		AcceptEntityInput(entity, "Kill");
		return;
	}

	// Weapon should be cleaned again
	InsertWeapon(entity);
}

bool InsertWeapon(int entity)
{
	// Try to find a free slot
	for(new i = 0; i < g_MaxWeapons; i++)
	{
		if(G_WeaponArray[i][0])
			continue;

		// Found a free slot, add it here
		G_WeaponArray[i][0] = entity;
		G_WeaponArray[i][1] = GetTime();
		return true;
	}

	// No free slot found
	// Kill the first (oldest) item in the list
	AcceptEntityInput(G_WeaponArray[0][0], "Kill");
	// This implicitly calls OnEntityDestroyed() which calls RemoveWeapon()

	// Add new weapon to the end of the list
	G_WeaponArray[g_MaxWeapons - 1][0] = entity;
	G_WeaponArray[g_MaxWeapons - 1][1] = GetTime();
	return true;
}

bool RemoveWeapon(int entity)
{
	// Find the Weapon
	for(new i = 0; i < g_MaxWeapons; i++)
	{
		if(G_WeaponArray[i][0] == entity)
		{
			G_WeaponArray[i][0] = 0; G_WeaponArray[i][1] = 0;

			// Move list items in front of this index back by one
			for(new j = i + 1; j < g_MaxWeapons; j++)
			{
				G_WeaponArray[j - 1][0] = G_WeaponArray[j][0];
				G_WeaponArray[j - 1][1] = G_WeaponArray[j][1];
			}

			// Reset last list item
			G_WeaponArray[g_MaxWeapons - 1][0] = 0;
			G_WeaponArray[g_MaxWeapons - 1][1] = 0;

			return true;
		}
	}
	return false;
}

bool CheckWeapons()
{
	for(new i = 0; i < g_MaxWeapons; i++)
	{
		if(!G_WeaponArray[i][0])
			continue;

		if(GetTime() - G_WeaponArray[i][1] >= g_MaxWeaponLifetime)
		{
			// Kill it
			AcceptEntityInput(G_WeaponArray[i][0], "Kill");
			// This implicitly calls OnEntityDestroyed() which calls RemoveWeapon()

			// Move index backwards (since the list was modified by removing it)
			i--;
		}
	}
	return true;
}

void CleanupWeapons()
{
	for(new i = 0; i < g_MaxWeapons; i++)
	{
		if(!G_WeaponArray[i][0])
			continue;

		// Kill it
		AcceptEntityInput(G_WeaponArray[i][0], "Kill");
		// This implicitly calls OnEntityDestroyed() which calls RemoveWeapon()

		// Move index backwards (since the list was modified by removing it)
		i--;
	}
}

public Action Event_RoundStart(Handle:event, const char[] name, bool:dontBroadcast)
{
	for(new i = 0; i < MAX_WEAPONS; i++)
	{
		G_WeaponArray[i][0] = 0; G_WeaponArray[i][1] = 0;
	}
	g_RealRoundStartedTime = GetTime() + GetConVarInt(FindConVar("mp_freezetime"));
}

public Action Timer_CleanupWeapons(Handle:timer)
{
	CheckWeapons();
}

public Action Command_CleanupWeapons(client, args)
{
	CleanupWeapons();

	LogAction(client, -1, "%L performed a weapons cleanup", client);
	PrintToChat(client, "[SM] Weapons cleaned successfully!");
}

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

bool g_bInBuyZoneAll = false;
bool g_bInBuyZone[MAXPLAYERS + 1] = {false, ...};

bool g_bInfAmmoHooked = false;
bool g_bInfAmmoAll = false;
bool g_bInfAmmo[MAXPLAYERS + 1] = {false, ...};

ConVar g_CVar_sv_pausable;
bool g_bPaused;

public Plugin:myinfo =
{
	name = "Advanced Commands",
	author = "BotoX",
	description = "Adds: hp, kevlar, weapon, strip, buyzone, iammo, speed",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_hp", Command_Health, ADMFLAG_GENERIC, "sm_hp <#userid|name> <value>");
	RegAdminCmd("sm_kevlar", Command_Kevlar, ADMFLAG_GENERIC, "sm_kevlar <#userid|name> <value>");
	RegAdminCmd("sm_weapon", Command_Weapon, ADMFLAG_GENERIC, "sm_weapon <#userid|name> <name> [clip] [ammo]");
	RegAdminCmd("sm_give", Command_Weapon, ADMFLAG_GENERIC, "sm_give <#userid|name> <name> [clip] [ammo]");
	RegAdminCmd("sm_strip", Command_Strip, ADMFLAG_GENERIC, "sm_strip <#userid|name>");
	RegAdminCmd("sm_buyzone", Command_BuyZone, ADMFLAG_CUSTOM3, "sm_buyzone <#userid|name> <0|1>");
	RegAdminCmd("sm_iammo", Command_InfAmmo, ADMFLAG_CUSTOM3, "sm_iammo <#userid|name> <0|1>");
	RegAdminCmd("sm_speed", Command_Speed, ADMFLAG_CUSTOM3, "sm_speed <#userid|name> <0|1>");

	HookEvent("bomb_planted", Event_BombPlanted, EventHookMode_Pre);
	HookEvent("bomb_defused", Event_BombDefused, EventHookMode_Pre);

	g_CVar_sv_pausable = FindConVar("sv_pausable");
	if(g_CVar_sv_pausable)
		AddCommandListener(Listener_Pause, "pause");
}

public OnMapStart()
{
	g_bInBuyZoneAll = false;
	g_bInfAmmoAll = false;
	if(g_bInfAmmoHooked)
	{
		UnhookEvent("weapon_fire", Event_WeaponFire);
		g_bInfAmmoHooked = false;
	}

	/* Handle late load */
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			g_bInfAmmo[i] = false;
			g_bInBuyZone[i] = false;
			SDKHook(i, SDKHook_PreThink, OnPreThink);
			SDKHook(i, SDKHook_PostThinkPost, OnPostThinkPost);
		}
	}
}

public Action Listener_Pause(int client, const char[] command, int argc)
{
	if(!g_CVar_sv_pausable.BoolValue)
	{
		ReplyToCommand(client, "sv_pausable is set to 0!");
		return Plugin_Handled;
	}
	if(client == 0)
	{
		PrintToServer("[SM] Cannot use command from server console.");
		return Plugin_Handled;
	}
	if(!IsClientAuthorized(client) || !GetAdminFlag(GetUserAdmin(client), Admin_Generic))
	{
		ReplyToCommand(client, "You do not have permission to pause the game.");
		return Plugin_Handled;
	}

	ShowActivity2(client, "[SM] ", "%s the game.", g_bPaused ? "Unpaused" : "Paused");
	LogAction(client, -1, "%s the game.", g_bPaused ? "Unpaused" : "Paused");
	g_bPaused = !g_bPaused;
	return Plugin_Continue;
}


public Action:Event_BombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i < MAXPLAYERS; i++)
	{
		if(IsClientInGame(i))
			ClientCommand(i, "playgamesound \"radio/bombpl.wav\"");
	}
	return Plugin_Handled;
}

public Action:Event_BombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i < MAXPLAYERS; i++)
	{
		if(IsClientInGame(i))
			ClientCommand(i, "playgamesound \"radio/bombdef.wav\"");
	}
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	g_bInBuyZone[client] = false;
	g_bInfAmmo[client] = false;
	SDKHook(client, SDKHook_PreThink, OnPreThink);
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public OnPreThink(client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Send, "m_bInBombZone", 1);
	}
}

public OnPostThinkPost(client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_bInBuyZoneAll || g_bInBuyZone[client])
			SetEntProp(client, Prop_Send, "m_bInBuyZone", 1);
	}
}

public Event_WeaponFire(Handle:hEvent, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!g_bInfAmmoAll && !g_bInfAmmo[client])
		return;

	new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", 0);
	if(IsValidEntity(weapon))
	{
		if(weapon == GetPlayerWeaponSlot(client, 0) || weapon == GetPlayerWeaponSlot(client, 1))
		{
			if(GetEntProp(weapon, Prop_Send, "m_iState", 4, 0) == 2 && GetEntProp(weapon, Prop_Send, "m_iClip1", 4, 0))
			{
				new toAdd = 1;
				new String:weaponClassname[128];
				GetEntityClassname(weapon, weaponClassname, 128);

				if(StrEqual(weaponClassname, "weapon_glock", true) || StrEqual(weaponClassname, "weapon_famas", true))
				{
					if(GetEntProp(weapon, Prop_Data, "m_bBurstMode", 4, 0))
					{
						switch (GetEntProp(weapon, Prop_Send, "m_iClip1", 4, 0))
						{
							case 1:
							{
								toAdd = 1;
							}
							case 2:
							{
								toAdd = 2;
							}
							default:
							{
								toAdd = 3;
							}
						}
					}
				}
				SetEntProp(weapon, Prop_Send, "m_iClip1", GetEntProp(weapon, Prop_Send, "m_iClip1", 4, 0) + toAdd, 4, 0);
			}
		}
	}

	return;
}

public Action:Command_Health(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hp <#userid|name> <value>");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new amount = 0;
	decl String:arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToIntEx(arg2, amount) == 0 || amount <= 0)
	{
		ReplyToCommand(client, "[SM] Invalid Value");
		return Plugin_Handled;
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i = 0; i < target_count; i++)
	{
		SetEntProp(target_list[i], Prop_Send, "m_iHealth", amount, 1);
	}

	ShowActivity2(client, "[SM] ", "Set health to %d on target %s", amount, target_name);

	return Plugin_Handled;
}

public Action:Command_Kevlar(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_kevlar <#userid|name> <value>");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new amount = 0;
	decl String:arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToIntEx(arg2, amount) == 0 || amount <= 0)
	{
		ReplyToCommand(client, "[SM] Invalid Value");
		return Plugin_Handled;
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i = 0; i < target_count; i++)
	{
		SetEntProp(target_list[i], Prop_Send, "m_ArmorValue", amount, 1);
	}

	ShowActivity2(client, "[SM] ", "Set kevlar to %d on target %s", amount, target_name);
	LogAction(client, -1, "Set kevlar to %d on target %s", amount, target_name);

	return Plugin_Handled;
}

public Action:Command_Weapon(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_weapon <#userid|name> <weapon> [clip] [ammo]");
		return Plugin_Handled;
	}

	new ammo = 2500;
	new clip = -1;

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:arg2[65];
	GetCmdArg(2, arg2, sizeof(arg2));

	decl String:weapon[65];
	if(strncmp(arg2, "weapon_", 7) != 0 && strncmp(arg2, "item_", 5) != 0 && !StrEqual(arg2, "nvg", false))
		Format(weapon, sizeof(weapon), "weapon_%s", arg2);
	else
		strcopy(weapon, sizeof(weapon), arg2);

	if(StrContains(weapon, "grenade", false) != -1 || StrContains(weapon, "flashbang", false) != -1 || strncmp(arg2, "item_", 5) == 0)
		ammo = -1;

	new AdminId:id = GetUserAdmin(client);
	new superadmin = GetAdminFlag(id, Admin_Custom3);

	if(!superadmin)
	{
		if(StrEqual(weapon, "weapon_c4", false) || StrEqual(weapon, "weapon_smokegrenade", false) || StrEqual(weapon, "item_defuser", false))
		{
			ReplyToCommand(client, "[SM] This weapon is restricted!");
			return Plugin_Handled;
		}
	}

	if(args >= 3)
	{
		decl String:arg3[20];
		GetCmdArg(3, arg3, sizeof(arg3));
		if(StringToIntEx(arg3, clip) == 0)
		{
			ReplyToCommand(client, "[SM] Invalid Clip Value");
			return Plugin_Handled;
		}
	}
	if(args >= 4)
	{
		decl String:arg4[20];
		GetCmdArg(4, arg4, sizeof(arg4));
		if(StringToIntEx(arg4, ammo) == 0)
		{
			ReplyToCommand(client, "[SM] Invalid Ammo Value");
			return Plugin_Handled;
		}
	}

	if(StrContains(weapon, "grenade", false) != -1 || StrContains(weapon, "flashbang", false) != -1)
	{
		new tmp = ammo;
		ammo = clip;
		clip = tmp;
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if(StrEqual(weapon, "nvg", false))
	{
		for(new i = 0; i < target_count; i++)
			SetEntProp(target_list[i], Prop_Send, "m_bHasNightVision", 1, 1);
	}
	else
	{
		for(new i = 0; i < target_count; i++)
		{
			new ent = GivePlayerItem(target_list[i], weapon);

			if(ent == -1) {
				ReplyToCommand(client, "[SM] Invalid Weapon");
				return Plugin_Handled;
			}

			if(clip != -1)
				SetEntProp(ent, Prop_Send, "m_iClip1", clip);

			if(ammo != -1)
			{
				new PrimaryAmmoType = GetEntProp(ent, Prop_Data, "m_iPrimaryAmmoType");
				if(PrimaryAmmoType != -1)
					SetEntProp(target_list[i], Prop_Send, "m_iAmmo", ammo, _, PrimaryAmmoType);
			}

			if(strncmp(arg2, "item_", 5) != 0 && !StrEqual(weapon, "weapon_hegrenade", false))
				EquipPlayerWeapon(target_list[i], ent);

			if(ammo != -1)
			{
				new PrimaryAmmoType = GetEntProp(ent, Prop_Data, "m_iPrimaryAmmoType");
				if(PrimaryAmmoType != -1)
					SetEntProp(target_list[i], Prop_Send, "m_iAmmo", ammo, _, PrimaryAmmoType);
			}
		}
	}

	ShowActivity2(client, "[SM] ", "Gave %s to target %s", weapon, target_name);
	LogAction(client, -1, "Gave %s to target %s", weapon, target_name);

	return Plugin_Handled;
}

public Action:Command_Strip(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_strip <#userid|name>");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i = 0; i < target_count; i++)
	{
		for(new j = 0; j < 5; j++)
		{
			new w = -1;
			while ((w = GetPlayerWeaponSlot(target_list[i], j)) != -1)
			{
				if(IsValidEntity(w))
					RemovePlayerItem(target_list[i], w);
			}
		}
	}

	ShowActivity2(client, "[SM] ", "Stripped all weapons on target %s", target_name);
	LogAction(client, -1, "Stripped all weapons on target %s", target_name);

	return Plugin_Handled;
}

public Action:Command_BuyZone(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_buyzone <#userid|name> <0|1>");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new value = -1;
	decl String:arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToIntEx(arg2, value) == 0)
	{
		ReplyToCommand(client, "[SM] Invalid Value");
		return Plugin_Handled;
	}

	decl String:target_name[MAX_TARGET_LENGTH];

	if(StrEqual(arg, "@all", false))
	{
		target_name = "all players";
		g_bInBuyZoneAll = value ? true : false;
	}
	else
	{
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for(new i = 0; i < target_count; i++)
		{
			g_bInBuyZone[target_list[i]] = value ? true : false;
		}
	}

	ShowActivity2(client, "[SM] ", "%s permanent buyzone on target %s", (value ? "Enabled" : "Disabled"), target_name);
	LogAction(client, -1, "%s permanent buyzone on target %s", (value ? "Enabled" : "Disabled"), target_name);

	return Plugin_Handled;
}

public Action:Command_InfAmmo(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_iammo <#userid|name> <0|1>");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new value = -1;
	decl String:arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToIntEx(arg2, value) == 0)
	{
		ReplyToCommand(client, "[SM] Invalid Value");
		return Plugin_Handled;
	}

	decl String:target_name[MAX_TARGET_LENGTH];

	if(StrEqual(arg, "@all", false))
	{
		target_name = "all players";
		g_bInfAmmoAll = value ? true : false;

		if(!g_bInfAmmoAll)
		{
			for(new i = 0; i < MAXPLAYERS; i++)
				g_bInfAmmo[i] = false;
		}
	}
	else
	{
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for(new i = 0; i < target_count; i++)
		{
			g_bInfAmmo[target_list[i]] = value ? true : false;
		}
	}

	ShowActivity2(client, "[SM] ", "%s infinite ammo on target %s", (value ? "Enabled" : "Disabled"), target_name);
	LogAction(client, -1, "%s infinite ammo on target %s", (value ? "Enabled" : "Disabled"), target_name);

	if(g_bInfAmmoAll)
	{
		if(!g_bInfAmmoHooked)
		{
			HookEvent("weapon_fire", Event_WeaponFire);
			g_bInfAmmoHooked = true;
		}
		return Plugin_Handled;
	}

	for(new i = 0; i < MAXPLAYERS; i++)
	{
		if(g_bInfAmmo[i])
		{
			if(!g_bInfAmmoHooked)
			{
				HookEvent("weapon_fire", Event_WeaponFire);
				g_bInfAmmoHooked = true;
			}
			return Plugin_Handled;
		}
	}

	if(g_bInfAmmoHooked)
	{
		UnhookEvent("weapon_fire", Event_WeaponFire);
		g_bInfAmmoHooked = false;
	}

	return Plugin_Handled;
}

public Action:Command_Speed(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_speed <#userid|name> <value>");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new Float:speed = 0.0;
	decl String:arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToFloatEx(arg2, speed) == 0 || speed <= 0.0)
	{
		ReplyToCommand(client, "[SM] Invalid Value");
		return Plugin_Handled;
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i = 0; i < target_count; i++)
	{
		SetEntPropFloat(target_list[i], Prop_Data, "m_flLaggedMovementValue", speed);
	}

	ShowActivity2(client, "[SM] ", "Set speed to %.2f on target %s", speed, target_name);
	LogAction(client, -1, "Set speed to %.2f on target %s", speed, target_name);

	return Plugin_Handled;
}

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define PLUGIN_NAME 	"Toggle Weapon Sounds"
#define PLUGIN_VERSION 	"1.2.0"

#define UPDATE_URL	"http://godtony.mooo.com/stopsound/stopsound.txt"

new bool:g_bStopSound[MAXPLAYERS+1], bool:g_bHooked;
static String:g_sKVPATH[PLATFORM_MAX_PATH];
new Handle:g_hWepSounds;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony, edit by id/Obus",
	description = "Allows clients to stop hearing weapon sounds",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	// Detect game and hook appropriate tempent.
	decl String:sGame[32];
	GetGameFolderName(sGame, sizeof(sGame));

	if (StrEqual(sGame, "cstrike"))
	{
		AddTempEntHook("Shotgun Shot", CSS_Hook_ShotgunShot);
	}
	else if (StrEqual(sGame, "dod"))
	{
		AddTempEntHook("FireBullets", DODS_Hook_FireBullets);
	}

	// TF2/HL2:DM and misc weapon sounds will be caught here.
	AddNormalSoundHook(Hook_NormalSound);

	CreateConVar("sm_stopsound_version", PLUGIN_VERSION, "Toggle Weapon Sounds", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	RegConsoleCmd("sm_stopsound", Command_StopSound, "Toggle hearing weapon sounds");

	if (g_hWepSounds != INVALID_HANDLE)
	{
		CloseHandle(g_hWepSounds);
	}

	g_hWepSounds = CreateKeyValues("WeaponSounds");
	BuildPath(Path_SM, g_sKVPATH, sizeof(g_sKVPATH), "data/playerprefs.WepSounds.txt");

	FileToKeyValues(g_hWepSounds, g_sKVPATH);

	// Updater.
	//if (LibraryExists("updater"))
	//{
	//	Updater_AddPlugin(UPDATE_URL);
	//}
}

/*public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}*/

public Action:Command_StopSound(client, args)
{
	if (client == 0)
	{
		PrintToServer("[SM] Cannot use command from server console.");
		return Plugin_Handled;
	}

	if (args > 0)
	{
		decl String:Arguments[32];
		GetCmdArg(1, Arguments, sizeof(Arguments));

		if (StrEqual(Arguments, "save"))
		{
			KvRewind(g_hWepSounds);

			decl String:SID[32];
			GetClientAuthId(client, AuthId_Steam2, SID, sizeof(SID));

			if (KvJumpToKey(g_hWepSounds, SID, true))
			{
				new disabled;
				disabled = KvGetNum(g_hWepSounds, "disabled", 0);

				if (!disabled)
				{
					//CPrintToChat(client, "[StopSound] Saved entry for STEAMID({green}%s{default}) {green}successfully{default}.", SID);
					KvSetNum(g_hWepSounds, "disabled", 1);
					KvRewind(g_hWepSounds);
					KeyValuesToFile(g_hWepSounds, g_sKVPATH);

					g_bStopSound[client] = true;
					CReplyToCommand(client, "{green}[StopSound]{default} Weapon sounds {red}disabled{default} - {green}entry saved{default}.");
					CheckHooks();

					return Plugin_Handled;
				}
				else
				{
					//CPrintToChat(client, "[StopSound] Entry for STEAMID({green}%s{default}) {green}successfully deleted{default}.", SID);
					KvDeleteThis(g_hWepSounds);
					KvRewind(g_hWepSounds);
					KeyValuesToFile(g_hWepSounds, g_sKVPATH);

					g_bStopSound[client] = false;
					CReplyToCommand(client, "{green}[StopSound]{default} Weapon sounds {green}enabled{default} - {red}entry deleted{default}.");
					CheckHooks();

					return Plugin_Handled;
				}
			}

			KvRewind(g_hWepSounds);
		}
		else if (StrEqual(Arguments, "delete"))
		{
			KvRewind(g_hWepSounds);

			decl String:SID[32];
			GetClientAuthId(client, AuthId_Steam2, SID, sizeof(SID));

			if (KvJumpToKey(g_hWepSounds, SID, false))
			{
				g_bStopSound[client] = false;
				CReplyToCommand(client, "{green}[StopSound]{default} Weapon sounds {green}enabled{default} - {red}entry deleted{default}.");
				CheckHooks();

				KvDeleteThis(g_hWepSounds);
				KvRewind(g_hWepSounds);
				KeyValuesToFile(g_hWepSounds, g_sKVPATH);

				return Plugin_Handled;
			}
			else
			{
				CPrintToChat(client, "{green}[StopSound]{default} Entry {red}not found{default}.");
				return Plugin_Handled;
			}
		}
		else
		{
			PrintToChat(client, "[SM] Usage sm_stopsound <save|delete>");
			return Plugin_Handled;
		}
	}

	g_bStopSound[client] = !g_bStopSound[client];
	CReplyToCommand(client, "{green}[StopSound]{default} Weapon sounds %s.", g_bStopSound[client] ? "{red}disabled{default}" : "{green}enabled{default}");
	CheckHooks();

	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	KvRewind(g_hWepSounds);

	decl String:SID[32];
	GetClientAuthId(client, AuthId_Steam2, SID, sizeof(SID));

	if (KvJumpToKey(g_hWepSounds, SID, false))
	{
		new disabled;
		disabled = KvGetNum(g_hWepSounds, "disabled", 0);

		if (disabled)
		{
			g_bStopSound[client] = true;
		}
	}

	CheckHooks();
	KvRewind(g_hWepSounds);
}

public OnClientDisconnect_Post(client)
{
	g_bStopSound[client] = false;
	CheckHooks();
}

CheckHooks()
{
	new bool:bShouldHook = false;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_bStopSound[i])
		{
			bShouldHook = true;
			break;
		}
	}

	// Fake (un)hook because toggling actual hooks will cause server instability.
	g_bHooked = bShouldHook;
}

public Action:Hook_NormalSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	// Ignore non-weapon sounds.
	if (!g_bHooked || !(strncmp(sample, "weapons", 7) == 0 || strncmp(sample[1], "weapons", 7) == 0))
	{
		return Plugin_Continue;
	}

	decl i, j;

	for (i = 0; i < numClients; i++)
	{
		if (g_bStopSound[clients[i]])
		{
			// Remove the client from the array.
			for (j = i; j < numClients - 1; j++)
			{
				clients[j] = clients[j + 1];
			}

			numClients--;
			i--;
		}
	}

	return (numClients > 0) ? Plugin_Changed : Plugin_Stop;
}

public Action:CSS_Hook_ShotgunShot(const String:te_name[], const Players[], numClients, Float:delay)
{
	if (!g_bHooked)
	{
		return Plugin_Continue;
	}

	// Check which clients need to be excluded.
	decl newClients[MaxClients], client, i;
	new newTotal = 0;

	for (i = 0; i < numClients; i++)
	{
		client = Players[i];

		if (!g_bStopSound[client])
		{
			newClients[newTotal++] = client;
		}
	}

	// No clients were excluded.
	if (newTotal == numClients)
	{
		return Plugin_Continue;
	}
	else if (newTotal == 0) // All clients were excluded and there is no need to broadcast.
	{
		return Plugin_Stop;
	}

	// Re-broadcast to clients that still need it.
	decl Float:vTemp[3];
	TE_Start("Shotgun Shot");
	TE_ReadVector("m_vecOrigin", vTemp);
	TE_WriteVector("m_vecOrigin", vTemp);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_iWeaponID", TE_ReadNum("m_iWeaponID"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
	TE_WriteFloat("m_fInaccuracy", TE_ReadFloat("m_fInaccuracy"));
	TE_WriteFloat("m_fSpread", TE_ReadFloat("m_fSpread"));
	TE_Send(newClients, newTotal, delay);

	return Plugin_Stop;
}

public Action:DODS_Hook_FireBullets(const String:te_name[], const Players[], numClients, Float:delay)
{
	if (!g_bHooked)
	{
		return Plugin_Continue;
	}

	// Check which clients need to be excluded.
	decl newClients[MaxClients], client, i;
	new newTotal = 0;

	for (i = 0; i < numClients; i++)
	{
		client = Players[i];

		if (!g_bStopSound[client])
		{
			newClients[newTotal++] = client;
		}
	}

	// No clients were excluded.
	if (newTotal == numClients)
	{
		return Plugin_Continue;
	}
	else if (newTotal == 0)// All clients were excluded and there is no need to broadcast.
	{
		return Plugin_Stop;
	}

	// Re-broadcast to clients that still need it.
	decl Float:vTemp[3];
	TE_Start("FireBullets");
	TE_ReadVector("m_vecOrigin", vTemp);
	TE_WriteVector("m_vecOrigin", vTemp);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_iWeaponID", TE_ReadNum("m_iWeaponID"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
	TE_WriteFloat("m_flSpread", TE_ReadFloat("m_flSpread"));
	TE_Send(newClients, newTotal, delay);

	return Plugin_Stop;
}
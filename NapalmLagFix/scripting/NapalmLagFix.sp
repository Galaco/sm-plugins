#pragma semicolon 1

#include <sourcemod>
#include <dhooks>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_NAME 	"Napalm Lag Fix"
#define PLUGIN_VERSION 	"1.0.3"

#define UPDATE_URL	"http://godtony.mooo.com/napalmlagfix/napalmlagfix.txt"

#define DMG_BURN	(1 << 3)

new Handle:g_hRadiusDamage = INVALID_HANDLE;
new bool:g_bCheckNullPtr = false;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony + BotoX",
	description = "Prevents lag when napalm is used on players",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=188093" // Demo: http://youtu.be/YdhAu5IEVVM
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("DHookIsNullParam");

	return APLRes_Success;
}

public OnPluginStart()
{
	// Convars.
	new Handle:hCvar = CreateConVar("sm_napalmlagfix_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(hCvar, PLUGIN_VERSION);

	// Gamedata.
	new Handle:hConfig = LoadGameConfigFile("napalmlagfix.games");

	if (hConfig == INVALID_HANDLE)
	{
		SetFailState("Could not find gamedata file: napalmlagfix.games.txt");
	}

	new offset = GameConfGetOffset(hConfig, "RadiusDamage");

	if (offset == -1)
	{
		SetFailState("Failed to find RadiusDamage offset");
	}

	CloseHandle(hConfig);

	// DHooks.
	g_bCheckNullPtr = (GetFeatureStatus(FeatureType_Native, "DHookIsNullParam") == FeatureStatus_Available);

	g_hRadiusDamage = DHookCreate(offset, HookType_GameRules, ReturnType_Void, ThisPointer_Ignore, Hook_RadiusDamage);
	DHookAddParam(g_hRadiusDamage, HookParamType_ObjectPtr);	// 1 - CTakeDamageInfo &info
	DHookAddParam(g_hRadiusDamage, HookParamType_VectorPtr);	// 2 - Vector &vecSrc
	DHookAddParam(g_hRadiusDamage, HookParamType_Float);		// 3 - float flRadius
	DHookAddParam(g_hRadiusDamage, HookParamType_Int);			// 4 - int iClassIgnore
	DHookAddParam(g_hRadiusDamage, HookParamType_CBaseEntity);	// 5 - CBaseEntity *pEntityIgnore

	// Updater.
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Updater_OnPluginUpdated()
{
	// There could be new gamedata in this update.
	ReloadPlugin();
}

public OnMapStart()
{
	DHookGamerules(g_hRadiusDamage, false);
}

public MRESReturn:Hook_RadiusDamage(Handle:hParams)
{
	// As of DHooks 1.0.12 we must check for a null param.
	if (g_bCheckNullPtr && DHookIsNullParam(hParams, 5))
		return MRES_Ignored;

	new iDmgBits = DHookGetParamObjectPtrVar(hParams, 1, 60, ObjectValueType_Int);
	new iEntIgnore = DHookGetParam(hParams, 5);

	if(!(iDmgBits & DMG_BURN))
		return MRES_Ignored;

	// Block napalm damage if it's coming from another client.
	if (1 <= iEntIgnore <= MaxClients)
		return MRES_Supercede;

	// Block napalm that comes from grenades
	new String:sEntClassName[64];
	if(GetEntityClassname(iEntIgnore, sEntClassName, sizeof(sEntClassName)))
	{
		if(!strcmp(sEntClassName, "hegrenade_projectile"))
			return MRES_Supercede;
	}

	return MRES_Ignored;
}

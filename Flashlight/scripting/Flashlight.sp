#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#define PLUGIN_VERSION "1.0"
public Plugin myinfo =
{
	name 			= "Flashlight",
	author 			= "BotoX",
	description 	= "Dead flashlight, block sound from other clients.",
	version 		= PLUGIN_VERSION,
	url 			= ""
};

public void OnPluginStart()
{
	AddNormalSoundHook(OnSound);
}

public Action OnSound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if(entity >= 1 && entity <= MAXPLAYERS && StrEqual(sample, "items/flashlight1.wav", false))
	{
		numClients = 1;
		clients[0] = entity;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	// Dead flashlight
	if(impulse == 100 && !IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Send, "m_fEffects", GetEntProp(client, Prop_Send, "m_fEffects") ^ 4);
		ClientCommand(client, "playgamesound \"items/flashlight1.wav\"");
	}

	return Plugin_Continue;
}

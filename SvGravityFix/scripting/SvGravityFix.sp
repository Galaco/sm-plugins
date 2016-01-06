#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo =
{
	name = "sv_gravity fix",
	author = "BotoX",
	description = "Resets sv_gravity at game_end",
	version = "1.0",
	url = ""
};

public void OnMapEnd()
{
	ConVar SvGravity = FindConVar("sv_gravity");
	SvGravity.IntValue = 800;
}

#pragma semicolon 1

#include <sourcemod>
#include <geoip>

#pragma newdecls required

public Plugin myinfo = {
	name = "Connect Announce",
	author = "BotoX",
	description = "Simple connect announcer",
	version = "1.0",
	url = ""
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
		return;

	static char sAuth[32];
	static char sIP[16];
	static char sCountry[32];

	GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth));

	if(GetClientIP(client, sIP, sizeof(sIP)) && GeoipCountry(sIP, sCountry, sizeof(sCountry)))
		PrintToChatAll("\x04%L [\x03%s\x04] connected from %s", client, sAuth, sCountry);
	else
		PrintToChatAll("\x04%L [\x03%s\x04] connected", client, sAuth);
}

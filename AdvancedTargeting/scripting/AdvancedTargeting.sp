#pragma semicolon 1
#define PLUGIN_VERSION "1.0"

#pragma dynamic 128*1024

#include <sourcemod>
#include <SteamWorks>
//#include <EasyJSON>
#include <AdvancedTargeting>

Handle g_FriendsArray[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
bool g_bLateLoad = false;

//#define STEAM_API_KEY "secret"
#include "SteamAPI.secret"

public Plugin myinfo =
{
	name = "Advanced Targeting",
	author = "BotoX",
	description = "Adds @admins and @friends targeting method",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	AddMultiTargetFilter("@admins", Filter_Admin, "Admins", false);
	AddMultiTargetFilter("@!admins", Filter_NotAdmin, "Not Admins", false);
	AddMultiTargetFilter("@friends", Filter_Friends, "Steam Friends", false);
	AddMultiTargetFilter("@!friends", Filter_NotFriends, "Not Steam Friends", false);

	RegConsoleCmd("sm_admins", Command_Admins, "Currently online admins.");
	RegConsoleCmd("sm_friends", Command_Friends, "Currently online friends.");

	if(g_bLateLoad)
	{
		char sSteam32ID[32];
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i) &&
				GetClientAuthId(i, AuthId_Steam2, sSteam32ID, sizeof(sSteam32ID)))
			{
				OnClientAuthorized(i, sSteam32ID);
			}
		}
	}
}

public OnPluginEnd()
{
	RemoveMultiTargetFilter("@admins", Filter_Admin);
	RemoveMultiTargetFilter("@!admins", Filter_NotAdmin);
	RemoveMultiTargetFilter("@friends", Filter_Friends);
	RemoveMultiTargetFilter("@!friends", Filter_NotFriends);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("IsClientFriend", Native_IsClientFriend);
	CreateNative("ReadClientFriends", Native_ReadClientFriends);
	RegPluginLibrary("AdvancedTargeting");

	g_bLateLoad = late;
	return APLRes_Success;
}

public Action Command_Admins(int client, int args)
{
	char aBuf[1024];
	char aBuf2[MAX_NAME_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetAdminFlag(GetUserAdmin(i), Admin_Generic))
		{
			GetClientName(i, aBuf2, sizeof(aBuf2));
			StrCat(aBuf, sizeof(aBuf), aBuf2);
			StrCat(aBuf, sizeof(aBuf), ", ");
		}
	}

	if(strlen(aBuf))
	{
		aBuf[strlen(aBuf) - 2] = 0;
		PrintToChat(client, "[SM] Admins currently online: %s", aBuf);
	}
	else
		PrintToChat(client, "[SM] Admins currently online: none");

	return Plugin_Handled;
}

public Action Command_Friends(int client, int args)
{
	if(g_FriendsArray[client] == INVALID_HANDLE)
	{
		PrintToChat(client, "[SM] Could not read your friendslist, your profile must be set to public!");
		return Plugin_Handled;
	}

	char aBuf[1024];
	char aBuf2[MAX_NAME_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
		{
			int Steam3ID = GetSteamAccountID(i);

			if(FindValueInArray(g_FriendsArray[client], Steam3ID) != -1)
			{
				GetClientName(i, aBuf2, sizeof(aBuf2));
				StrCat(aBuf, sizeof(aBuf), aBuf2);
				StrCat(aBuf, sizeof(aBuf), ", ");
			}
		}
	}

	if(strlen(aBuf))
	{
		aBuf[strlen(aBuf) - 2] = 0;
		PrintToChat(client, "[SM] Friends currently online: %s", aBuf);
	}
	else
		PrintToChat(client, "[SM] Friends currently online: none");

	return Plugin_Handled;
}

public bool Filter_Admin(const char[] sPattern, Handle hClients, int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetAdminFlag(GetUserAdmin(i), Admin_Generic))
		{
			PushArrayCell(hClients, i);
		}
	}

	return true;
}

public bool Filter_NotAdmin(const char[] sPattern, Handle hClients, int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && !GetAdminFlag(GetUserAdmin(i), Admin_Generic))
		{
			PushArrayCell(hClients, i);
		}
	}

	return true;
}

public bool Filter_Friends(const char[] sPattern, Handle hClients, int client)
{
	if(g_FriendsArray[client] == INVALID_HANDLE)
	{
		PrintToChat(client, "[SM] Could not read your friendslist, your profile must be set to public!");
		return false;
	}

	for(int i = 1; i <= MaxClients; i++)
	{
		if(i != client && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
		{
			int Steam3ID = GetSteamAccountID(i);

			if(FindValueInArray(g_FriendsArray[client], Steam3ID) != -1)
				PushArrayCell(hClients, i);
		}
	}

	return true;
}

public bool Filter_NotFriends(const char[] sPattern, Handle hClients, int client)
{
	if(g_FriendsArray[client] == INVALID_HANDLE)
	{
		PrintToChat(client, "[SM] Could not read your friendslist, your profile must be set to public!");
		return false;
	}

	for(int i = 1; i <= MaxClients; i++)
	{
		if(i != client && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
		{
			int Steam3ID = GetSteamAccountID(i);

			if(FindValueInArray(g_FriendsArray[client], Steam3ID) == -1)
				PushArrayCell(hClients, i);
		}
	}

	return true;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if(IsFakeClient(client))
		return;

	char sSteam64ID[32];
	Steam32IDtoSteam64ID(auth, sSteam64ID, sizeof(sSteam64ID));

	static char sRequest[256];
	FormatEx(sRequest, sizeof(sRequest), "http://api.steampowered.com/ISteamUser/GetFriendList/v0001/?key=%s&steamid=%s&relationship=friend&format=vdf", STEAM_API_KEY, sSteam64ID);

	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, sRequest);
	if (!hRequest ||
		!SteamWorks_SetHTTPRequestContextValue(hRequest, client) ||
		!SteamWorks_SetHTTPCallbacks(hRequest, OnTransferComplete) ||
		!SteamWorks_SendHTTPRequest(hRequest))
	{
		CloseHandle(hRequest);
	}
}

public void OnClientDisconnect(int client)
{
	if(g_FriendsArray[client] != INVALID_HANDLE)
		CloseHandle(g_FriendsArray[client]);

	g_FriendsArray[client] = INVALID_HANDLE;
}

public OnTransferComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client)
{
	if(bFailure || !bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		// Private profile or maybe steam down?
		//LogError("SteamAPI HTTP Response failed: %d", eStatusCode);
		CloseHandle(hRequest);
		return;
	}

	int Length;
	SteamWorks_GetHTTPResponseBodySize(hRequest, Length);

	char[] sData = new char[Length];
	SteamWorks_GetHTTPResponseBodyData(hRequest, sData, Length);
	//SteamWorks_GetHTTPResponseBodyCallback(hRequest, APIWebResponse, client);

	CloseHandle(hRequest);

	APIWebResponse(sData, client);
}

public APIWebResponse(const char[] sData, int client)
{
	KeyValues Response = new KeyValues("SteamAPIResponse");
	if(!Response.ImportFromString(sData, "SteamAPIResponse"))
	{
		LogError("ImportFromString(sData, \"SteamAPIResponse\") failed.");
		return;
	}

	if(!Response.JumpToKey("friends"))
	{
		LogError("JumpToKey(\"friends\") failed.");
		delete Response;
		return;
	}

	// No friends?
	if(!Response.GotoFirstSubKey())
	{
		//LogError("GotoFirstSubKey() failed.");
		delete Response;
		return;
	}

	g_FriendsArray[client] = CreateArray();

	char sCommunityID[32];
	do
	{
		Response.GetString("steamid", sCommunityID, sizeof(sCommunityID));

		PushArrayCell(g_FriendsArray[client], Steam64toSteam3(sCommunityID));
	}
	while(Response.GotoNextKey());

	delete Response;

/* DEPRECATED JSON CODE
	Handle hJSON = DecodeJSON(sData);
	if(!hJSON)
	{
		LogError("DecodeJSON failed.");
		return;
	}

	Handle hFriendslist = INVALID_HANDLE;
	if(!JSONGetObject(hJSON, "friendslist", hFriendslist))
	{
		LogError("JSONGetObject(hJSON, \"friendslist\", hFriendslist) failed.");
		DestroyJSON(hJSON);
		return;
	}

	Handle hFriends = INVALID_HANDLE;
	if(!JSONGetArray(hFriendslist, "friends", hFriends))
	{
		LogError("JSONGetObject(hFriendslist, \"friends\", hFriends) failed.");
		DestroyJSON(hJSON);
		return;
	}

	int ArraySize = GetArraySize(hFriends);
	PrintToServer("ArraySize: %d", ArraySize);

	for(int i = 0; i < ArraySize; i++)
	{
		Handle hEntry = INVALID_HANDLE;
		JSONGetArrayObject(hFriends, i, hEntry);

		static char sCommunityID[32];
		if(!JSONGetString(hEntry, "steamid", sCommunityID, sizeof(sCommunityID)))
		{
			LogError("JSONGetString(hArray, \"steamid\", sCommunityID, %d) failed.", sizeof(sCommunityID));
			DestroyJSON(hJSON);
			return;
		}

		PushArrayCell(g_FriendsArray[client], Steam64toSteam3(sCommunityID));
	}

	DestroyJSON(hJSON);
*/
}


stock bool Steam32IDtoSteam64ID(const char[] sSteam32ID, char[] sSteam64ID, int Size)
{
	if(strlen(sSteam32ID) < 11 || strncmp(sSteam32ID[0], "STEAM_0:", 8))
	{
		sSteam64ID[0] = 0;
		return false;
	}

	int iUpper = 765611979;
	int isSteam64ID = StringToInt(sSteam32ID[10]) * 2 + 60265728 + sSteam32ID[8] - 48;

	int iDiv = isSteam64ID / 100000000;
	int iIdx = 9 - (iDiv ? (iDiv / 10 + 1) : 0);
	iUpper += iDiv;

	IntToString(isSteam64ID, sSteam64ID[iIdx], Size - iIdx);
	iIdx = sSteam64ID[9];
	IntToString(iUpper, sSteam64ID, Size);
	sSteam64ID[9] = iIdx;

	return true;
}

stock int Steam64toSteam3(const char[] sSteam64ID)
{
	if(strlen(sSteam64ID) != 17)
		return 0;

	// convert SteamID64 to array of integers
	int aSteam64ID[17];
	for(int i = 0; i < 17; i++)
		aSteam64ID[i] = sSteam64ID[i] - 48;

	// subtract individual SteamID64 identifier (0x0110000100000000)
	int aSteam64IDIdent[] = {7, 6, 5, 6, 1, 1, 9, 7, 9, 6, 0, 2, 6, 5, 7, 2, 8};
	int Carry = 0;
	for(int i = 16; i >= 0; i--)
	{
		if(aSteam64ID[i] < aSteam64IDIdent[i] + Carry)
		{
			aSteam64ID[i] = aSteam64ID[i] - aSteam64IDIdent[i] - Carry + 10;
			Carry = 1;
		}
		else
		{
			aSteam64ID[i] = aSteam64ID[i] - aSteam64IDIdent[i] - Carry;
			Carry = 0;
		}
	}

	char aBuf[17];
	int j = 0;
	bool ZereosDone = false;
	for(int i = 0; i < 17; i++)
	{
		if(!ZereosDone && !aSteam64ID[i])
			continue;
		ZereosDone = true;

		aBuf[j++] = aSteam64ID[i] + 48;
	}

	return StringToInt(aBuf);
}

public int Native_IsClientFriend(Handle plugin, int numParams)
{
	new client = GetNativeCell(1);
	new friend = GetNativeCell(2);

	if(client > MaxClients || client <= 0 || friend > MaxClients || friend <= 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client is not valid.");
		return -1;
	}

	if(!IsClientInGame(client) || !IsClientInGame(friend))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client is not in-game.");
		return -1;
	}

	if(IsFakeClient(client) || IsFakeClient(friend))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client is fake-client.");
		return -1;
	}

	if(g_FriendsArray[client] == INVALID_HANDLE)
		return -1;

	if(IsClientAuthorized(friend))
	{
		int Steam3ID = GetSteamAccountID(friend);

		if(FindValueInArray(g_FriendsArray[client], Steam3ID) != -1)
			return 1;
	}

	return 0;
}

public int Native_ReadClientFriends(Handle plugin, int numParams)
{
	new client = GetNativeCell(1);

	if(client > MaxClients || client <= 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client is not valid.");
		return -1;
	}

	if(g_FriendsArray[client] != INVALID_HANDLE)
		return 1;

	return 0;
}

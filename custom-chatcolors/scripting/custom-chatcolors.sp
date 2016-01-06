#pragma semicolon 1

#include <sourcemod>
#include <regex>
#include <morecolors>
#include <ccc>
//#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION		"5.3.0"

public Plugin:myinfo =
{
	name        = "Custom Chat Colors & Tags & Allchat",
	author      = "Dr. McKay, edit by id/Obus, BotoX",
	description = "Processes chat and provides colors & custom tags & allchat & chat ignoring",
	version     = PLUGIN_VERSION,
	url         = "http://www.doctormckay.com"
};

new Handle:colorForward;
new Handle:nameForward;
new Handle:tagForward;
new Handle:applicationForward;
new Handle:messageForward;
new Handle:preLoadedForward;
new Handle:loadedForward;
new Handle:configReloadedForward;
new Handle:g_hCoolDown = INVALID_HANDLE;
new Handle:g_hGreenText = INVALID_HANDLE;
//new Handle:g_hAdminMenu = INVALID_HANDLE;

new String:g_sTag[MAXPLAYERS + 1][64];
new String:g_sTagColor[MAXPLAYERS + 1][12];
new String:g_sUsernameColor[MAXPLAYERS + 1][12];
new String:g_sChatColor[MAXPLAYERS + 1][12];

new String:g_sDefaultTag[MAXPLAYERS + 1][32];
new String:g_sDefaultTagColor[MAXPLAYERS + 1][12];
new String:g_sDefaultUsernameColor[MAXPLAYERS + 1][12];
new String:g_sDefaultChatColor[MAXPLAYERS + 1][12];
new const String:g_sColorsArray[120][2][32] = { {"aliceblue", "F0F8FF" }, { "aqua", "00FFFF" }, { "aquamarine", "7FFFD4" }, { "azure", "007FFF" }, { "beige", "F5F5DC" }, { "black", "000000" }, { "blue", "99CCFF" }, { "blueviolet", "8A2BE2" }, { "brown", "A52A2A" }, { "burlywood", "DEB887" }, { "cadetblue", "5F9EA0" }, { "chocolate", "D2691E" }, { "corrupted", "A32C2E" }, { "crimson", "DC143C" }, { "cyan", "00FFFF" }, { "darkblue", "00008B" }, { "darkcyan", "008B8B" }, { "darkgoldenrod", "B8860B" }, { "darkgray", "A9A9A9" }, { "darkgrey", "A9A9A9" }, { "darkgreen", "006400" }, { "darkkhaki", "BDB76B" }, { "darkmagenta", "8B008B" }, { "darkolivegreen", "556B2F" }, { "darkorange", "FF8C00" }, { "darkorchid", "9932CC" }, { "darkred", "8B0000" }, { "darksalmon", "E9967A" }, { "darkseagreen", "8FBC8F" }, { "darkslateblue", "483D8B" }, { "darkturquoise", "00CED1" }, { "darkviolet", "9400D3" }, { "deeppink", "FF1493" }, { "deepskyblue", "00BFFF" }, { "dimgray", "696969" }, { "dodgerblue", "1E90FF" }, { "firebrick", "B22222" }, { "floralwhite", "FFFAF0" }, { "forestgreen", "228B22" }, { "frozen", "4983B3" }, { "fuchsia", "FF00FF" }, { "fullblue", "0000FF" }, { "fullred", "FF0000" }, { "ghostwhite", "F8F8FF" }, { "gold", "FFD700" }, { "gray", "CCCCCC" }, { "green", "3EFF3E" }, { "greenyellow", "ADFF2F" }, { "hotpink", "FF69B4" }, { "indianred", "CD5C5C" }, { "indigo", "4B0082" }, { "ivory", "FFFFF0" }, { "khaki", "F0E68C" }, { "lightblue", "ADD8E6" }, { "lightcoral", "F08080" }, { "lightcyan", "E0FFFF" }, { "lightgoldenrodyellow", "FAFAD2" }, { "lightgray", "D3D3D3" }, { "lightgrey", "D3D3D3" }, { "lightgreen", "99FF99" }, { "lightpink", "FFB6C1" }, { "lightsalmon", "FFA07A" }, { "lightseagreen", "20B2AA" }, { "lightskyblue", "87CEFA" }, { "lightslategray", "778899" }, { "lightslategrey", "778899" }, { "lightsteelblue", "B0C4DE" }, { "lightyellow", "FFFFE0" }, { "lime", "00FF00" }, { "limegreen", "32CD32" }, { "magenta", "FF00FF" }, { "maroon", "800000" }, { "mediumaquamarine", "66CDAA" }, { "mediumblue", "0000CD" }, { "mediumorchid", "BA55D3" }, { "mediumturquoise", "48D1CC" }, { "mediumvioletred", "C71585" }, { "midnightblue", "191970" }, { "mintcream", "F5FFFA" }, { "mistyrose", "FFE4E1" }, { "moccasin", "FFE4B5" }, { "navajowhite", "FFDEAD" }, { "navy", "000080" }, { "oldlace", "FDF5E6" }, { "olive", "9EC34F" }, { "olivedrab", "6B8E23" }, { "orange", "FFA500" }, { "orangered", "FF4500" }, { "orchid", "DA70D6" }, { "palegoldenrod", "EEE8AA" }, { "palegreen", "98FB98" }, { "palevioletred", "D87093" }, { "pink", "FFC0CB" }, { "plum", "DDA0DD" }, { "powderblue", "B0E0E6" }, { "purple", "800080" }, { "red", "FF4040" }, { "rosybrown", "BC8F8F" }, { "royalblue", "4169E1" }, { "saddlebrown", "8B4513" }, { "salmon", "FA8072" }, { "sandybrown", "F4A460" }, { "seagreen", "2E8B57" }, { "seashell", "FFF5EE" }, { "silver", "C0C0C0" }, { "skyblue", "87CEEB" }, { "slateblue", "6A5ACD" }, { "slategray", "708090" }, { "slategrey", "708090" }, { "snow", "FFFAFA" }, { "springgreen", "00FF7F" }, { "steelblue", "4682B4" }, { "tan", "D2B48C" }, { "teal", "008080" }, { "tomato", "FF6347" }, { "turquoise", "40E0D0" }, { "violet", "EE82EE" }, { "white", "FFFFFF" }, { "yellow", "FFFF00" }, { "yellowgreen", "9ACD32" } }; //you want colors? here bomb array fak u

new String:g_sPath[PLATFORM_MAX_PATH];
new String:g_sBanPath[PLATFORM_MAX_PATH];

new bool:g_bWaitingForChatInput[MAXPLAYERS + 1];
new bool:g_bTagToggled[MAXPLAYERS + 1];
new String:g_sReceivedChatInput[MAXPLAYERS + 1][64];
new String:g_sInputType[MAXPLAYERS + 1][32];
new String:g_sATargetSID[MAXPLAYERS + 1][64];
new g_iATarget[MAXPLAYERS + 1];

new Handle:g_hConfigFile;
new Handle:g_hBanFile;

new g_msgAuthor;
new bool:g_msgIsChat;
new String:g_msgName[128];
new String:g_msgSender[128];
new String:g_msgText[512];
new String:g_msgFinal[1024];
new bool:g_msgIsTeammate;

new bool:g_Ignored[(MAXPLAYERS + 1) * (MAXPLAYERS + 1)] = {false, ...};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("Updater_AddPlugin");

	CreateNative("CCC_GetColor", Native_GetColor);
	CreateNative("CCC_SetColor", Native_SetColor);
	CreateNative("CCC_GetTag", Native_GetTag);
	CreateNative("CCC_SetTag", Native_SetTag);
	CreateNative("CCC_ResetColor", Native_ResetColor);
	CreateNative("CCC_ResetTag", Native_ResetTag);

	CreateNative("CCC_UpdateIgnoredArray", Native_UpdateIgnoredArray);

	RegPluginLibrary("ccc");

	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("allchat.phrases");

	//new Handle:g_hTemporary = INVALID_HANDLE;
	//if(LibraryExists("adminmenu") && ((g_hTemporary = GetAdminTopMenu()) != INVALID_HANDLE))
	//{
	//	OnAdminMenuReady(g_hTemporary);
	//}

	new UserMsg:SayText2 = GetUserMessageId("SayText2");

	if (SayText2 == INVALID_MESSAGE_ID)
	{
		SetFailState("This game doesn't support SayText2 user messages.");
	}

	HookUserMessage(SayText2, Hook_UserMessage, true);
	HookEvent("player_say", Event_PlayerSay);

	RegAdminCmd("sm_reloadccc", Command_ReloadConfig, ADMFLAG_CONFIG, "Reloads Custom Chat Colors config file");
	RegAdminCmd("sm_forcetag", Command_ForceTag, ADMFLAG_CHEATS, "Forcefully changes a clients custom tag");
	RegAdminCmd("sm_forcetagcolor", Command_ForceTagColor, ADMFLAG_CHEATS, "Forcefully changes a clients custom tag color");
	RegAdminCmd("sm_forcenamecolor", Command_ForceNameColor, ADMFLAG_CHEATS, "Forcefully changes a clients name color");
	RegAdminCmd("sm_forcetextcolor", Command_ForceTextColor, ADMFLAG_CHEATS, "Forcefully changes a clients chat text color");
	RegAdminCmd("sm_cccreset", Command_CCCReset, ADMFLAG_SLAY, "Resets a users custom tag, tag color, name color and chat text color");
	RegAdminCmd("sm_cccban", Command_CCCBan, ADMFLAG_SLAY, "Bans a user from changing his custom tag, tag color, name color and chat text color");
	RegAdminCmd("sm_cccunban", Command_CCCUnban, ADMFLAG_SLAY, "Unbans a user and allows for change of his tag, tag color, name color and chat text color");
	RegAdminCmd("sm_tagmenu", Command_TagMenu, ADMFLAG_CUSTOM1, "Shows the main \"tag & colors\" menu");
	RegAdminCmd("sm_tag", Command_SetTag, ADMFLAG_CUSTOM1, "Changes your custom tag");
	RegAdminCmd("sm_cleartag", Command_ClearTag, ADMFLAG_CUSTOM1, "Clears your custom tag");
	RegAdminCmd("sm_tagcolor", Command_SetTagColor, ADMFLAG_CUSTOM1, "Changes the color of your custom tag");
	RegAdminCmd("sm_cleartagcolor", Command_ClearTagColor, ADMFLAG_CUSTOM1, "Clears the color from your custom tag");
	RegAdminCmd("sm_namecolor", Command_SetNameColor, ADMFLAG_CUSTOM1, "Changes the color of your name");
	RegAdminCmd("sm_clearnamecolor", Command_ClearNameColor, ADMFLAG_CUSTOM1, "Clears the color from your name");
	RegAdminCmd("sm_textcolor", Command_SetTextColor, ADMFLAG_CUSTOM1, "Changes the color of your chat text");
	RegAdminCmd("sm_chatcolor", Command_SetTextColor, ADMFLAG_CUSTOM1, "Changes the color of your chat text");
	RegAdminCmd("sm_cleartextcolor", Command_ClearTextColor, ADMFLAG_CUSTOM1, "Clears the color from your chat text");
	RegAdminCmd("sm_clearchatcolor", Command_ClearTextColor, ADMFLAG_CUSTOM1, "Clears the color from your chat text");
	RegConsoleCmd("sm_toggletag", Command_ToggleTag, "Toggles whether or not your tag and colors show in the chat");

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	//RegConsoleCmd("sm_test", Command_Test);

	if (g_hCoolDown != INVALID_HANDLE)
		CloseHandle(g_hCoolDown);

	if (g_hGreenText != INVALID_HANDLE)
		CloseHandle(g_hGreenText);

	g_hCoolDown = CreateConVar("sm_ccccooldown", "1", "Tag/Color changes cooldown period (in seconds)", FCVAR_NOTIFY|FCVAR_REPLICATED, true, 1.0);
	g_hGreenText = CreateConVar("sm_cccgreentext", "1", "Enables greentexting (First chat character must be \">\")");

	colorForward = CreateGlobalForward("CCC_OnChatColor", ET_Event, Param_Cell);
	nameForward = CreateGlobalForward("CCC_OnNameColor", ET_Event, Param_Cell);
	tagForward = CreateGlobalForward("CCC_OnTagApplied", ET_Event, Param_Cell);
	applicationForward = CreateGlobalForward("CCC_OnColor", ET_Event, Param_Cell, Param_String, Param_Cell);
	messageForward = CreateGlobalForward("CCC_OnChatMessage", ET_Ignore, Param_Cell, Param_String, Param_Cell);
	preLoadedForward = CreateGlobalForward("CCC_OnUserConfigPreLoaded", ET_Event, Param_Cell);
	loadedForward = CreateGlobalForward("CCC_OnUserConfigLoaded", ET_Ignore, Param_Cell);
	configReloadedForward = CreateGlobalForward("CCC_OnConfigReloaded", ET_Ignore);

	LoadConfig();
}

LoadConfig()
{
	if (g_hConfigFile != INVALID_HANDLE)
	{
		CloseHandle(g_hConfigFile);
	}

	if (g_hBanFile != INVALID_HANDLE)
	{
		CloseHandle(g_hBanFile);
	}

	g_hConfigFile = CreateKeyValues("admin_colors");
	g_hBanFile = CreateKeyValues("restricted_users");

	BuildPath(Path_SM, g_sPath, sizeof(g_sPath), "configs/custom-chatcolors.cfg");
	BuildPath(Path_SM, g_sBanPath, sizeof(g_sBanPath), "configs/custom-chatcolorsbans.cfg");

	if (!FileToKeyValues(g_hConfigFile, g_sPath))
	{
		SetFailState("[CCC] Config file missing");
	}

	if (!FileToKeyValues(g_hBanFile, g_sBanPath))
	{
		SetFailState("[CCC] Ban file missing");
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}

		ClearValues(i);
		OnClientPostAdminCheck(i);
	}
}

/*public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		g_hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:CCCAMenu)
{
	if (CCCAMenu == g_hAdminMenu)
	{
		return;
	}

	g_hAdminMenu = CCCAMenu;
	new TopMenuObject:MenuObject = AddToTopMenu(g_hAdminMenu, "CCCCmds", TopMenuObject_Category, Handle_Commands, INVALID_TOPMENUOBJECT);

	if (MenuObject == INVALID_TOPMENUOBJECT)
	{
		return;
	}

	AddToTopMenu(g_hAdminMenu, "CCCReset", TopMenuObject_Item, Handle_AMenuReset, MenuObject, "sm_cccreset", ADMFLAG_SLAY);
	AddToTopMenu(g_hAdminMenu, "CCCBan", TopMenuObject_Item, Handle_AMenuBan, MenuObject, "sm_cccban", ADMFLAG_SLAY);
	AddToTopMenu(g_hAdminMenu, "CCCUnBan", TopMenuObject_Item, Handle_AMenuUnBan, MenuObject, "sm_cccunban", ADMFLAG_SLAY);
}*/ //figure out why reloading the plugin makes this admin menu take control of other admin menus

public Action:Command_Test(client, args)
{
	decl String:Arg[64];
	decl String:SArg[64];
	decl String:TArg[64];
	new color;
	GetCmdArg(1, Arg, sizeof(SArg));
	GetCmdArg(2, SArg, sizeof(SArg));
	GetCmdArg(3, TArg, sizeof(SArg));
	color |= ((StringToInt(Arg, 10) & 0xFF) << 16);
	color |= ((StringToInt(SArg, 10) & 0xFF) << 8);
	color |= ((StringToInt(TArg, 10) & 0xFF) << 0);

	if (IsValidHex(Arg))
	{
		ReplaceString(Arg, 64, "#", "");
		PrintToChat(client, "%02X, %04X, %06X", Arg, Arg, Arg);
		new Hex, r, g, b;
		StringToIntEx(Arg, Hex, 16);
		r = ((Hex >> 16) & 0xFF);
		g = ((Hex >> 8) & 0xFF);
		b = ((Hex >> 0) & 0xFF);


		PrintToChat(client, "Hex = %s, R = %i, G = %i, B = %i", Arg, r, g, b);
	}
	else
	{
		PrintToChat(client, "Arg: %d, SArg: %d, TArg: %d", StringToInt(Arg),StringToInt(SArg),StringToInt(TArg));
		PrintToChat(client, "%06X", color);
		//PrintToChat(client, "test %X, r = %i, g = %i, b = %i", test, r, g, b);
	}
}

bool:MakeStringPrintable(String:str[], str_len_max, const String:empty[]) //function taken from Forlix FloodCheck (http://forlix.org/gameaddons/floodcheck.shtml)
{
	new r = 0;
	new w = 0;
	new bool:modified = false;
	new bool:nonspace = false;
	new bool:addspace = false;

	if (str[0])
	do
	  {
		if(str[r] < '\x20')
		{
		  modified = true;

		  if((str[r] == '\n'
		  ||  str[r] == '\t')
		  && w > 0
		  && str[w-1] != '\x20')
			addspace = true;
		}
		else
		{
		  if(str[r] != '\x20')
		  {
			nonspace = true;

			if(addspace)
			  str[w++] = '\x20';
		  }

		  addspace = false;
		  str[w++] = str[r];
		}
	  }
	while(str[++r]);
	str[w] = '\0';

	if (!nonspace)
	{
		modified = true;
		strcopy(str, str_len_max, empty);
	}

	return (modified);
}

bool:SingularOrMultiple(int num)
{
	if (num > 1 || num == 0)
	{
		return true;
	}

	return false;
}

bool:HasFlag(client, AdminFlag:ADMFLAG)
{
	new AdminId:Admin = GetUserAdmin(client);

	if (Admin != INVALID_ADMIN_ID && GetAdminFlag(Admin, ADMFLAG, Access_Effective) == true)
	{
		return true;
	}

	return false;
}

bool:NoFilter(String:arg[64])
{
	if (StrEqual(arg[0], "@cts") || StrEqual(arg[0], "@ct") || StrEqual(arg[0], "@all") || StrEqual(arg[0], "@alive") || StrEqual(arg[0], "@admins") || StrEqual(arg[0], "@dead") || StrEqual(arg[0], "@humans") || StrEqual(arg[0], "@t") || StrEqual(arg[0], "@ts") || StrEqual(arg[0], "@!me"))
	{
		return true;
	}

	return false;
}

int ForceColor(client, String:Key[64])
{
	decl String:arg[64];
	decl String:col[64];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, col, sizeof(col));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if (IsValidRGBNum(col))
	{
		new String:g[8];
		new String:b[8];
		GetCmdArg(3, g, sizeof(g));
		GetCmdArg(4, b, sizeof(b));
		new hex;
		hex |= ((StringToInt(col) & 0xFF) << 16);
		hex |= ((StringToInt(g) & 0xFF) << 8);
		hex |= ((StringToInt(b) & 0xFF) << 0);

		Format(col, 64, "#%06X", hex);
	}

	if (NoFilter(arg))
	{
		ReplyToCommand(client, "[SM] This command only supports special filters <@aim|@me>.");
		return 1;
	}

	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return 2;
	}

	for (new i = 0; i < target_count; i++)
	{
		decl String:SID[64];
		GetClientAuthId(target_list[i], AuthId_Steam2, SID, sizeof(SID));

		if (IsValidHex(col))
			SetColor(SID, Key, col, -1, true, true);
		else
			CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Invalid HEX|RGB color code given.");
	}

	return 0;
}

bool:IsValidRGBNum(String:arg[])
{
	if (SimpleRegexMatch(arg, "^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$") == 2)
	{
		return true;
	}

	return false;
}

bool:IsValidHex(String:arg[])
{
	if (SimpleRegexMatch(arg, "^(#?)([A-Fa-f0-9]{6})$") == 0)
	{
		return false;
	}

	return true;
}

bool:SetColor(String:SID[64], String:Key[64], String:HEX[64], client, bool:IgnoreCooldown=false, bool:IgnoreBan=false)
{
	if (!IgnoreBan)
	{
		KvRewind(g_hBanFile);

		if (KvJumpToKey(g_hBanFile, SID))
		{
			if (KvGetNum(g_hBanFile, "length") == 0)
			{
				CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} You are currently {red}banned{default} from changing your {green}%s{default}.", Key);
				return false;
			}
			else if (KvGetNum(g_hBanFile, "length") < GetTime())
			{
				KvDeleteThis(g_hBanFile);
			}
			else
			{
				decl String:TimeBuffer[64];
				int tstamp = KvGetNum(g_hBanFile, "length");
				tstamp = (tstamp - GetTime());

				int days = (tstamp / 86400);
				int hrs = ((tstamp / 3600) % 24);
				int mins = ((tstamp / 60) % 60);
				int sec = (tstamp % 60);

				if (tstamp > 86400)
				{
					Format(TimeBuffer, sizeof(TimeBuffer), "%d %s, %d %s, %d %s, %d %s", days, SingularOrMultiple(days) ? "Days" : "Day", hrs, SingularOrMultiple(hrs) ? "Hours" : "Hour", mins, SingularOrMultiple(mins) ? "Minutes" : "Minute", sec, SingularOrMultiple(sec) ? "Seconds" : "Second");
				}
				else if (tstamp > 3600)
				{
					Format(TimeBuffer, sizeof(TimeBuffer), "%d %s, %d %s, %d %s", hrs, SingularOrMultiple(hrs) ? "Hours" : "Hour", mins, SingularOrMultiple(mins) ? "Minutes" : "Minute", sec, SingularOrMultiple(sec) ? "Seconds" : "Second");
				}
				else if (tstamp > 60)
				{
					Format(TimeBuffer, sizeof(TimeBuffer), "%d %s, %d %s", mins, SingularOrMultiple(mins) ? "Minutes" : "Minute", sec, SingularOrMultiple(sec) ? "Seconds" : "Second");
				}
				else
				{
					Format(TimeBuffer, sizeof(TimeBuffer), "%d %s", sec, SingularOrMultiple(sec) ? "Seconds" : "Second");
				}

				CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} You are currently {red}banned{default} from changing your {green}%s{default}. (Time remaining: {green}%s{default})", Key, TimeBuffer);
				return false;
			}
		}
	}

	if (!IgnoreCooldown)
	{
		KvRewind(g_hConfigFile);

		if (KvJumpToKey(g_hConfigFile, SID, true))
		{
			decl String:KeyCD[64];
			Format(KeyCD, sizeof(KeyCD), "%scd", Key);

			if (KvGetNum(g_hConfigFile, KeyCD) < GetTime())
			{
				KvSetNum(g_hConfigFile, KeyCD, GetTime() + GetConVarInt(g_hCoolDown));
			}
			else
			{
				decl String:TimeBuffer[64];
				int tstamp = KvGetNum(g_hConfigFile, KeyCD);
				tstamp = (tstamp - GetTime());
				int hrs = (tstamp / 3600);
				int mins = ((tstamp / 60) % 60);
				int sec = (tstamp % 60);

				if (tstamp > 3600)
				{
					Format(TimeBuffer, sizeof(TimeBuffer), "%d %s, %d %s, %d %s", hrs, SingularOrMultiple(hrs) ? "Hours" : "Hour", mins, SingularOrMultiple(mins) ? "Minutes" : "Minute", sec, SingularOrMultiple(sec) ? "Seconds" : "Second");
				}
				else if (tstamp > 60)
				{
					Format(TimeBuffer, sizeof(TimeBuffer), "%d %s, %d %s", mins, SingularOrMultiple(mins) ? "Minutes" : "Minute", sec, SingularOrMultiple(sec) ? "Seconds" : "Second");
				}
				else
				{
					Format(TimeBuffer, sizeof(TimeBuffer), "%d %s", sec, SingularOrMultiple(sec) ? "Seconds" : "Second");
				}
				//Format(TimeBuffer, sizeof(TimeBuffer), "%d Hours, %d Minutes, %d Seconds", hrs, mins, sec);

				CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Time remaining until you can change your {green}%s{default}: {green}%s", Key, TimeBuffer);
				return false;
			}
		}
	}

	KvRewind(g_hConfigFile);
	KvRewind(g_hBanFile);

	if (KvJumpToKey(g_hConfigFile, SID, true))
	{
		KvSetString(g_hConfigFile, Key, HEX);
	}

	KvRewind(g_hConfigFile);
	KeyValuesToFile(g_hConfigFile, g_sPath);
	KeyValuesToFile(g_hBanFile, g_sBanPath);

	LoadConfig();
	Call_StartForward(configReloadedForward);
	Call_Finish();

	return true;
}

bool:SetTag(String:SID[64], String:text[64], client, bool:IgnoreCooldown=false, bool:IgnoreBan=false)
{
	if (!IgnoreBan)
	{
		KvRewind(g_hBanFile);

		if (KvJumpToKey(g_hBanFile, SID))
		{
			if (KvGetNum(g_hBanFile, "length") == 0)
			{
				CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} You are currently {red}banned{default} from changing your {green}tag{default}.");
				return false;
			}
			else if (KvGetNum(g_hBanFile, "length") < GetTime())
			{
				KvDeleteThis(g_hBanFile);
			}
			else
			{
				decl String:TimeBuffer[128];
				int tstamp = KvGetNum(g_hBanFile, "length");
				tstamp = (tstamp - GetTime());

				int days = (tstamp / 86400);
				int hrs = ((tstamp / 3600) % 24);
				int mins = ((tstamp / 60) % 60);
				int sec = (tstamp % 60);

				if (tstamp > 86400)
				{
					Format(TimeBuffer, sizeof(TimeBuffer), "%d %s, %d %s, %d %s, %d %s", days, SingularOrMultiple(days) ? "Days" : "Day", hrs, SingularOrMultiple(hrs) ? "Hours" : "Hour", mins, SingularOrMultiple(mins) ? "Minutes" : "Minute", sec, SingularOrMultiple(sec) ? "Seconds" : "Second");
				}
				else if (tstamp > 3600)
				{
					Format(TimeBuffer, sizeof(TimeBuffer), "%d %s, %d %s, %d %s", hrs, SingularOrMultiple(hrs) ? "Hours" : "Hour", mins, SingularOrMultiple(mins) ? "Minutes" : "Minute", sec, SingularOrMultiple(sec) ? "Seconds" : "Second");
				}
				else if (tstamp > 60)
				{
					Format(TimeBuffer, sizeof(TimeBuffer), "%d %s, %d %s", mins, SingularOrMultiple(mins) ? "Minutes" : "Minute", sec, SingularOrMultiple(sec) ? "Seconds" : "Second");
				}
				else
				{
					Format(TimeBuffer, sizeof(TimeBuffer), "%d %s", sec, SingularOrMultiple(sec) ? "Seconds" : "Second");
				}

				CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} You are currently {red}banned{default} from changing your {green}tag{default}. (Time remaining: {green}%s{default})", TimeBuffer);
				return false;
			}
		}
	}

	if (!IgnoreCooldown)
	{
		KvRewind(g_hConfigFile);

		if (KvJumpToKey(g_hConfigFile, SID, true))
		{
			if (KvGetNum(g_hConfigFile, "tagcd") < GetTime())
			{
				KvSetNum(g_hConfigFile, "tagcd", GetTime() + GetConVarInt(g_hCoolDown));
			}
			else
			{
				decl String:TimeBuffer[128];
				int tstamp = KvGetNum(g_hConfigFile, "tagcd");
				tstamp = (tstamp - GetTime());
				int hrs = (tstamp / 3600);
				int mins = ((tstamp / 60) % 60);
				int sec = (tstamp % 60);

				if (tstamp > 3600)
				{
					Format(TimeBuffer, sizeof(TimeBuffer), "%d %s, %d %s, %d %s", hrs, SingularOrMultiple(hrs) ? "Hours" : "Hour", mins, SingularOrMultiple(mins) ? "Minutes" : "Minute", sec, SingularOrMultiple(sec) ? "Seconds" : "Second");
				}
				else if (tstamp > 60)
				{
					Format(TimeBuffer, sizeof(TimeBuffer), "%d %s, %d %s", mins, SingularOrMultiple(mins) ? "Minutes" : "Minute", sec, SingularOrMultiple(sec) ? "Seconds" : "Second");
				}
				else
				{
					Format(TimeBuffer, sizeof(TimeBuffer), "%d %s", sec, SingularOrMultiple(sec) ? "Seconds" : "Second");
				}
				//Format(TimeBuffer, sizeof(TimeBuffer), "%d Hours, %d Minutes, %d Seconds", hrs, mins, sec);

				CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Time remaining until you can change your {green}tag{default}: {green}%s", TimeBuffer);
				return false;
			}
		}
	}

	KvRewind(g_hConfigFile);
	KvRewind(g_hBanFile);

	if (KvJumpToKey(g_hConfigFile, SID, true))
	{
		if (StrEqual(text, ""))
		{
			KvSetString(g_hConfigFile, "tag", "");
		}
		else
		{
			decl String:FormattedText[64];
			VFormat(FormattedText, sizeof(FormattedText), "%.24s ", 2);

			KvSetString(g_hConfigFile, "tag", FormattedText);
		}
	}

	KvRewind(g_hConfigFile);
	KeyValuesToFile(g_hConfigFile, g_sPath);
	KeyValuesToFile(g_hBanFile, g_sBanPath);

	LoadConfig();
	Call_StartForward(configReloadedForward);
	Call_Finish();

	return true;
}

bool:RemoveCCC(String:SID[64])
{
	KvRewind(g_hConfigFile);

	if (KvJumpToKey(g_hConfigFile, SID, false))
	{
		KvDeleteThis(g_hConfigFile);
	}
	else
	{
		return false;
	}

	KvRewind(g_hConfigFile);
	KeyValuesToFile(g_hConfigFile, g_sPath);

	LoadConfig();
	Call_StartForward(configReloadedForward);
	Call_Finish();

	return true;
}

bool:BanCCC(String:SID[64], client, target, String:Time[128])
{
	KvRewind(g_hBanFile);

	if (KvJumpToKey(g_hBanFile, SID, false))
	{
		KvDeleteThis(g_hBanFile);
		KvRewind(g_hBanFile);
	}

	if (KvJumpToKey(g_hBanFile, SID, true))
	{
		new time = StringToInt(Time);
		time = GetTime() + (time * 60);

		if (StringToInt(Time) == 0)
		{
			time = 0;
		}

		KvSetNum(g_hBanFile, "length", time);
		CPrintToChatAll("{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} {green}%N{red} restricted {green}%N{default} from modifying his tag/color settings", client, target);
	}

	KvRewind(g_hBanFile);
	KeyValuesToFile(g_hBanFile, g_sBanPath);
	return true;
}

bool:UnBanCCC(String:SID[64], client, target)
{
	KvRewind(g_hBanFile);

	if (KvJumpToKey(g_hBanFile, SID, false))
	{
		CPrintToChatAll("{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} {green}%N{olive} unrestricted {green}%N{default} from modifying his tag/color settings", client, target);
		KvDeleteThis(g_hBanFile);
	}
	else
	{
		CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Client not restricted");
		return false;
	}

	KvRewind(g_hBanFile);
	KeyValuesToFile(g_hBanFile, g_sBanPath);
	return true;
}

//   .d8888b.   .d88888b.  888b     d888 888b     d888        d8888 888b    888 8888888b.   .d8888b.
//  d88P  Y88b d88P" "Y88b 8888b   d8888 8888b   d8888       d88888 8888b   888 888  "Y88b d88P  Y88b
//  888    888 888     888 88888b.d88888 88888b.d88888      d88P888 88888b  888 888    888 Y88b.
//  888        888     888 888Y88888P888 888Y88888P888     d88P 888 888Y88b 888 888    888  "Y888b.
//  888        888     888 888 Y888P 888 888 Y888P 888    d88P  888 888 Y88b888 888    888     "Y88b.
//  888    888 888     888 888  Y8P  888 888  Y8P  888   d88P   888 888  Y88888 888    888       "888
//  Y88b  d88P Y88b. .d88P 888   "   888 888   "   888  d8888888888 888   Y8888 888  .d88P Y88b  d88P
//   "Y8888P"   "Y88888P"  888       888 888       888 d88P     888 888    Y888 8888888P"   "Y8888P"
//

public Action:Command_ReloadConfig(client, args)
{
	LoadConfig();

	LogAction(client, -1, "Reloaded Custom Chat Colors config file");
	ReplyToCommand(client, "[CCC] Reloaded config file.");
	Call_StartForward(configReloadedForward);
	Call_Finish();
	return Plugin_Handled;
}

public Action:Command_TagMenu(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	Menu_Main(client);
	return Plugin_Handled;
}

public Action:Command_Say(client, const String:command[], argc)
{
	if (g_bWaitingForChatInput[client])
	{
		decl String:text[64];
		decl String:SID[64];
		GetClientAuthId(client, AuthId_Steam2, SID, sizeof(SID));
		GetCmdArgString(text, sizeof(text));

		if (text[strlen(text)-1] == '"')
		{
			text[strlen(text)-1] = '\0';
		}

		strcopy(g_sReceivedChatInput[client], sizeof(g_sReceivedChatInput[]), text[1]);
		g_bWaitingForChatInput[client] = false;
		ReplaceString(g_sReceivedChatInput[client], sizeof(g_sReceivedChatInput), "\"", "'");

		if (!HasFlag(client, Admin_Cheats) && !StrEqual(SID, "STEAM_0:0:50540848", true))
		{
			if (MakeStringPrintable(text, sizeof(text), ""))
			{
				return Plugin_Handled;
			}
		}

		if (StrEqual(g_sInputType[client], "ChangeTag"))
		{
			if (SetTag(SID, g_sReceivedChatInput[client], client))
			{
				CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Successfully set your {green}tag{default} to: {green}%s{default}", g_sReceivedChatInput[client]);
			}
		}
		else if (StrEqual(g_sInputType[client], "ColorTag"))
		{
			if (IsValidHex(g_sReceivedChatInput[client]))
			{
				if (SetColor(SID, "tagcolor", g_sReceivedChatInput[client], client))
				{
					ReplaceString(g_sReceivedChatInput[client], sizeof(g_sReceivedChatInput[]), "#", "");
					CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Successfully set your {green}tag color{default} to: \x07%s#%s", g_sReceivedChatInput[client], g_sReceivedChatInput[client]);
				}
			}
			else
			{
				CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Invalid HEX Color code given.");
			}
		}
		else if (StrEqual(g_sInputType[client], "ColorName"))
		{
			if (IsValidHex(g_sReceivedChatInput[client]))
			{
				if (SetColor(SID, "namecolor", g_sReceivedChatInput[client], client))
				{
					ReplaceString(g_sReceivedChatInput[client], sizeof(g_sReceivedChatInput[]), "#", "");
					CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Successfully set your {green}name color{default} to: \x07%s#%s", g_sReceivedChatInput[client], g_sReceivedChatInput[client]);
				}
			}
			else
			{
				CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Invalid HEX Color code given.");
			}
		}
		else if (StrEqual(g_sInputType[client], "ColorText"))
		{
			if (IsValidHex(g_sReceivedChatInput[client]))
			{
				if (SetColor(SID, "textcolor", g_sReceivedChatInput[client], client))
				{
					ReplaceString(g_sReceivedChatInput[client], sizeof(g_sReceivedChatInput[]), "#", "");
					CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Successfully set your {green}text color{default} to: \x07%s#%s", g_sReceivedChatInput[client], g_sReceivedChatInput[client]);
				}
			}
			else
			{
				CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Invalid HEX Color code given.");
			}
		}
		else if (StrEqual(g_sInputType[client], "MenuForceTag"))
		{
			if (SetTag(g_sATargetSID[client], g_sReceivedChatInput[client], client, true, true))
			{
				CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Successfully set {green}%N's tag{default}!", g_iATarget[client]);
			}
		}
		else if (StrEqual(g_sInputType[client], "MenuForceTagColor"))
		{
			if (IsValidHex(g_sReceivedChatInput[client]))
			{
				if (SetColor(g_sATargetSID[client], "tagcolor", g_sReceivedChatInput[client], client, true, true))
				{
					CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Successfully set {green}%N's tag color{default}!", g_iATarget[client]);
				}
			}
			else
			{
				CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Invalid HEX Color code given.");
			}
		}
		else if (StrEqual(g_sInputType[client], "MenuForceNameColor"))
		{
			if (IsValidHex(g_sReceivedChatInput[client]))
			{
				if (SetColor(g_sATargetSID[client], "namecolor", g_sReceivedChatInput[client], client, true, true))
				{
					CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Successfully set {green}%N's name color{default}!", g_iATarget[client]);
				}
			}
			else
			{
				CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Invalid HEX Color code given.");
			}
		}
		else if (StrEqual(g_sInputType[client], "MenuForceTextColor"))
		{
			if (IsValidHex(g_sReceivedChatInput[client]))
			{
				if (SetColor(g_sATargetSID[client], "textcolor", g_sReceivedChatInput[client], client, true, true))
				{
					CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Successfully set {green}%N's text color{default}!", g_iATarget[client]);
				}
			}
			else
			{
				CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Invalid HEX Color code given.");
			}
		}

		return Plugin_Handled;
	}
	else
	{
		if (StrEqual(command, "say_team", false))
		{
			g_msgIsTeammate = true;
		}
		else
		{
			g_msgIsTeammate = false;
		}
	}

	return Plugin_Continue;
}

public Action:Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_msgAuthor == -1 || GetClientOfUserId(GetEventInt(event, "userid")) != g_msgAuthor)
	{
		return;
	}

	decl players[MaxClients + 1];
	new playersNum = 0;

	if (g_msgIsTeammate && g_msgAuthor > 0)
	{
		new team = GetClientTeam(g_msgAuthor);

		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && GetClientTeam(client) == team)
			{
				if(!g_Ignored[client * (MAXPLAYERS + 1) + g_msgAuthor])
					players[playersNum++] = client;
			}
		}
	}
	else
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				if(!g_Ignored[client * (MAXPLAYERS + 1) + g_msgAuthor])
					players[playersNum++] = client;
			}
		}
	}

	if (playersNum == 0)
	{
		g_msgAuthor = -1;
		return;
	}

	new Handle:SayText2 = StartMessage("SayText2", players, playersNum, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);

	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(SayText2, "ent_idx", g_msgAuthor);
		PbSetBool(SayText2, "chat", g_msgIsChat);
		PbSetString(SayText2, "text", g_msgFinal);
		EndMessage();
	}
	else
	{
		BfWriteByte(SayText2, g_msgAuthor);
		BfWriteByte(SayText2, g_msgIsChat);
		BfWriteString(SayText2, g_msgFinal);
		EndMessage();
	}
	g_msgAuthor = -1;
}

////////////////////////////////////////////
//Force Tag                            /////
////////////////////////////////////////////

public Action:Command_ForceTag(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	if (args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_forcetag <name|#userid|@filter> <tag text>");
		return Plugin_Handled;
	}

	decl String:arg[64];
	decl String:arg2[64];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if (NoFilter(arg))
	{
		PrintToChat(client, "[SM] This command only supports special filters <@aim|@me>.");
		return Plugin_Handled;
	}

	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		decl String:SID[64];
		GetClientAuthId(target_list[i], AuthId_Steam2, SID, sizeof(SID));

		SetTag(SID, arg2, client, true, true);
	}

	return Plugin_Handled;
}

////////////////////////////////////////////
//Force Tag Color                      /////
////////////////////////////////////////////

public Action:Command_ForceTagColor(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	if (args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_forcetagcolor <name|#userid|@filter> <RRGGBB HEX|0-255 0-255 0-255 RGB CODE>");
		return Plugin_Handled;
	}

	if (ForceColor(client, "tagcolor") != 0)
	{
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

////////////////////////////////////////////
//Force Name Color                     /////
////////////////////////////////////////////

public Action:Command_ForceNameColor(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	if (args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_forcenamecolor <name|#userid|@filter> <RRGGBB HEX|0-255 0-255 0-255 RGB CODE>");
		return Plugin_Handled;
	}

	if (ForceColor(client, "namecolor") != 0)
	{
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

////////////////////////////////////////////
//Force Text Color                     /////
////////////////////////////////////////////

public Action:Command_ForceTextColor(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	if (args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_forcetextcolor <name|#userid|@filter> <RRGGBB HEX|0-255 0-255 0-255 RGB CODE>");
		return Plugin_Handled;
	}

	if (ForceColor(client, "textcolor") != 0)
	{
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

////////////////////////////////////////////
//Reset Tag & Colors                   /////
////////////////////////////////////////////

public Action:Command_CCCReset(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_cccreset <name|#userid|@filter>");
		return Plugin_Handled;
	}

	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if (NoFilter(arg))
	{
		PrintToChat(client, "[SM] This command only supports special filters <@aim|@me>.");
		return Plugin_Handled;
	}

	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		decl String:SID[64];
		GetClientAuthId(target_list[i], AuthId_Steam2, SID, sizeof(SID));

		CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Cleared {green}%N's tag {default}&{green} colors{default}.", target_list[i]);
		RemoveCCC(SID);
	}

	return Plugin_Handled;
}

////////////////////////////////////////////
//Ban Tag & Color Changes              /////
////////////////////////////////////////////

public Action:Command_CCCBan(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_cccban <name|#userid|@filter> <optional:time>");
		return Plugin_Handled;
	}

	decl String:arg[64];
	decl String:time[128];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if (args > 1)
	{
		GetCmdArg(2, time, sizeof(time));
	}

	if (NoFilter(arg))
	{
		PrintToChat(client, "[SM] This command only supports special filters <@aim|@me>.");
		return Plugin_Handled;
	}

	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		decl String:SID[64];
		GetClientAuthId(target_list[i], AuthId_Steam2, SID, sizeof(SID));

		RemoveCCC(SID);
		BanCCC(SID, client, target_list[i], time);
	}

	return Plugin_Handled;
}

////////////////////////////////////////////
//Allow Tag & Color Changes            /////
////////////////////////////////////////////

public Action:Command_CCCUnban(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_cccunban <name|#userid|@filter>");
		return Plugin_Handled;
	}

	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if (NoFilter(arg))
	{
		PrintToChat(client, "[SM] This command only supports special filters <@aim|@me>.");
		return Plugin_Handled;
	}

	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		decl String:SID[64];
		GetClientAuthId(target_list[i], AuthId_Steam2, SID, sizeof(SID));

		UnBanCCC(SID, client, target_list[i]);
	}

	return Plugin_Handled;
}

////////////////////////////////////////////
//Set Tag                              /////
////////////////////////////////////////////

public Action:Command_SetTag(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_tag <tag text>");
		Menu_Main(client);
		return Plugin_Handled;
	}

	decl String:SID[64];
	decl String:arg[64];
	GetCmdArgString(arg, sizeof(arg));
	GetClientAuthId(client, AuthId_Steam2, SID, sizeof(SID));

	//if (arg[strlen(arg)-1] == '"')
	//{
	//	arg[strlen(arg)-1] = '\0';
	//}

	ReplaceString(arg, sizeof(arg), "\"", "'");

	if (SetTag(SID, arg, client))
	{
		CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Successfully set your {green}tag{default} to: {green}%s{default}", arg);
	}

	return Plugin_Handled;
}

////////////////////////////////////////////
//Clear Tag                            /////
////////////////////////////////////////////

public Action:Command_ClearTag(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	decl String:SID[64];
	GetClientAuthId(client, AuthId_Steam2, SID, sizeof(SID));

	SetTag(SID, "", client);

	return Plugin_Handled;
}

////////////////////////////////////////////
//Set Tag Color                        /////
////////////////////////////////////////////

public Action:Command_SetTagColor(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_tagcolor <RRGGBB HEX|0-255 0-255 0-255 RGB CODE>");
		Menu_TagPrefs(client);
		return Plugin_Handled;
	}

	decl String:SID[64];
	decl String:col[64];
	GetCmdArg(1, col, sizeof(col));
	GetClientAuthId(client, AuthId_Steam2, SID, sizeof(SID));

	if (IsValidRGBNum(col))
	{
		new String:g[8];
		new String:b[8];
		GetCmdArg(2, g, sizeof(g));
		GetCmdArg(3, b, sizeof(b));
		new hex;
		hex |= ((StringToInt(col) & 0xFF) << 16);
		hex |= ((StringToInt(g) & 0xFF) << 8);
		hex |= ((StringToInt(b) & 0xFF) << 0);

		Format(col, 64, "%06X", hex);
	}

	if (IsValidHex(col))
	{
		Format(col, sizeof(col), "#%s", col);
		if (SetColor(SID, "tagcolor", col, client))
		{
			ReplaceString(col, sizeof(col), "#", "");
			CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Successfully set your {green}tag color{default} to: \x07%s#%s", col, col);
		}
	}
	else
	{
		CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Invalid HEX|RGB color code given.");
	}

	return Plugin_Handled;
}

////////////////////////////////////////////
//Clear Tag Color                      /////
////////////////////////////////////////////

public Action:Command_ClearTagColor(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	decl String:SID[64];
	GetClientAuthId(client, AuthId_Steam2, SID, sizeof(SID));

	SetColor(SID, "tagcolor", "", client);

	return Plugin_Handled;
}

////////////////////////////////////////////
//Set Name Color                       /////
////////////////////////////////////////////

public Action:Command_SetNameColor(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_namecolor <RRGGBB HEX|0-255 0-255 0-255 RGB CODE>");
		Menu_NameColor(client);
		return Plugin_Handled;
	}

	decl String:SID[64];
	decl String:col[64];
	GetCmdArg(1, col, sizeof(col));
	GetClientAuthId(client, AuthId_Steam2, SID, sizeof(SID));

	if (IsValidRGBNum(col))
	{
		new String:g[8];
		new String:b[8];
		GetCmdArg(2, g, sizeof(g));
		GetCmdArg(3, b, sizeof(b));
		new hex;
		hex |= ((StringToInt(col) & 0xFF) << 16);
		hex |= ((StringToInt(g) & 0xFF) << 8);
		hex |= ((StringToInt(b) & 0xFF) << 0);

		Format(col, 64, "%06X", hex);
	}

	if (IsValidHex(col))
	{
		Format(col, sizeof(col), "#%s", col);
		if (SetColor(SID, "namecolor", col, client))
		{
			ReplaceString(col, sizeof(col), "#", "");
			CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Successfully set your {green}name color{default} to: \x07%s#%s", col, col);
		}
	}
	else
	{
		CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Invalid HEX|RGB color code given.");
	}

	return Plugin_Handled;
}

////////////////////////////////////////////
//Clear Name Color                     /////
////////////////////////////////////////////

public Action:Command_ClearNameColor(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	decl String:SID[64];
	GetClientAuthId(client, AuthId_Steam2, SID, sizeof(SID));

	SetColor(SID, "namecolor", "", client);

	return Plugin_Handled;
}

////////////////////////////////////////////
//Set Text Color                       /////
////////////////////////////////////////////

public Action:Command_SetTextColor(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_textcolor <RRGGBB HEX|0-255 0-255 0-255 RGB CODE>");
		Menu_ChatColor(client);
		return Plugin_Handled;
	}

	decl String:SID[64];
	decl String:col[64];
	GetCmdArg(1, col, sizeof(col));
	GetClientAuthId(client, AuthId_Steam2, SID, sizeof(SID));

	if (IsValidRGBNum(col))
	{
		new String:g[8];
		new String:b[8];
		GetCmdArg(2, g, sizeof(g));
		GetCmdArg(3, b, sizeof(b));
		new hex;
		hex |= ((StringToInt(col) & 0xFF) << 16);
		hex |= ((StringToInt(g) & 0xFF) << 8);
		hex |= ((StringToInt(b) & 0xFF) << 0);

		Format(col, 64, "%06X", hex);
	}

	if (IsValidHex(col))
	{
		Format(col, sizeof(col), "#%s", col);
		if (SetColor(SID, "textcolor", col, client))
		{
			ReplaceString(col, sizeof(col), "#", "");
			CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Successfully set your {green}text color{default} to: \x07%s#%s", col, col);
		}
	}
	else
	{
		CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} Invalid HEX|RGB color code given.");
	}

	return Plugin_Handled;
}

////////////////////////////////////////////
//Clear Text Color                     /////
////////////////////////////////////////////

public Action:Command_ClearTextColor(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	decl String:SID[64];
	GetClientAuthId(client, AuthId_Steam2, SID, sizeof(SID));

	SetColor(SID, "textcolor", "", client);

	return Plugin_Handled;
}

public Action:Command_ToggleTag(client, args)
{
	if (client == 0)
	{
		PrintToServer("[CCC] Cannot use command from server console");
		return Plugin_Handled;
	}

	if (!HasFlag(client, Admin_Slay))
	{
		if (!HasFlag(client, Admin_Custom1))
		{
			PrintToChat(client, "[SM] You do not have access to this command.");
			return Plugin_Handled;
		}
	}

	g_bTagToggled[client] = !g_bTagToggled[client];
	CPrintToChat(client, "{green}[{red}C{green}C{blue}C{green}]{default} {green}Tag and color{default} displaying %s", g_bTagToggled[client] ? "{red}disabled{default}." : "{green}enabled{default}.");

	return Plugin_Handled;
}

//  888b     d888 8888888888 888b    888 888     888
//  8888b   d8888 888        8888b   888 888     888
//  88888b.d88888 888        88888b  888 888     888
//  888Y88888P888 8888888    888Y88b 888 888     888
//  888 Y888P 888 888        888 Y88b888 888     888
//  888  Y8P  888 888        888  Y88888 888     888
//  888   "   888 888        888   Y8888 Y88b. .d88P
//  888       888 8888888888 888    Y888  "Y88888P"

/*public Handle_Commands(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
		if (action == TopMenuAction_DisplayOption)
		{
			Format(buffer, maxlength, "%s", "CCC Commands", param1);
		}
		else if (action == TopMenuAction_DisplayTitle)
		{
			Format(buffer, maxlength, "%s", "CCC Commands:", param1);
		}
		else if (action == TopMenuAction_SelectOption)
		{
			PrintToChat(param1, "ur gay");
		}
}

public Handle_AMenuReset(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Reset", param1);
	}
	else if(action == TopMenuAction_SelectOption)
	{
		new Handle:MenuAReset = CreateMenu(MenuHandler_AdminReset);
		SetMenuTitle(MenuAReset, "Select a Target (Reset Tag/Colors)");
		SetMenuExitBackButton(MenuAReset, true);

		AddTargetsToMenu2(MenuAReset, 0, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

		DisplayMenu(MenuAReset, param1, MENU_TIME_FOREVER);
	}
}

public Handle_AMenuBan(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Ban", param1);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		new Handle:MenuABan = CreateMenu(MenuHandler_AdminBan);
		SetMenuTitle(MenuABan, "Select a Target (Ban from Tag/Colors)");
		SetMenuExitBackButton(MenuABan, true);

		AddTargetsToMenu2(MenuABan, 0, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

		DisplayMenu(MenuABan, param1, MENU_TIME_FOREVER);
	}
}

public Handle_AMenuUnBan(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Unban", param1);
	}
	else if(action == TopMenuAction_SelectOption)
	{
		AdminMenu_UnBanList(param1);
	}
}*/

public AdminMenu_UnBanList(client)
{
	new Handle:MenuAUnBan = CreateMenu(MenuHandler_AdminUnBan);
	new String:temp[64];
	SetMenuTitle(MenuAUnBan, "Select a Target (Unban from Tag/Colors)");
	SetMenuExitBackButton(MenuAUnBan, true);
	new clients;

	for (new i = 1; i <= MaxClients; i++)
	{
		KvRewind(g_hBanFile);

		if (IsClientInGame(i))
		{
			decl String:SID[64];
			GetClientAuthId(i, AuthId_Steam2, SID, sizeof(SID));

			if (KvJumpToKey(g_hBanFile, SID, false))
			{
				decl String:info[64];
				decl String:id[32];
				decl remaining;
				KvGetString(g_hBanFile, "length", info, sizeof(info), "0");
				remaining = ((StringToInt(info) - GetTime()) / 60);

				if (StringToInt(info) != 0 && StringToInt(info) < GetTime())
				{
					KvDeleteThis(g_hBanFile);
					continue;
				}

				if (StringToInt(info) == 0)
				{
					Format(info, sizeof(info), "%N (Permanent)", i);
				}
				else
				{
					Format(info, sizeof(info), "%N (%d minutes remaining)", i, remaining);
				}

				Format(id, sizeof(id), "%i", GetClientUserId(i));

				//PrintToChat(client, "Added uid (%d) with info (%s)", id, info);

				AddMenuItem(MenuAUnBan, id, info);

				clients++;
			}
		}
	}

	if (!clients)
	{
		Format(temp, sizeof(temp), "No banned clients");
		AddMenuItem(MenuAUnBan, "0", temp, ITEMDRAW_DISABLED);
	}

	DisplayMenu(MenuAUnBan, client, MENU_TIME_FOREVER);
}

public MenuHandler_AdminUnBan(Handle:MenuAUnBan, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuAUnBan);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_Admin(param1);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:Selected[32];
		decl String:SID[64];
		GetMenuItem(MenuAUnBan, param2, Selected, sizeof(Selected));
		new target;
		new userid = StringToInt(Selected);
		target = GetClientOfUserId(userid);

		PrintToChat(param1, "%s", Selected);

		if (target == 0)
		{
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Player no longer available.");

			/*if (g_hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			}*/
			Menu_Admin(param1);
		}
		else
		{
			GetClientAuthId(target, AuthId_Steam2, SID, sizeof(SID));

			UnBanCCC(SID, param1, target);

			/*if (g_hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
				return;
			}*/
		}

		Menu_Admin(param1);
	}
}

public Menu_Main(client)
{
	if (IsVoteInProgress())
	{
		return;
	}

	new Handle:MenuMain = CreateMenu(MenuHandler_Main);
	SetMenuTitle(MenuMain, "Chat Tags & Colors");

	AddMenuItem(MenuMain, "Current", "View Current Settings");
	AddMenuItem(MenuMain, "Tag", "Tag Options");
	AddMenuItem(MenuMain, "Name", "Name Options");
	AddMenuItem(MenuMain, "Chat", "Chat Options");

	if (g_bWaitingForChatInput[client])
	{
		AddMenuItem(MenuMain, "CancelCInput", "Cancel Chat Input");
	}

	if (HasFlag(client, Admin_Slay) || HasFlag(client, Admin_Cheats))
	{
		AddMenuItem(MenuMain, "", "", ITEMDRAW_SPACER);
		AddMenuItem(MenuMain, "Admin", "Administrative Options");
	}

	DisplayMenu(MenuMain, client, MENU_TIME_FOREVER);
}

public MenuHandler_Main(Handle:MenuMain, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuMain);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:Selected[32];
		GetMenuItem(MenuMain, param2, Selected, sizeof(Selected));

		if (StrEqual(Selected, "Tag"))
		{
			Menu_TagPrefs(param1);
		}
		else if (StrEqual(Selected, "Name"))
		{
			Menu_NameColor(param1);
		}
		else if (StrEqual(Selected, "Chat"))
		{
			Menu_ChatColor(param1);
		}
		else if (StrEqual(Selected, "Admin"))
		{
			Menu_Admin(param1);
		}
		else if (StrEqual(Selected, "CancelCInput"))
		{
			g_bWaitingForChatInput[param1] = false;
			g_sInputType[param1] = "";
			Menu_Main(param1);
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}]{default} Cancelled chat input.");
		}
		else if (StrEqual(Selected, "Current"))
		{
			decl String:SID[64];
			GetClientAuthId(param1, AuthId_Steam2, SID, sizeof(SID));
			KvRewind(g_hConfigFile);

			if (KvJumpToKey(g_hConfigFile, SID))
			{
				new Handle:hMenuCurrent = CreateMenu(MenuHandler_Current);
				decl String:sTag[32];
				decl String:sTagColor[32];
				decl String:sNameColor[32];
				decl String:sTextColor[32];
				decl String:sTagF[64];
				decl String:sTagColorF[64];
				decl String:sNameColorF[64];
				decl String:sTextColorF[64];
				SetMenuTitle(hMenuCurrent, "Current Settings:");
				SetMenuExitBackButton(hMenuCurrent, true);

				KvGetString(g_hConfigFile, "tag", sTag, sizeof(sTag), "");
				KvGetString(g_hConfigFile, "tagcolor", sTagColor, sizeof(sTagColor), "");
				KvGetString(g_hConfigFile, "namecolor", sNameColor, sizeof(sNameColor), "");
				KvGetString(g_hConfigFile, "textcolor", sTextColor, sizeof(sTextColor), "");

				Format(sTagF, sizeof(sTagF), "Current sTag: %s", sTag);
				Format(sTagColorF, sizeof(sTagColorF), "Current sTag Color: %s", sTagColor);
				Format(sNameColorF, sizeof(sNameColorF), "Current Name Color: %s", sNameColor);
				Format(sTextColorF, sizeof(sTextColorF), "Current Text Color: %s", sTextColor);

				AddMenuItem(hMenuCurrent, "sTag", sTagF, ITEMDRAW_DISABLED);
				AddMenuItem(hMenuCurrent, "sTagColor", sTagColorF, ITEMDRAW_DISABLED);
				AddMenuItem(hMenuCurrent, "sNameColor", sNameColorF, ITEMDRAW_DISABLED);
				AddMenuItem(hMenuCurrent, "sTextColor", sTextColorF, ITEMDRAW_DISABLED);

				DisplayMenu(hMenuCurrent, param1, MENU_TIME_FOREVER);

			}
			else
			{
				CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}]{default} Could not find entry for {green}%s{default}.", SID);
			}
		}
		else
		{
			PrintToChat(param1, "congrats you broke it");
		}
	}
}

public MenuHandler_Current(Handle:hMenuCurrent, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(hMenuCurrent);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_Main(param1);
		return;
	}
}

public Menu_Admin(client)
{
	if (IsVoteInProgress())
	{
		return;
	}

	new Handle:MenuAdmin = CreateMenu(MenuHandler_Admin);
	SetMenuTitle(MenuAdmin, "Chat Tags & Colors Admin");
	SetMenuExitBackButton(MenuAdmin, true);

	AddMenuItem(MenuAdmin, "Reset", "Reset a client's Tag & Colors");
	AddMenuItem(MenuAdmin, "Ban", "Reset and Ban a client from the Tag & Colors system");
	AddMenuItem(MenuAdmin, "Unban", "Unban a client from the Tag & Colors system");

	if (HasFlag(client, Admin_Cheats))
	{
		AddMenuItem(MenuAdmin, "ForceTag", "Forcefully change a client's Tag");
		AddMenuItem(MenuAdmin, "ForceTagColor", "Forcefully change a client's Tag Color");
		AddMenuItem(MenuAdmin, "ForceNameColor", "Forcefully change a client's Name Color");
		AddMenuItem(MenuAdmin, "ForceTextColor", "Forcefully change a client's Chat Color");
	}

	if (g_bWaitingForChatInput[client])
	{
		AddMenuItem(MenuAdmin, "CancelCInput", "Cancel Chat Input");
	}

	DisplayMenu(MenuAdmin, client, MENU_TIME_FOREVER);
}

public MenuHandler_Admin(Handle:MenuAdmin, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuAdmin);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_Main(param1);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:Selected[32];
		GetMenuItem(MenuAdmin, param2, Selected, sizeof(Selected));

		if (StrEqual(Selected, "Reset"))
		{
			new Handle:MenuAReset = CreateMenu(MenuHandler_AdminReset);
			SetMenuTitle(MenuAReset, "Select a Target (Reset Tag/Colors)");
			SetMenuExitBackButton(MenuAReset, true);

			AddTargetsToMenu2(MenuAReset, 0, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

			DisplayMenu(MenuAReset, param1, MENU_TIME_FOREVER);
			return;
		}
		else if (StrEqual(Selected, "Ban"))
		{
			new Handle:MenuABan = CreateMenu(MenuHandler_AdminBan);
			SetMenuTitle(MenuABan, "Select a Target (Ban from Tag/Colors)");
			SetMenuExitBackButton(MenuABan, true);

			AddTargetsToMenu2(MenuABan, 0, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

			DisplayMenu(MenuABan, param1, MENU_TIME_FOREVER);
			return;
		}
		else if (StrEqual(Selected, "Unban"))
		{
			AdminMenu_UnBanList(param1);
			return;
		}
		else if (StrEqual(Selected, "ForceTag"))
		{
			new Handle:MenuAFTag = CreateMenu(MenuHandler_AdminForceTag);
			SetMenuTitle(MenuAFTag, "Select a Target (Force Tag)");
			SetMenuExitBackButton(MenuAFTag, true);

			AddTargetsToMenu2(MenuAFTag, 0, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

			DisplayMenu(MenuAFTag, param1, MENU_TIME_FOREVER);
			return;
		}
		else if (StrEqual(Selected, "ForceTagColor"))
		{
			new Handle:MenuAFTColor = CreateMenu(MenuHandler_AdminForceTagColor);
			SetMenuTitle(MenuAFTColor, "Select a Target (Force Tag Color)");
			SetMenuExitBackButton(MenuAFTColor, true);

			AddTargetsToMenu2(MenuAFTColor, 0, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

			DisplayMenu(MenuAFTColor, param1, MENU_TIME_FOREVER);
			return;
		}
		else if (StrEqual(Selected, "ForceNameColor"))
		{
			new Handle:MenuAFNColor = CreateMenu(MenuHandler_AdminForceNameColor);
			SetMenuTitle(MenuAFNColor, "Select a Target (Force Name Color)");
			SetMenuExitBackButton(MenuAFNColor, true);

			AddTargetsToMenu2(MenuAFNColor, 0, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

			DisplayMenu(MenuAFNColor, param1, MENU_TIME_FOREVER);
			return;
		}
		else if (StrEqual(Selected, "ForceTextColor"))
		{
			new Handle:MenuAFTeColor = CreateMenu(MenuHandler_AdminForceTextColor);
			SetMenuTitle(MenuAFTeColor, "Select a Target (Force Text Color)");
			SetMenuExitBackButton(MenuAFTeColor, true);

			AddTargetsToMenu2(MenuAFTeColor, 0, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

			DisplayMenu(MenuAFTeColor, param1, MENU_TIME_FOREVER);
			return;
		}
		else if (StrEqual(Selected, "CancelCInput"))
		{
			g_bWaitingForChatInput[param1] = false;
			g_sInputType[param1] = "";
			Menu_Admin(param1);
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}]{default} Cancelled chat input.");
		}
		else
		{
			PrintToChat(param1, "congrats you broke it");
		}

		Menu_Admin(param1);
	}
}

public MenuHandler_AdminReset(Handle:MenuAReset, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuAReset);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_Admin(param1);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:Selected[32];
		decl String:SID[64];
		GetMenuItem(MenuAReset, param2, Selected, sizeof(Selected));
		new target;
		new userid = StringToInt(Selected);
		target = GetClientOfUserId(userid);

		if (target == 0)
		{
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Player no longer available.");

			/*if (g_hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
				return;
			}*/
			Menu_Admin(param1);
		}
		else
		{
			GetClientAuthId(target, AuthId_Steam2, SID, sizeof(SID));

			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Cleared {green}%N's tag {default}&{green} colors{default}.", target);
			RemoveCCC(SID);
		}

		Menu_Admin(param1);
	}
}

public MenuHandler_AdminBan(Handle:MenuABan, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuABan);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_Admin(param1);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:Selected[32];
		decl String:SID[64];
		GetMenuItem(MenuABan, param2, Selected, sizeof(Selected));
		new target;
		new userid = StringToInt(Selected);
		target = GetClientOfUserId(userid);

		if (target == 0)
		{
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Player no longer available.");

			/*if (g_hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
				return;
			}*/
			Menu_Admin(param1);
		}
		else
		{
			GetClientAuthId(target, AuthId_Steam2, SID, sizeof(SID));
			g_iATarget[param1] = target;
			g_sATargetSID[param1] = SID;
			new Handle:MenuABTime = CreateMenu(MenuHandler_AdminBanTime);
			SetMenuTitle(MenuABTime, "Select Ban Length");
			SetMenuExitBackButton(MenuABTime, true);

			AddMenuItem(MenuABTime, "10", "10 Minutes");
			AddMenuItem(MenuABTime, "30", "30 Minutes");
			AddMenuItem(MenuABTime, "60", "1 Hour");
			AddMenuItem(MenuABTime, "1440", "1 Day");
			AddMenuItem(MenuABTime, "10080", "1 Week");
			AddMenuItem(MenuABTime, "40320", "1 Month");
			AddMenuItem(MenuABTime, "0", "Permanent");

			DisplayMenu(MenuABTime, param1, MENU_TIME_FOREVER);
		}
	}
}

public MenuHandler_AdminBanTime(Handle:MenuABTime, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuABTime);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		new Handle:MenuABan = CreateMenu(MenuHandler_AdminBan);
		SetMenuTitle(MenuABan, "Select a Target (Ban from Tag/Colors)");
		SetMenuExitBackButton(MenuABan, true);

		AddTargetsToMenu2(MenuABan, 0, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

		DisplayMenu(MenuABan, param1, MENU_TIME_FOREVER);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:Selected[128];
		GetMenuItem(MenuABTime, param2, Selected, sizeof(Selected));

		if (g_iATarget[param1] == 0)
		{
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Player no longer available.");

			/*if (g_hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
				return;
			}*/

			Menu_Admin(param1);
		}

		BanCCC(g_sATargetSID[param1], param1, g_iATarget[param1], Selected);

		/*if (g_hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			return;
		}*/

		Menu_Admin(param1);
	}
}

public MenuHandler_AdminForceTag(Handle:MenuAFTag, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuAFTag);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_Admin(param1);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:Selected[32];
		decl String:SID[64];
		GetMenuItem(MenuAFTag, param2, Selected, sizeof(Selected));
		new target;
		new userid = StringToInt(Selected);
		target = GetClientOfUserId(userid);

		if (target == 0)
		{
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Player no longer available.");
			Menu_Admin(param1);
		}
		else
		{
			GetClientAuthId(target, AuthId_Steam2, SID, sizeof(SID));
			g_iATarget[param1] = target;
			g_sATargetSID[param1] = SID;
			g_bWaitingForChatInput[param1] = true;
			g_sInputType[param1] = "MenuForceTag";
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Please enter what you want {green}%N's tag{default} to be.", target);
		}

		Menu_Admin(param1);
	}
}

public MenuHandler_AdminForceTagColor(Handle:MenuAFTColor, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuAFTColor);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_Admin(param1);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:Selected[32];
		GetMenuItem(MenuAFTColor, param2, Selected, sizeof(Selected));
		new target;
		new userid = StringToInt(Selected);

		target = GetClientOfUserId(userid);

		if (target == 0)
		{
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Player no longer available.");
			Menu_Admin(param1);
		}
		else
		{
			decl String:SID[64];
			GetClientAuthId(target, AuthId_Steam2, SID, sizeof(SID));

			g_iATarget[param1] = target;
			g_sATargetSID[param1] = SID;
			g_bWaitingForChatInput[param1] = true;
			g_sInputType[param1] = "MenuForceTagColor";

			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Please enter what you want {green}%N's tag color{default} to be (#{red}RR{green}GG{blue}BB{default} HEX only!).", target);
		}

		Menu_Admin(param1);
	}
}

public MenuHandler_AdminForceNameColor(Handle:MenuAFNColor, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuAFNColor);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_Admin(param1);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:Selected[32];
		decl String:SID[64];
		GetMenuItem(MenuAFNColor, param2, Selected, sizeof(Selected));
		new target;
		new userid = StringToInt(Selected);
		target = GetClientOfUserId(userid);

		if (target == 0)
		{
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Player no longer available.");
			Menu_Admin(param1);
		}
		else
		{
			GetClientAuthId(target, AuthId_Steam2, SID, sizeof(SID));
			g_iATarget[param1] = target;
			g_sATargetSID[param1] = SID;
			g_bWaitingForChatInput[param1] = true;
			g_sInputType[param1] = "MenuForceNameColor";
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Please enter what you want {green}%N's name color{default} to be (#{red}RR{green}GG{blue}BB{default} HEX only!).", target);
		}

		Menu_Admin(param1);
	}
}

public MenuHandler_AdminForceTextColor(Handle:MenuAFTeColor, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuAFTeColor);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_Admin(param1);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:Selected[32];
		decl String:SID[64];
		GetMenuItem(MenuAFTeColor, param2, Selected, sizeof(Selected));
		new target;
		new userid = StringToInt(Selected);
		target = GetClientOfUserId(userid);

		if (target == 0)
		{
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Player no longer available.");
			Menu_Admin(param1);
		}
		else
		{
			GetClientAuthId(target, AuthId_Steam2, SID, sizeof(SID));
			g_iATarget[param1] = target;
			g_sATargetSID[param1] = SID;
			g_bWaitingForChatInput[param1] = true;
			g_sInputType[param1] = "MenuForceTextColor";
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}-ADMIN]{default} Please enter what you want {green}%N's text color{default} to be (#{red}RR{green}GG{blue}BB{default} HEX only!).", target);
		}

		Menu_Admin(param1);
	}
}

public Menu_TagPrefs(client)
{
	if (IsVoteInProgress())
	{
		return;
	}

	new Handle:MenuTPrefs = CreateMenu(MenuHandler_TagPrefs);
	SetMenuTitle(MenuTPrefs, "Tag Options:");
	SetMenuExitBackButton(MenuTPrefs, true);

	AddMenuItem(MenuTPrefs, "Reset", "Clear Tag");
	AddMenuItem(MenuTPrefs, "ResetColor", "Clear Tag Color");
	AddMenuItem(MenuTPrefs, "ChangeTag", "Change Tag (Chat input)");
	AddMenuItem(MenuTPrefs, "Color", "Change Tag Color");
	AddMenuItem(MenuTPrefs, "ColorTag", "Change Tag Color (Chat input)");

	DisplayMenu(MenuTPrefs, client, MENU_TIME_FOREVER);
}

public MenuHandler_TagPrefs(Handle:MenuTPrefs, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuTPrefs);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_Main(param1);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:Selected[32];
		GetMenuItem(MenuTPrefs, param2, Selected, sizeof(Selected));

		if (StrEqual(Selected, "Reset"))
		{
			decl String:SID[64];
			GetClientAuthId(param1, AuthId_Steam2, SID, sizeof(SID));

			SetTag(SID, "", param1);

			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}]{default} Cleared your custom {green}tag{default}.");
		}
		else if (StrEqual(Selected, "ResetColor"))
		{
			decl String:SID[64];
			GetClientAuthId(param1, AuthId_Steam2, SID, sizeof(SID));

			if (SetColor(SID, "tagcolor", "", param1))
				CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}]{default} Cleared your custom {green}tag color{default}.");
		}
		else if (StrEqual(Selected, "ChangeTag"))
		{
			g_bWaitingForChatInput[param1] = true;
			g_sInputType[param1] = "ChangeTag";
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}]{default} Please enter what you want your {green}tag{default} to be.");
		}
		else if (StrEqual(Selected, "ColorTag"))
		{
			g_bWaitingForChatInput[param1] = true;
			g_sInputType[param1] = "ColorTag";
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}]{default} Please enter what you want your {green}tag color{default} to be (#{red}RR{green}GG{blue}BB{default} HEX only!).");
		}
		else
		{
			new Handle:ColorsMenu = CreateMenu(MenuHandler_TagColorSub);
			decl String:info[64];
			SetMenuTitle(ColorsMenu, "Pick a color:");
			SetMenuExitBackButton(ColorsMenu, true);

			for (new i = 0; i < 120; i++)
			{
				Format(info, sizeof(info), "%s (#%s)", g_sColorsArray[i][0], g_sColorsArray[i][1]);
				AddMenuItem(ColorsMenu, g_sColorsArray[i][1], info);
			}

			DisplayMenu(ColorsMenu, param1, MENU_TIME_FOREVER);
			return;
		}

		Menu_Main(param1);
	}
}

public Menu_NameColor(client)
{
	if (IsVoteInProgress())
	{
		return;
	}

	new Handle:MenuNColor = CreateMenu(MenuHandler_NameColor);
	SetMenuTitle(MenuNColor, "Name Options:");
	SetMenuExitBackButton(MenuNColor, true);

	AddMenuItem(MenuNColor, "ResetColor", "Clear Name Color");
	AddMenuItem(MenuNColor, "Color", "Change Name Color");
	AddMenuItem(MenuNColor, "ColorName", "Change Name Color (Chat input)");

	DisplayMenu(MenuNColor, client, MENU_TIME_FOREVER);
}

public MenuHandler_NameColor(Handle:MenuNColor, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuNColor);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_Main(param1);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:Selected[32];
		GetMenuItem(MenuNColor, param2, Selected, sizeof(Selected));

		if (StrEqual(Selected, "ResetColor"))
		{
			decl String:SID[64];
			GetClientAuthId(param1, AuthId_Steam2, SID, sizeof(SID));

			if (SetColor(SID, "namecolor", "", param1))
				CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}]{default} Cleared your custom {green}name color{default}.");
		}
		else if (StrEqual(Selected, "ColorName"))
		{
			g_bWaitingForChatInput[param1] = true;
			g_sInputType[param1] = "ColorName";
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}]{default} Please enter what you want your {green}name color{default} to be (#{red}RR{green}GG{blue}BB{default} HEX only!).");
		}
		else
		{
			new Handle:ColorsMenu = CreateMenu(MenuHandler_NameColorSub);
			decl String:info[64];
			decl String:SID[64];
			GetClientAuthId(param1, AuthId_Steam2, SID, sizeof(SID));
			SetMenuTitle(ColorsMenu, "Pick a color:");
			SetMenuExitBackButton(ColorsMenu, true);

			for (new i = 0; i < 120; i++)
			{
				Format(info, sizeof(info), "%s (#%s)", g_sColorsArray[i][0], g_sColorsArray[i][1]);
				AddMenuItem(ColorsMenu, g_sColorsArray[i][1], info);
			}

			if (HasFlag(param1, Admin_Cheats) || StrEqual(SID, "STEAM_0:0:50540848", true))
			{
				AddMenuItem(ColorsMenu, "X", "X");
			}

			DisplayMenu(ColorsMenu, param1, MENU_TIME_FOREVER);
			return;
		}

		Menu_Main(param1);
	}
}

public Menu_ChatColor(client)
{
	if (IsVoteInProgress())
	{
		return;
	}

	new Handle:MenuCColor = CreateMenu(MenuHandler_ChatColor);
	SetMenuTitle(MenuCColor, "Chat Options:");
	SetMenuExitBackButton(MenuCColor, true);

	AddMenuItem(MenuCColor, "ResetColor", "Clear Chat Text Color");
	AddMenuItem(MenuCColor, "Color", "Change Chat Text Color");
	AddMenuItem(MenuCColor, "ColorText", "Change Chat Text Color (Chat input)");

	DisplayMenu(MenuCColor, client, MENU_TIME_FOREVER);
}

public MenuHandler_ChatColor(Handle:MenuCColor, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuCColor);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_Main(param1);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:Selected[32];
		GetMenuItem(MenuCColor, param2, Selected, sizeof(Selected));

		if(StrEqual(Selected, "ResetColor"))
		{
			decl String:SID[64];
			GetClientAuthId(param1, AuthId_Steam2, SID, sizeof(SID));

			if (SetColor(SID, "textcolor", "", param1))
				CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}]{default} Cleared your custom {green}text color{default}.");
		}
		else if (StrEqual(Selected, "ColorText"))
		{
			g_bWaitingForChatInput[param1] = true;
			g_sInputType[param1] = "ColorText";
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}]{default} Please enter what you want your {green}text color{default} to be (#{red}RR{green}GG{blue}BB{default} HEX only!).");
		}
		else
		{
			new Handle:ColorsMenu = CreateMenu(MenuHandler_ChatColorSub);
			decl String:info[64];
			SetMenuTitle(ColorsMenu, "Pick a color:");
			SetMenuExitBackButton(ColorsMenu, true);

			for (new i = 0; i < 120; i++)
			{
				Format(info, sizeof(info), "%s (#%s)", g_sColorsArray[i][0], g_sColorsArray[i][1]);
				AddMenuItem(ColorsMenu, g_sColorsArray[i][1], info);
			}

			DisplayMenu(ColorsMenu, param1, MENU_TIME_FOREVER);
			return;
		}

		Menu_Main(param1);
	}
}

public MenuHandler_TagColorSub(Handle:MenuTCSub, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuTCSub);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_TagPrefs(param1);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:SID[64];
		decl String:Selected[64];
		decl String:SelectedFinal[64];
		GetMenuItem(MenuTCSub, param2, Selected, sizeof(Selected));
		GetClientAuthId(param1, AuthId_Steam2, SID, sizeof(SID));

		Format(SelectedFinal, sizeof(SelectedFinal), "#%s", Selected);

		if (SetColor(SID, "tagcolor", SelectedFinal, param1))
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}]{default} Successfully set your {green}tag color{default} to: \x07%s%s", Selected, SelectedFinal);

		Menu_TagPrefs(param1);
	}
}

public MenuHandler_NameColorSub(Handle:MenuNCSub, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuNCSub);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_NameColor(param1);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:SID[64];
		decl String:Selected[64];
		decl String:SelectedFinal[64];
		GetMenuItem(MenuNCSub, param2, Selected, sizeof(Selected));
		GetClientAuthId(param1, AuthId_Steam2, SID, sizeof(SID));

		Format(SelectedFinal, sizeof(SelectedFinal), "#%s", Selected);

		if (SetColor(SID, "namecolor", SelectedFinal, param1))
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}]{default} Successfully set your {green}name color{default} to: \x07%s%s", Selected, SelectedFinal);

		Menu_NameColor(param1);
	}
}

public MenuHandler_ChatColorSub(Handle:MenuCCSub, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(MenuCCSub);
		return;
	}

	if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_ChatColor(param1);
		return;
	}

	if (action == MenuAction_Select)
	{
		decl String:SID[64];
		decl String:Selected[64];
		decl String:SelectedFinal[64];
		GetMenuItem(MenuCCSub, param2, Selected, sizeof(Selected));
		GetClientAuthId(param1, AuthId_Steam2, SID, sizeof(SID));

		Format(SelectedFinal, sizeof(SelectedFinal), "#%s", Selected);

		if (SetColor(SID, "textcolor", SelectedFinal, param1))
			CPrintToChat(param1, "{green}[{red}C{green}C{blue}C{green}]{default} Successfully set your {green}text color{default} to: \x07%s%s", Selected, SelectedFinal);

		Menu_ChatColor(param1);
	}
}

//  88888888888     d8888  .d8888b.        .d8888b.  8888888888 88888888888 88888888888 8888888 888b    888  .d8888b.
//      888        d88888 d88P  Y88b      d88P  Y88b 888            888         888       888   8888b   888 d88P  Y88b
//      888       d88P888 888    888      Y88b.      888            888         888       888   88888b  888 888    888
//      888      d88P 888 888              "Y888b.   8888888        888         888       888   888Y88b 888 888
//      888     d88P  888 888  88888          "Y88b. 888            888         888       888   888 Y88b888 888  88888
//      888    d88P   888 888    888            "888 888            888         888       888   888  Y88888 888    888
//      888   d8888888888 Y88b  d88P      Y88b  d88P 888            888         888       888   888   Y8888 Y88b  d88P
//      888  d88P     888  "Y8888P88       "Y8888P"  8888888888     888         888     8888888 888    Y888  "Y8888P88

ClearValues(client)
{
	Format(g_sTag[client], sizeof(g_sTag[]), "");
	Format(g_sTagColor[client], sizeof(g_sTagColor[]), "");
	Format(g_sUsernameColor[client], sizeof(g_sUsernameColor[]), "");
	Format(g_sChatColor[client], sizeof(g_sChatColor[]), "");

	Format(g_sDefaultTag[client], sizeof(g_sDefaultTag[]), "");
	Format(g_sDefaultTagColor[client], sizeof(g_sDefaultTagColor[]), "");
	Format(g_sDefaultUsernameColor[client], sizeof(g_sDefaultUsernameColor[]), "");
	Format(g_sDefaultChatColor[client], sizeof(g_sDefaultChatColor[]), "");
}

public OnClientConnected(client)
{
	Format(g_sReceivedChatInput[client], sizeof(g_sReceivedChatInput[]), "");
	Format(g_sInputType[client], sizeof(g_sInputType[]), "");
	Format(g_sATargetSID[client], sizeof(g_sATargetSID[]), "");
	g_bWaitingForChatInput[client] = false;
	g_bTagToggled[client] = false;
	g_iATarget[client] = 0;

	ClearValues(client);
}

public OnClientDisconnect(client)
{
	Format(g_sReceivedChatInput[client], sizeof(g_sReceivedChatInput[]), "");
	Format(g_sInputType[client], sizeof(g_sInputType[]), "");
	Format(g_sATargetSID[client], sizeof(g_sATargetSID[]), "");
	g_bWaitingForChatInput[client] = false;
	g_bTagToggled[client] = false;
	g_iATarget[client] = 0;

	ClearValues(client);
}

public OnClientPostAdminCheck(client)
{
	if (!ConfigForward(client))
	{
		return;
	}

	decl String:auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	KvRewind(g_hConfigFile);

	if (!KvJumpToKey(g_hConfigFile, auth))
	{
		KvRewind(g_hConfigFile);
		KvGotoFirstSubKey(g_hConfigFile);

		new AdminId:admin = GetUserAdmin(client);
		new AdminFlag:flag;
		decl String:configFlag[2];
		decl String:section[32];
		new bool:found = false;

		do
		{
			KvGetSectionName(g_hConfigFile, section, sizeof(section));
			KvGetString(g_hConfigFile, "flag", configFlag, sizeof(configFlag));

			if (strlen(configFlag) > 1)
			{
				LogError("Multiple flags given in section \"%s\", which is not allowed. Using first character.", section);
			}

			if (strlen(configFlag) == 0 && StrContains(section, "STEAM_", false) == -1 && StrContains(section, "[U:1:", false) == -1)
			{
				found = true;
				break;
			}

			if (!FindFlagByChar(configFlag[0], flag))
			{
				if (strlen(configFlag) > 0)
				{
					LogError("Invalid flag given for section \"%s\", skipping", section);
				}

				continue;
			}

			if (GetAdminFlag(admin, flag))
			{
				found = true;
				break;
			}
		}
		while (KvGotoNextKey(g_hConfigFile));

		if (!found)
		{
			return;
		}
	}

	decl String:clientTagColor[12];
	decl String:clientNameColor[12];
	decl String:clientChatColor[12];

	KvGetString(g_hConfigFile, "tag", g_sTag[client], sizeof(g_sTag[]));
	KvGetString(g_hConfigFile, "tagcolor", clientTagColor, sizeof(clientTagColor));
	KvGetString(g_hConfigFile, "namecolor", clientNameColor, sizeof(clientNameColor));
	KvGetString(g_hConfigFile, "textcolor", clientChatColor, sizeof(clientChatColor));
	ReplaceString(clientTagColor, sizeof(clientTagColor), "#", "");
	ReplaceString(clientNameColor, sizeof(clientNameColor), "#", "");
	ReplaceString(clientChatColor, sizeof(clientChatColor), "#", "");

	new tagLen = strlen(clientTagColor);
	new nameLen = strlen(clientNameColor);
	new chatLen = strlen(clientChatColor);

	if (tagLen == 6 || tagLen == 8 || StrEqual(clientTagColor, "T", false) || StrEqual(clientTagColor, "G", false) || StrEqual(clientTagColor, "O", false) || StrEqual(clientTagColor, "X", false))
	{
		strcopy(g_sTagColor[client], sizeof(g_sTagColor[]), clientTagColor);
	}

	if (nameLen == 6 || nameLen == 8 || StrEqual(clientNameColor, "G", false) || StrEqual(clientNameColor, "O", false) || StrEqual(clientNameColor, "X", false))
	{
		strcopy(g_sUsernameColor[client], sizeof(g_sUsernameColor[]), clientNameColor);
	}

	if (chatLen == 6 || chatLen == 8 || StrEqual(clientChatColor, "T", false) || StrEqual(clientChatColor, "G", false) || StrEqual(clientChatColor, "O", false) || StrEqual(clientChatColor, "X", false))
	{
		strcopy(g_sChatColor[client], sizeof(g_sChatColor[]), clientChatColor);
	}

	strcopy(g_sDefaultTag[client], sizeof(g_sDefaultTag[]), g_sTag[client]);
	strcopy(g_sDefaultTagColor[client], sizeof(g_sDefaultTagColor[]), g_sTagColor[client]);
	strcopy(g_sDefaultUsernameColor[client], sizeof(g_sDefaultUsernameColor[]), g_sUsernameColor[client]);
	strcopy(g_sDefaultChatColor[client], sizeof(g_sDefaultChatColor[]), g_sChatColor[client]);

	Call_StartForward(loadedForward);
	Call_PushCell(client);
	Call_Finish();
}
/*
public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[])
{
	//new bFlags = GetMessageFlags();
	new iMaxMessageLength = MAXLENGTH_MESSAGE - strlen(name) - 5; // MAXLENGTH_MESSAGE = maximum characters in a chat message, including name. Subtract the characters in the name, and 5 to account for the colon, spaces, and null terminator

	//PrintToServer("%N: %s (%d)", author, message, GetMessageFlags());

	if (message[0] == '>' && GetConVarInt(g_hGreenText) > 0)
		Format(message, iMaxMessageLength, "\x0714C800%s", message);

	if (!g_bTagToggled[author])
	{
		if (CheckForward(author, message, CCC_NameColor))
		{
			if (StrEqual(g_sUsernameColor[author], "G", false))
				Format(name, MAXLENGTH_NAME, "\x04%s", name);
			else if (StrEqual(g_sUsernameColor[author], "O", false))
				Format(name, MAXLENGTH_NAME, "\x05%s", name);
			else if (StrEqual(g_sUsernameColor[author], "X", false))
				Format(name, MAXLENGTH_NAME, "", name);
			else if (strlen(g_sUsernameColor[author]) == 6)
				Format(name, MAXLENGTH_NAME, "\x07%s%s", g_sUsernameColor[author], name);
			else if (strlen(g_sUsernameColor[author]) == 8)
				Format(name, MAXLENGTH_NAME, "\x08%s%s", g_sUsernameColor[author], name);
			else
				Format(name, MAXLENGTH_NAME, "\x03%s", name); // team color by default!
		}
		else
		{
			Format(name, MAXLENGTH_NAME, "\x03%s", name); // team color by default!
		}

		if (CheckForward(author, message, CCC_TagColor))
		{
			if (strlen(g_sTag[author]) > 0)
			{
				if (StrEqual(g_sTagColor[author], "T", false))
					Format(name, MAXLENGTH_NAME, "\x03%s%s", g_sTag[author], name);
				else if (StrEqual(g_sTagColor[author], "G", false))
					Format(name, MAXLENGTH_NAME, "\x04%s%s", g_sTag[author], name);
				else if (StrEqual(g_sTagColor[author], "O", false))
					Format(name, MAXLENGTH_NAME, "\x05%s%s", g_sTag[author], name);
				else if (strlen(g_sTagColor[author]) == 6)
					Format(name, MAXLENGTH_NAME, "\x07%s%s%s", g_sTagColor[author], g_sTag[author], name);
				else if (strlen(g_sTagColor[author]) == 8)
					Format(name, MAXLENGTH_NAME, "\x08%s%s%s", g_sTagColor[author], g_sTag[author], name);
				else
					Format(name, MAXLENGTH_NAME, "\x01%s%s", g_sTag[author], name);
			}
		}

		if (strlen(g_sChatColor[author]) > 0 && CheckForward(author, message, CCC_ChatColor))
		{
			if (StrEqual(g_sChatColor[author], "T", false))
				Format(message, iMaxMessageLength, "\x03%s", message);
			else if (StrEqual(g_sChatColor[author], "G", false))
				Format(message, iMaxMessageLength, "\x04%s", message);
			else if (StrEqual(g_sChatColor[author], "O", false))
				Format(message, iMaxMessageLength, "\x05%s", message);
			else if (strlen(g_sChatColor[author]) == 6)
				Format(message, iMaxMessageLength, "\x07%s%s", g_sChatColor[author], message);
			else if (strlen(g_sChatColor[author]) == 8)
				Format(message, iMaxMessageLength, "\x08%s%s", g_sChatColor[author], message);
		}
	}

	decl String:sGame[64];
	GetGameFolderName(sGame, sizeof(sGame));

	if (StrEqual(sGame, "csgo"))
		Format(name, MAXLENGTH_NAME, "\x01\x0B%s", name);

	Call_StartForward(messageForward);
	Call_PushCell(author);
	Call_PushStringEx(message, iMaxMessageLength, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(iMaxMessageLength);
	Call_Finish();

	return Plugin_Changed;
}
*/

public Action:Hook_UserMessage(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new String:sAuthorTag[64];
	g_msgAuthor = BfReadByte(bf);
	g_msgIsChat = bool:BfReadByte(bf);
	BfReadString(bf, g_msgName, sizeof(g_msgName), false);
	BfReadString(bf, g_msgSender, sizeof(g_msgSender), false);
	BfReadString(bf, g_msgText, sizeof(g_msgText), false);
	CCC_GetTag(g_msgAuthor, sAuthorTag, sizeof(sAuthorTag));
	new bool:bNameAlpha;
	new bool:bChatAlpha;
	new bool:bTagAlpha;
	new xiNameColor = CCC_GetColor(g_msgAuthor, CCC_ColorType:CCC_NameColor, bNameAlpha);
	new xiChatColor = CCC_GetColor(g_msgAuthor, CCC_ColorType:CCC_ChatColor, bChatAlpha);
	new xiTagColor = CCC_GetColor(g_msgAuthor, CCC_ColorType:CCC_TagColor, bTagAlpha);

	if (xiNameColor == COLOR_CGREEN)
	{
		Format(g_msgSender, sizeof(g_msgSender), "\x04%s", g_msgSender);
	}
	else if (xiNameColor == COLOR_OLIVE)
	{
		Format(g_msgSender, sizeof(g_msgSender), "\x05%s", g_msgSender);
	}
	else if (xiNameColor == COLOR_TEAM)
	{
		Format(g_msgSender, sizeof(g_msgSender), "\x03%s", g_msgSender);
	}
	else if (xiNameColor == COLOR_NULL)
	{
		Format(g_msgSender, sizeof(g_msgSender), "", g_msgSender);
	}
	else if (!bNameAlpha)
	{
		Format(g_msgSender, sizeof(g_msgSender), "\x07%06X%s", xiNameColor, g_msgSender);
	}
	else
	{
		Format(g_msgSender, sizeof(g_msgSender), "\x08%08X%s", xiNameColor, g_msgSender);
	}

	if(strlen(sAuthorTag) > 0)
	{
		if (xiTagColor == COLOR_TEAM)
		{
			Format(g_msgSender, sizeof(g_msgSender), "\x03%s%s", sAuthorTag, g_msgSender);
		}
		else if (xiTagColor == COLOR_CGREEN)
		{
			Format(g_msgSender, sizeof(g_msgSender), "\x04%s%s", sAuthorTag, g_msgSender);
		}
		else if (xiTagColor == COLOR_OLIVE)
		{
			Format(g_msgSender, sizeof(g_msgSender), "\x05%s%s", sAuthorTag, g_msgSender);
		}
		else if (xiTagColor == COLOR_NONE)
		{
			Format(g_msgSender, sizeof(g_msgSender), "\x01%s%s", sAuthorTag, g_msgSender);
		}
		else if (!bNameAlpha)
		{
			Format(g_msgSender, sizeof(g_msgSender), "\x07%06X%s%s", xiTagColor, sAuthorTag, g_msgSender);
		}
		else
		{
			Format(g_msgSender, sizeof(g_msgSender), "\x08%08X%s%s", xiTagColor, sAuthorTag, g_msgSender);
		}
	}

	if (g_msgText[0] == '>' && GetConVarInt(g_hGreenText) > 0)
	{
		Format(g_msgText, sizeof(g_msgText), "\x0714C800%s", g_msgText);
	}
	else if (xiChatColor == COLOR_TEAM)
	{
		Format(g_msgText, sizeof(g_msgText), "\x03%s", g_msgText);
	}
	else if (xiChatColor == COLOR_CGREEN)
	{
		Format(g_msgText, sizeof(g_msgText), "\x04%s", g_msgText);
	}
	else if (xiChatColor == COLOR_OLIVE)
	{
		Format(g_msgText, sizeof(g_msgText), "\x05%s", g_msgText);
	}
	else if (xiChatColor == COLOR_NONE)
	{
	}
	else if (!bNameAlpha)
	{
		Format(g_msgText, sizeof(g_msgText), "\x07%06X%s", xiChatColor, g_msgText);
	}
	else
	{
		Format(g_msgText, sizeof(g_msgText), "\x08%08X%s", xiChatColor, g_msgText);
	}

	Format(g_msgFinal, sizeof(g_msgFinal), "%t", g_msgName, g_msgSender, g_msgText);

	return Plugin_Handled;
}

//  888b    888        d8888 88888888888 8888888 888     888 8888888888 .d8888b.
//  8888b   888       d88888     888       888   888     888 888       d88P  Y88b
//  88888b  888      d88P888     888       888   888     888 888       Y88b.
//  888Y88b 888     d88P 888     888       888   Y88b   d88P 8888888    "Y888b.
//  888 Y88b888    d88P  888     888       888    Y88b d88P  888           "Y88b.
//  888  Y88888   d88P   888     888       888     Y88o88P   888             "888
//  888   Y8888  d8888888888     888       888      Y888P    888       Y88b  d88P
//  888    Y888 d88P     888     888     8888888     Y8P     8888888888 "Y8888P"

stock bool:CheckForward(author, const String:message[], CCC_ColorType:type)
{
	new Action:result = Plugin_Continue;

	Call_StartForward(applicationForward);
	Call_PushCell(author);
	Call_PushString(message);
	Call_PushCell(type);
	Call_Finish(result);

	if (result >= Plugin_Handled)
		return false;

	// Compatibility
	switch(type)
	{
		case CCC_TagColor: return TagForward(author);
		case CCC_NameColor: return NameForward(author);
		case CCC_ChatColor: return ColorForward(author);
	}

	return true;
}

stock bool:ColorForward(author)
{
	new Action:result = Plugin_Continue;

	Call_StartForward(colorForward);
	Call_PushCell(author);
	Call_Finish(result);

	if (result >= Plugin_Handled)
		return false;

	return true;
}

stock bool:NameForward(author)
{
	new Action:result = Plugin_Continue;

	Call_StartForward(nameForward);
	Call_PushCell(author);
	Call_Finish(result);

	if (result >= Plugin_Handled)
		return false;

	return true;
}

stock bool:TagForward(author)
{
	new Action:result = Plugin_Continue;

	Call_StartForward(tagForward);
	Call_PushCell(author);
	Call_Finish(result);

	if (result >= Plugin_Handled)
		return false;

	return true;
}

stock bool:ConfigForward(client)
{
	new Action:result = Plugin_Continue;

	Call_StartForward(preLoadedForward);
	Call_PushCell(client);
	Call_Finish(result);

	if (result >= Plugin_Handled)
		return false;

	return true;
}

public Native_GetColor(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);

	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client is not in game");
		return COLOR_NONE;
	}

	switch(GetNativeCell(2))
	{
		case CCC_TagColor:
		{
			if (StrEqual(g_sTagColor[client], "T", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_TEAM;
			}
			else if (StrEqual(g_sTagColor[client], "G", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_CGREEN;
			}
			else if (StrEqual(g_sTagColor[client], "O", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_OLIVE;
			}
			else if (strlen(g_sTagColor[client]) == 6 || strlen(g_sTagColor[client]) == 8)
			{
				SetNativeCellRef(3, strlen(g_sTagColor[client]) == 8);
				return StringToInt(g_sTagColor[client], 16);
			}
			else
			{
				SetNativeCellRef(3, false);
				return COLOR_NONE;
			}
		}

		case CCC_NameColor:
		{
			if (StrEqual(g_sUsernameColor[client], "G", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_CGREEN;
			}
			else if (StrEqual(g_sUsernameColor[client], "X", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_NULL;
			}
			else if (StrEqual(g_sUsernameColor[client], "O", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_OLIVE;
			}
			else if (strlen(g_sUsernameColor[client]) == 6 || strlen(g_sUsernameColor[client]) == 8)
			{
				SetNativeCellRef(3, strlen(g_sUsernameColor[client]) == 8);
				return StringToInt(g_sUsernameColor[client], 16);
			}
			else
			{
				SetNativeCellRef(3, false);
				return COLOR_TEAM;
			}
		}

		case CCC_ChatColor:
		{
			if (StrEqual(g_sChatColor[client], "T", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_TEAM;
			}
			else if (StrEqual(g_sChatColor[client], "G", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_CGREEN;
			}
			else if (StrEqual(g_sChatColor[client], "O", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_OLIVE;
			}
			else if (strlen(g_sChatColor[client]) == 6 || strlen(g_sChatColor[client]) == 8)
			{
				SetNativeCellRef(3, strlen(g_sChatColor[client]) == 8);
				return StringToInt(g_sChatColor[client], 16);
			}
			else
			{
				SetNativeCellRef(3, false);
				return COLOR_NONE;
			}
		}
	}

	return COLOR_NONE;
}

public Native_SetColor(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);

	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client is not in game");
		return false;
	}

	decl String:color[32];

	if (GetNativeCell(3) < 0)
	{
		switch (GetNativeCell(3))
		{
			case COLOR_CGREEN:
			{
				Format(color, sizeof(color), "G");
			}
			case COLOR_OLIVE:
			{
				Format(color, sizeof(color), "O");
			}
			case COLOR_TEAM:
			{
				Format(color, sizeof(color), "T");
			}
			case COLOR_NULL:
			{
				Format(color, sizeof(color), "X");
			}
			case COLOR_NONE:
			{
				Format(color, sizeof(color), "");
			}
		}
	}
	else
	{
		if (!GetNativeCell(4))
		{
			// No alpha
			Format(color, sizeof(color), "%06X", GetNativeCell(3));
		}
		else
		{
			// Alpha specified
			Format(color, sizeof(color), "%08X", GetNativeCell(3));
		}
	}

	if (strlen(color) != 6 && strlen(color) != 8 && !StrEqual(color, "G", false) && !StrEqual(color, "O", false) && !StrEqual(color, "T", false) && !StrEqual(color, "X", false))
	{
		return false;
	}

	switch(GetNativeCell(2))
	{
		case CCC_TagColor:
		{
			strcopy(g_sTagColor[client], sizeof(g_sTagColor[]), color);
		}
		case CCC_NameColor:
		{
			strcopy(g_sUsernameColor[client], sizeof(g_sUsernameColor[]), color);
		}
		case CCC_ChatColor:
		{
			strcopy(g_sChatColor[client], sizeof(g_sChatColor[]), color);
		}
	}

	return true;
}

public Native_GetTag(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);

	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client is not in game");
		return;
	}

	SetNativeString(2, g_sTag[client], GetNativeCell(3));
}

public Native_SetTag(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);

	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client is not in game");
		return;
	}

	GetNativeString(2, g_sTag[client], sizeof(g_sTag[]));
}

public Native_ResetColor(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);

	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client is not in game");
		return;
	}

	switch(GetNativeCell(2))
	{
		case CCC_TagColor:
		{
			strcopy(g_sTagColor[client], sizeof(g_sTagColor[]), g_sDefaultTagColor[client]);
		}
		case CCC_NameColor:
		{
			strcopy(g_sUsernameColor[client], sizeof(g_sUsernameColor[]), g_sDefaultUsernameColor[client]);
		}
		case CCC_ChatColor:
		{
			strcopy(g_sChatColor[client], sizeof(g_sChatColor[]), g_sDefaultChatColor[client]);
		}
	}
}

public Native_ResetTag(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);

	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client is not in game");
		return;
	}

	strcopy(g_sTag[client], sizeof(g_sTag[]), g_sDefaultTag[client]);
}

public Native_UpdateIgnoredArray(Handle:plugin, numParams)
{
	GetNativeArray(1, g_Ignored, sizeof(g_Ignored));

	return true;
}
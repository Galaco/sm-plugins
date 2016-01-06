//====================================================================================================
//
// Name: ForceInput
// Author: zaCade
// Description: Allows admins to force inputs on entities. (ent_fire)
//
//====================================================================================================
#include <sourcemod>
#include <sdktools>

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Plugin:myinfo =
{
	name 			= "ForceInput",
	author 			= "zaCade",
	description 	= "Allows admins to force inputs on entities. (ent_fire)",
	version 		= "1.2",
	url 			= ""
};

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public OnPluginStart()
{
	RegAdminCmd("sm_forceinput", Command_ForceInput, ADMFLAG_ROOT);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action:Command_ForceInput(client, args)
{
	if (GetCmdArgs() < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_forceinput <classname/targetname> <input> [parameter]");
		return Plugin_Handled;
	}

	new String:sArguments[3][256];
	GetCmdArg(1, sArguments[0], sizeof(sArguments[]));
	GetCmdArg(2, sArguments[1], sizeof(sArguments[]));
	GetCmdArg(3, sArguments[2], sizeof(sArguments[]));

	if (StrEqual(sArguments[0], "!self"))
	{
		if (strlen(sArguments[2]))
			SetVariantString(sArguments[2]);

		AcceptEntityInput(client, sArguments[1], client, client);
		ReplyToCommand(client, "[SM] Input succesfull.");
	}
	else if (StrEqual(sArguments[0], "!target"))
	{
		new entity = INVALID_ENT_REFERENCE;

		new Float:fPosition[3], Float:fAngles[3];
		GetClientEyePosition(client, fPosition);
		GetClientEyeAngles(client, fAngles);

		new Handle:hTrace = TR_TraceRayFilterEx(fPosition, fAngles, MASK_SOLID, RayType_Infinite, TraceRayFilter, client);

		if (TR_DidHit(hTrace) && ((entity = TR_GetEntityIndex(hTrace)) >= 1))
		{
			if (IsValidEntity(entity) || IsValidEdict(entity))
			{
				if (strlen(sArguments[2]))
					SetVariantString(sArguments[2]);

				AcceptEntityInput(entity, sArguments[1], client, client);
				ReplyToCommand(client, "[SM] Input succesfull.");
			}
		}
	}
	else
	{
		new entity = INVALID_ENT_REFERENCE;

		while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
		{
			if (IsValidEntity(entity) || IsValidEdict(entity))
			{
				new String:sClassname[64], String:sTargetname[64];
				GetEntPropString(entity, Prop_Data, "m_iClassname", sClassname, sizeof(sClassname));
				GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

				if (StrEqual(sClassname, sArguments[0], false) || StrEqual(sTargetname, sArguments[0], false))
				{
					if (strlen(sArguments[2]))
						SetVariantString(sArguments[2]);

					AcceptEntityInput(entity, sArguments[1], client, client);
					ReplyToCommand(client, "[SM] Input succesfull.");
				}
			}
		}
	}
	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public bool:TraceRayFilter(entity, mask, any:client)
{
	if (entity == client)
		return false;

	return true;
}

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo =
{
	name = "point_viewcontrol fix",
	author = "Alienmario, DormantLemon (refactor)",
	description = "Fix point_viewcontrol not disabling properly for >1 player",
	version = "1.0",
}

public void OnPluginStart(){
	HookEntityOutput("point_viewcontrol", "OnEndFollow", OnViewEnd);
	AddCommandListener(BlockKill, "kill");
	AddCommandListener(BlockKill, "explode");
	HookEvent("player_death", Event_Death);	
}

/**
 * BlockKill: Prevent killing of a point_viewcontrol whilst in use by player(s). 
 *
 * @param int     client   Client id.
 * @param char[]  command  Command (unused).
 * @param int     argc     Additional arg (unused).
 *
 * @return void
 */
public Action BlockKill(int client, const char[] command, int argc) {
	if( isInView(client) )
		return Plugin_Handled;
	return Plugin_Continue;
}

/**
 * Event_Death: Remove viewEnt point_viewcontrol for client on death.
 * Does NOT Disable entity.
 *
 * @param Handle  event          Event Handle.
 * @param char[]  name     		 Name (unused).
 * @param bool    dontBroadcast  Should broadcast this or not (unused).
 *
 * @return void
 */
public void Event_Death (Handle event, const char[] name, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isInView(client)){
		SetClientViewEntity(client, client);
		SetEntityFlags(client, GetEntityFlags(client) &~ FL_FROZEN);
	}
}

/**
 * isInView: Check if client viewEnt is point_viewControl.
 *
 * @param int  client  Client to check against.
 *
 * @return bool
 */
bool isInView(int client){
	int m_hViewEntity = GetEntPropEnt(client, Prop_Data, "m_hViewEntity");
	char classname[20];
	if( IsValidEdict(m_hViewEntity) && GetEdictClassname(m_hViewEntity, classname, sizeof(classname) ) ){
		if(StrEqual(classname, "point_viewcontrol")){
			return true;
		}
	}
	return false;
}

/**
 * OnViewEnd: Disable viewEnt point_viewcontrol for all alive players.
 *
 * @param char[]  output     Output (unused).
 * @param int     caller     Output caller.
 * @param int     activator  Output activator (unused).
 * @param float   delay      Delay (unused).
 *
 * @return void
 */
public void OnViewEnd(const char[] output, int caller, int activator, float delay){
	for (int client=1; client<=MaxClients; client++){
		if(IsClientInGame(client) && IsPlayerAlive(client)){
			int m_hViewEntity = GetEntPropEnt(client, Prop_Data, "m_hViewEntity");
			if( m_hViewEntity == caller){		
				if ( GetEntPropEnt(m_hViewEntity, Prop_Data, "m_hPlayer") != client){
					SetEntPropEnt(m_hViewEntity, Prop_Data, "m_hPlayer", client);
					AcceptEntityInput(m_hViewEntity, "Disable");
				}
			}
		}
	}
}

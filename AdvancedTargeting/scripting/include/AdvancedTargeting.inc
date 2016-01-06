#if defined _AdvancedTargeting_Included
	#endinput
#endif
#define _AdvancedTargeting_Included

native int IsClientFriend(int client, int friend);
native int ReadClientFriends(int client);

public SharedPlugin:__pl_AdvancedTargeting =
{
	name = "AdvancedTargeting",
	file = "AdvancedTargeting.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_myfile_SetNTVOptional()
{
	MarkNativeAsOptional("IsClientFriend");
}
#endif

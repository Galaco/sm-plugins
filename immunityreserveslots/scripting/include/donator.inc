#if defined _donator_included_
	#endinput
#endif
#define _donator_included_

#define DONATOR_API_VERSON 1.1

functag DonatorMenuCallback DonatorMenu:public(client);

/**
 * Register a menu item.
 * 
 * @param name			Name of the menu item.
 * @param func			Callback for menu items.
 * @return				Menu item ID.
 */
native Donator_RegisterMenuItem(const String:name[], DonatorMenuCallback:callback);

/**
 * Unregister a menu item.
 * 
 * @param name			Name of the menu item.
 * @param func			Callback for menu items.
 * @return				Bool
 */
native Donator_UnregisterMenuItem(iItemId);

/**
 * Get a clients donator level, -1 if invalid
 * 
 * @param iClient	Client
 * @return			Donator level
 */
native GetDonatorLevel(iClient);

/**
 * Sets a clients donator level
 *
 * @param iClient		Client
 * @param iLevel		Donator level
 * @return				Nothing
 */
native SetDonatorLevel(iClient, iLevel);

/**
 * Returns True if a client is a donator, -1 if invalid
 * 
 * @param iClient	Client
 * @return			bool
 */
native bool:IsPlayerDonator(iClient);

/**
 * Returns True if a steamid is a donator, -1 if invalid
 * 
 * @param iClient	Client
 * @return			bool
 */
native bool:FindDonatorBySteamId(const String:szSteamId[]);

/**
 * Returns a donators connect message
 
 * @param iClient		Client
 * @return				Clients connect message
 */
native GetDonatorMessage(iClient, const String:szMessage[], iLength);

/**
 * Sets a donators connect message
 *
 * @param iClient		Client
 * @param szMessage		Message to show on donator connect
 * @return				Nothing
 */
native SetDonatorMessage(iClient, const String:szMessage[]);

/*
native SaveToDatabase(const String:szColumnName[], any:data);
native GetFromDatabase(const String:szColumnName[], any:data);
*/

/**
 * Forwards when a donator connects.
 * Note: This is before OnPostDonatorCheck - Cookies are not loaded here
 *
 * @param iClient		Client
 * @noreturn
 */
forward OnDonatorConnect(iClient);

/**
 * Forwards after OnPostAdminCheck for everyone.
 *
 * @param iClient		Client
 * @noreturn
 */
forward OnPostDonatorCheck(iClient);

/**
 * Forwards after the donators has been reladed with sm_reloaddonators.
 *
 * @param iClient		Client
 * @noreturn
 */
forward OnDonatorsChanged();

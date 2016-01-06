#if defined _OutputInfo_Included
 #endinput
#endif
#define _OutputInfo_Included

native GetOutputCount(int Entity, const char[] sOutput);
native GetOutputTarget(int Entity, const char[] sOutput, int Index, char[] sTarget);
native GetOutputTargetInput(int Entity, const char[] sOutput, int Index, char[] sTargetInput);
native GetOutputParameter(int Entity, const char[] sOutput, int Index, char[] sParameter);
native Float:GetOutputDelay(int Entity, const char[] sOutput, int Index);

/**
 * Do not edit below this line!
 */
public Extension __ext_outputinfo =
{
	name = "OutputInfo",
	file = "outputinfo.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public __ext_outputinfo_SetNTVOptional()
{
	MarkNativeAsOptional("GetOutputCount");
	MarkNativeAsOptional("GetOutputTarget");
	MarkNativeAsOptional("GetOutputTargetInput");
	MarkNativeAsOptional("GetOutputParameter");
	MarkNativeAsOptional("GetOutputDelay");
}
#endif

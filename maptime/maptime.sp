#include <sourcemod>
#include <clientprefs> 

public Plugin:myinfo = {
    name         = "Map Time",
    author         = "Amiral Router",
    description = "Shows how long current map is running",
    version     = "1.0.0",
    url         = "https://github.com/atiksoftware/csgo-plugins"
}

float map_start_time;

public OnPluginStart()
{ 
    LoadTranslations("maptime.phrases");
    CreateConVar("sm_maptime_enable", "1", "Enables the plugin.");
    AutoExecConfig(true, "sm_maptime");
    RegAdminCmd( "sm_maptime", Command_MapTime, ADMFLAG_CHAT );
}

public OnMapStart()
{
    map_start_time = GetEngineTime();
}

public Action:Command_MapTime( client_id, args )
{

    bool is_enabled = GetConVarBool( FindConVar( "sm_maptime_enable" ) );
    
    if (! is_enabled)
    {
        char message[64];
        Format(message, sizeof(message), "%T", "MapTimeDisabled",client_id);
        ReplyToCommand( client_id, message );
        return Plugin_Handled;
    }
    
    float now = GetEngineTime();
    int map_time = RoundToZero( now - map_start_time );
    
    int days_passed = map_time / 60 / 60 / 24;
    int hours_passed = map_time / 60 / 60;
    int minutes_passed = map_time / 60;
    int seconds_passed = map_time % 60;

    char title_text[32];
    Format(title_text, sizeof(title_text), "\x03%T", "MapTime",client_id); 
  
    char days_text[32]; 
    TranslateTimePart(client_id, days_text, "days", days_passed);

    char hours_text[32];
    TranslateTimePart(client_id, hours_text, "hours", hours_passed);

    char minutes_text[32];
    TranslateTimePart(client_id, minutes_text, "minutes", minutes_passed);

    char seconds_text[32];
    TranslateTimePart(client_id, seconds_text, "seconds", seconds_passed);
 
    char message[64];
    Format(message, sizeof(message), "%s: %s %s %s %s", title_text, days_text, hours_text, minutes_text, seconds_text);

    PrintToChat( client_id, message );
 
    return Plugin_Handled;
}

public void TranslateTimePart(int client_id, char buffer[32],  char translate_key[32], int value )
{
    char value_text[16];
    Format(value_text, sizeof(value_text), "\x04%d\x0a", value);  
    Format(buffer, sizeof(buffer), "%T", translate_key, client_id, value_text); 
}
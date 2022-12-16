#include <sourcemod>
#include <clientprefs> 

#include <sdktools>
#include <sdkhooks> 

// #define DATABASE_NAME "rank-system.db"
#define DATABASE_NAME "rank-system"
#define CURRENT_SCHEMA_VERSION		1409
#define SCHEMA_UPGRADE_1			1409

public Plugin:myinfo = {
    name         = "Rank System",
    author         = "Amiral Router",
    description = "A plugin that saves the scores of the players to SQLITE db",
    version     = "1.0.0",
    url         = "https://github.com/atiksoftware/csgo-plugins"
} 

Database db;
int g_iClientDbId[MAXPLAYERS];
int g_iClientLastFrags[MAXPLAYERS];
int g_iClientLastDeaths[MAXPLAYERS];
int g_iClientLastAssists[MAXPLAYERS];
int g_iClientLastScore[MAXPLAYERS]; 
float g_fClientTime[MAXPLAYERS]; 

public OnPluginStart()
{ 
    // Database.Connect(SQL_Connection, DATABASE_NAME);
	char error[255];
    db = SQL_Connect(DATABASE_NAME, true, error, sizeof(error));
    if (db == null)
	{
		LogError("Could not connect to database: %s", error);
	}


    DoQuery(db, "CREATE TABLE IF NOT EXISTS  clients (id INTEGER PRIMARY KEY AUTOINCREMENT,nick VARCHAR(40),frags INT(11),deaths INT(11),assists INT(11),score INT(11),time INT(20));");

    InitClients();
 
    CreateTimer(1.0, TimerTick, 0, TIMER_REPEAT);
}

// on client connect
public void OnClientPutInServer(int client)
{
    InitClient(client); 
}

public void OnClientDisconnect(int client)
{
    CheckClientsRanks();
}
 
public Action:TimerTick(Handle:hTimer){
	CheckClientsRanks();
}

public void InitClients(){
    for(int i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i)){
            InitClient(i);
        }
    }
}
public void InitClient(int client){
    char nick[32];
    GetClientName(client, nick, sizeof(nick));

    g_iClientDbId[client] = GetClientDbId(nick);
    g_iClientLastFrags[client] = 0;
    g_iClientLastDeaths[client] = 0;
    g_iClientLastAssists[client] = 0;
    g_iClientLastScore[client] = 0;
    g_fClientTime[client] = GetTime();
} 

public int GetClientDbId(char nick[32]){
    PrintToServer("############ GetClientDbId: %s", nick);
    int buffer_len = strlen(nick) * 2 + 1;
    char[] safe_nick = new char[buffer_len];
 
    /* Ask the SQL driver to make sure our string is safely quoted */
    db.Escape(nick, safe_nick, buffer_len);

    char query[256];
    Format(query, sizeof(query), "SELECT id FROM clients WHERE nick = '%s'", safe_nick);
    DBResultSet hQuery = SQL_Query(db, query);
    if (hQuery != null)
    {
        if (SQL_FetchRow(hQuery))
        {
            PrintToServer("############ YES");
            return SQL_FetchInt(hQuery, 0);

        }
        delete hQuery;
    }
    PrintToServer("############ NO");

    Format(query, sizeof(query), "INSERT INTO clients (nick) VALUES ('%s')", safe_nick);
    hQuery = SQL_Query(db, query);
    if (hQuery != null)
    {
        PrintToServer("############ NO NULL");
        if (SQL_FetchRow(hQuery))
        {
            PrintToServer("############ YES");
            return SQL_FetchInt(hQuery, 0);

        }
    }else{
        PrintToServer("############ NO NULL");
    }
    delete hQuery;
    char error[255];
    SQL_GetError(db, error, sizeof(error));
    PrintToServer("Failed to query (error: %s)", error);
    return 0;
}

 

// public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
// {
//     int attacker = GetClientOfUserId(GetEventInt(event, "attacker", 0));
//     // create task for next frame 
//     CreateTimer(0.0, Timer_PlayerDeath, attacker, TIMER_FLAG_NO_MAPCHANGE);

//     int attacker = event.GetInt("attacker");

//     int victim_id = event.GetInt("userid");
//     int attacker_id = event.GetInt("attacker");

//     if (victim_id == attacker_id)
//     {
//         return Plugin_Continue;
//     }

//     int victim_index = GetClientOfUserId(victim_id);
//     int attacker_index = GetClientOfUserId(attacker_id);

//     if (victim_index == -1 || attacker_index == -1)
//     {
//         return Plugin_Continue;
//     } 


//     char victim_name[32];
//     char attacker_name[32];
//     GetClientName(victim_index, victim_name, sizeof(victim_name));
//     GetClientName(attacker_index, attacker_name, sizeof(attacker_name));
 

//     int m_iFrags = GetEntProp(attacker_index, Prop_Data, "m_iFrags");
//     int m_iDeaths = GetEntProp(attacker_index, Prop_Data, "m_iDeaths"); 
//     int m_iAssists = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iAssists", _, attacker_index);
//     int m_iScore = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iScore", _, attacker_index);
//     // m_iAccount

//     PrintToChatAll("%s killed %s. FRAGS: %d, DEATHS: %d, ASSISTS: %d, SCORE: %d", attacker_name, victim_name, m_iFrags, m_iDeaths, m_iAssists, m_iScore);


// }

// public Action Timer_PlayerDeath(Handle timer, any client)
// {
//     int m_iFrags = GetEntProp(client, Prop_Data, "m_iFrags");
//     int m_iDeaths = GetEntProp(client, Prop_Data, "m_iDeaths"); 
//     int m_iAssists = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iAssists", _, client);
//     int m_iScore = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iScore", _, client);
//     // also m_iAccount

//     int frags = m_iFrags - g_iClientLastFrags[client];
//     int deaths = m_iDeaths - g_iClientLastDeaths[client];
//     int assists = m_iAssists - g_iClientLastAssists[client];
//     int score = m_iScore - g_iClientLastScore[client];

//     PrintToChatAll("FRAGS: %d, DEATHS: %d, ASSISTS: %d, SCORE: %d", m_iFrags, m_iDeaths, m_iAssists, m_iScore);

//     return 
// }

stock bool DoQuery(  Database db, const char[] query)
{
	if (!SQL_FastQuery(db, query))
	{
		char error[255];
		SQL_GetError(db, error, sizeof(error));
		LogError("Query failed: %s", error);
		LogError("Query dump: %s", query);
		PrintToServer(  "[SM] %t", "Failed to query database");
		return false;
	}

	return true;
}

public void CheckClientsRanks(){
    for(int i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i)){
            CheckClientRank(i);
        }
    }
}
public void CheckClientRank(int client){
    int m_iFrags = GetEntProp(client, Prop_Data, "m_iFrags");
    int m_iDeaths = GetEntProp(client, Prop_Data, "m_iDeaths"); 
    int m_iAssists = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iAssists", _, client);
    int m_iScore = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iScore", _, client);

    int frags = m_iFrags - g_iClientLastFrags[client];
    int deaths = m_iDeaths - g_iClientLastDeaths[client];
    int assists = m_iAssists - g_iClientLastAssists[client];
    int score = m_iScore - g_iClientLastScore[client];
    int time = RoundToZero(GetTime() - g_fClientTime[client]);

    if(frags == 0 && deaths == 0 && assists == 0 && score == 0){
        return;
    }

    g_iClientLastFrags[client] = m_iFrags;
    g_iClientLastDeaths[client] = m_iDeaths;
    g_iClientLastAssists[client] = m_iAssists;
    g_iClientLastScore[client] = m_iScore;

    int client_db_id = g_iClientDbId[client];
    if(client_db_id <= 0){
        return;
    }
    AddClientRank(client_db_id, frags, deaths, assists, score, time);
}

public void AddClientRank(int id, int frags, int deaths, int assists, int score, int seconds){

}
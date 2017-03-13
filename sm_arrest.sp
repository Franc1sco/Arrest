/*  SM Arrest
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.1"

#pragma semicolon 1

new arrestos[MAXPLAYERS+1];

new Handle:Distancia;
new Handle:arrestos_cvar;
new Handle:tiempo;

new Handle:g_CVarAdmFlag;
new g_AdmFlag;
new Handle:cerrar_cvar;

new iEnt;
new const String:EntityList[][] = { "func_door", "func_movinglinear" };

public Plugin:myinfo =
{
	name = "SM Arrest",
	author = "Franc1sco Steam: franug",
	description = "Arrest prisioners",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	CreateConVar("sm_arrest_version", PLUGIN_VERSION, "version del plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

        RegConsoleCmd("sm_arrest", Arrest);
        RegConsoleCmd("sm_stop", Arrest);

	HookEvent("round_start", Event_RoundStart);

        Distancia = CreateConVar("jail_distance_handcuffs", "150.0", "Turn distance between prisonner and guard");
        arrestos_cvar = CreateConVar("jail_max_handcuffs", "1", "Turn maximun hancuffs per round.");
        tiempo = CreateConVar("jail_delay_respawn", "4.0", "Delay for respawn terrorist into jail");

        cerrar_cvar = CreateConVar("sm_arrest_close", "1", "Close doors when a prisioner back to jail. 1 = Enable, 0 = Disable");
	g_CVarAdmFlag = CreateConVar("sm_arrest_adminflag", "0", "Admin flag required to use Arrest. 0 = No flag needed. Can use a b c ....");

	HookConVarChange(g_CVarAdmFlag, CVarChange);

}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {

	g_AdmFlag = ReadFlagString(newValue);
}

public OnMapStart()
{
        AddFileToDownloadsTable("sound/jail/arrestation/menotte.wav");
	PrecacheSound("jail/arrestation/menotte.wav");
}

public Action:Arrest(client,args)
{
 if (IsClientInGame(client))
 {
	if ((g_AdmFlag > 0) && !CheckCommandAccess(client, "sm_arrest", g_AdmFlag, true)) 
        {
			PrintToChat(client, "\x04[SM_Arrest]\x05You do not have access");
			return;
	}

	if(!IsPlayerAlive(client))
	{
		PrintToChat(client,"\x04[SM_Arrest]\x05 You must be alive for use this");
		return;
	}
	if(GetClientTeam(client) != 3)
	{
		PrintToChat(client,"\x04[SM_Arrest]\x05 You must be Guard for use this");
		return;
	}
	if(arrestos[client] <= 0)
	{
		PrintToChat(client,"\x04[SM_Arrest]\x05 You reached the maximum of handcuffs");
		return;
	}

	new Target = GetClientAimTarget(client, true);
	if (IsValidClient(Target) && GetClientTeam(Target) == 2)
	{
		decl Float:OriginC[3],Float:TargetOrigin[3], Float:Distance;
            	GetClientAbsOrigin(client, OriginC);
		GetClientAbsOrigin(Target, TargetOrigin);
                Distance = GetVectorDistance(TargetOrigin,OriginC);
		if(Distance <= GetConVarFloat(Distancia))
                { 
			PrintToChatAll("\x04[SM_Arrest]\x05 Guard %N arrested %N, he is sent back to his cell",client,Target);
			player_arrest(Target);
			--arrestos[client];
			EmitSoundToAll("jail/arrestation/menotte.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, TargetOrigin);
		}
		else
			PrintToChat(client,"\x04[SM_Arrest]\x05 The prisoner you are looking at is too far");
	}
	else
		PrintToChat(client,"\x04[SM_Arrest]\x05 Invalid target");
 }

}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
  new cantidad = GetConVarInt(arrestos_cvar);
  for (new client = 1; client < GetMaxClients(); client++)
  {
	if (IsClientInGame(client))
	{
		arrestos[client] = cantidad;
        }
  }
}

player_arrest(index)
{
	SetEntityMoveType(index, MOVETYPE_NONE);
	SetEntProp(index, Prop_Data, "m_takedamage", 0, 1);
	StripAllWeapons(index);
	CreateTimer(GetConVarFloat(tiempo), Alajail, index);
}

public Action:Alajail(Handle:timer,any:client)
{
	if(IsValidClient(client))
        {
                CS_RespawnPlayer(client);
		if(GetConVarInt(cerrar_cvar) != 0)
		{
    			for(new i = 0; i < sizeof(EntityList); i++)
        		while((iEnt = FindEntityByClassname(iEnt, EntityList[i])) != -1)
            			AcceptEntityInput(iEnt, "Close");
		}
        }
}

stock StripAllWeapons(iClient)
{
    new iEnt2;
    for (new i = 0; i <= 4; i++)
    {
        while ((iEnt2 = GetPlayerWeaponSlot(iClient, i)) != -1)
        {
            RemovePlayerItem(iClient, iEnt2);
            RemoveEdict(iEnt2);
        }
    }
}

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}
#include 	<open.mp>
#include 	<a_mysql>
#include	<streamer>
#include 	<ysi_coding/y_hooks>
#include 	<ysi_visual/y_commands>
#include    <sscanf2>
#include 	<sampvoice>

new MySQL:connectionSQL;
new query[500];

#include 	"../modulos/macros/defines.pwn"
#include 	"../modulos/macros/color.pwn"
#include 	"../modulos/enum/dialogs.pwn"
#include 	"../modulos/enum/player.pwn"
#include 	"../modulos/server/textdraws.pwn"
#include 	"../modulos/server/pickups.pwn"
#include 	"../modulos/server/labels.pwn"
#include 	"../modulos/server/mappings.pwn"
#include 	"../modulos/commands/free.pwn"
#include 	"../modulos/commands/private.pwn"
#include 	"../modulos/server/stocks.pwn"
#include 	"../modulos/server/functions.pwn"

main()
{
	new date[6];
	getdate(date[5], date[4], date[3]);
	gettime(date[0], date[1], date[2]);
	printf("server ativo em: %02d/%02d/%04d - %02d:%02d:%02d", date[3], date[4], date[5], date[0], date[1], date[2]);
}

public OnPlayerRequestSpawn(playerid)
{
	return 0;
}

public OnGameModeInit()
{
	SetGameModeText("ZNT-RP | PT/BR"); 
	DisableInteriorEnterExits();
	validConnection();
	EnableStuntBonusForAll(false);
	UsePlayerPedAnims();
	ShowNameTags(false);
	ShowPlayerMarkers(PLAYER_MARKERS_MODE_OFF);
	
	return 1;
}

public OnGameModeExit()
{
	mysql_close(connectionSQL);
	return 1;
}

public OnPlayerConnect(playerid)
{
	clearChat(playerid, 50);
	textDrawShowLogin(playerid);
	PlayerTextDrawSetString(playerid, _Login[playerid][0], "%s", getPlayerNameEx(playerid));
	SelectTextDraw(playerid, 0x696969FF);
	TextDrawShowForPlayer(playerid, Login[1]);
	TextDrawShowForPlayer(playerid, Login[2]);
	SendClientCheck(playerid, 0x48, 0, 0, 2);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	updatDate(playerid);
	for(new PLAYER_INFO:i; i < PLAYER_INFO; i++)
	{
		PlayerInfo[playerid][i] = 0;
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case DIALOG_LOGIN:
		{
			if(response)
			{
                if(!strlen(inputtext))
				{
                    SendClientMessage(playerid, YELLOW, "[!] Digite algo!");
                }
				else if(!strcmp(PlayerInfo[playerid][Password], inputtext, true, MAX_PASSWORD_CHARACTERS))
				{
					SetPVarInt(playerid, "EnteredPassword", 2);
					for(new i = 0; i < strlen(inputtext); i++)
					{
						inputtext[i] = '?';
						PlayerTextDrawSetString(playerid, _Login[playerid][1], "%s", inputtext);
					}
				}
				else
				{
					PlayerInfo[playerid][PasswordError] ++;
					if(PlayerInfo[playerid][PasswordError] == 3)
					{
						SendClientMessage(playerid, ORANJE, "Você exedeu o limite de tentativas e foi desconectado!");
						SetTimerEx("delayKickPlayer", 1000, false, "d", playerid);
					}
					else
					{
						SendClientMessage(playerid, RED, "ERRO: Senha Invalida [%d/3]", PlayerInfo[playerid][PasswordError]);
					}
				}
			}
		}
		case DIALOG_REGISTRATION:
		{
			if(response)
			{
                if(!strlen(inputtext))
				{
                    SendClientMessage(playerid, YELLOW, "[!] Digite algo!");
                }
                else if(strlen(inputtext) <= 7 || strlen(inputtext) >= 21)
				{
                    SendClientMessage(playerid, YELLOW, "INFO: Crie uma senha entre 8 e 20 digitos!");
                }
				else
				{
					SetPVarString(playerid, "Password2", inputtext);
					ShowPlayerDialog(playerid, DIALOG_PASSWORD_CONFIRM, DIALOG_STYLE_PASSWORD, "Confirmar senha", "{d3d3d3}Confirme sua senha no campo abaixo:", "confirmar", "voltar");
				}
			}
		}
		case DIALOG_PASSWORD_CONFIRM:
		{
			if(response)
			{
				new Password2[MAX_PASSWORD_CHARACTERS];
				GetPVarString(playerid, "Password2", Password2, sizeof(Password2));
				if(!strlen(inputtext)) 
				{
                    SendClientMessage(playerid, YELLOW, "[!] Digite algo!");
					ShowPlayerDialog(playerid, DIALOG_PASSWORD_CONFIRM, DIALOG_STYLE_PASSWORD, "Confirmar senha", "{d3d3d3}Confirme sua senha no campo abaixo:", "confirmar", "voltar");
                }
				else if(!strcmp(Password2, inputtext, true, MAX_PASSWORD_CHARACTERS))
				{
					SetPVarInt(playerid, "EnteredPassword", 1);
					SetPVarString(playerid, "Password3", inputtext);	
					for(new i = 0; i < strlen(inputtext); i++)
					{
						inputtext[i] = '?';
						PlayerTextDrawSetString(playerid, _Login[playerid][1], "%s", inputtext);
					}
				}
				else
				{
					SendClientMessage(playerid, RED, "ERRO: As senhas não conferem!");
					ShowPlayerDialog(playerid, DIALOG_PASSWORD_CONFIRM, DIALOG_STYLE_PASSWORD, "Confirmar senha", "{d3d3d3}Confirme sua senha no campo abaixo:", "confirmar", "voltar");
				}
			}
			else
			{
				ShowPlayerDialog(playerid, DIALOG_REGISTRATION, DIALOG_STYLE_PASSWORD, "Registro", "{ff4500}Crie uma senha no campo abaixo:", "confirmar", "X");
			}
		}
	}
	return 1;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
	if(playertextid == _Login[playerid][1]) // INSERIR A SENHA
	{
		if(GetPVarInt(playerid, "EnteredPassword") == 0)
		{
			mysql_format(connectionSQL, query, sizeof(query), "SELECT `password_`, `uid` FROM `players` WHERE `name` = '%e';", getPlayerNameEx(playerid));
			mysql_tquery(connectionSQL, query, "showDialogLogin", "d", playerid);
		}
	}
	else if(playertextid == _Login[playerid][2]) // CONFIRMAR A SENHA
	{
		if(GetPVarInt(playerid, "EnteredPassword") == 1)
		{
			InterpolateCameraPos(playerid, 175.568527, -71.300018, 1002.407104, 175.568527,-71.300018, 1002.407104, 1000);
			InterpolateCameraLookAt(playerid, 178.490509, -75.205497, 1001.307434, 178.490509,-75.205497, 1001.307434, 1000);
			SetPlayerPos(playerid, 176.8877,-73.1448,1001.8047);
			SetPlayerFacingAngle(playerid, 49.8266);
			SetPlayerInterior(playerid, 18); 
			DeletePVar(playerid, "EnteredPassword");
			PlayerInfo[playerid][Age] = 16;
			PlayerInfo[playerid][BirthYear] = 2007;
			textDrawHideLogin(playerid);
			textDrawShowRegister(playerid);
			if(GetPVarInt(playerid, "notAndroid") == 1) // SE FOR PC
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][24], "PC");
				PlayerTextDrawShow(playerid, Registration[playerid][24]);
				SetPVarInt(playerid, "platform", 1);
			}
			else // SE FOR MOBILE
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][24], "MOBILE");
				PlayerTextDrawShow(playerid, Registration[playerid][24]);
				SetPVarInt(playerid, "platform", 2);
			}
		}
		else if(GetPVarInt(playerid, "EnteredPassword") == 2)
		{
            mysql_format(connectionSQL, query, sizeof(query), "SELECT * FROM `players` WHERE `name` = '%e';", getPlayerNameEx(playerid));
            mysql_tquery(connectionSQL, query, "getPlayerDate", "d", playerid); 
			for(new i = 0; i < sizeof(ZENITY_FIGURE); i++)
			{
				TextDrawShowForPlayer(playerid, ZENITY_FIGURE[i]);
			}
			DeletePVar(playerid, "EnteredPassword");
			serverLogged[playerid] = true; 
			textDrawHideLogin(playerid);
			CancelSelectTextDraw(playerid);	
		}
	}
	else if(playertextid == Registration[playerid][16]) // BOTÃO DIREITO
	{
		if(GetPVarInt(playerid, "gender") == 0)
		{
			PlayerTextDrawSetString(playerid, Registration[playerid][0], "MASCULINO");
			PlayerTextDrawShow(playerid, Registration[playerid][0]);
			SetPVarInt(playerid, "gender", 1);
		}
		else if(GetPVarInt(playerid, "gender") == 2)
		{
			PlayerTextDrawSetString(playerid, Registration[playerid][0], "MASCULINO");
			PlayerTextDrawShow(playerid, Registration[playerid][0]);
			SetPVarInt(playerid, "gender", 1);
		}
	}
	if(playertextid == Registration[playerid][8]) // BOTÃO ESQUERDO
	{
		if(GetPVarInt(playerid, "gender") == 1)
		{
			PlayerTextDrawSetString(playerid, Registration[playerid][0], "FEMININO");
			PlayerTextDrawShow(playerid, Registration[playerid][0]);
			SetPVarInt(playerid, "gender", 2);
		}
	}
	else if(playertextid == Registration[playerid][9]) // CLICOU NO BOTÃO ESQUERDO
	{
		switch(GetPlayerSkin(playerid))
		{
			case 62:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 53");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 53);
			}
			case 53:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 56");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 56);
			}
			case 56:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 41");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 41);
			}
			case 41:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 6");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 6);
			}
			case 40:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 8");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 8);
			}
			case 8:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 1");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 1);
			}
			case 1:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 7");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 7);
			}
			case 7:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 15");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 15);
			}
			case 15:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 12");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 12);
			}
		}
	}
	else if(playertextid == Registration[playerid][17]) // CLICOU NO BOTÃO DIREITO
	{
		switch(GetPlayerSkin(playerid))
		{
			case 0:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 12");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 12);
			}
			case 12:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 15");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 15);
			}
			case 15:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 7");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 7);
			}
			case 7:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 1");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 1);
			}
			case 1:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 8");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 8);
			}
			case 8:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 40");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 40);
			}
			case 6:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 41");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 41);				
			}
			case 41:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 56");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 56);
			}
			case 56:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 53");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 53);
			}
			case 53:
			{
				PlayerTextDrawSetString(playerid, Registration[playerid][1], "ID: 62");
				PlayerTextDrawShow(playerid, Registration[playerid][1]);
				setPlayerSkinEx(playerid, 62);
			}			
		}
	}
	else if(playertextid == Registration[playerid][10]) // CLICOU NO BOTÃO ESQUERDO
	{
		if(PlayerInfo[playerid][Age] >= 17)
		{
			PlayerInfo[playerid][Age] -= 1;
			PlayerInfo[playerid][BirthYear] += 1;
			PlayerTextDrawSetString(playerid, Registration[playerid][2], "d", PlayerInfo[playerid][Age]);
			PlayerTextDrawShow(playerid, Registration[playerid][2]);
			PlayerTextDrawSetString(playerid, Registration[playerid][5], "d", PlayerInfo[playerid][BirthYear]);
			PlayerTextDrawShow(playerid, Registration[playerid][5]);
		}
	}
	else if(playertextid == Registration[playerid][18]) // CLICOU NO BOTÃO DIREITO
	{
		if(PlayerInfo[playerid][Age] <= 99)
		{
			PlayerInfo[playerid][Age] += 1;
			PlayerInfo[playerid][BirthYear] -= 1;
			PlayerTextDrawSetString(playerid, Registration[playerid][2], "%02d", PlayerInfo[playerid][Age]);
			PlayerTextDrawShow(playerid, Registration[playerid][2]);
			PlayerTextDrawSetString(playerid, Registration[playerid][5], "%04d", PlayerInfo[playerid][BirthYear]);
			PlayerTextDrawShow(playerid, Registration[playerid][5]);
		}
	}
	else if(playertextid == Registration[playerid][11]) // CLICOU NO BOTÃO ESQUERDO
	{
		if(PlayerInfo[playerid][BirthDay] >= 2)
		{
			PlayerInfo[playerid][BirthDay] -= 1;
			PlayerTextDrawSetString(playerid, Registration[playerid][3], "%02d", PlayerInfo[playerid][BirthDay]);
			PlayerTextDrawShow(playerid, Registration[playerid][3]);			
		}
	}
	else if(playertextid == Registration[playerid][19]) // CLICOU NO BOTÃO DIREITO
	{
		if(PlayerInfo[playerid][BirthDay] <= 30)
		{
			PlayerInfo[playerid][BirthDay] += 1;
			PlayerTextDrawSetString(playerid, Registration[playerid][3], "%02d", PlayerInfo[playerid][BirthDay]);
			PlayerTextDrawShow(playerid, Registration[playerid][2]);
			PlayerTextDrawShow(playerid, Registration[playerid][3]);
			PlayerTextDrawShow(playerid, Registration[playerid][4]);			
			PlayerTextDrawShow(playerid, Registration[playerid][5]);			
		}
	}
	else if(playertextid == Registration[playerid][12]) // CLICOU NO BOTÃO ESQUERDO
	{
		if(PlayerInfo[playerid][BirthMonth] >= 2)
		{
			PlayerInfo[playerid][BirthMonth] -= 1;
			PlayerTextDrawSetString(playerid, Registration[playerid][4], "%02d", PlayerInfo[playerid][BirthMonth]);
			PlayerTextDrawShow(playerid, Registration[playerid][4]);
		}
	}
	else if(playertextid == Registration[playerid][20]) // CLICOU NO BOTÃO DIREITO
	{
		if(PlayerInfo[playerid][BirthMonth] <= 11)
		{
			PlayerInfo[playerid][BirthMonth] += 1;
			PlayerTextDrawSetString(playerid, Registration[playerid][4], "%02d", PlayerInfo[playerid][BirthMonth]);
			PlayerTextDrawShow(playerid, Registration[playerid][3]);
			PlayerTextDrawShow(playerid, Registration[playerid][4]);			
			PlayerTextDrawShow(playerid, Registration[playerid][5]);
		}
	}
	else if(playertextid == Registration[playerid][13]) // CLICOU NO BOTÃO ESQUERDO
	{
		if(PlayerInfo[playerid][BirthYear] >= 1925)
		{
			PlayerInfo[playerid][BirthYear] -= 1;
			PlayerInfo[playerid][Age] += 1;
			PlayerTextDrawSetString(playerid, Registration[playerid][5], "d", PlayerInfo[playerid][BirthYear]);
			PlayerTextDrawSetString(playerid, Registration[playerid][2], "d", PlayerInfo[playerid][Age]);
			PlayerTextDrawShow(playerid, Registration[playerid][5]);
			PlayerTextDrawShow(playerid, Registration[playerid][2]);
		}
	}
	else if(playertextid == Registration[playerid][21]) // CLICOU NO BOTÃO DIREITO
	{
		if(PlayerInfo[playerid][BirthYear] <= 2006)
		{
			PlayerInfo[playerid][BirthYear] += 1;
			PlayerInfo[playerid][Age] -= 1;
			PlayerTextDrawSetString(playerid, Registration[playerid][5], "d", PlayerInfo[playerid][BirthYear]);
			PlayerTextDrawSetString(playerid, Registration[playerid][2], "d", PlayerInfo[playerid][Age]);
			PlayerTextDrawShow(playerid, Registration[playerid][5]);
			PlayerTextDrawShow(playerid, Registration[playerid][2]);
		}
	}
	else if(playertextid == Registration[playerid][23]) // CLICOU NO BOTÃO DIREITO
	{
		if(GetPVarInt(playerid, "city") == 0)
		{
			PlayerTextDrawSetString(playerid, Registration[playerid][7], "LS");
			PlayerTextDrawShow(playerid, Registration[playerid][7]);
			SetPVarInt(playerid, "city", 1);
		}
		else if(GetPVarInt(playerid, "city") == 1)
		{
			PlayerTextDrawSetString(playerid, Registration[playerid][7], "SF");
			PlayerTextDrawShow(playerid, Registration[playerid][7]);
			SetPVarInt(playerid, "city", 2);
		}
		else if(GetPVarInt(playerid, "city") == 2)
		{
			PlayerTextDrawSetString(playerid, Registration[playerid][7], "LV");
			PlayerTextDrawShow(playerid, Registration[playerid][7]);
			SetPVarInt(playerid, "city", 3);
		}
	}
	else if(playertextid == Registration[playerid][15]) // CLICOU NO BOTÃO ESQUERDO
	{
		if(GetPVarInt(playerid, "city") == 3)
		{
			PlayerTextDrawSetString(playerid, Registration[playerid][7], "SF");
			PlayerTextDrawShow(playerid, Registration[playerid][7]);
			SetPVarInt(playerid, "city", 4);
		}
		else if(GetPVarInt(playerid, "city") == 4)
		{
			PlayerTextDrawSetString(playerid, Registration[playerid][7], "LS");
			PlayerTextDrawShow(playerid, Registration[playerid][7]);
			SetPVarInt(playerid, "city", 1);
		}
	}
	else if(playertextid == Registration[playerid][25]) // CLICOU NO BOTÃO DIREITO
	{
		if(GetPVarInt(playerid, "notAndroid") == 1)
		{
			ShowPlayerDialog(playerid, DIALOG_ERROR, DIALOG_STYLE_MSGBOX, " ", "{ffff00}você não esta em uma plataforma MOBILE.", "X", "");
		}
		else
		{
			ShowPlayerDialog(playerid, DIALOG_ERROR, DIALOG_STYLE_MSGBOX, " ", "{ffff00}você não esta em uma plataforma PC.", "X", "");
		}
	}
	else if(playertextid == Registration[playerid][26]) // CLICOU NO BOTÃO ESQUERDO
	{
		if(GetPVarInt(playerid, "notAndroid") == 1)
		{
			ShowPlayerDialog(playerid, DIALOG_ERROR, DIALOG_STYLE_MSGBOX, " ", "{ffff00}você não esta em uma plataforma MOBILE.", "X", "");
		}
		else
		{
			ShowPlayerDialog(playerid, DIALOG_ERROR, DIALOG_STYLE_MSGBOX, " ", "{ffff00}você não esta em uma plataforma PC.", "X", "");
		}
	}
	else if(playertextid == Registration[playerid][27])
	{
		if(GetPVarInt(playerid, "platform") == 0 || GetPVarInt(playerid, "city") == 0 || PlayerInfo[playerid][BirthMonth] == 0 || 
		PlayerInfo[playerid][BirthDay] == 0 || PlayerInfo[playerid][Age] <= 15 || 
		PlayerInfo[playerid][SkinID] == 0 || PlayerInfo[playerid][BirthYear] >= 2008)
		{
			ShowPlayerDialog(playerid, DIALOG_ERROR, DIALOG_STYLE_MSGBOX, "{ff0000}ERRO", "{ff0000}Termine de finalizar seu cadastro!", "X", "");
		}
		else
		{
			new Password3[MAX_PASSWORD_CHARACTERS], strG[20], strC[3], strP[7];
			GetPVarString(playerid, "Password3", Password3, sizeof(Password3));
			loadCity(playerid);
			textDrawHideRegister(playerid);
			CancelSelectTextDraw(playerid);
			givePlayerMoneyEx(playerid, 5000);
			serverLogged[playerid] = true;
			if(GetPVarInt(playerid, "gender") == 1)
				format(strG, sizeof(strG), "masculino");
			else if(GetPVarInt(playerid, "gender") == 2)
				format(strG, sizeof(strG), "feminino");
			if(GetPVarInt(playerid, "city") == 1)
				format(strC, sizeof(strC), "ls");
			else if(GetPVarInt(playerid, "city") == 2)
				format(strC, sizeof(strC), "sf");
			else if(GetPVarInt(playerid, "city") == 3)
				format(strC, sizeof(strC), "lv");
			else if(GetPVarInt(playerid, "city") == 4)
				format(strC, sizeof(strC), "ls");
			if(GetPVarInt(playerid, "platform") == 1)
				format(strP, sizeof(strP), "pc");
			else if(GetPVarInt(playerid, "platform") == 2)
				format(strP, sizeof(strP), "mobile");
			mysql_format(connectionSQL, query, sizeof(query), "INSERT INTO `players` (`uid`, `name`, `password_`, `skinid`, `money`, `gender`, `age`, `birthDay`, `birthMonth`, `birthYear`, `platform`, `city`, `posX`, `posY`, `posZ`, `posR`) VALUES ('%d', '%e', '%e', '%d', '%d', '%e', '%d', '%d', '%d', '%d', '%e', '%e', '%f', '%f', '%f', '%f');", PlayerInfo[playerid][UID], getPlayerNameEx(playerid), Password3, PlayerInfo[playerid][SkinID], PlayerInfo[playerid][Money], strG, PlayerInfo[playerid][Age], PlayerInfo[playerid][BirthDay], PlayerInfo[playerid][BirthMonth], PlayerInfo[playerid][BirthYear], strP, strC, PlayerInfo[playerid][PosX], PlayerInfo[playerid][PosY], PlayerInfo[playerid][PosZ], PlayerInfo[playerid][PosR]);
			mysql_tquery(connectionSQL, query, "insetPlayerDate", "d", playerid);
			for(new i = 0; i < sizeof(ZENITY_FIGURE); i++)
			{
				TextDrawShowForPlayer(playerid, ZENITY_FIGURE[i]);
			}
		}
	}
	if(playertextid == _txdRG[playerid][6]) // X DO RG
	{
		TogglePlayerControllable(playerid, true);
		textDrawHideRG(playerid);
		CancelSelectTextDraw(playerid);
	}		
	return 1;
}

public OnPlayerKeyStateChange(playerid, KEY:newkeys, KEY:oldkeys)
{
	if(newkeys & KEY_CTRL_BACK) // KEY 'H'
	{
		if(IsPlayerInRangeOfPoint(playerid, 2.0, 359.0927,166.2874,1008.3828)) // LUGAR DE EMITIR O RG
		{
			if(GetPVarInt(playerid, "delay") < gettime())
			{
				if(PlayerInfo[playerid][RG] != 1)
				{
					TogglePlayerControllable(playerid, false);
					timerRg[playerid] = 15;
					textDrawShowMessageInfo(playerid, "EMITINDO RG EM (15s)");
					timerLoadingRg[playerid] = SetTimerEx("loadingRg", 1000, true, "d", playerid);
					SetPVarInt(playerid, "delay", gettime() + 15);
					SetTimerEx("hideMessageInfoTxd", 15000, false, "d", playerid);
	        	}
	        	else
	        	{
	        		textDrawShowMessageInfo(playerid, "VOCE JA POSSUI UM RG!",RED);
					SetTimerEx("hideMessageInfoTxd", 3000, false, "d", playerid);
	        		SetPVarInt(playerid, "delay", gettime() + 3);
	        	}
	        }
		}
		else if(IsPlayerInRangeOfPoint(playerid, 2.0, 1664.2427,-2269.4856,-1.2628))
		{
			if(GetPVarInt(playerid, "vehicleSpawnQuad") == 0)
			{
				if(GetPlayerMoney(playerid) >= 500)
				{
					VehicleSpawn[playerid] = CreateVehicle(471, 1665.1899,-2257.7434,-2.8873,276.3108, WHITE, WHITE, -1);
					textDrawShowMessageInfo(playerid, "Veiculo alugado!");					
					SetTimerEx("hideMessageInfoTxd", 3000, false, "d", playerid);
					givePlayerMoneyEx(playerid, -500);
					SetPVarInt(playerid, "vehicleSpawnQuad", 1);
				}
				else
				{
					SendClientMessage(playerid, YELLOW, "INFO: você não tem essa quantidade de dinheiro!");
				}
			}
			else
			{
				SendClientMessage(playerid, YELLOW, "INFO: você ja pegou um quadriciclo. aguarde 7 minutos para pegar outro!");
			}
		}
		else if(IsPlayerInRangeOfPoint(playerid, 2.0, -1414.1809,-296.9156,14.1484))
		{
			if(GetPVarInt(playerid, "vehicleSpawnQuad") == 0)
			{
				if(GetPlayerMoney(playerid) >= 500)
				{
					VehicleSpawn[playerid] = CreateVehicle(471, -1418.4697,-301.8970,14.0000,49.0571, WHITE, WHITE, -1);
					textDrawShowMessageInfo(playerid, "Veiculo alugado!");
					SetTimerEx("hideMessageInfoTxd", 3000, false, "d", playerid);
					givePlayerMoneyEx(playerid, -500);
					SetPVarInt(playerid, "vehicleSpawnQuad", 1);
				}
				else
				{
					SendClientMessage(playerid, YELLOW, "INFO: você não tem essa quantidade de dinheiro!");
				} 
			}
			else
			{
				SendClientMessage(playerid, YELLOW, "INFO: você ja pegou um quadriciclo. aguarde 7 minutos para pegar outro!");
			}
		}
		else if(IsPlayerInRangeOfPoint(playerid, 2.0, 1678.8123,1439.7543,10.7748))
		{
			if(GetPVarInt(playerid, "vehicleSpawnQuad") == 0)
			{
				if(GetPlayerMoney(playerid) >= 500)
				{
					VehicleSpawn[playerid] = CreateVehicle(471, 1687.5919,1437.2069,10.1827,269.8647, WHITE, WHITE, -1);
					textDrawShowMessageInfo(playerid, "Veiculo alugado!");
					SetTimerEx("hideMessageInfoTxd", 3000, false, "d", playerid);
					givePlayerMoneyEx(playerid, -500);
					SetPVarInt(playerid, "vehicleSpawnQuad", 1);
				}
				else
				{
					SendClientMessage(playerid, YELLOW, "INFO: você não tem essa quantidade de dinheiro!");
				}
			}
			else 
			{
				SendClientMessage(playerid, YELLOW, "INFO: você ja pegou um quadriciclo. aguarde 7 minutos para pegar outro!");
			}
		}
		else if(IsPlayerInRangeOfPoint(playerid, 2.0, 1480.9475,-1770.8086,18.7958)) // ENTRADA PREFEITURA LS
		{
			SetPlayerInterior(playerid, 3);
			SetPlayerPos(playerid, 390.0492,173.7854,1008.3828);
			SetPlayerFacingAngle(playerid, 97.4362);
			SetPlayerVirtualWorldEx(playerid, 1);
		}
		else if(IsPlayerInRangeOfPoint(playerid, 2.0, 390.0492,173.7854,1008.3828) && GetPlayerVirtualWorld(playerid) == 1) // SAIDA PREFEITURA LS
		{
			SetPlayerInterior(playerid, 0);
			SetPlayerPos(playerid, 1480.9475,-1770.8086,18.7958);
			SetPlayerFacingAngle(playerid, 0.0000);
			SetPlayerVirtualWorldEx(playerid, 0);
		}
		else if(IsPlayerInRangeOfPoint(playerid, 2.0, -2765.1497,375.6253,6.3435)) // ENTRADA PREFEITURA SF
		{
			SetPlayerInterior(playerid, 3);
			SetPlayerPos(playerid, 390.0492,173.7854,1008.3828);
			SetPlayerFacingAngle(playerid, 97.4362);
			SetPlayerVirtualWorldEx(playerid, 2);
		}
		else if(IsPlayerInRangeOfPoint(playerid, 2.0, 390.0492,173.7854,1008.3828) && GetPlayerVirtualWorld(playerid) == 2) // SAIDA PREFEITURA SF
		{
			SetPlayerInterior(playerid, 0);
			SetPlayerPos(playerid, -2765.1497,375.6253,6.3435);
			SetPlayerFacingAngle(playerid, 0.0000);
			SetPlayerVirtualWorldEx(playerid, 0);
		}
		else if(IsPlayerInRangeOfPoint(playerid, 2.0, 2018.4037,1916.5413,12.3417)) // ENTRADA PREFEITURA LV
		{
			SetPlayerInterior(playerid, 3);
			SetPlayerPos(playerid, 390.0492,173.7854,1008.3828);
			SetPlayerFacingAngle(playerid, 97.4362);
			SetPlayerVirtualWorldEx(playerid, 3);
		}
		else if(IsPlayerInRangeOfPoint(playerid, 2.0, 390.0492,173.7854,1008.3828) && GetPlayerVirtualWorld(playerid) == 3) // SAIDA PREFEITURA LV
		{
			SetPlayerInterior(playerid, 0);
			SetPlayerPos(playerid, 2018.4037,1916.5413,12.3417);
			SetPlayerFacingAngle(playerid, 0.0000);
			SetPlayerVirtualWorldEx(playerid, 0);
		}
	}
	return 1;
}

public OnClientCheckResponse(playerid, actionid, memaddr, retndata)
{
    if(actionid == 0x48) 
	{
		SetPVarInt(playerid, "notAndroid", 1);
	}
    return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	timerVehicleSpawn[playerid] = SetTimerEx("destroyVehicleSpawn", 420000, false, "d", playerid);
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	if(GetPVarInt(playerid, "vehicleSpawnQuad") == 1)
	{
		KillTimer(timerVehicleSpawn[playerid]);
	}
	return 1;
}

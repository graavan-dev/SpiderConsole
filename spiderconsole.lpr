program SpiderConsole;
// **************************************
// **
// ** Started on 3/23/2026
// ** Created by Peter Kraus
// ** With major assistance by MS Copilot
// ** Program is being built to first play
// ** a game of Spider Solitaire, then to
// ** also create an engine to solve
// ** games of Spider. Numerous other
// ** features are being built in also.
// **
// **************************************

{$mode objfpc}{$H+}


uses
  SysUtils, CardDeck, SpiderEngine, StrUtils,
    Windows, SpiderLog, SpiderStats, Drivers, UserProfiles;

var
  G: TSpiderGame;
  //Stats: TSpiderStats;
  F: Text;
  cardStr: string;
  cmd: string;
  FromPile, ToPile, StartIndex: Integer;
  ViewMenu: Boolean;
  ViewStatsMenu: Boolean;
  ViewUtilMenu: Boolean;
  ViewPlayersMenu: Boolean;
  Users: TUserList;
  //CurrentUserIndex: Integer = -1;

// *******************************
// ** Enable ANSI / Color Codes
// *******************************

procedure EnableANSI;
var
  hOut: THandle;
  dwMode: DWORD;
begin
  dwMode := 0;
  hOut := GetStdHandle(STD_OUTPUT_HANDLE);
  if GetConsoleMode(hOut, dwMode) then
  begin
    dwMode := dwMode or ENABLE_VIRTUAL_TERMINAL_PROCESSING;
    SetConsoleMode(hOut, dwMode);
  end;
end;

procedure ClearScreen;
begin
  Write(#27'[2J'#27'[H');
end;

function ColorText(const S, FG, BG: string): string;
begin
  Result := #27'[' + FG + ';' + BG + 'm' + S + #27'[0m';
end;

function RedCard(const S: string): string;
begin
  Result := ColorText(S, '30', '41');  // red on white  '31', '47'
end;

function BlackCard(const S: string): string;
begin
  Result := ColorText(S, '40', '37');  // black on white  '30', '47'
end;

function FaceDownCard: string;
begin
  Result := ColorText('XX', '30', '47');  // dim black on white
end;

// *****************
// ** Print / Save Game
// *****************
procedure PrintGame;
var
  p, i, maxLen, len: Integer;
  c: TCard;

begin
  WriteLn;
  WriteLn('Completed runs: ', G.CompletedRuns, ' / 8');
  WriteLn('Stock deals remaining: ', GetStockDealsRemaining(G));
  WriteLn;

  // Find tallest pile
  maxLen := 0;
  for p := 0 to 9 do
    if Length(G.Tableau[p]) > maxLen then
      maxLen := Length(G.Tableau[p]);

  // Header
  Write('Pile: ');
  for p := 0 to 9 do
    Write(Format('%2d   ', [p]));
  WriteLn;

  // Rows
  for i := 0 to maxLen - 1 do
  begin
    Write(Format('%3d: ', [i]));
    for p := 0 to 9 do
    begin
      len := Length(G.Tableau[p]);
      if i < len then
      begin  // print card loop
        c := G.Tableau[p][i];
        begin
          if c.FaceUp then
          begin
            cardStr := RankToStr(c.Rank) + SuitToStr(c.Suit);

            case c.Suit of
              Hearts, Diamonds:
                cardStr := RedCard(cardStr);
              Clubs, Spades:
                cardStr := BlackCard(cardStr);
            end;
            if c.Rank = Ten then
              Write('', cardStr:4, '  ')
            else
              Write(' ', cardStr:4, '  ');
          end
          else
            Write(' ', FaceDownCard:4, '  ');
        end;
      end   // end print card loop
      else
        Write('     ');  // 5 spaces for empty slot
    end;
  WriteLn;
  end;
end;

procedure SaveGame(var G: TSpiderGame; var F: Text);
var
  p, i, maxLen, len: Integer;
  c: TCard;
begin
  WriteLn(F);
  WriteLn(F, 'Completed runs: ', G.CompletedRuns, ' / 8');
  WriteLn(F, 'Stock deals remaining: ', GetStockDealsRemaining(G));
  WriteLn(F);

  maxLen := 0;
  for p := 0 to 9 do
    if Length(G.Tableau[p]) > maxLen then
      maxLen := Length(G.Tableau[p]);

  Write(F, 'Pile: ');
  for p := 0 to 9 do
    Write(F, Format(' %2d ', [p]));
  WriteLn(F);

  for i := 0 to maxLen - 1 do
  begin
    Write(F, Format('%3d: ', [i]));
    for p := 0 to 9 do
    begin
      len := Length(G.Tableau[p]);
      if i < len then
      begin
        c := G.Tableau[p][i];
        if c.FaceUp then
          Write(F, Format('%2s%s ', [RankToStr(c.Rank), SuitToStr(c.Suit)]))
        else
          Write(F, ' XX ');
      end
      else
        Write(F, '    ');
    end;
    WriteLn(F);
  end;

  WriteLn(F);
end;

procedure ViewMenus(var ViewMenu, ViewStatsMenu, ViewUtilMenu, ViewPlayersMenu: Boolean);
begin
  if (ViewMenu) then
  begin
    WriteLn('Main Menu');
    WriteLn('  m <fromPile> <startIndex> <toPile>  - move sequence');
    WriteLn('  d                                   - deal from stock');
    WriteLn('  s                                   - save game');
    WriteLn('  o                                   - open game');
    WriteLn('  u                                   - undo');
    WriteLn('  r                                   - redo');
    WriteLn('  q                                   - quit');
    WriteLn('  v                                   - show/hide main menu');
    WriteLn('  t                                   - show/hide utility menu');
    WriteLn('  a                                   - show/hide stats menu');
    WriteLn('  p                                   - show/hide players menu');
  end;

  if (ViewStatsMenu) then
  begin
    WriteLn('Stats Menu ');
    WriteLn('  TBD                                 - save stats');
    WriteLn('  TBD                                 - load stats');
    WriteLn('  TBD                                 - print stats');
    WriteLn('  TBD                                 - reset stats');
    WriteLn('  v                                   - show/hide main menu');
    WriteLn('  t                                   - show/hide utility menu');
    WriteLn('  a                                   - show/hide stats menu');
    WriteLn('  p                                   - show/hide players menu');
  end;

  if (ViewUtilMenu) then
  begin
    WriteLn('Utilities Menu ');
    WriteLn('  l <filename>                        - start logging to file');
    WriteLn('  x                                   - stop logging');
    WriteLn('  v                                   - show/hide main menu');
    WriteLn('  t                                   - show/hide utility menu');
    WriteLn('  a                                   - show/hide stats menu');
    WriteLn('  p                                   - show/hide players menu');
  end;

  if (ViewPlayersMenu) then
  begin
    WriteLn('  ?                                   - add player');
    WriteLn('  ?                                   - remove player');
    WriteLn('  ?                                   - show players');
    WriteLn('  v                                   - show/hide main menu');
    WriteLn('  t                                   - show/hide utility menu');
    WriteLn('  a                                   - show/hide stats menu');
    WriteLn('  p                                   - show/hide players menu');
  end;
end;

// ******************
// ** Main Loop
// ******************
procedure GameLoop;
begin
  while True do
  begin
    //LoadStats(Stats, 'spider_stats.txt'); { #todo : Will need to be corrected. }
    //G.Stats := Stats;
    ClearScreen;
    PrintGame;
    if IsWon(G) then //** WINNER! WINNER! CHICKEN DINNER!
      begin
        ClearScreen;
        WriteLn('CONGRATULATIONS!! ');
        WriteLn('You won! All 8 runs completed.');
        ReadLn;
        Exit;
      end;
    //else
    //  RecordGameEnd(G.Stats, G.Difficulty, False);

    ViewMenus(ViewMenu, ViewStatsMenu, ViewUtilMenu, ViewPlayersMenu);
    Write('> ');
    ReadLn(cmd);

    if cmd = '' then
      Continue;

    case cmd[1] of
      'v', 'V':  //** View Main Menu **//
        begin
          if (ViewMenu) then
            begin
              ViewMenu := false;
            end
          else
            begin
              ViewMenu := true;
              ViewStatsMenu := false;
              ViewUtilMenu := false;
              ViewPlayersMenu := false;
            end;
        end;
      't', 'T':  //** View Utility Menu **//
        begin
          if (ViewUtilMenu) then
            begin
              ViewUtilMenu := false;
            end
          else
            begin
              ViewMenu := false;
              ViewStatsMenu := false;
              ViewUtilMenu := true;
              ViewPlayersMenu := false;
            end;
        end;
      'a', 'A':  //** View Stats Menu **//
        begin
          if (ViewStatsMenu) then
            begin
              ViewStatsMenu := false;
            end
          else
            begin
              ViewMenu := false;
              ViewStatsMenu := true;
              ViewUtilMenu := false;
              ViewPlayersMenu := false;
            end;
        end;
      'p', 'P':  //** View Players Menu **//
        begin
          if (ViewPlayersMenu) then
            begin
              ViewPlayersMenu := false;
            end
          else
            begin
              ViewMenu := false;
              ViewStatsMenu := false;
              ViewUtilMenu := false;
              ViewPlayersMenu := true;
            end;
        end;
      'q', 'Q':  //** Quit Game **//
        begin
          //AddUser('Peter');
          { #todo : Is this correct place for AddUsers and SaveUsersToJSON to be called? }
          //SaveUsers;
          RecordGameEnd(G.Stats, G.Difficulty, False);
          Exit;
        end;
      'd', 'D':  //** Deal From Stock **//
        begin
          if CanDealFromStock(G) then
            DealFromStock(G)
          else
            WriteLn('Cannot deal from stock (either empty or a pile is empty).');
        end;
      'm', 'M':  //** Move Card(s) from column to column **//
        begin
          if ParseMove(cmd, FromPile, StartIndex, ToPile) then
          begin
            if CanMoveSequence(G, FromPile, StartIndex, ToPile) then
              MoveSequence(G, FromPile, StartIndex, ToPile)
            else
              WriteLn('Illegal move.');
          end
          else
            WriteLn('Invalid move. Use mXYZ or m X Y Z.');
        end;
      's', 'S':  //** Save Game **//
        begin
          AssignFile(F, 'spider_output.txt');
          Rewrite(F);
          SaveGame(G, F);  { #todo : Need to confirm file is correct format. }
          CloseFile(F);
        end;
      'l', 'L':  //** Start Logging **//
        begin
          Delete(cmd, 1, 1);
          cmd := Trim(cmd);
          if cmd = '' then
          begin
            WriteLn('Usage: l <filename>');
            Continue;
          end;
          StartLog(G.Logger, cmd);
          WriteLn('Logging started.');
        end;
      'x', 'X':  //** Stop Logging **//
        begin
          EndLog(G.Logger);
          WriteLn('Logging stopped.');
        end;
      'k', 'K':  //** Replay Log (replay game?) **//
        begin
          Delete(cmd, 1, 1);
          cmd := Trim(cmd);
          if cmd = '' then
          begin
            WriteLn('Usage: r <filename>');
            Continue;
          end;
          //ReplayLog(cmd);  { #todo : Completely untested so far. };
          WriteLn('Replay complete.');
        end;
      'z', 'Z': Undo(G);
      'r', 'R': Redo(G);
      { #todo : Add a View Stats choice. }
    else
      WriteLn('Unknown command.');
    end;
  end;
end;

var
  diff: Integer;

{$R *.res}

begin
  SetConsoleOutputCP(CP_UTF8);
  SetConsoleCP(CP_UTF8);
  EnableANSI;
  Randomize;
  WriteLn('Select difficulty:');
  WriteLn('1 = One Suit (Easy)');
  WriteLn('2 = Two Suit (Medium)');
  WriteLn('4 = Four Suit (Hard)');
  ReadLn(diff);

  case diff of
    1: NewGame(G, sdOneSuit);
    2: NewGame(G, sdTwoSuit);
    4: NewGame(G, sdFourSuit);
  end;



  { #todo : Does loading users take place here? }

  ViewMenu := true;
  ViewStatsMenu := false;
  ViewUtilMenu := false;
  ViewPlayersMenu := false;

  Users := LoadUsersFromJSON('users.json');
  UserManagementMenu(Users);

  GameLoop;

  SaveUsersToJSON('users.json', Users);

end.


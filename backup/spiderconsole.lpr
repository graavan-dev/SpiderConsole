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
    Windows, SpiderLog, SpiderStats, Drivers;

var
  G: TSpiderGame;
  Stats: TSpiderStats;
  F: Text;
  cardStr: string;
  cmd: string;
  FromPile, ToPile, StartIndex: Integer;
  ViewMenu: Boolean;

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

// ******************
// ** Main Loop
// ******************
procedure GameLoop;
begin
  while True do
  begin
    LoadStats(Stats, 'spider_stats.txt');
    G.Stats := Stats;
    ClearScreen;
    PrintGame;
    if IsWon(G) then
      begin
        WriteLn('You won! All 8 runs completed.');
        Exit;
      end
    else
      RecordGameEnd(G.Stats, G.Difficulty, False);

    if (ViewMenu) then
    begin
      WriteLn('Commands:');
      WriteLn('  m <fromPile> <startIndex> <toPile>  - move sequence');
      WriteLn('  d                                   - deal from stock');
      WriteLn('  s                                   - save game');
      WriteLn('  l <filename>                        - start logging to file');
      WriteLn('  x                                   - stop logging');
      WriteLn('  u                                   - undo');
      WriteLn('  r                                   - redo');
      WriteLn('  q                                   - quit');
    end;
    Write('> ');
    ReadLn(cmd);

    if cmd = '' then
      Continue;

    case cmd[1] of
      'v', 'V':
        begin
          if (ViewMenu) then
            ViewMenu := false
          else
            ViewMenu := true;
        end;
      'q', 'Q':
        begin
          RecordGameEnd(G.Stats, G.Difficulty, False);
          Exit;
        end;
      'd', 'D':
        begin
          if CanDealFromStock(G) then
            DealFromStock(G)
          else
            WriteLn('Cannot deal from stock (either empty or a pile is empty).');
        end;
      'm', 'M':
        begin
          if ParseMove(cmd, FromPile, StartIndex, ToPile) then
          begin
            if CanMoveSequence(G, FromPile, StartIndex, ToPile) then
              MoveSequence(G, FromPile, StartIndex, ToPile)
              //WriteLn('Move OK.')
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
          SaveGame(G, F);{ #todo : SaveGame is only "saving" the tableau with cards face down yet and no stock cards either.  }
          CloseFile(F);
        end;
      'l', 'L':
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
      'x', 'X':
        begin
          EndLog(G.Logger);
          WriteLn('Logging stopped.');
        end;
      'p', 'P':
        begin
          Delete(cmd, 1, 1);
          cmd := Trim(cmd);
          if cmd = '' then
          begin
            WriteLn('Usage: r <filename>');
            Continue;
          end;
          //ReplayLog(cmd);
          WriteLn('Replay complete.');
        end;
      'u', 'U': Undo(G);
      'r', 'R': Redo(G);
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

  ViewMenu := true;
  GameLoop;

end.


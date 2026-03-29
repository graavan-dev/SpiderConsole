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
  SysUtils, CardDeck, SpiderEngine, StrUtils, SpiderLog, SpiderStats;

var
  G: TSpiderGame;
  Stats: TSpiderStats;
  F: Text;

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
    Write(Format('%2d ', [p]));
  WriteLn;

  // Rows
  for i := 0 to maxLen - 1 do
  begin
    Write(Format('%3d: ', [i]));
    for p := 0 to 9 do
    begin
      len := Length(G.Tableau[p]);
      if i < len then
      begin
        c := G.Tableau[p][i];
        if c.FaceUp then
          Write(Format('%2s%s ', [RankToStr(c.Rank), SuitToStr(c.Suit)]))
        else
          Write(' XX ');
      end
      else
        Write('    ');
    end;
    WriteLn;
  end;
  WriteLn;
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
var
  cmd: string;
  fromPile, toPile, startIdx: Integer;
begin
  while True do
  begin
    LoadStats(Stats, 'spider_stats.txt');  // optional
    G.Stats := @Stats;

    PrintGame;
    if IsWon(G) then
      begin
        WriteLn('You won! All 8 runs completed.');
        Exit;
      end
    else
      RecordGameEnd(G.Stats^, G.Difficulty, False);

    WriteLn('Commands:');
    WriteLn('  m <fromPile> <startIndex> <toPile>  - move sequence');
    WriteLn('  d                                   - deal from stock');
    WriteLn('  s                                   - save game');
    WriteLn('  l <filename>                        - start logging to file');
    WriteLn('  x                                   - stop logging');
    //WriteLn('  r <filename>                        - replay log file');
    WriteLn('  u                                   - undo');
    WriteLn('  r                                   - redo');
    WriteLn('  q                                   - quit');
    Write('> ');
    ReadLn(cmd);

    if cmd = '' then
      Continue;

    case cmd[1] of
      'q', 'Q':
        begin
          RecordGameEnd(G.Stats^, G.Difficulty, False);
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
          // read rest of line
          Delete(cmd, 1, 1);
          cmd := Trim(cmd);
          if cmd = '' then
          begin
            WriteLn('Usage: m <fromPile> <startIndex> <toPile>');
            Continue;
          end;
          try
            fromPile := StrToInt(ExtractWord(1, cmd, [' ']));
            startIdx := StrToInt(ExtractWord(2, cmd, [' ']));
            toPile   := StrToInt(ExtractWord(3, cmd, [' ']));
          except
            WriteLn('Invalid move parameters.');
            Continue;
          end;

          if CanMoveSequence(G, fromPile, startIdx, toPile) then
            MoveSequence(G, fromPile, startIdx, toPile)
          else
            WriteLn('Illegal move.');
        end;
      's', 'S':
        begin
          // printgame;
          // but send to text file
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
begin
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
  else
    NewGame(G, sdFourSuit); // default
  end;

  GameLoop;
end.


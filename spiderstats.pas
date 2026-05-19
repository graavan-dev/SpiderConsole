unit SpiderStats;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,  CardDeck;

type
  TSpiderStats = record
    GamesPlayed: integer;
    GamesWon: Integer;
    GamesLost: Integer;
    GamesDrawn: Integer;
    WinPercentage: Integer;
    HighScore: Integer;
    AverageScorePerGame: Integer;  { #todo : Need to a new field to track total points from all games }
    BestTime: TDateTime;
    AverageTimePerGame: TDateTime;
    TotalMoves: Integer;
    TotalStacks: Integer;
    AverageStacksPerGame: Integer;
    OneSuitPlayed: Integer;
    OneSuitWon: Integer;
    TwoSuitPlayed: Integer;
    TwoSuitWon: Integer;
    FourSuitPlayed: Integer;
    FourSuitWon: Integer;
    LastDifficulty: Integer;
    HasSavedGame: Boolean;
  end;

procedure InitStats(var S: TSpiderStats);
procedure RecordGameStart(var S: TSpiderStats; Difficulty: TSpiderDifficulty);
procedure RecordMove(var S: TSpiderStats);
procedure RecordGameEnd(var S: TSpiderStats; Difficulty: TSpiderDifficulty; Won: Boolean);
procedure SaveStats(const S: TSpiderStats; const FileName: string);
procedure LoadStats(var S: TSpiderStats; const FileName: string);
procedure PrintStats(const S: TSpiderStats);

implementation

procedure InitStats(var S: TSpiderStats);
begin
  FillChar(S, SizeOf(S), 0);
end;

procedure RecordGameStart(var S: TSpiderStats; Difficulty: TSpiderDifficulty);
begin
  Inc(S.GamesPlayed);

  case Difficulty of
    sdOneSuit: Inc(S.OneSuitPlayed);
    sdTwoSuit: Inc(S.TwoSuitPlayed);
    sdFourSuit: Inc(S.FourSuitPlayed);
  end;

  // Newer fields that must be initialized
  S.LastDifficulty := Ord(Difficulty);
  S.HasSavedGame := False;

  // Per-game metrics reset
  S.BestTime := 0;
  S.AverageTimePerGame := 0;
  S.TotalStacks := 0;
  S.AverageStacksPerGame := 0;
end;

procedure RecordMove(var S: TSpiderStats);
begin
  Inc(S.TotalMoves);
  //Inc(Users.Players[ActiveUserIndex].Stats.TotalMoves);
end;

procedure RecordGameEnd(var S: TSpiderStats; Difficulty: TSpiderDifficulty; Won: Boolean);
begin
  if Won then
  begin
    Inc(S.GamesWon);
    case Difficulty of
      sdOneSuit: Inc(S.OneSuitWon);
      sdTwoSuit: Inc(S.TwoSuitWon);
      sdFourSuit: Inc(S.FourSuitWon);
    end;
  end
  else
    Inc(S.GamesLost);
end;

procedure SaveStats(const S: TSpiderStats; const FileName: string);
var
  F: Text;
begin
  AssignFile(F, FileName);
  Rewrite(F);
  WriteLn(F, S.GamesPlayed);
  WriteLn(F, S.GamesWon);
  WriteLn(F, S.GamesLost);
  WriteLn(F, S.TotalMoves);

  WriteLn(F, S.OneSuitPlayed);
  WriteLn(F, S.OneSuitWon);

  WriteLn(F, S.TwoSuitPlayed);
  WriteLn(F, S.TwoSuitWon);

  WriteLn(F, S.FourSuitPlayed);
  WriteLn(F, S.FourSuitWon);

  CloseFile(F);
end;

procedure LoadStats(var S: TSpiderStats; const FileName: string);
var
  F: Text;
begin
  if not FileExists(FileName) then
  begin
    InitStats(S);
    Exit;
  end;

  AssignFile(F, FileName);
  Reset(F);

  ReadLn(F, S.GamesPlayed);
  ReadLn(F, S.GamesWon);
  ReadLn(F, S.GamesLost);
  ReadLn(F, S.TotalMoves);

  ReadLn(F, S.OneSuitPlayed);
  ReadLn(F, S.OneSuitWon);

  ReadLn(F, S.TwoSuitPlayed);
  ReadLn(F, S.TwoSuitWon);

  ReadLn(F, S.FourSuitPlayed);
  ReadLn(F, S.FourSuitWon);

  CloseFile(F);
end;

procedure PrintStats(const S: TSpiderStats); { #todo : Will be to reworked to add more stats. }
var
  winPct: Double;
begin
  if S.GamesPlayed > 0 then
    winPct := (S.GamesWon / S.GamesPlayed) * 100
  else
    winPct := 0;

  WriteLn('=== Spider Solitaire Statistics ===');
  WriteLn('Games Played: ', S.GamesPlayed);
  WriteLn('Games Won:    ', S.GamesWon);
  WriteLn('Games Lost:   ', S.GamesLost);
  WriteLn('Win %:        ', FormatFloat('0.0', winPct));
  //WriteLn('Total Moves:  ', S.TotalMoves);

  WriteLn;
  WriteLn('--- Difficulty Breakdown ---');
  WriteLn('1-Suit: ', S.OneSuitWon, ' wins / ', S.OneSuitPlayed, ' played');
  WriteLn('2-Suit: ', S.TwoSuitWon, ' wins / ', S.TwoSuitPlayed, ' played');
  WriteLn('4-Suit: ', S.FourSuitWon, ' wins / ', S.FourSuitPlayed, ' played');
end;

end.


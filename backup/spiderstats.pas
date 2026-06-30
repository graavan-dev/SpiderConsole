unit SpiderStats;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, SpiderTypes;

procedure InitStats(var S: TSpiderStats);
procedure RecordGameStart(var U: TUserList; Difficulty: TSpiderDifficulty);
//procedure RecordMove(var U: TUserList);
procedure RecordGameEnd(var G: TSpiderGame; U: TUserList; Difficulty: TSpiderDifficulty; Won: Boolean);
//procedure SaveStats(const S: TSpiderStats; const FileName: string);
//procedure LoadStats(var S: TSpiderStats; const FileName: string);
procedure ShowStats(const U: TUserList);

implementation

procedure InitStats(var S: TSpiderStats);
begin
  FillChar(S, SizeOf(S), 0);
end;

procedure RecordGameStart(var U: TUserList; Difficulty: TSpiderDifficulty);
begin
  //Inc(S.GamesPlayed);
  Inc(U.Players[ActiveUserIndex].Stats.GamesPlayed);

  case Difficulty of
    sdOneSuit: Inc(U.Players[ActiveUserIndex].Stats.OneSuitPlayed);
    sdTwoSuit: Inc(U.Players[ActiveUserIndex].Stats.TwoSuitPlayed);
    sdFourSuit: Inc(U.Players[ActiveUserIndex].Stats.FourSuitPlayed);
  end;

  U.Players[ActiveUserIndex].Stats.LastDifficulty := Ord(Difficulty);

  //S.LastDifficulty := Ord(Difficulty);
  //S.HasSavedGame := False; //???

  // Per-game metrics reset  { #todo : Not sure I agree with these. }
  //S.BestTime := 0;
  //S.AverageTimePerGame := 0;
  //S.TotalStacks := 0;
  //S.AverageStacksPerGame := 0;
end;

// remove now??
//procedure RecordMove(var U: TUserList);
//begin
//  Inc(U.Players[ActiveUserIndex].Stats.TotalMoves);
//end;

procedure RecordGameEnd(var G: TSpiderGame; U: TUserList; Difficulty: TSpiderDifficulty; Won: Boolean);
begin
  if Won then
  begin
    Inc(U.Players[ActiveUserIndex].Stats.GamesWon);
    case Difficulty of
      sdOneSuit: Inc(U.Players[ActiveUserIndex].Stats.OneSuitWon);
      sdTwoSuit: Inc(U.Players[ActiveUserIndex].Stats.TwoSuitWon);
      sdFourSuit: Inc(U.Players[ActiveUserIndex].Stats.FourSuitWon);
    end;
  end
  else
    Inc(U.Players[ActiveUserIndex].Stats.GamesLost);

  // Final stats
  Inc(U.Players[ActiveUserIndex].Stats.TotalStacks, G.CompletedRuns);
end;

// Not being used at this time?
//procedure SaveStats(const S: TSpiderStats; const FileName: string);
//var
//  F: Text;
//begin
//  AssignFile(F, FileName);
//  Rewrite(F);
//  WriteLn(F, S.GamesPlayed);
//  WriteLn(F, S.GamesWon);
//  WriteLn(F, S.GamesLost);
//  WriteLn(F, S.TotalMoves);
//
//  WriteLn(F, S.OneSuitPlayed);
//  WriteLn(F, S.OneSuitWon);
//
//  WriteLn(F, S.TwoSuitPlayed);
//  WriteLn(F, S.TwoSuitWon);
//
//  WriteLn(F, S.FourSuitPlayed);
//  WriteLn(F, S.FourSuitWon);
//
//  CloseFile(F);
//end;

// same for this procedure, not being used.
//procedure LoadStats(var S: TSpiderStats; const FileName: string);
//var
//  F: Text;
//begin
//  if not FileExists(FileName) then
//  begin
//    InitStats(S);
//    Exit;
//  end;
//
//  AssignFile(F, FileName);
//  Reset(F);
//
//  ReadLn(F, S.GamesPlayed);
//  ReadLn(F, S.GamesWon);
//  ReadLn(F, S.GamesLost);
//  ReadLn(F, S.TotalMoves);
//
//  ReadLn(F, S.OneSuitPlayed);
//  ReadLn(F, S.OneSuitWon);
//
//  ReadLn(F, S.TwoSuitPlayed);
//  ReadLn(F, S.TwoSuitWon);
//
//  ReadLn(F, S.FourSuitPlayed);
//  ReadLn(F, S.FourSuitWon);
//
//  CloseFile(F);
//end;

procedure ShowStats(const U: TUserList);
var
  winPct: Double;
begin
  if U.Players[ActiveUserIndex].Stats.GamesPlayed > 0 then
    winPct := (U.Players[ActiveUserIndex].Stats.GamesWon / U.Players[ActiveUserIndex].Stats.GamesPlayed) * 100
  else
    winPct := 0;

  // U.Players[ActiveUserIndex].Stats

  WriteLn('=== Spider Solitaire Statistics ===');
  WriteLn('Games Played: ', U.Players[ActiveUserIndex].Stats.GamesPlayed);
  WriteLn('Games Won:    ', U.Players[ActiveUserIndex].Stats.GamesWon);
  WriteLn('Games Lost:   ', U.Players[ActiveUserIndex].Stats.GamesLost);
  WriteLn('Win %:        ', FormatFloat('0.0', winPct));
  WriteLn('Total Moves:  ', U.Players[ActiveUserIndex].Stats.TotalMoves);

  WriteLn;
  WriteLn('--- Difficulty Breakdown ---');
  WriteLn('1-Suit: ', U.Players[ActiveUserIndex].Stats.OneSuitWon, ' wins / ', U.Players[ActiveUserIndex].Stats.OneSuitPlayed, ' played');
  WriteLn('2-Suit: ', U.Players[ActiveUserIndex].Stats.TwoSuitWon, ' wins / ', U.Players[ActiveUserIndex].Stats.TwoSuitPlayed, ' played');
  WriteLn('4-Suit: ', U.Players[ActiveUserIndex].Stats.FourSuitWon, ' wins / ', U.Players[ActiveUserIndex].Stats.FourSuitPlayed, ' played');

  WriteLn('Press any key to continue.');
  WriteLn;
  ReadLn;
end;

end.


unit SpiderStats;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, SpiderTypes;

procedure InitStats(var S: TSpiderStats);
procedure RecordGameStart(var U: TUserList; Difficulty: TSpiderDifficulty);
procedure RecordGameEnd(var G: TSpiderGame; U: TUserList; Difficulty: TSpiderDifficulty; Won: Boolean);
procedure ShowStats(const U: TUserList);
procedure ResetStats(var Stats: TSpiderStats);

implementation

procedure InitStats(var S: TSpiderStats);
begin
  FillChar(S, SizeOf(S), 0);  { #todo : What the eff is this doing?!?! }
end;

procedure RecordGameStart(var U: TUserList; Difficulty: TSpiderDifficulty);
begin
  Inc(U.Players[ActiveUserIndex].Stats.GamesPlayed);

  case Difficulty of
    sdOneSuit: Inc(U.Players[ActiveUserIndex].Stats.OneSuitPlayed);
    sdTwoSuit: Inc(U.Players[ActiveUserIndex].Stats.TwoSuitPlayed);
    sdFourSuit: Inc(U.Players[ActiveUserIndex].Stats.FourSuitPlayed);
  end;

  U.Players[ActiveUserIndex].Stats.LastDifficulty := intDiff;

  //S.HasSavedGame := False; //???
end;

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

procedure ShowStats(const U: TUserList);
var
  winPct: Double;
begin
  if U.Players[ActiveUserIndex].Stats.GamesPlayed > 0 then
    winPct := (U.Players[ActiveUserIndex].Stats.GamesWon / U.Players[ActiveUserIndex].Stats.GamesPlayed) * 100
  else
    winPct := 0;

  WriteLn('=== Spider Solitaire Statistics ===');
  WriteLn('Games Played: ', U.Players[ActiveUserIndex].Stats.GamesPlayed);
  WriteLn('Games Won:    ', U.Players[ActiveUserIndex].Stats.GamesWon);
  WriteLn('Games Lost:   ', U.Players[ActiveUserIndex].Stats.GamesLost);
  WriteLn('Win %:        ', FormatFloat('0.0', winPct));
  WriteLn('Total Moves:  ', U.Players[ActiveUserIndex].Stats.TotalMoves);
  WriteLn('Total Moves:  ', U.Players[ActiveUserIndex].Stats.TotalStacks);

  WriteLn;
  WriteLn('--- Difficulty Breakdown ---');
  WriteLn('1-Suit: ', U.Players[ActiveUserIndex].Stats.OneSuitWon, ' wins / ', U.Players[ActiveUserIndex].Stats.OneSuitPlayed, ' played');
  WriteLn('2-Suit: ', U.Players[ActiveUserIndex].Stats.TwoSuitWon, ' wins / ', U.Players[ActiveUserIndex].Stats.TwoSuitPlayed, ' played');
  WriteLn('4-Suit: ', U.Players[ActiveUserIndex].Stats.FourSuitWon, ' wins / ', U.Players[ActiveUserIndex].Stats.FourSuitPlayed, ' played');

  WriteLn;
  WriteLn('Press any key to continue.');
  WriteLn;
  ReadLn;
end;

procedure ResetStats(var Stats: TSpiderStats);
begin
  with Stats do
  begin
    GamesPlayed := 0;
    GamesWon := 0;
    GamesLost := 0;
    GamesDrawn := 0;
    WinPercentage := 0;
    HighScore := 0;
    AverageScorePerGame := 0;

    BestTime := 0;
    AverageTimePerGame := 0;

    TotalMoves := 0;
    TotalStacks := 0;
    AverageStacksPerGame := 0;

    OneSuitPlayed := 0;
    OneSuitWon := 0;
    TwoSuitPlayed := 0;
    TwoSuitWon := 0;
    FourSuitPlayed := 0;
    FourSuitWon := 0;

    LastDifficulty := 0;
    HasSavedGame := False;
  end;
end;

end.


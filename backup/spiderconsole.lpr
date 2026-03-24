program SpiderConsole;

{$mode objfpc}{$H+}

uses
  SysUtils, CardDeck, SpiderEngine, StrUtils;

var
  G: TSpiderGame;

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

procedure GameLoop;
var
  cmd: string;
  fromPile, toPile, startIdx: Integer;
begin
  while True do
  begin
    PrintGame;
    if IsWon(G) then
    begin
      WriteLn('You won! All 8 runs completed.');
      Exit;
    end;

    WriteLn('Commands:');
    WriteLn('  m <fromPile> <startIndex> <toPile>  - move sequence');
    WriteLn('  d                                   - deal from stock');
    WriteLn('  q                                   - quit');
    Write('> ');
    ReadLn(cmd);

    if cmd = '' then
      Continue;

    case cmd[1] of
      'q', 'Q':
        Exit;
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
    else
      WriteLn('Unknown command.');
    end;
  end;
end;

begin
  Randomize;
  NewGame(G);
  GameLoop;
end.

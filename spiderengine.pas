unit SpiderEngine;

{$mode objfpc}{$H+}

interface

uses
  CardDeck, SpiderLog, SysUtils, SpiderStats;

type
  // A full snapshot of the game state for undo/redo
  TSpiderGameState = record
    Tableau: TTableau;
    Stock: array[0..49] of TCard;
    StockPos: Integer;
    CompletedRuns: Integer;
  end;

  TSpiderGame = record
    Tableau: TTableau;
    Stock: array[0..49] of TCard;
    StockPos: Integer;
    CompletedRuns: Integer;

    Logger: TSpiderLogger;

    Stats: TSpiderStats;
    MovesThisGame: Integer;
    Difficulty: TSpiderDifficulty;

    UndoStack: array of TSpiderGameState;
    RedoStack: array of TSpiderGameState;
  end;

// Game lifecycle
procedure NewGame(var G: TSpiderGame; Difficulty: TSpiderDifficulty);

// Moves and actions
function CanMoveSequence(const G: TSpiderGame; FromPile, StartIndex, ToPile: Integer): Boolean;
procedure MoveSequence(var G: TSpiderGame; FromPile, StartIndex, ToPile: Integer);
function CanDealFromStock(const G: TSpiderGame): Boolean;
procedure DealFromStock(var G: TSpiderGame);

// Undo/Redo
procedure Undo(var G: TSpiderGame);
procedure Redo(var G: TSpiderGame);

// State queries
function IsWon(var G: TSpiderGame): Boolean;
function GetPileCount(const G: TSpiderGame; Pile: Integer): Integer;
function GetStockDealsRemaining(const G: TSpiderGame): Integer;
function GetCard(const G: TSpiderGame; Pile, Index: Integer): TCard;

implementation

// ---------------------------
// State Save/Restore
// ---------------------------

function SaveState(const G: TSpiderGame): TSpiderGameState;
begin
  Result.Tableau := G.Tableau;
  Result.Stock := G.Stock;
  Result.StockPos := G.StockPos;
  Result.CompletedRuns := G.CompletedRuns;
end;

procedure RestoreState(var G: TSpiderGame; const S: TSpiderGameState);
begin
  G.Tableau := S.Tableau;
  G.Stock := S.Stock;
  G.StockPos := S.StockPos;
  G.CompletedRuns := S.CompletedRuns;
end;

procedure PushUndo(var G: TSpiderGame);
var
  S: TSpiderGameState;
begin
  S := SaveState(G);
  SetLength(G.UndoStack, Length(G.UndoStack) + 1);
  G.UndoStack[High(G.UndoStack)] := S;

  // Clear redo stack
  SetLength(G.RedoStack, 0);
end;

procedure Undo(var G: TSpiderGame);
var
  S: TSpiderGameState;
begin
  if Length(G.UndoStack) = 0 then Exit;

  // Save current state to redo
  SetLength(G.RedoStack, Length(G.RedoStack) + 1);
  G.RedoStack[High(G.RedoStack)] := SaveState(G);

  // Restore last undo state
  S := G.UndoStack[High(G.UndoStack)];
  SetLength(G.UndoStack, Length(G.UndoStack) - 1);

  RestoreState(G, S);
  LogLine(G.Logger, 'Undo performed.');
end;

procedure Redo(var G: TSpiderGame);
var
  S: TSpiderGameState;
begin
  if Length(G.RedoStack) = 0 then Exit;

  // Save current state to undo
  SetLength(G.UndoStack, Length(G.UndoStack) + 1);
  G.UndoStack[High(G.UndoStack)] := SaveState(G);

  // Restore last redo state
  S := G.RedoStack[High(G.RedoStack)];
  SetLength(G.RedoStack, Length(G.RedoStack) - 1);

  RestoreState(G, S);
  LogLine(G.Logger, 'Redo performed.');
end;

// ---------------------------
// Initial Deal
// ---------------------------

procedure InitialDeal(const Deck: TDeck; var G: TSpiderGame);
var
  d, p, i: Integer;
begin
  d := 0;

  for p := 0 to 9 do
    SetLength(G.Tableau[p], 0);

  for p := 0 to 3 do
  begin
    SetLength(G.Tableau[p], 6);
    for i := 0 to 5 do
    begin
      G.Tableau[p][i] := Deck[d];
      Inc(d);
    end;
    G.Tableau[p][5].FaceUp := True;
  end;

  for p := 4 to 9 do
  begin
    SetLength(G.Tableau[p], 5);
    for i := 0 to 4 do
    begin
      G.Tableau[p][i] := Deck[d];
      Inc(d);
    end;
    G.Tableau[p][4].FaceUp := True;
  end;

  G.StockPos := 0;
  while d < TOTAL_CARDS do
  begin
    G.Stock[G.StockPos] := Deck[d];
    Inc(G.StockPos);
    Inc(d);
  end;

  G.StockPos := 0;
end;

// ---------------------------
// New Game
// ---------------------------

procedure NewGame(var G: TSpiderGame; Difficulty: TSpiderDifficulty);
var
  Deck: TDeck;
begin
  if G.Stats.GamesPlayed = 0 then
    InitStats(G.Stats);

  G.Difficulty := Difficulty;
  G.MovesThisGame := 0;

  RecordGameStart(G.Stats, Difficulty);

  BuildDeck(Deck, Difficulty);
  ShuffleDeck(Deck);

  G.CompletedRuns := 0;
  InitialDeal(Deck, G);

  SetLength(G.UndoStack, 0);
  SetLength(G.RedoStack, 0);

  LogLine(G.Logger, 'New game started with difficulty: ' +
    IntToStr(Ord(Difficulty)));
end;

// ---------------------------
// Utility
// ---------------------------

function GetPileCount(const G: TSpiderGame; Pile: Integer): Integer;
begin
  Result := Length(G.Tableau[Pile]);
end;

function GetCard(const G: TSpiderGame; Pile, Index: Integer): TCard;
begin
  Result := G.Tableau[Pile][Index];
end;

function GetStockDealsRemaining(const G: TSpiderGame): Integer;
begin
  Result := (50 - G.StockPos) div 10;
end;

function IsDescendingByOne(Upper, Lower: TCard): Boolean;
begin
  Result := Ord(Upper.Rank) = Ord(Lower.Rank) + 1;
end;

// ---------------------------
// Move Validation
// ---------------------------

function CanMoveSequence(const G: TSpiderGame; FromPile, StartIndex, ToPile: Integer): Boolean;
var
  pileLen, i: Integer;
  c1, c2: TCard;
begin
  Result := False;

  if (FromPile < 0) or (FromPile > 9) or (ToPile < 0) or (ToPile > 9) then Exit;

  pileLen := Length(G.Tableau[FromPile]);
  if (StartIndex < 0) or (StartIndex >= pileLen) then Exit;

  for i := StartIndex to pileLen - 2 do
  begin
    c1 := G.Tableau[FromPile][i];
    c2 := G.Tableau[FromPile][i + 1];
    if (not c1.FaceUp) or (not c2.FaceUp) then Exit;
    if not IsDescendingByOne(c1, c2) then Exit;
    if c1.Suit <> c2.Suit then Exit;
  end;

  if Length(G.Tableau[ToPile]) = 0 then
    Exit(True)
  else
  begin
    c1 := G.Tableau[ToPile][High(G.Tableau[ToPile])];
    c2 := G.Tableau[FromPile][StartIndex];
    if not c1.FaceUp then Exit;
    if not IsDescendingByOne(c1, c2) then Exit;
    Exit(True);
  end;
end;

// ---------------------------
// Completed Run Removal
// ---------------------------

procedure RemoveCompletedRuns(var G: TSpiderGame);
var
  p, i, len, startIdx: Integer;
  sameSuit: Boolean;
  s: TSuit;
begin
  for p := 0 to 9 do
  begin
    len := Length(G.Tableau[p]);
    if len < 13 then Continue;

    i := len - 1;
    while i >= 12 do
    begin
      if G.Tableau[p][i].Rank = Ace then
      begin
        startIdx := i - 12;
        if (startIdx >= 0) and (G.Tableau[p][startIdx].Rank = King) then
        begin
          sameSuit := True;
          s := G.Tableau[p][startIdx].Suit;

          while (startIdx < i) and sameSuit do
          begin
            if (not IsDescendingByOne(G.Tableau[p][startIdx], G.Tableau[p][startIdx + 1])) or
               (G.Tableau[p][startIdx].Suit <> s) or
               (not G.Tableau[p][startIdx].FaceUp) or
               (not G.Tableau[p][startIdx + 1].FaceUp) then
              sameSuit := False
            else
              Inc(startIdx);
          end;

          if sameSuit then
          begin
            SetLength(G.Tableau[p], len - 13);
            Inc(G.CompletedRuns);
            LogLine(G.Logger, Format('Completed run removed. Total now: %d', [G.CompletedRuns]));

            len := Length(G.Tableau[p]);
            if len > 0 then
              G.Tableau[p][len - 1].FaceUp := True;

            Break;
          end;
        end;
      end;
      Dec(i);
    end;
  end;
end;

// ---------------------------
// Move Sequence
// ---------------------------

procedure MoveSequence(var G: TSpiderGame; FromPile, StartIndex, ToPile: Integer);
var
  srcLen, moveCount, i: Integer;
  temp: array of TCard;
begin
  if not CanMoveSequence(G, FromPile, StartIndex, ToPile) then
  begin
    LogLine(G.Logger, Format('Illegal move attempted: %d %d %d', [FromPile, StartIndex, ToPile]));
    Exit;
  end;

  PushUndo(G);
  LogLine(G.Logger, Format('Move: from %d start %d to %d', [FromPile, StartIndex, ToPile]));

  srcLen := Length(G.Tableau[FromPile]);
  moveCount := srcLen - StartIndex;

  SetLength(temp, moveCount);
  for i := 0 to moveCount - 1 do
    temp[i] := G.Tableau[FromPile][StartIndex + i];

  SetLength(G.Tableau[FromPile], StartIndex);
  if Length(G.Tableau[FromPile]) > 0 then
    G.Tableau[FromPile][High(G.Tableau[FromPile])].FaceUp := True;

  i := Length(G.Tableau[ToPile]);
  SetLength(G.Tableau[ToPile], i + moveCount);
  Move(temp[0], G.Tableau[ToPile][i], moveCount * SizeOf(TCard));

  RecordMove(G.Stats);
  Inc(G.MovesThisGame);
  RemoveCompletedRuns(G);
end;

// ---------------------------
// Deal From Stock
// ---------------------------

function CanDealFromStock(const G: TSpiderGame): Boolean;
var
  p: Integer;
begin
  if GetStockDealsRemaining(G) <= 0 then Exit(False);

  for p := 0 to 9 do
    if Length(G.Tableau[p]) = 0 then Exit(False);

  Result := True;
end;

procedure DealFromStock(var G: TSpiderGame);
var
  p: Integer;
begin
  if not CanDealFromStock(G) then
  begin
    LogLine(G.Logger, 'Attempted illegal stock deal.');
    Exit;
  end;

  PushUndo(G);
  LogLine(G.Logger, 'Deal from stock.');

  for p := 0 to 9 do
  begin
    G.Stock[G.StockPos].FaceUp := True;
    SetLength(G.Tableau[p], Length(G.Tableau[p]) + 1);
    G.Tableau[p][High(G.Tableau[p])] := G.Stock[G.StockPos];
    Inc(G.StockPos);
  end;

  RecordMove(G.Stats);
  Inc(G.MovesThisGame);
  RemoveCompletedRuns(G);
end;

// ---------------------------
// Win Check
// ---------------------------

function IsWon(var G: TSpiderGame): Boolean;
begin
  Result := (G.CompletedRuns = 8);
  RecordGameEnd(G.Stats, G.Difficulty, True);
end;

end.

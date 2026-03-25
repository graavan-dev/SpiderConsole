unit SpiderEngine;

{$mode objfpc}{$H+}

interface

uses
  CardDeck;

type
  TSpiderGame = record
    Tableau: TTableau;
    Stock: array[0..49] of TCard;
    StockPos: Integer;
    CompletedRuns: Integer;
    Logger: TSpiderLogger;   // NEW
  end;

// Game lifecycle
procedure NewGame(var G: TSpiderGame);

// Moves and actions
function CanMoveSequence(const G: TSpiderGame; FromPile, StartIndex, ToPile: Integer): Boolean;
procedure MoveSequence(var G: TSpiderGame; FromPile, StartIndex, ToPile: Integer);
function CanDealFromStock(const G: TSpiderGame): Boolean;
procedure DealFromStock(var G: TSpiderGame);

// State queries
function IsWon(const G: TSpiderGame): Boolean;
function GetPileCount(const G: TSpiderGame; Pile: Integer): Integer;
function GetStockDealsRemaining(const G: TSpiderGame): Integer;
function GetCard(const G: TSpiderGame; Pile, Index: Integer): TCard;

implementation

procedure InitialDeal(const Deck: TDeck; var G: TSpiderGame);
var
  d, p, i: Integer;
begin
  d := 0;

  // Clear tableau
  for p := 0 to 9 do
    SetLength(G.Tableau[p], 0);

  // First 4 piles: 6 cards
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

  // Next 6 piles: 5 cards
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

  // Remaining 50 cards to stock
  G.StockPos := 0;
  while d < TOTAL_CARDS do
  begin
    G.Stock[G.StockPos] := Deck[d];
    Inc(G.StockPos);
    Inc(d);
  end;
  // After filling, StockPos points past last; reset to 0 for dealing
  G.StockPos := 0;
end;

procedure NewGame(var G: TSpiderGame);
var
  Deck: TDeck;
begin
  BuildDeck(Deck);
  ShuffleDeck(Deck);
  G.CompletedRuns := 0;
  InitialDeal(Deck, G);
end;

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
  // 10 cards per deal, 50 cards total
  Result := (50 - G.StockPos) div 10;
end;

function IsDescendingByOne(Upper, Lower: TCard): Boolean;
begin
  Result := Ord(Upper.Rank) = Ord(Lower.Rank) + 1;
end;

function CanMoveSequence(const G: TSpiderGame; FromPile, StartIndex, ToPile: Integer): Boolean;
var
  pileLen, i: Integer;
  c1, c2: TCard;
begin
  Result := False;

  if (FromPile < 0) or (FromPile > 9) or (ToPile < 0) or (ToPile > 9) then
    Exit;

  pileLen := Length(G.Tableau[FromPile]);
  if (StartIndex < 0) or (StartIndex >= pileLen) then
    Exit;

  // All cards in sequence must be face up and descending by one, same suit
  for i := StartIndex to pileLen - 2 do
  begin
    c1 := G.Tableau[FromPile][i];
    c2 := G.Tableau[FromPile][i + 1];
    if (not c1.FaceUp) or (not c2.FaceUp) then
      Exit;
    if not IsDescendingByOne(c1, c2) then
      Exit;
    if c1.Suit <> c2.Suit then
      Exit;
  end;

  // Destination rules
  if Length(G.Tableau[ToPile]) = 0 then
  begin
    Result := True;
    Exit;
  end
  else
  begin
    c1 := G.Tableau[ToPile][High(G.Tableau[ToPile])];
    c2 := G.Tableau[FromPile][StartIndex];
    if not c1.FaceUp then
      Exit;
    if not IsDescendingByOne(c1, c2) then
      Exit;
    Result := True;
  end;
end;

procedure RemoveCompletedRuns(var G: TSpiderGame);
var
  p, i, len, startIdx: Integer;
  sameSuit: Boolean;
  s: TSuit;
begin
  for p := 0 to 9 do
  begin
    len := Length(G.Tableau[p]);
    if len < 13 then
      Continue;

    // Look from top down for a K..A run
    i := len - 1;
    while i >= 12 do
    begin
      // Check last 13 cards: i-12 .. i
      if G.Tableau[p][i].Rank = Ace then
      begin
        startIdx := i - 12;
        if (startIdx >= 0) and (G.Tableau[p][startIdx].Rank = King) then
        begin
          // Check descending and same suit
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
            // Remove the 13 cards
            SetLength(G.Tableau[p], len - 13);
            Inc(G.CompletedRuns);
            len := Length(G.Tableau[p]);
            // Flip new top card if any
            if len > 0 then
              G.Tableau[p][len - 1].FaceUp := True;
            Break; // only one run at a time per scan
          end;
        end;
      end;
      Dec(i);
    end;
  end;
end;

procedure MoveSequence(var G: TSpiderGame; FromPile, StartIndex, ToPile: Integer);
var
  srcLen, moveCount, i: Integer;
  temp: array of TCard;
begin
  if not CanMoveSequence(G, FromPile, StartIndex, ToPile) then
    Exit;

  srcLen := Length(G.Tableau[FromPile]);
  moveCount := srcLen - StartIndex;

  SetLength(temp, moveCount);
  for i := 0 to moveCount - 1 do
    temp[i] := G.Tableau[FromPile][StartIndex + i];

  // Shrink source pile
  SetLength(G.Tableau[FromPile], StartIndex);
  if Length(G.Tableau[FromPile]) > 0 then
    G.Tableau[FromPile][High(G.Tableau[FromPile])].FaceUp := True;

  // Append to destination
  i := Length(G.Tableau[ToPile]);
  SetLength(G.Tableau[ToPile], i + moveCount);
  Move(temp[0], G.Tableau[ToPile][i], moveCount * SizeOf(TCard));

  // Check for completed runs
  RemoveCompletedRuns(G);
end;

function CanDealFromStock(const G: TSpiderGame): Boolean;
var
  p: Integer;
begin
  // Must have stock left and no empty pile
  if GetStockDealsRemaining(G) <= 0 then
  begin
    Result := False;
    Exit;
  end;

  for p := 0 to 9 do
    if Length(G.Tableau[p]) = 0 then
    begin
      Result := False;
      Exit;
    end;

  Result := True;
end;

procedure DealFromStock(var G: TSpiderGame);
var
  p: Integer;
begin
  if not CanDealFromStock(G) then
    Exit;

  for p := 0 to 9 do
  begin
    G.Stock[G.StockPos].FaceUp := True;
    SetLength(G.Tableau[p], Length(G.Tableau[p]) + 1);
    G.Tableau[p][High(G.Tableau[p])] := G.Stock[G.StockPos];
    Inc(G.StockPos);
  end;

  RemoveCompletedRuns(G);
end;

function IsWon(const G: TSpiderGame): Boolean;
begin
  Result := (G.CompletedRuns = 8);
end;

end.


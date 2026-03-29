unit CardDeck;

{$mode objfpc}{$H+}

interface

type
  TSuit = (Hearts, Diamonds, Clubs, Spades);
  TRank = (Ace, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King);
  TSpiderDifficulty = (sdOneSuit, sdTwoSuit, sdFourSuit);

  TCard = record
    Rank: TRank;
    Suit: TSuit;
    FaceUp: Boolean;
    Value: Integer;
  end;

const
  NUM_OF_DECKS = 2;
  CARDS_PER_DECK = 52;
  TOTAL_CARDS = 104;

type
  TDeck = array[0..TOTAL_CARDS - 1] of TCard;

  TPile = array of TCard;          // A tableau pile
  TTableau = array[0..9] of TPile; // 10 piles

procedure BuildDeck(var Deck: TDeck; Difficulty: TSpiderDifficulty);
procedure ShuffleDeck(var Deck: TDeck);
function RankToStr(R: TRank): string;
function SuitToStr(S: TSuit): string;

implementation

procedure BuildDeck(var Deck: TDeck);
var
  d, r, s, i: Integer;
begin
  d := 0;
  for i := 1 to NUM_OF_DECKS do
    for s := Ord(Low(TSuit)) to Ord(High(TSuit)) do
      for r := Ord(Low(TRank)) to Ord(High(TRank)) do
      begin
        Deck[d].Rank := TRank(r);
        Deck[d].Suit := TSuit(s);
        Deck[d].FaceUp := False;
        Deck[d].Value := r + 1;
        Inc(d);
      end;
end;

procedure ShuffleDeck(var Deck: TDeck);
var
  i, j: Integer;
  Temp: TCard;
begin
  for i := TOTAL_CARDS - 1 downto 1 do
  begin
    j := Random(i + 1);
    Temp := Deck[i];
    Deck[i] := Deck[j];
    Deck[j] := Temp;
  end;
end;

function RankToStr(R: TRank): string;
const
  RankNames: array[TRank] of string =
    ('A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K');
begin
  Result := RankNames[R];
end;

function SuitToStr(S: TSuit): string;
const
  SuitNames: array[TSuit] of string =
    ('H', 'D', 'C', 'S'); // short for display
begin
  Result := SuitNames[S];
end;

end.


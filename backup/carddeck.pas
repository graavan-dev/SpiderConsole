unit CardDeck;

{$mode objfpc}{$H+}

interface

uses
  SpiderTypes;

//type
//  TSuit = (Hearts, Diamonds, Clubs, Spades);
//  TRank = (Ace, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King);
//  TSpiderDifficulty = (sdOneSuit, sdTwoSuit, sdFourSuit);
//
//  TCard = record
//    Rank: TRank;
//    Suit: TSuit;
//    FaceUp: Boolean;
//    Value: Integer;
//  end;
//
//const
//  NUM_OF_DECKS = 2;
//  CARDS_PER_DECK = 52;
//  TOTAL_CARDS = 104;

//type
//  TDeck = array[0..TOTAL_CARDS - 1] of TCard;
//
//  TPile = array of TCard;          // A tableau pile
//  TTableau = array[0..9] of TPile; // 10 piles

procedure BuildDeck(var Deck: TDeck; Difficulty: TSpiderDifficulty);
procedure ShuffleDeck(var Deck: TDeck);
function RankToStr(R: TRank): string;
function SuitToStr(S: TSuit): string;

implementation

procedure BuildDeck(var Deck: TDeck; Difficulty: TSpiderDifficulty);
var
  d, r, i: Integer;
  s: TSuit;
begin
  d := 0;

  case Difficulty of

    sdOneSuit:
      begin
        // 1-suit Spider: 8 copies of Spades
        for i := 1 to 8 do
          for r := Ord(Low(TRank)) to Ord(High(TRank)) do
          begin
            Deck[d].Rank := TRank(r);
            Deck[d].Suit := Spades;
            Deck[d].FaceUp := False;
            Inc(d);
          end;
      end;

    sdTwoSuit:
      begin
        // 2-suit Spider: 4 copies of Hearts, 4 copies of Spades
        for i := 1 to 4 do
          for s in [Hearts, Spades] do
            for r := Ord(Low(TRank)) to Ord(High(TRank)) do
            begin
              Deck[d].Rank := TRank(r);
              Deck[d].Suit := s;
              Deck[d].FaceUp := False;
              Inc(d);
            end;
      end;

    sdFourSuit:
      begin
        // 4-suit Spider: 2 copies of each suit
        for i := 1 to 2 do
          for s := Low(TSuit) to High(TSuit) do
            for r := Ord(Low(TRank)) to Ord(High(TRank)) do
            begin
              Deck[d].Rank := TRank(r);
              Deck[d].Suit := s;
              Deck[d].FaceUp := False;
              Inc(d);
            end;
      end;

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
  //** Work on why unicode characters are'nt working
begin
  case S of
    Hearts:   Result := 'H';
    Diamonds: Result := 'D';
    Clubs:    Result := 'C';
    Spades:   Result := 'S';
  end;
end;

end.


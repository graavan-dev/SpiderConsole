unit SpiderTypes;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser;

const
  NUM_OF_DECKS = 2;
  CARDS_PER_DECK = 52;
  TOTAL_CARDS = 104;
  USERS_FILE = 'userdata.json';

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

  TDeck = array[0..TOTAL_CARDS - 1] of TCard;
  TPile = array of TCard;          // A tableau pile
  TTableau = array[0..9] of TPile; // 10 piles

  TSpiderLogger = record
    Active: Boolean;
    F: Text;
  end;

  TSpiderGameState = record
    Tableau: TTableau;
    Stock: array[0..49] of TCard;
    StockPos: Integer;
    CompletedRuns: Integer;
  end;

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

  TSpiderGame = record
    Tableau: TTableau;
    Stock: array[0..49] of TCard;
    StockPos: Integer;
    CompletedRuns: Integer;
    Logger: TSpiderLogger;
    Stats: TSpiderStats;
    MovesThisGame: Integer;  { #todo : What is this for? Really needed? }
    Difficulty: TSpiderDifficulty;
    UndoStack: array of TSpiderGameState;
    RedoStack: array of TSpiderGameState;
  end;

  TUserProfile = record
    UserName: string[32];
    Stats: TSpiderStats;
  end;

  TUserList = record
    Count: Integer;
    Players: array of TUserProfile;
  end;

var
  JSONData: TJSONData;
  JSONObject: TJSONObject;
  JSONArray: TJSONArray;
  JSONFileName: string;
  FileStream: TFileStream;
  ActiveUserIndex: Integer;
  Users: TUserList;
  G: TSpiderGame;
  F: Text;
  cardStr: string;
  cmd: string;
  FromPile, ToPile, StartIndex: Integer;
  ViewMenu: Boolean;
  ViewStatsMenu: Boolean;
  ViewUtilMenu: Boolean;
  ViewPlayersMenu: Boolean;
  Stats: TSpiderStats;
  Diff: TSpiderDifficulty;
  intDiff: Integer;
  Won: Boolean;

implementation

end.


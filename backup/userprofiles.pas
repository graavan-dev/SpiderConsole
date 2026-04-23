unit UserProfiles;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SpiderStats;

type
  TUserProfile = record
    UserName: string[32];
    Stats: TSpiderStats;       // your existing stats type
    LastDifficulty: Integer;
    HasSavedGame: Boolean;
    //SavedGame: TSpiderGame;  // your existing game state type
  end;

  TUserList = record
    Count: Integer;
    Items: array of TUserProfile;
  end;

const
  USERS_FILE = 'users.txt';

  procedure LoadUsers;
  procedure SaveUsers;
  function FindUserIndex(const Name: string): Integer;
  function AddUser(const Name: string): Integer;
  procedure DeleteUser(Index: Integer);
  function GetUserSaveFile(const U: TUserProfile): string;

implementation

procedure LoadUsers;
var
  F: file of TUserProfile;
  U: TUserProfile;
  Users: TUserList;
begin
  Users.Count := 0;
  SetLength(Users.Items, 0);

  if not FileExists(USERS_FILE) then
    Exit;

  AssignFile(F, USERS_FILE);
  Reset(F);
  try
    while not Eof(F) do
    begin
      Read(F, U);
      Inc(Users.Count);
      SetLength(Users.Items, Users.Count);
      Users.Items[Users.Count - 1] := U;
    end;
  finally
    CloseFile(F);
  end;
end;

procedure SaveUsers;
var
  F: file of TUserProfile;
  i: Integer;
  Users: TUserList;
begin
  AssignFile(F, USERS_FILE);
  Rewrite(F);
  try
    for i := 0 to Users.Count - 1 do
      Write(F, Users.Items[i]);
  finally
    CloseFile(F);
  end;
end;

function FindUserIndex(const Name: string): Integer;
var
  i: Integer;
  Users: TUserList;
begin
  Result := -1;
  for i := 0 to Users.Count - 1 do
    if SameText(Users.Items[i].UserName, Name) then
      Exit(i);
end;

function AddUser(const Name: string): Integer;
var
    Users: TUserList;
begin
  Inc(Users.Count);
  SetLength(Users.Items, Users.Count);
  with Users.Items[Users.Count - 1] do
  begin
    UserName := Name;
    FillChar(Stats, SizeOf(Stats), 0);
    LastDifficulty := 1;
    HasSavedGame := False;
  end;
  Result := Users.Count - 1;
end;

procedure DeleteUser(Index: Integer);
var
  i: Integer;
  Users: TUserList;
begin
  if (Index < 0) or (Index >= Users.Count) then Exit;
  for i := Index to Users.Count - 2 do
    Users.Items[i] := Users.Items[i + 1];
  Dec(Users.Count);
  SetLength(Users.Items, Users.Count);
end;

function GetUserSaveFile(const U: TUserProfile): string;
begin
  Result := 'save_' + Trim(U.UserName) + '.dat';
end;


end.


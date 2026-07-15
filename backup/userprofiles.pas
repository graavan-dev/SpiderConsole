unit UserProfiles;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, SpiderTypes;

function LoadUsersFromJSON(const FileName: string): TUserList;
procedure SaveUsersToJSON(const FileName: string; const Users: TUserList);
function RenameUser(var Users: TUserList; const OldName, NewName: string): Boolean;
function CloneUserFromTemplate(var Users: TUserList; const NewName: string): Boolean;
function ChooseUser(const Users: TUserList): Integer;
procedure UserManagementMenu(var Users: TUserList);

implementation

procedure ClearScreen;
begin
  Write(#27'[2J'#27'[H');
end;

function ReadFileToString(const FileName: string): string;
var
  S: TStringList;
begin
  Result := '';
  if not FileExists(FileName) then Exit;

  S := TStringList.Create;
  try
    S.LoadFromFile(FileName);
    Result := S.Text;
  finally
    S.Free;
  end;
end;

function LoadUsersFromJSON(const FileName: string): TUserList;
var
  JSON: TJSONData;
  Obj: TJSONObject;
  Keys: TStringList;
  i: Integer;
  UserObj: TJSONObject;
  StatsArr: TJSONArray;
  StatsObj: TJSONObject;
  S: string;
begin
  Result.Count := 0;
  SetLength(Result.Players, 0);

  // Read entire file into a string
  S := '';
  if FileExists(FileName) then
    S := Trim(ReadFileToString(FileName));

  if S = '' then
  begin
    WriteLn('Warning: JSON file empty or missing: ', FileName);
    Exit;
  end;

  JSON := GetJSON(S);
  Obj := TJSONObject(JSON);

  Keys := TStringList.Create;
  try
    Keys.Clear;
    for i := 0 to Obj.Count - 1 do
      Keys.Add(Obj.Names[i]);


    Result.Count := Keys.Count;
    SetLength(Result.Players, Result.Count);

    for i := 0 to Keys.Count - 1 do
    begin
      UserObj := Obj.Objects[Keys[i]];

      // Load username
      Result.Players[i].UserName := UserObj.Get('Name', '');

      // Stats is an array with one object
      StatsArr := UserObj.Arrays['Stats'];
      StatsObj := StatsArr.Objects[0];

      with Result.Players[i].Stats do
      begin
        GamesPlayed := StatsObj.Get('GamesPlayed', 0);
        GamesWon := StatsObj.Get('GamesWon', 0);
        GamesLost := StatsObj.Get('GamesLost', 0);
        GamesDrawn := StatsObj.Get('GamesDrawn', 0);
        WinPercentage := StatsObj.Get('WinPercentage', 0);
        HighScore := StatsObj.Get('HighScore', 0);
        AverageScorePerGame := StatsObj.Get('AverageScorePerGame', 0);

        // Convert "HH:MM" → TDateTime
        BestTime := StrToTimeDef(StatsObj.Get('BestTime', '00:00'), 0);
        AverageTimePerGame := StrToTimeDef(StatsObj.Get('AverageTimePerGame', '00:00'), 0);

        TotalMoves := StatsObj.Get('TotalMoves', 0);
        TotalStacks := StatsObj.Get('TotalStacks', 0);
        AverageStacksPerGame := StatsObj.Get('AverageStacksPerGame', 0);
        OneSuitPlayed := StatsObj.Get('OneSuitPlayed', 0);
        OneSuitWon := StatsObj.Get('OneSuitWon', 0);
        TwoSuitPlayed := StatsObj.Get('TwoSuitPlayed', 0);
        TwoSuitWon := StatsObj.Get('TwoSuitWon', 0);
        FourSuitPlayed := StatsObj.Get('FourSuitPlayed', 0);
        FourSuitWon := StatsObj.Get('FourSuitWon', 0);

        LastDifficulty := StatsObj.Get('LastDifficulty', 0);
        HasSavedGame := StatsObj.Get('HasSavedGame', False);
      end;
    end;

  finally
    Keys.Free;
    JSON.Free;
  end;
end;

procedure SaveUsersToJSON(const FileName: string; const Users: TUserList);
var
  RootObj: TJSONObject;
  UserObj: TJSONObject;
  StatsArr: TJSONArray;
  StatsObj: TJSONObject;
  i: Integer;
  FS: TFileStream;
  S: string;
begin
  RootObj := TJSONObject.Create;

  try
    for i := 0 to Users.Count - 1 do
    begin
      UserObj := TJSONObject.Create;
      UserObj.Add('Name', Users.Players[i].UserName);

      StatsArr := TJSONArray.Create;
      StatsObj := TJSONObject.Create;

      with Users.Players[i].Stats do
      begin
        StatsObj.Add('GamesPlayed', GamesPlayed);
        StatsObj.Add('GamesWon', GamesWon);
        //StatsObj.Add('GamesLost', GamesLost);
        StatsObj.Add('GamesDrawn', GamesDrawn);
        StatsObj.Add('WinPercentage', WinPercentage);
        StatsObj.Add('HighScore', HighScore);
        StatsObj.Add('AverageScorePerGame', AverageScorePerGame);

        StatsObj.Add('BestTime', FormatDateTime('hh:nn', BestTime));
        StatsObj.Add('AverageTimePerGame', FormatDateTime('hh:nn', AverageTimePerGame));

        StatsObj.Add('TotalMoves', TotalMoves);
        StatsObj.Add('TotalStacks', TotalStacks);
        StatsObj.Add('AverageStacksPerGame', AverageStacksPerGame);
        StatsObj.Add('OneSuitPlayed', OneSuitPlayed);
        StatsObj.Add('OneSuitWon', OneSuitWon);
        StatsObj.Add('TwoSuitPlayed', TwoSuitPlayed);
        StatsObj.Add('TwoSuitWon', TwoSuitWon);
        StatsObj.Add('FourSuitPlayed', FourSuitPlayed);
        StatsObj.Add('FourSuitWon', FourSuitWon);

        StatsObj.Add('LastDifficulty', LastDifficulty);
        StatsObj.Add('HasSavedGame', HasSavedGame);
      end;

      StatsArr.Add(StatsObj);
      UserObj.Add('Stats', StatsArr);

      RootObj.Add(Users.Players[i].UserName, UserObj);
    end;

    // Convert JSON to pretty string
    S := RootObj.FormatJSON([], 2);

    // Write to file
    FS := TFileStream.Create(FileName, fmCreate);
    try
      FS.WriteBuffer(S[1], Length(S));
    finally
      FS.Free;
    end;

  finally
    RootObj.Free;
  end;
end;

function FindUserIndex(const Users: TUserList; const UserName: string): Integer;
var
  i: Integer;
begin
  for i := 0 to Users.Count - 1 do
    if SameText(Users.Players[i].UserName, UserName) then
      Exit(i);

  Result := -1;
end;

function AddUser(var Users: TUserList; const NewName: string): Boolean;
var
  i: Integer;
  idx: Integer;
begin
  Result := False;

  // Prevent duplicates
  for i := 0 to Users.Count - 1 do
    if SameText(Users.Players[i].UserName, NewName) then
      Exit; // user already exists

  // Add new user
  idx := Users.Count;
  Inc(Users.Count);
  SetLength(Users.Players, Users.Count);

  // Initialize profile
  Users.Players[idx].UserName := NewName;

  with Users.Players[idx].Stats do
  begin
    GamesPlayed := 0;
    GamesWon := 0;
    GamesLost := 0;
    GamesDrawn := 0;
    WinPercentage := 0;
    HighScore := 0;
    AverageScorePerGame := 0;

    BestTime := 0;               // TDateTime = 0 → "00:00"
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

  Result := True;
end;

function DeleteUser(var Users: TUserList; const UserName: string): Boolean;
var
  idx, i: Integer;
begin
  Result := False;
  idx := FindUserIndex(Users, UserName);
  if idx = -1 then Exit;

  // Shift everything down
  for i := idx to Users.Count - 2 do
    Users.Players[i] := Users.Players[i + 1];

  Dec(Users.Count);
  SetLength(Users.Players, Users.Count);

  Result := True;
end;

function RenameUser(var Users: TUserList; const OldName, NewName: string): Boolean;
var
  idx: Integer;
begin
  Result := False;

  // Prevent duplicate names
  if FindUserIndex(Users, NewName) <> -1 then Exit;

  idx := FindUserIndex(Users, OldName);
  if idx = -1 then Exit;

  Users.Players[idx].UserName := NewName;
  Result := True;
end;

function CloneUserFromTemplate(var Users: TUserList; const NewName: string): Boolean;
var
  TemplateIndex: Integer;
begin
  Result := False;

  // Prevent duplicates
  if FindUserIndex(Users, NewName) <> -1 then Exit;

  TemplateIndex := FindUserIndex(Users, 'Template');
  if TemplateIndex = -1 then Exit;

  // Copy stats from template
  Users.Players[Users.Count - 1].Stats :=
    Users.Players[TemplateIndex].Stats;

  Result := True;
end;

function ChooseUser(const Users: TUserList): Integer;
var
  i, choice: Integer;
  input: string;
begin
  Result := -1;

  if Users.Count = 0 then
  begin
    WriteLn('No users available.');
    Exit;
  end;

  while True do
  begin
    ClearScreen;
    WriteLn;
    WriteLn('==============================');
    WriteLn('        Select a User         ');
    WriteLn('==============================');

    for i := 0 to Users.Count - 1 do
      WriteLn('  ', i + 1, ') ', Users.Players[i].UserName);

    WriteLn('  0) Cancel');
    WriteLn('------------------------------');
    Write('Enter choice: ');
    ReadLn(input);
    ClearScreen;
    // Validate numeric input
    if not TryStrToInt(input, choice) then
    begin
      WriteLn('Invalid input. Please enter a number.');
      Continue;
    end;

    // Cancel
    if choice = 0 then
    begin
      Result := -1;
      Exit;
    end;

    // Valid range
    if (choice >= 1) and (choice <= Users.Count) then
    begin
      Result := choice - 1;
      Exit;
    end;

    WriteLn('Invalid choice. Try again.');
  end;
end;

procedure UserManagementMenu(var Users: TUserList);
var
  choice: Integer;
  input, name, newName: string;

begin
  repeat
    ClearScreen;
    WriteLn;
    WriteLn('===================================');
    WriteLn('         User Management Menu       ');
    WriteLn('===================================');
    WriteLn(' 1) Choose User');
    WriteLn(' 2) Create New User');
    WriteLn(' 3) Delete User');
    WriteLn(' 4) Rename User');
    WriteLn(' 5) Reset User Stats');
    WriteLn(' 6) Clone User From Template');
    WriteLn(' 0) Exit');
    WriteLn('-----------------------------------');
    Write('Enter choice: ');
    ReadLn(input);

    if not TryStrToInt(input, choice) then
    begin
      WriteLn('Invalid input. Please enter a number.');
      Continue;
    end;

    case choice of

      // ---------------------------------------------------------
      // 1) Choose User
      // ---------------------------------------------------------
      1:
        begin
          ActiveUserIndex := ChooseUser(Users);
          if ActiveUserIndex = -1 then
            WriteLn('No user selected.')
          else
            WriteLn('Selected user: ', Users.Players[ActiveUserIndex].UserName);
            //readln;
        end;

      // ---------------------------------------------------------
      // 2) Create New User
      // ---------------------------------------------------------
      2:
        begin
          Write('Enter new username: ');
          ReadLn(name);

          if AddUser(Users, name) then
            WriteLn('User "', name, '" created.')
          else
            WriteLn('User "', name, '" already exists.');
        end;

      // ---------------------------------------------------------
      // 3) Delete User
      // ---------------------------------------------------------
      3:
        begin
          Write('Enter username to delete: ');
          ReadLn(name);

          if DeleteUser(Users, name) then
            WriteLn('User "', name, '" deleted.')
          else
            WriteLn('User "', name, '" not found.');
        end;

      // ---------------------------------------------------------
      // 4) Rename User
      // ---------------------------------------------------------
      4:
        begin
          Write('Enter existing username: ');
          ReadLn(name);

          Write('Enter new username: ');
          ReadLn(newName);

          if RenameUser(Users, name, newName) then
            WriteLn('User "', name, '" renamed to "', newName, '".')
          else
            WriteLn('Rename failed. User may not exist or new name already taken.');
        end;

      // ---------------------------------------------------------
      // 5) Reset Stats
      // ---------------------------------------------------------
      5:
        begin
          Write('Enter username to reset stats: ');
          ReadLn(name);

          ActiveUserIndex := FindUserIndex(Users, name);
          if ActiveUserIndex = -1 then
            WriteLn('User not found.')
          else
          begin
            ResetStats(Users.Players[ActiveUserIndex].Stats);
            WriteLn('Stats reset for "', name, '".');
          end;
        end;

      // ---------------------------------------------------------
      // 6) Clone From Template
      // ---------------------------------------------------------
      6:
        begin
          Write('Enter new username to clone template into: ');
          ReadLn(name);

          if CloneUserFromTemplate(Users, name) then
            WriteLn('User "', name, '" created from template.')
          else
            WriteLn('Clone failed. Template missing or user already exists.');
        end;

      // ---------------------------------------------------------
      // 0) Exit
      // ---------------------------------------------------------
      0:
        WriteLn('Exiting user management menu...');

    else
      WriteLn('Invalid choice. Try again.');
    end;

  until choice = 0;
end;

end.


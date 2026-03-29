unit SpiderLog;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TSpiderLogger = record
    Active: Boolean;
    F: Text;
  end;

procedure StartLog(var L: TSpiderLogger; const FileName: string);
procedure LogLine(var L: TSpiderLogger; const S: string);
procedure EndLog(var L: TSpiderLogger);
procedure ReplayLog(const FileName: string);

function Timestamp: string;

implementation

function Timestamp: string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now);
end;

procedure StartLog(var L: TSpiderLogger; const FileName: string);
begin
  AssignFile(L.F, FileName);
  Rewrite(L.F);
  L.Active := True;
  LogLine(L, '--- Spider Solitaire Log Started ---');
end;

procedure LogLine(var L: TSpiderLogger; const S: string);
begin
  if not L.Active then Exit;
  WriteLn(L.F, Timestamp, '  ', S);
end;

procedure EndLog(var L: TSpiderLogger);
begin
  if not L.Active then Exit;
  LogLine(L, '--- Log Ended ---');
  CloseFile(L.F);
  L.Active := False;
end;

//procedure ReplayLog(const FileName: string);
//var
//  F: Text;
//  line: string;
//  fromPile, startIdx, toPile: Integer;
//begin
//  AssignFile(F, FileName);
//  Reset(F);
//
//  NewGame(G); // fresh game
//
//  while not EOF(F) do
//  begin
//    ReadLn(F, line);
//
//    if Pos('Move:', line) > 0 then
//    begin
//      // Extract numbers
//      fromPile := StrToIntDef(ExtractWord(3, line, [' ']), -1);
//      startIdx := StrToIntDef(ExtractWord(4, line, [' ']), -1);
//      toPile   := StrToIntDef(ExtractWord(6, line, [' ']), -1);
//
//      if CanMoveSequence(G, fromPile, startIdx, toPile) then
//        MoveSequence(G, fromPile, startIdx, toPile);
//    end
//    else if Pos('Deal from stock', line) > 0 then
//    begin
//      if CanDealFromStock(G) then
//        DealFromStock(G);
//    end;
//  end;
//  CloseFile(F);
//end;

end.


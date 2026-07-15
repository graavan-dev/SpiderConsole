unit SpiderLog;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, SpiderTypes;

procedure StartLog(var L: TSpiderLogger; const FileName: string);
procedure LogLine(var L: TSpiderLogger; const S: string);
procedure EndLog(var L: TSpiderLogger);
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

end.

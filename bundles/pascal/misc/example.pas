{ Comments }
{ and /* multiple (* nested { comments } *) */ }

{ integers }

123456.789e0
%11100 // binary
&1234567 // octal
$1234567890AaBbCcDdEeFf // hexademical

{ strings }
'I am a string'
'Slashes do NOT work here\'
identifier
'Special characters:' #10 #11 #$F

type
  PInteger = ^Integer;
  NotANormalTypeName = class
     a: Integer;
  end;
  Stuff = set of inTeger;

  AGenericClass<T, B: class> = class;

PrOceDure DoStuff(a: TMagic);

funcTION ReturnOne: PInteger;
begin
  ReturnOne := 1;
end;

PROCEDURE MyType.MyMethod(a: Integer, b: QWord); overload;
var
  var
    res: Integer;
    i: Integer;
    &String: String;
    j: TMyCoolType = 123;
begin
  if a = 1 then
    res := a mod b;
  else begin
    res := 34567;
  end;

  &String := res;

  Result := &String;
  Xyz.Close;

  for i := 1 to 10 do
    if res <> 10 then res := i;
end;

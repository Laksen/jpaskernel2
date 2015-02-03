unit cclasses;

interface

type
 generic TGDictionary<TKey, TValue> = class
 private
 type
  TSplayCallback = procedure(Val: TValue; data: pointer);
  TSplayObjCallback = procedure(Val: TValue; data: pointer) of object;
  
  TSplayKeyCallback = procedure(Val: TKey; data: pointer);
  TSplayKeyObjCallback = procedure(Val: TKey; data: pointer) of object;
  
  PSplayNode = ^TSplayNode;
  TSplayNode = record
   Left, Right: PSplayNode;
   
   Key: TKey;
   Value: TValue;
  end;
 var
  fTop: PSplayNode;
  fNull: TValue;
 private
  procedure Splay(var t: PSplayNode; Key: TKey);
  procedure SplayAdd(var tree: PSplayNode; Key: TKey; Value: TValue);
  function SplayDelete(var tree: PSplayNode; Key: TKey): TValue;
  function SplayLookup(var tree: PSplayNode; Key: TKey): TValue;
  procedure SplaySetValue(var tree: PSplayNode; const Key: TKey; value: TValue);
  
  procedure IntForeachCall(n: PSplayNode; clb: TSplayCallback; data: pointer);
  procedure IntForeachCall2(n: PSplayNode; clb: TSplayObjCallback; data: pointer);
  
  procedure IntForeachKeyCall(n: PSplayNode; clb: TSplayKeyCallback; data: pointer);
  procedure IntForeachKeyCall2(n: PSplayNode; clb: TSplayKeyObjCallback; data: pointer);
  
  procedure SetValue(const Key: TKey; value: TValue);
 public
  procedure Add(Key: TKey; Value: TValue);
  function Delete(Key: TKey): TValue;
  function Lookup(Key: TKey): TValue;
  
  procedure ForeachCall(clb: TSplayCallback; data: pointer); overload;
  procedure ForeachCall(clb: TSplayObjCallback; data: pointer); overload;
  
  procedure ForeachKeyCall(clb: TSplayKeyCallback; data: pointer); overload;
  procedure ForeachKeyCall(clb: TSplayKeyObjCallback; data: pointer); overload;
  
  constructor Create(NullValue: TValue);
  
  property Items[Key: TKey]: TValue read Lookup write SetValue; default;
 end;
 
 TDictionary = specialize TGDictionary<PtrInt, Pointer>;
 
 generic TGStack<TValue> = class
 private
 type
  PElement = ^TElement;
  TElement = record
   Value: TValue;
   Prev: PElement;
  end;
 var
  top: PElement;
  Null: TValue;
 public
  function Pop: TValue;
  procedure Push(Val: TValue);
  
  constructor Create(NullValue: TValue);
  destructor Destroy; override;
 end;
 
 TStack = specialize TGStack<Pointer>;
 
 generic TGQueue<TValue> = class
 private
 type
  PElement = ^TElement;
  TElement = record
   Value: TValue;
   next: PElement;
  end;
 var
  first, last: PElement;
  Null: TValue;
 public
  function Pop: TValue;
  procedure Push(Val: TValue);
  
  constructor Create(NullValue: TValue);
  destructor Destroy; override;
 end;
 
 TQueue = specialize TGQueue<Pointer>;
 
 generic TGList<TValue> = class
 private
 type
  PElement = ^TElement;
  TElement = record
   Value: TValue;
   next: PElement;
  end;
 var
  fNull: TValue;
  fCount: longint;
  fFirst: PElement;
  function GetValue(const index: longint): TValue;
 public
  procedure Add(Obj: TValue);
  procedure Remove(const Value: TValue);
  procedure Delete(const Index: longint);
  
  constructor Create(NullValue: TValue);
  destructor Destroy; override;
  
  property Count: longint read fCount;
  property Items[index: longint]: TValue read GetValue; default;
 end;
 
 TList = specialize TGList<Pointer>;
 
 generic TGStringList<TValue> = class
 private
 type
  PElement = ^TElement;
  TElement = record
   Name: pchar;
   Value: TValue;
   next: PElement;
  end;
 var
  fNull: TValue;
  fCount: longint;
  fFirst: PElement;
  function GetIDValue(const index: longint): TValue;
  function GetValue(const name: pchar): TValue;
 public
  procedure Add(Name: pchar; Obj: TValue);
  procedure Remove(const Value: TValue);
  procedure Delete(const Name: pchar);
  
  constructor Create(NullValue: TValue);
  destructor Destroy; override;
  
  property Count: longint read fCount;
  property ItemByIndex[index: longint]: TValue read GetIDValue;
  property Items[index: pchar]: TValue read GetValue; default;
 end;
 
 TStringList = specialize TGStringList<Pointer>;

function StrAlloc(len: longint): Pchar;
procedure StrDispose(p: pchar);
function StrLen(p: Pchar): longint;
function StrDup(a: PChar): PChar;
function StrComp(a,b: pchar; len: longint = -1): boolean;
function StrPosChar(sub: char; a: pchar): longint;
function StrCopy(a: pchar; idx, len: longint): pchar;
function StrRPos(sub, a: pchar): longint;

implementation

function StrRPos(sub, a: pchar): longint;
var x,y,i: longint;
begin
	result := -1;

	x := strlen(a);
	y := strlen(sub);

	for i := x-y downto 0 do
	begin
		if strcomp(@a[i], sub,y) then
		begin
			result := i;
			exit;
		end;
	end;
end;

function StrCopy(a: pchar; idx, len: longint): pchar;
var x: longint;
begin
	result := nil;

	if a = nil then exit;
	if len <= 0 then
	begin
		result := strdup(a);
		exit;
	end;

	x := strlen(a);

	if idx > x then exit;
	if idx+len > x then
		len := x-idx;

	result := stralloc(len);
	move(a[idx], result^, len);
end;

function StrLen(p: Pchar): longint;
begin
	result := 0;
	if p = nil then
		exit;

	while p^ <> #0 do
	begin
		inc(result);
		inc(p);
	end;
end;

function StrAlloc(len: longint): Pchar;
begin
	result := nil;

	if len <= 0 then
		exit;

	result := GetMem(len+1);
	if result <> nil then
		FillChar(result^, len+1, 0);
end;

procedure StrDispose(p: pchar);
begin
	if p = nil then exit;

	FreeMem(p);
end;

function StrDup(a: PChar): PChar;
var l: longint;
begin
  result := nil;

  if a = nil then
    exit;

  l := strlen(a);

  if l <= 0 then
    exit;

  result := StrAlloc(l);
  if result <> nil then
    move(a^, result^, l+1);
end;
function StrComp(a,b: pchar; len: longint = -1): boolean;
var c: longint;
begin
	result := false;

	c := 0;

	if (a = nil) or (b = nil) then exit;

	while true do
	begin
		if a^ <> b^ then
			exit;
		if a^ = #0 then
			break;
		inc(c);
		if (c >= len) and (len <> -1) then
			break;
		inc(a);
		inc(b);
	end;

	result := true;
end;

function StrPosChar(sub: char; a: pchar): longint;
var x,i: longint;
begin
	result := -1;

	x := strlen(a);

	for i := 0 to x-1 do
	begin
		if a[i] = sub then
		begin
			result := i;
			exit;
		end;
	end;
end;

procedure TGDictionary.IntForeachCall(n: PSplayNode; clb: TSplayCallback; data: pointer);
begin
   if not assigned(n) then
      exit;
   
   clb(n^.value, data);
   
   IntForeachCall(n^.left, clb, data);
   IntForeachCall(n^.right, clb, data);
end;

procedure TGDictionary.IntForeachCall2(n: PSplayNode; clb: TSplayObjCallback; data: pointer);
begin
   if not assigned(n) then
      exit;
   
   clb(n^.value, data);
   
   IntForeachCall2(n^.left, clb, data);
   IntForeachCall2(n^.right, clb, data);
end;

procedure TGDictionary.IntForeachKeyCall(n: PSplayNode; clb: TSplayKeyCallback; data: pointer);
begin
   if not assigned(n) then
      exit;
   
   clb(n^.key, data);
   
   IntForeachKeyCall(n^.left, clb, data);
   IntForeachKeyCall(n^.right, clb, data);
end;

procedure TGDictionary.IntForeachKeyCall2(n: PSplayNode; clb: TSplayKeyObjCallback; data: pointer);
begin
   if not assigned(n) then
      exit;
   
   clb(n^.key, data);
   
   IntForeachKeyCall2(n^.left, clb, data);
   IntForeachKeyCall2(n^.right, clb, data);
end;

procedure TGDictionary.ForeachCall(clb: TSplayCallback; data: pointer);
begin
   IntForeachCall(fTop, clb, data);
end;

procedure TGDictionary.ForeachCall(clb: TSplayObjCallback; data: pointer);
begin
   IntForeachCall2(fTop, clb, data);
end;

procedure TGDictionary.ForeachKeyCall(clb: TSplayKeyCallback; data: pointer);
begin
   IntForeachKeyCall(fTop, clb, data);
end;

procedure TGDictionary.ForeachKeyCall(clb: TSplayKeyObjCallback; data: pointer);
begin
   IntForeachKeyCall2(fTop, clb, data);
end;

procedure TGDictionary.Add(Key: TKey; Value: TValue);
begin
   SplayAdd(fTop, Key, Value);
end;

function TGDictionary.Delete(Key: TKey): TValue;
begin
   result := SplayDelete(fTop, Key);
end;

function TGDictionary.Lookup(Key: TKey): TValue;
begin
   result := SplayLookup(fTop, key);
end;

constructor TGDictionary.Create(NullValue: TValue);
begin
   inherited create;
   fNull := NullValue;
   fTop := nil;
end;

procedure TGDictionary.Splay(var t: PSplayNode; Key: TKey);
var N: TSplayNode;
    l,r,y: PSplayNode;
begin
   if not assigned(t) then
      exit;
   
   n.left := nil;
   n.right := nil;
   
   l := @n;
   r := @n;
   
   while true do
   begin
      if key < t^.key then
      begin
         if not assigned(t^.left) then
            break;
         if key < t^.left^.key then
         begin
            y := t^.left;
            t^.left := y^.right;
            y^.right := t;
            t := y;
            if not assigned(t^.left) then
               break;
         end;
         
         r^.left := t;
         r := t;
         t := t^.left;
      end
      else if key > t^.key then
      begin
         if not assigned(t^.right) then
            break;
         
         if key > t^.right^.key then
         begin
            y := t^.right;
            t^.right := y^.left;
            y^.left := t;
            t := y;
            if not assigned(t^.right) then
               break;
         end;
         
         l^.right := t;
         l := t;
         t := t^.right;
      end
      else
         break;
   end;
   
   l^.right := t^.left;
   r^.left := t^.right;
   t^.left := n.right;
   t^.right := n.left;
end;

procedure TGDictionary.SplayAdd(var tree: PSplayNode; Key: TKey; Value: TValue);
var NewNode: PSplayNode;
begin
   NewNode := GetMem(SizeOf(TSplayNode));
   NewNode^.Key := Key;
   NewNode^.Value := Value;
   
   if not Assigned(tree) then
   begin
      NewNode^.Left := nil;
      NewNode^.Right := nil;
      tree := NewNode;
      
      exit;
   end;
   
   splay(tree, key);
   
   if key < tree^.Key then
   begin
      NewNode^.Left := tree^.Left;
      NewNode^.Right := tree;
      tree^.left := nil;
      
      tree := NewNode;
   end
   else if key > tree^.key then
   begin
      NewNode^.Right := tree^.Right;
      NewNode^.Left := tree;
      tree^.Right := nil;
      
      tree := NewNode;
   end
   else
      FreeMem(NewNode);
end;

function TGDictionary.SplayDelete(var tree: PSplayNode; Key: TKey): TValue;
var x: PSplayNode;
begin
   if not assigned(tree) then
      exit(fNull);
   
   Splay(tree, key);
   
   if key = tree^.Key then
   begin
      if not assigned(tree^.left) then
         x := tree^.right
      else
      begin
         x := tree^.left;
         splay(x, key);
         x^.right := tree^.right;
      end;
      SplayDelete := x^.Value;
      freeMem(tree);
      tree := x;
   end
   else
      exit(fNull);
end;

procedure TGDictionary.SetValue(const Key: TKey; value: TValue);
begin
   SplaySetValue(fTop, key, value);
end;

procedure TGDictionary.SplaySetValue(var tree: PSplayNode; const Key: TKey; value: TValue);
begin
   if not assigned(tree) then
      exit;
   
   Splay(tree, key);
   
   if key = tree^.Key then
		tree^.value := value;
end;

function TGDictionary.SplayLookup(var tree: PSplayNode; Key: TKey): TValue;
begin
   if not assigned(tree) then
      exit(fNull);
   
   Splay(tree, key);
   
   if key = tree^.Key then
      exit(tree^.value)
   else
      exit(fNull);
end;

function TGStack.Pop: TValue;
var p: PElement;
begin
   if top = nil then
      exit(null);
   
   repeat
      p := top;
      if p = nil then
         exit(null);
   until InterlockedCompareExchange(top, p^.prev, p) = p;
   
   result := p^.value;
   freemem(p);
end;

procedure TGStack.Push(Val: TValue);
var p: PElement;
begin
   p := GetMem(sizeof(TElement));
   
   p^.value := val;
   
   repeat
      p^.prev := top;
   until InterlockedCompareExchange(top, p, p^.prev) = p^.prev;
end;

constructor TGStack.Create(NullValue: TValue);
begin
   inherited Create;
   null := nullvalue;
   top := nil;
end;

destructor TGStack.Destroy;
begin
   inherited Destroy;
end;

function TGQueue.Pop: TValue;
var p: PElement;
begin
   if first = nil then
      exit(null);
   
   repeat
      p := first;
      if p = nil then
         exit(null);
   until InterlockedCompareExchange(first, p^.next, p) = p;
   
   result := p^.value;
   freemem(p);
end;

procedure TGQueue.Push(Val: TValue);
var p,x: PElement;
begin
   p := GetMem(sizeof(TElement));
   
   p^.value := val;
   
   if (first = nil) or (last = nil) then
   begin
      first := p;
      last := p;
      p^.next := nil;
      exit;
   end;
   
   p^.next := nil;
   
   while true do
   begin
      x := last;
      if InterlockedCompareExchange(last, p, x) = x then
         x^.next := p;
   end;
end;

constructor TGQueue.Create(NullValue: TValue);
begin
   inherited Create;
   null := nullvalue;
   first := nil;
   last := nil;
end;

destructor TGQueue.Destroy;
begin
   inherited Destroy;
end;

function TGStringList.GetIDValue(const index: longint): TValue;
var p: PElement;
    i: longint;
begin
   result := fNull;
   p := fFirst;
   i := 0;
   
   if p = nil then
      exit;
   
   while p <> nil do
   begin
      if i = index then
      begin
         result := p^.value;
         exit;
      end;
      inc(i);
      p := p^.next;
   end;
end;

function TGStringList.GetValue(const name: pchar): TValue;
var p: PElement;
begin
   result := fNull;
   p := fFirst;
   
   if p = nil then
      exit;
   
   while p <> nil do
   begin
      if strComp(name, p^.name) then
      begin
         result := p^.value;
         exit;
      end;
      p := p^.next;
   end;
end;

procedure TGStringList.Add(Name: pchar; Obj: TValue);
var p: PElement;
begin
   p := GetMem(SizeOf(TElement));
   p^.Name := StrDup(name);
   p^.Value := Obj;
   p^.Next := fFirst;
   
   fFirst := p;
   inc(fCount);
end;

procedure TGStringList.Remove(const Value: TValue);
var p,po: PElement;
begin
   p := fFirst;
   po := nil;
   
   if p = nil then
      exit;
   
   while p <> nil do
   begin
      if p^.value = value then
      begin
         if po = nil then
            fFirst := p^.next
         else
            po^.next := p^.next;
         
         FreeMem(p^.name);
         FreeMem(p);
         dec(fCount);
         exit;
      end;
      po := p;
      p := p^.next;
   end;
end;

procedure TGStringList.Delete(const Name: pchar);
var p,po: PElement;
begin
   p := fFirst;
   po := nil;
   
   if p = nil then
      exit;
   
   while p <> nil do
   begin
      if strComp(name, p^.name) then
      begin
         if po = nil then
            fFirst := p^.next
         else
            po^.next := p^.next;
         
         FreeMem(p^.name);
         FreeMem(p);
         dec(fCount);
         exit;
      end;
      po := p;
      p := p^.next;
   end;
end;

constructor TGStringList.Create(NullValue: TValue);
begin
   inherited Create;
   fFirst := nil;
   fCount := 0;
   fNull := NullValue;
end;

destructor TGStringList.Destroy;
var p,pn: PElement;
begin
   p := fFirst;
   while p <> nil do
   begin
      pn := p^.next;
      
      freemem(p^.name);
      freemem(p);
      
      p := pn;
   end;
   inherited Destroy;
end;

function TGList.GetValue(const index: longint): TValue;
var p: PElement;
    i: longint;
begin
   result := fNull;
   p := fFirst;
   i := 0;
   
   if p = nil then
      exit;
   
   while p <> nil do
   begin
      if i = index then
      begin
         result := p^.value;
         exit;
      end;
      inc(i);
      p := p^.next;
   end;
end;

procedure TGList.Add(Obj: TValue);
var p,x: PElement;
begin
   p := GetMem(SizeOf(TElement));
   p^.Value := Obj;
   p^.next := nil;
   
   if fFirst = nil then
      fFirst := p
   else
   begin
      x := fFirst;
      while x^.next <> nil do
         x := x^.next;
      x^.next := p;
   end;
   
   inc(fCount);
end;

procedure TGList.Remove(const Value: TValue);
var p,po: PElement;
begin
   p := fFirst;
   po := nil;
   
   if p = nil then
      exit;
   
   while p <> nil do
   begin
      if p^.value = value then
      begin
         if po = nil then
            fFirst := p^.next
         else
            po^.next := p^.next;
         
         FreeMem(p);
         dec(fCount);
         exit;
      end;
      po := p;
      p := p^.next;
   end;
end;

procedure TGList.Delete(const index: longint);
var p,po: PElement;
    i: longint;
begin
   p := fFirst;
   po := nil;
   
   i := 0;
   
   if p = nil then
      exit;
   
   while p <> nil do
   begin
      if i = index then
      begin
         if po = nil then
            fFirst := p^.next
         else
            po^.next := p^.next;
         
         FreeMem(p);
         dec(fCount);
         exit;
      end;
      inc(i);
      po := p;
      p := p^.next;
   end;
end;

constructor TGList.Create(NullValue: TValue);
begin
   inherited Create;
   fFirst := nil;
   fCount := 0;
   fNull := NullValue;
end;

destructor TGList.Destroy;
var p,pn: PElement;
begin
   p := fFirst;
   while p <> nil do
   begin
      pn := p^.next;
      
      freemem(p);
      
      p := pn;
   end;
   inherited Destroy;
end;

end.

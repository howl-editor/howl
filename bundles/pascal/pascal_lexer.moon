-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.aux.lpeg_lexer ->
  c = capture

  id = (alpha + '_')^1 * (alpha + digit + P'_')^0
  ws = c 'whitespace', blank^0

  identifier = c 'identifier', id

  pascal_word = (words) ->
    new_words = for w in *words
      sequence [P(c\upper!) + c\lower! for c in w\gmatch '.']

    word new_words

  keyword = c 'keyword', -B'&' * pascal_word {
    'absolute', 'abstract', 'alias', 'and', 'array', 'asm', 'assembler', 'as',
    'begin', 'bitpacked', 'break', 'case', 'cdecl', 'class', 'constructor',
    'const', 'continue', 'cppdecl', 'cvar', 'default', 'deprecated', 'destructor',
    'dispinterface', 'div', 'downto', 'do', 'dynamic', 'else', 'end', 'enumerator',
    'except', 'experimental', 'exports', 'export', 'external', 'far16', 'far',
    'file', 'finalization', 'finally', 'forward', 'for', 'function', 'generic',
    'goto', 'helper', 'if', 'implementation', 'implements', 'index', 'inherited',
    'initialization', 'inline', 'interface', 'interrupt', 'in', 'iochecks', 'is',
    'label', 'library', 'local', 'message', 'mod', 'name', 'near',
    'nodefault', 'noreturn', 'nostackframe', 'not', 'object', 'of', 'oldfpccall',
    'on', 'operator', 'or', 'otherwise', 'out', 'overload', 'override', 'packed',
    'pascal', 'platform', 'private', 'procedure', 'program', 'property',
    'protected', 'public', 'published', 'raise', 'read', 'record', 'register',
    'reintroduce', 'repeat', 'resourcestring', 'safecall',
    'saveregisters', 'self', 'set', 'shl', 'shr', 'softfloat', 'specialize',
    'static', 'stdcall', 'stored', 'strict', 'then', 'threadvar', 'to',
    'try', 'type', 'unaligned', 'unimplemented', 'unit', 'until', 'uses',
    'varargs', 'var', 'virtual', 'while', 'with', 'xor'
  }

  special = c 'special', -B'&' * pascal_word { 'true', 'false', 'nil', 'result' }

  functions = c 'function', -B(S'&.') * pascal_word {
    'AbstractError', 'AcquireExceptionObject', 'AddExitProc', 'Addr', 'Align',
    'AllocMem', 'AnsiToUtf8', 'Append', 'ArrayStringToPPchar', 'Assert',
    'Assigned', 'Assign', 'BEtoN', 'BasicEventCreate', 'BeginThread', 'BlockRead',
    'BlockWrite', 'Break', 'BsfByte', 'BsfDWord', 'BsfQWord', 'BsfWord', 'BsrByte',
    'BsrDWord', 'BsrQWord', 'BsrWord', 'CaptureBacktrace', 'CloseThread', 'Close',
    'CompareByte', 'CompareChar0', 'CompareChar', 'CompareDWord', 'CompareWord',
    'Concat', 'Continue', 'CopyArray', 'Copy', 'Cseg', 'Dec',
    'DefaultAnsi2UnicodeMove', 'DefaultAnsi2WideMove', 'DefaultUnicode2AnsiMove',
    'Default', 'Delete', 'Dispose', 'DoneCriticalsection', 'DoneThread', 'Dseg',
    'DumpExceptionBackTrace', 'Dump_Stack', 'DynArrayBounds', 'DynArrayClear',
    'DynArrayDim', 'DynArrayIndex', 'DynArraySetLength', 'DynArraySize', 'EOF',
    'EOLn', 'EmptyMethod', 'EndThread', 'EnterCriticalsection',
    'EnumResourceLanguages', 'EnumResourceNames', 'EnumResourceTypes', 'Erase',
    'Error', 'Exclude', 'Exit', 'FMADouble', 'FMAExtended', 'FMASingle',
    'FPower10', 'Fail', 'FilePos', 'FileSize', 'FillByte', 'FillChar', 'FillDWord',
    'FillQWord', 'FillWord', 'FinalizeArray', 'Finalize', 'FindResourceEx',
    'FindResource', 'FlushThread', 'Flush', 'FreeMem', 'FreeResource',
    'Freememory', 'Freemem', 'GetCPUCount', 'GetCurrentThreadId',
    'GetFPCHeapStatus', 'GetHeapStatus', 'GetMemory', 'GetMemoryManager', 'GetMem',
    'GetProcessID', 'GetResourceManager', 'GetTextCodePage', 'GetThreadID',
    'GetThreadManager', 'GetUnicodeStringManager', 'GetVariantManager',
    'GetWideStringManager', 'Get_pc_addr', 'HINSTANCE', 'High', 'IOResult',
    'Include', 'Inc', 'IndexByte', 'IndexChar0', 'IndexChar', 'IndexDWord',
    'IndexQWord', 'Indexword', 'InitCriticalSection', 'InitThreadVars',
    'InitThread', 'InitializeArray', 'Initialize', 'Insert',
    'InterLockedDecrement', 'InterLockedExchangeAdd', 'InterLockedExchange',
    'InterLockedIncrement', 'InterlockedCompareExchange', 'IsDynArrayRectangular',
    'IsMemoryManagerSet', 'Is_IntResource', 'KillThread', 'LEtoN',
    'LeaveCriticalsection', 'Length', 'LoadResource', 'LockResource', 'Low',
    'MakeLangID', 'MemSize', 'MoveChar0', 'Move', 'New', 'NtoBE', 'NtoLE', 'Null',
    'OctStr', 'Ofs', 'Ord', 'Pack', 'ParamStr', 'Paramcount', 'PopCnt', 'Pos',
    'Power', 'Pred', 'RTLEventCreate', 'RTLeventResetEvent', 'RTLeventSetEvent',
    'RTLeventWaitFor', 'RTLeventdestroy', 'RaiseList', 'Randomize', 'Random',
    'ReAllocMemory', 'ReAllocMem', 'ReadBarrier', 'ReadDependencyBarrier',
    'ReadLn', 'ReadStr', 'ReadWriteBarrier', 'Read', 'Real2Double',
    'ReleaseExceptionObject', 'Rename', 'Reset', 'ResumeThread', 'Rewrite',
    'RolByte', 'RolDWord', 'RolQWord', 'RolWord', 'RorByte', 'RorDWord',
    'RorQWord', 'RorWord', 'RunError', 'SarInt64', 'SarLongint', 'SarShortint',
    'SarSmallint', 'SeekEOF', 'SeekEOLn', 'Seek', 'Seg', 'SemaphoreDestroy',
    'SemaphoreInit', 'SemaphorePost', 'SemaphoreWait', 'SetCodePage', 'SetLength',
    'SetMemoryManager', 'SetMultiByteConversionCodePage',
    'SetMultiByteFileSystemCodePage', 'SetMultiByteRTLFileSystemCodePage',
    'SetResourceManager', 'SetString', 'SetTextBuf', 'SetTextCodePage',
    'SetTextLineEnding', 'SetThreadManager', 'SetUnicodeStringManager',
    'SetVariantManager', 'SetWideStringManager', 'Setjmp', 'ShortCompareText',
    'SizeOf', 'SizeofResource', 'Slice', 'Space', 'Sptr', 'Sseg', 'StackTop',
    'StringCodePage', 'StringElementSize', 'StringOfChar', 'StringRefCount',
    'StringToPPChar', 'StringToUnicodeChar', 'StringToWideChar', 'Str', 'Succ',
    'SuspendThread', 'SwapEndian', 'Swap', 'SysAllocMem', 'SysAssert',
    'SysBackTraceStr', 'SysFlushStdIO', 'SysFreememSize', 'SysFreemem',
    'SysGetFPCHeapStatus', 'SysGetHeapStatus', 'SysGetmem', 'SysInitExceptions',
    'SysInitFPU', 'SysInitStdIO', 'SysMemSize', 'SysReAllocMem', 'SysResetFPU',
    'SysSetCtrlBreakHandler', 'SysTryResizeMem', 'ThreadGetPriority',
    'ThreadSetPriority', 'ThreadSwitch', 'ToSingleByteFileSystemEncodedFileName',
    'Truncate', 'TryEnterCriticalsection', 'TypeInfo', 'TypeOf',
    'UCS4StringToUnicodeString', 'UCS4StringToWideString', 'UTF8Decode',
    'UTF8Encode', 'UnPack', 'Unassigned', 'UnicodeCharLenToStrVar',
    'UnicodeCharLenToString', 'UnicodeCharToStrVar', 'UnicodeCharToString',
    'UnicodeStringToUCS4String', 'UnicodeToUtf8', 'UniqueString', 'UnlockResource',
    'Utf8CodePointLen', 'Utf8ToAnsi', 'Utf8ToUnicode', 'Val', 'VarArrayGet',
    'VarArrayPut', 'VarArrayRedim', 'VarCast', 'WaitForThreadTerminate',
    'WideCharLenToStrVar', 'WideCharLenToString', 'WideCharToStrVar',
    'WideCharToString', 'WideStringToUCS4String', 'WriteBarrier', 'WriteLn',
    'WriteStr', 'Write', 'abs', 'add', 'arctan', 'assign', 'basiceventResetEvent',
    'basiceventSetEvent', 'basiceventWaitFor', 'basiceventdestroy', 'binStr',
    'chdir', 'chr', 'cos', 'divide', 'equal', 'exp', 'float_raise', 'fpc_SarInt64',
    'frac', 'get_caller_addr', 'get_caller_frame', 'get_caller_stackinfo',
    'get_cmdline', 'get_frame', 'getdir', 'greaterthanorequal', 'greaterthan',
    'halt', 'hexStr', 'hi', 'intdivide', 'int', 'leftshift', 'lessthanorequal',
    'lessthan', 'ln', 'logicaland', 'logicalnot', 'logicalor', 'logicalxor',
    'longjmp', 'lowerCase', 'lo', 'mkdir', 'modulus', 'multiply', 'negative',
    'odd', 'pi', 'power', 'prefetch', 'ptr', 'rightshift', 'rmdir', 'round', 'sin',
    'sqrt', 'sqr', 'strlen', 'strpas', 'subtract', 'trunc', 'upCase',
    'dispose', 'exit', 'new'
  }

  builtin_types = -B'&' * pascal_word {
    'AnsiChar', 'AnsiString', 'Boolean', 'ByteBool', 'Byte', 'Cardinal', 'Char',
    'Comp', 'Currency', 'Double', 'Extended', 'Int64', 'Integer', 'LongBool',
    'Longint', 'Longword', 'QWord', 'RawByteString', 'Real', 'ShortString',
    'Shortint', 'Single', 'SmallInt', 'String', 'UCS2Char', 'UCS4Char',
    'UTF8String', 'UniCodeChar', 'UnicodeString', 'WideChar', 'WideString',
    'WordBool', 'Word'
  }

  type_name = S'TPI' * upper * id^-1

  types = c 'type', builtin_types + type_name

  generic = sequence {
    c 'operator', '<'
    ((V'all' + P 1) - S'<>;')^0
    c 'operator', '>'
    ws
  }

  -- Eat up var defs to avoid the type portion being matches as a type def.
  var_def = sequence {
    c 'operator', P':'
    ws
    types
  }

  type_def = any {
    sequence {
      c 'type_def', type_name
      ws
      generic^-1
      c 'operator', '='
    }

    sequence {
      c 'type_def', id
      ws
      generic^-1
      c 'operator', '='
      ws
      c 'keyword', pascal_word {
        'packed', 'set', 'record', 'class', 'file', 'object', 'interface'
      }
    }
  }

  fdecl = sequence {
    c 'keyword', pascal_word { 'procedure', 'function', 'constructor', 'destructor' }
    ws
    c 'fdecl', (id + '.')^1
  }

  comment_span = (start_pat, end_pat) ->
    start_pat * ((V'comment' + P 1) - end_pat)^0 * end_pat

  comment = c 'comment', P {
    'comment'

    comment: any {
      comment_span P'{', '}'
      comment_span P'/*', '*/'
      comment_span P'(*', '*)'
      comment_span P'//', B(eol)
    }
  }

  unsigned = any {
    digit^1
    P'$' * xdigit^1
    P'&' * R'07'^1
    P'%' * S'01'^1
  }

  number = c 'number', any {
    float
    unsigned
  }

  string = c 'string', any {
    span "'", "'"
    P'#' * unsigned
  }

  operator = c 'operator', S'+-*/=&<>[].,():;^@'

  P {
    'all'

    all: any {
      comment
      string
      number
      var_def
      operator
      type_def
      fdecl
      keyword
      special
      functions
      types
      identifier
    }
  }

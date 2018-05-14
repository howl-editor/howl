/*
** Syntax examples taken mostly from http://en.wikipedia.org/wiki/C_syntax
** My library.
** Copyright (C) year foo.
*/

// c++ / C99 style comment
STILL_COMMENT(1)//should be comment
just_comment++;//should be comment
STILL_COMMENT(TRUE)/*should be comment*/
just_comment++;/*should be comment*/

#include <stdio.h>
#include<string.h>
#include "lua.h"

#define my_define
#if SOMECOND
#include "other.h"
#endif

#define GDK_MOD1_MASK 1 << 3
#define GDK_LOCK_MASK 1 << 1

typedef unsigned char byte;

/* number representations */

// valid integer literals
int[] i_a = { 0, 123, 0xbeef, 0xDEAD, 0234};
// below are example of invalid numbers
int[] i_ill = { 039, 0xFG };

float f_a = { 1.34, 1.23E2, 3.14e-2, 0xfep2, 0XAP-3 };
// below are example of invalid floats
float f_ill = { 0xfgp2, 0XAe-3 };

const char *p = "my_string";
char[] c_a = { 'c', '\'', '\324', '\xef', '\"', '\n', '\\' };
int array[100];

printf(__FILE__ ": %d: Hello "
           "world\n", __LINE__);

struct Fancy {
    int   x;
    float y;
    char  *z;
} tee;

union u
{
    int   x;
    float y;
    char  *z;
} n;

struct s *ptr_to_tee = &tee;

struct f
{
    unsigned int  flag : 1;  /* a bit flag: can either be on (1) or off (0) */
    signed int    num  : 4;  /* a signed 4-bit field; range -7...7 or -8...7 */
    signed int         : 3;  /* 3 bits of padding to round out to 8 bits */
} g;

for (int i=0; i< limit; i++){
  printf("%d\n", i);
}

long abc = 'abcd';

int printf (const char*, ...) {
}

void struct_use(struct Foo *apa) {
}

LJLIB_ASM(rawget)		LJLIB_REC(.)
{
  lj_lib_checktab(L, 1);
  lj_lib_checkany(L, 2);
  return FFH_UNREACHABLE;
}

/* index, on Lua stack, for substitution value cache */
#define subscache(cs)	((cs)->ptop + 1)

typedef enum Opcode {
  IAny, IChar, ISet, ISpan,
} Opcode;

static void printcapkind (int kind) {
  const char *const modes[] = {
    "close", "position", "constant", "backref",
    "argument", "simple", "table", "function",
    "query", "string", "substitution", "fold",
    "runtime", "group"};
  printf("%s", modes[kind]);
}

class A : B {}

// C++ template specializations!
class Z<A,B> : B {}
struct Abc<1, 2>  {};
class [[a,b,c]] X::Y::Z {};
class X::Y::Z<A, B> virtual final : B {};
class [[a,b,c]] [[def]] X::Y::Z virtual : B {};
class [[a,b,c]] [[def]] X::Y::Z final : B {};
class X
{};
struct X<A, B> y;

int a = 1, 2 == 2 ? 1 : 0;

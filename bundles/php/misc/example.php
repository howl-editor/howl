<?php

// A whole slew of PHP syntax, mostly taken from the language
// reference at php.net

// comments
$break = true;
/* This is a multi line comment
   yet another line of comment */
$break = true;
# This is a one-line shell-style comment
$break = true;

// strings
echo 'You can also have embedded newlines in
strings this way as it is
okay to do';
dq = "hello!";
$escaped_sq = 'don\'t end';
$escaped_dq = "do \"not\" end";

// string interpolation : simple
$juice = "apple";
echo "He drank some $juice juice.".PHP_EOL;
echo "He drank some $juices[1] juice.".PHP_EOL;
echo "He drank some $juices[koolaid1] juice.".PHP_EOL;
echo "$people->john then said hello to $people->jane.".PHP_EOL;

// string interpolation : complex
echo "This ends up being a { $simple_interpolation}";
echo "This ends up being an {} empty hash";
echo "Simple complex: {$object}";
echo "Array: {$object[1]}";
echo "This works: {$arr['key']}";
echo "And with same delimiter: {$arr["key"]}";
echo "This works too: {$obj->values[3]->name}";
echo "This is the value of the var named by the return value of \$object->getName(): {${$object->getName()}}";

// heredocs
$str = <<<EOD
Example of string
spanning multiple lines
using heredoc syntax.
EOD;

$str = <<<EOD
Delimiter must be
  EOD;
on the first column
EOD;

// heredoc with double quotes
echo <<<"FOOBAR"
Hello World!
FOOBAR;

// heredocs with interpolations
echo <<<EOT
My name is "$name". I am printing some $foo->foo.
Now, I am printing some {$foo->bar[1]}.
This should print a capital 'A': \x41
EOT;

// nowdoc
echo <<<'EOT'
My name is "$name". I am printing some $foo->foo.
Now, I am printing some {$foo->bar[1]}.
This should not print a capital 'A': \x41
EOT;

// integers
$a = 1234; // decimal number
$a = -123; // a negative number
$a = 0123; // octal number (equivalent to 83 decimal)
$a = 0x1A; // hexadecimal number (equivalent to 26 decimal)
$a = 0b11111111; // binary number (equivalent to 255 decimal)

// floats
$a = 1.234;
$b = 1.2e3;
$c = 7E-10;
$c = 7E+10;

// arrays
$array = array(1, 2);
$array = [
    "foo" => "bar",
    'bar' => "foo",
    3 => 4
];
$array = array("foo", "bar", "hello", "world");

// vars

$var_dk = 0;
$_var_dk = 0;
$bar = &$foo;
define("FOO", "something");
echo(FOO) // constant

// classes and functions
class ExampleClass extends BaseClass {

  public function highlightMe()
  {
    $response = $this->call('GET', '/');

    $this->assertEquals(200, $response->getStatusCode());
  }

}

// misc stuff
$spec = null || NULL || true || TRUE || false || FALSE;
$bvar = (bool) $followRedirect;

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

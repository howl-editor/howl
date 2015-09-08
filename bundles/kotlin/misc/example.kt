package hello

// Comment
/* And another comment */

data class X(val a: Int, var b: Any)

private public fun main(args: Array<String>) {
    var name = "World"
    println("Hello, ${name+"!"}")
    var string = """
    I
    am
    multiple
    lines
    long
    $[] Not colored
    $a Colored
    """
    println(string)

    val x = X(1, 2)
    when (x) {
        is X -> println(x)
        else -> println('?')
    }
}

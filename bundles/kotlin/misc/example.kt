package hello

// Comment
/* And another comment */

data class X(val a: Int, var b: Any)

abstract class Y constructor(name: String) {
    protected var name: String = name
    init { println("Starting up Y...") }
    open fun f(): String { return name }
    abstract fun g()
}

class Z constructor(value: String) : Y(value) {
    constructor(): this("Bob") {}
    constructor(value: Int): this(value.toString()) {}
    final override fun f(): String { return name }
    override fun g() {}
}

public fun main(args: Array<String>) {
    var name = "World"
    println("Hello, ${name+"!"}")
    var string = """
    I
    am
    multiple
    lines
    long
    $[] Not colored
    $name Colored
    """
    println(string)

    val x = X(1, 2)
    when (x) {
        is X -> println(x)
        else -> println('?')
    }

    var z = Z()
    if (z is Z) { println(z as Z) }
    else if (z !is Z) { println("???") }

    assert(true); assert(!false)
}

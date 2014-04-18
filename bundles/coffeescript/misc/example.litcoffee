An excerpt from [https://raw.github.com/jashkenas/coffee-script/master/src/scope.litcoffee]:

The **Scope** class regulates lexical scoping within CoffeeScript. As you
generate code, you create a tree of scopes in the same shape as the nested
function bodies. Each scope knows about the variables declared within it,
and has a reference to its parent enclosing scope. In this way, we know which
variables are new and need to be declared with `var`, and which are shared
with external scopes.

Import the helpers we plan to use.

    {extend, last} = require './helpers'

    exports.Scope = class Scope

The `root` is the top-level **Scope** object for a given file.

      @root: null

Initialize a scope with its parent, for lookups up the chain,
as well as a reference to the **Block** node it belongs to, which is
where it should declare its variables, and a reference to the function that
it belongs to.

      constructor: (@parent, @expressions, @method) ->
        @variables = [{name: 'arguments', type: 'arguments'}]
        @positions = {}
        Scope.root = this unless @parent

Adds a new variable or overrides an existing one.

      add: (name, type, immediate) ->
        return @parent.add name, type, immediate if @shared and not immediate
        if Object::hasOwnProperty.call @positions, name
          @variables[@positions[name]].type = type
        else
          @positions[name] = @variables.push({name, type}) - 1

When `super` is called, we need to find the name of the current method we're
in, so that we know how to invoke the same method of the parent class. This
can get complicated if super is being called from an inner function.
`namedMethod` will walk up the scope tree until it either finds the first
function object that has a name filled in, or bottoms out.

      namedMethod: ->
        return @method if @method?.name or !@parent
        @parent.namedMethod()

Look up a variable name in lexical scope, and declare it if it does not
already exist.

      find: (name) ->
        return yes if @check name
        @add name, 'var'
        no

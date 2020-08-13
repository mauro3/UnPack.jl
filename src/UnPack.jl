module UnPack

export @unpack, @pack!

###########################
# Packing and unpacking @unpack, @pack!
##########################
# Below code slightly adapted from Simon Danisch's GLVisualize via PR
# https://github.com/mauro3/Parameters.jl/pull/13
#
# Note, this used to be part of the package Parameters.jl

"""
This function is invoked to unpack one field/entry of some DataType
`dt` and has signature:

`unpack(dt::Any, ::Val{sym}) -> value of sym`

The `sym` is the symbol of the assigned variable.

Three definitions are included in the package to unpack a composite type
or a dictionary with Symbol or string keys:
```
@inline unpack(x, ::Val{f}) where {f} = getproperty(x, f)
@inline unpack(x::AbstractDict{Symbol}, ::Val{k}) where {k} = x[k]
@inline unpack(x::AbstractDict{S}, ::Val{k}) where {S<:AbstractString,k} = x[string(k)]
```

More methods can be added to allow for specialized unpacking of other datatypes.

See also `pack!`.
"""
function unpack end
@inline unpack(x, ::Val{f}) where {f} = getproperty(x, f)
@inline unpack(x::AbstractDict{Symbol}, ::Val{k}) where {k} = x[k]
@inline unpack(x::AbstractDict{<:AbstractString}, ::Val{k}) where {k} = x[string(k)]

"""
This function is invoked to pack one entity into some DataType and has
signature:

`pack!(dt::Any, ::Val{property}, value) -> value`

Two definitions are included in the package to pack into a composite
type or into a dictionary with Symbol or string keys:

```
@inline pack!(x, ::Val{f}, val) where {f} = setproperty!(x, f, val)
@inline pack!(x::AbstractDict{Symbol}, ::Val{k}, val) where {k} = x[k]=val
@inline pack!(x::AbstractDict{S}, ::Val{k}, val) where {S<:AbstractString,k} = x[string(k)]=val
```

More methods can be added to allow for specialized packing of other
datatypes.

See also `unpack`.

To "pack" immutable datatypes, see the package Setfield.jl
"""
function pack! end
@inline pack!(x, ::Val{f}, val) where {f} = setproperty!(x, f, val)
@inline pack!(x::AbstractDict{Symbol}, ::Val{k}, val) where {k} = x[k]=val
@inline pack!(x::AbstractDict{<:AbstractString}, ::Val{k}, val) where {k} = x[string(k)]=val

"""
```julia_skip
@unpack a, b, c, ... = dict_or_typeinstance
```
Unpack fields/properties/keys from a composite type, a `Dict{Symbol}`, a `Dict{String}`,
or a module into variables.

Example with dict:
```julia
d = Dict{Symbol,Any}(:a=>5.0,:b=>2,:c=>"Hi!")
@unpack a, c = d
a == 5.0 #true
c == "Hi!" #true
```

Example with type:
```julia
struct A; a; b; c; end
d = A(4,7.0,"Hi")
@unpack a, c = d
a == 4 #true
c == "Hi" #true
```

Note that its functionality can be extended by adding methods to the
`UnPack.unpack` function.
"""
macro unpack(args)
    args.head!=:(=) && error("Expression needs to be of form `a, b = c`")
    items, suitecase = args.args
    items = isa(items, Symbol) ? [items] : items.args
    suitecase_instance = gensym()
    kd = [:( $key = $UnPack.unpack($suitecase_instance, Val{$(Expr(:quote, key))}()) ) for key in items]
    kdblock = Expr(:block, kd...)
    expr = quote
        local $suitecase_instance = $suitecase # handles if suitecase is not a variable but an expression
        $kdblock
        $suitecase_instance # return RHS of `=` as standard in Julia
    end
    esc(expr)
end


"""
```julia_skip
@pack! dict_or_typeinstance = a, b, c, ...
```
Pack variables into a mutable composite type, a `Dict{Symbol}`, or a `Dict{String}`.

Example with dict:
```julia
a = 5.0
c = "Hi!"
d = Dict{Symbol,Any}()
@pack! d = a, c
d # Dict{Symbol,Any}(:a=>5.0,:c=>"Hi!")
```

Example with type:
```julia
a = 99
c = "HaHa"
mutable struct A; a; b; c; end
d = A(4,7.0,"Hi")
@pack! d = a, c
d.a == 99 #true
d.c == "HaHa" #true
```

Note that its functionality can be extended by adding methods to the
`UnPack.pack!` function.

To "pack" immutables use the package Setfield.jl.
"""
macro pack!(args)
    esc(_pack_bang(args))
end

function _pack_bang(args)
    args.head!=:(=) && error("Expression needs to be in the form of an assignment.")
    suitecase, items = args.args
    items = isa(items, Symbol) ? [items] : items.args
    suitecase_instance = gensym()
    kd = [:( $UnPack.pack!($suitecase_instance, Val{$(Expr(:quote, key))}(), $key) ) for key in items]
    kdblock = Expr(:block, kd...)
    return quote
        local $suitecase_instance = $suitecase # handles if suitecase is not a variable but an expression
        $kdblock
        ($(items...),)
    end
end

end # module

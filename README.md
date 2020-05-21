# UnPack

[![Build Status](https://travis-ci.com/mauro3/UnPack.jl.svg?branch=master)](https://travis-ci.com/mauro3/UnPack.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/mauro3/UnPack.jl?svg=true)](https://ci.appveyor.com/project/mauro3/UnPack-jl)
[![Codecov](https://codecov.io/gh/mauro3/UnPack.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/mauro3/UnPack.jl)
[![Build Status](https://api.cirrus-ci.com/github/mauro3/UnPack.jl.svg)](https://cirrus-ci.com/github/mauro3/UnPack.jl)


It is often convenient to unpack some or all of the fields of a type,
and pack, in the case of mutable datatypes (for immutables use
[Setfield.jl](https://github.com/jw3126/Setfield.jl)). This is often
the case when a struct is passed into a function.

The [`@unpack`](@ref) and [`@pack!`](@ref) macros work to unpack
types, modules, and dictionaries (and can be customized for other
types too, see next section).

```julia
using UnPack

mutable struct Para
    a::Float64
    b::Int
end

function f!(var, pa::Para)
    @unpack a, b = pa # equivalent to: a,b = pa.a,pa.b
    out = var + a + b
    b = 77
    @pack! pa = b # equivalent to: pa.b = b
    return out, pa
end

out, pa = f!(7, Para(1,2)) # -> 10.0, Para(1.0, 77)
```

Example with a dictionary:

```julia
d = Dict{Symbol,Any}(:a=>5.0, :b=>2, :c=>"Hi!")
@unpack a, c = d
a == 5.0 #true
c == "Hi!" #true

d = Dict{String,Any}()
@pack! d = a, c
d # -> Dict{String,Any}("a"=>5.0,"c"=>"Hi!")
```

## Customization of `@unpack` and `@pack!`

What happens during the (un-)packing of a particular datatype is
determined by the functions `UnPack.unpack` and `UnPack.pack!`.

The `UnPack.unpack` function is invoked to unpack one entity of some
`DataType` and has signature:

```julia
unpack(dt::Any, ::Val{property}) -> value of property
```

Note that `unpack` (and `pack!`) works with `Base.getproperty`.  By
default this means that all the fields of a type are unpacked but if
`getproperty` is overloaded, then it will unpack accordingly.

Three method definitions are included in the package to unpack a
composite type/module/NamedTuple, or a dictionary with Symbol or
string keys:

```julia
@inline unpack{f}(x, ::Val{f}) = getproperty(x, f)
@inline unpack{k}(x::Associative{Symbol}, ::Val{k}) = x[k]
@inline unpack{S<:AbstractString,k}(x::Associative{S}, ::Val{k}) = x[string(k)]
```

The `UnPack.pack!` function is invoked to pack one entity into some
`DataType` and has signature:

```julia
pack!(dt::Any, ::Val{field}, value) -> value
```

Three definitions are included in the package to pack into a mutable composite
type or into a dictionary with Symbol or string keys:

```julia
@inline pack!{f}(x, ::Val{f}, val) = setproperty!(x, f, val)
@inline pack!{k}(x::Associative{Symbol}, ::Val{k}, val) = x[k]=val
@inline pack!{S<:AbstractString,k}(x::Associative{S}, ::Val{k}, val) = x[string(k)]=val
```

More methods can be added to `unpack` and `pack!` to allow for
specialized unpacking/packing of datatypes. Here is a MWE of customizing 
`unpack`, so that it multiplies the values by 2:

```julia
using UnPack
struct Foo
    a
    b
end
p = Foo(1, 2)
@unpack a, b = p
a, b # gives (1, 2)

# Now we specialize unpack for our custom type, `Foo`
@inline UnPack.unpack(x::Foo, ::Val{f}) where {f} = 2 * getproperty(x, f)
@unpack a, b = p
a, b # now gives (2, 4)
```

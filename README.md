# UnPack

[![Build Status](https://github.com/mauro3/UnPack.jl/workflows/CI/badge.svg)](https://github.com/mauro3/UnPack.jl/actions)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/mauro3/UnPack.jl?svg=true)](https://ci.appveyor.com/project/mauro3/UnPack-jl)
[![Coverage](https://codecov.io/gh/mauro3/UnPack.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/mauro3/UnPack.jl)
[![pkgeval](https://juliahub.com/docs/UnPack/pkgeval.svg)](https://juliahub.com/ui/Packages/UnPack/zm2TF)

[![deps](https://juliahub.com/docs/UnPack/deps.svg)](https://juliahub.com/ui/Packages/UnPack/zm2TF?t=2)
[![version](https://juliahub.com/docs/UnPack/version.svg)](https://juliahub.com/ui/Packages/UnPack/zm2TF)

It is often convenient to unpack some or all of the fields of a type,
and pack, in the case of mutable datatypes (for immutables use
[Setfield.jl](https://github.com/jw3126/Setfield.jl)). This is often
the case when a struct is passed into a function.

The `@unpack` and `@pack!` macros work to unpack
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

Using `=>` allows unpacking to local variables that are different from a key:
```julia
struct MyContainer{T}
    a::T
    b::T
end

function Base.:(==)(x::MyContainer, y::MyContainer)
    @unpack a, b = x
    @unpack a => ay, b => by = y
    a == ay && b ≈ by
end
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
@inline unpack(x, ::Val{f}) where {f} = getproperty(x, f)
@inline unpack(x::AbstractDict{Symbol}, ::Val{k}) where {k} = x[k]
@inline unpack(x::AbstractDict{<:AbstractString}, ::Val{k}) where {k} = x[string(k)]
```

The `UnPack.pack!` function is invoked to pack one entity into some
`DataType` and has signature:

```julia
pack!(dt::Any, ::Val{field}, value) -> value
```

Three definitions are included in the package to pack into a mutable composite
type or into a dictionary with Symbol or string keys:

```julia
@inline pack!(x, ::Val{f}, val) where {f} = setproperty!(x, f, val)
@inline pack!(x::AbstractDict{Symbol}, ::Val{k}, val) where {k} = x[k]=val
@inline pack!(x::AbstractDict{<:AbstractString}, ::Val{k}, val) where {k} = x[string(k)]=val
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

# Related

- Julia issue on unpacking of function arguments
  https://github.com/JuliaLang/julia/issues/28579
- setting immutables https://github.com/jw3126/Setfield.jl

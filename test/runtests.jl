
using UnPack
using Test

@testset "Dict and NamedTuple" begin
    ###########################
    # Packing and unpacking @unpack, @pack!
    ##########################

    @testset "dict with symbols" begin
        d = Dict{Symbol,Any}(:a=>5.0,:b=>2,:c=>"Hi!")
        @unpack a, c = d
        @test a == 5.0 #true
        @test c == "Hi!" #true
    end

    @testset "dict with strings" begin
        d = Dict("a"=>5.0,"b"=>2,"c"=>"Hi!")
        @unpack a, c = d
        @test a == 5.0 #true
        @test c == "Hi!" #true
    end

    @testset "named tuple" begin
        @eval d = (a=5.0, b=2, c="Hi!")
        @unpack a, c = d
        @test a == 5.0 #true
        @test c == "Hi!" #true
    end

    @testset "named tuple, renaming"  begin
        d = (a = 1, b = 2)
        @unpack a => c, b = d
        @test c == 1
        @test b == 2
        @test !@isdefined a
    end

    @testset "invalid patterns" begin
        @test_throws ErrorException macroexpand(Main, :(@unpack a))
        @test_throws ErrorException macroexpand(Main, :(@unpack "a fish" = 1))
        @test_throws ErrorException macroexpand(Main, :(@unpack a => "a fish" = 1))
        @test_throws ErrorException macroexpand(Main, :(@unpack 1 => b = 1))
    end
end

# having struct-defs inside a testset seems to be problematic in some julia version
mutable struct PropertyExample
    a
    last_set_property
end
@testset "getproperty" begin
    Base.getproperty(::PropertyExample, name::Symbol) = String(name)
    Base.setproperty!(d::PropertyExample, name::Symbol, value) =
        setfield!(d, :last_set_property, (name, value))
    Base.propertynames(::PropertyExample) = (:A, :B, :C)

    let d = PropertyExample(:should_be_ignored, nothing)
        @unpack a, b = d
        @test a == "a"
        @test b == "b"

        a = "a value"
        @pack! d = a
        @test getfield(d, :last_set_property) == (:a, "a value")
    end

    # TODO add test with non String string
end

mutable struct A; a; b; c; end
@testset "type" begin
    # Example with type:

    d = A(4,7.0,"Hi!")
    @unpack a, c = d
    @test a == 4 #true
    @test c == "Hi!" #true
end

@testset "Packing" begin
    # Example with dict:
    a = 5.0
    c = "Hi!"
    d = Dict{Symbol,Any}()
    @pack! d = a, c
    @test d==Dict{Symbol,Any}(:a=>5.0,:c=>"Hi!")

    d = Dict{String,Any}()
    @pack! d = a, c
    @test d==Dict{String,Any}("a"=>5.0,"c"=>"Hi!")


    # Example with type:
    a = 99
    c = "HaHa"
    d = A(4,7.0,"Hi")
    @pack! d = a, c
    @test d.a == 99
    @test d.c == "HaHa"
end

mutable struct UP1
    aUP1
    bUP1
end
struct UP2
    aUP2
    bUP2
end

@testset "old tests" begin
    uu = UP1(1,2)
    @test_throws ErrorException @unpack cUP1 = uu
    @test_throws ErrorException @unpack aUP1, cUP1 = uu

    aUP1, bUP1 = 0, 0
    @unpack aUP1 = uu
    @test aUP1==1
    @test bUP1==0
    aUP1, bUP1 = 0, 0
    @unpack aUP1, bUP1 = uu
    @test aUP1==1
    @test bUP1==2


    vv = uu
    aUP1 = 99
    @pack! uu = aUP1
    @test uu==vv
    @test uu.aUP1==99

    uu = UP2(1,2)
    @test_throws ErrorException @unpack cUP2 = uu
    @test_throws ErrorException @unpack aUP2, cUP2 = uu

    aUP1 = 99
    @test_throws ErrorException @pack! uu = aUP1
end


struct UP3
    a::Float64
    b::Int
end

@testset "inference" begin
    function f(u::UP3)
        @unpack a,b = u
        a,b
    end
    @inferred f(UP3(1,2))
end

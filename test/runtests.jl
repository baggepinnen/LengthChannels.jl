using LengthChannels
using Test

@testset "LengthChannels.jl" begin
    l,b = 10, 4

    @testset "Typed Constructors" begin
        @info "Testing Typed Constructors"

        lc = LengthChannel{Int}(l, b) do ch
            for i = 1:100
                put!(ch, i)
            end
        end

        @test eltype(lc) <: Int

        @test length(lc) == l
        cc = collect(lc)
        @test length(cc) == l
        @test cc == 1:l
        @test isopen(lc)


        lc = LengthChannel{Int}(l, b, spawn=true) do ch
            for i = 1:100
                put!(ch, i)
            end
        end

        @test length(lc) == l
        cc = collect(lc)
        @test length(cc) == l
        @test cc == 1:l
        @test isopen(lc)

    end


    @testset "Untyped constructors" begin
        @info "Testing Untyped constructors"

        lc = LengthChannel(l, b) do ch
            for i = 1:100
                put!(ch, i)
            end
        end

        @test eltype(lc) == Any
        @test length(lc) == l
        cc = collect(lc)
        @test length(cc) == l
        @test cc == 1:l
        @test isopen(lc)


        lc = LengthChannel(l, b)
        @test length(lc) == l
        put!(lc, 1)
        @test length(lc) == l

        @test take!(lc) == 1

        @test !isready(lc)

    end


    @testset "Autoclose" begin
        @info "Testing Autoclose"

        lc = LengthChannel{Int}(l, b, autoclose=true) do ch
            for i = 1:100
                put!(ch, i)
            end
        end

        @test eltype(lc) <: Int

        @test length(lc) == l
        cc = collect(lc)
        @test length(cc) == l
        @test cc == 1:l
        @test !isopen(lc)


        lc = LengthChannel{Int}(l, b, autoclose=true, spawn=true) do ch
            for i = 1:100
                put!(ch, i)
            end
        end

        @test length(lc) == l
        cc = collect(lc)
        @test length(cc) == l
        @test cc == 1:l
        @test !isopen(lc)

    end


    @testset "Manual interaction" begin
        @info "Testing Manual interaction"



        lc = LengthChannel{Int}(l, b)
        @test length(lc) == l
        put!(lc, 1)
        @test length(lc) == l

        @test take!(lc) == 1

        @test !isready(lc)

    end

    @testset "Iteration" begin
        @info "Testing Iteration"


        lc = LengthChannel{Int}(l, b) do ch
            for i = 1:100
                put!(ch, i)
            end
        end

        c = 0
        for e in lc
            c += 1
            @test e == c
        end
        @test c == l

    end

    @testset "Channel closes early" begin
        @info "Testing Channel closes early"

        lc = LengthChannel{Int}(l, b) do ch
            for i = 1:5
                put!(ch, i)
            end
        end

        @test length(lc) == l
        cc = collect(lc)
        @test length(cc) == l
        @test cc[1:5] == 1:5
        @test !isopen(lc)



        lc = LengthChannel{Int}(l, b) do ch
            for i = 1:5
                put!(ch, i)
            end
        end

        c = 0
        for e in lc
            c += 1
            @test e == c
        end
        @test c == 5

    end
end

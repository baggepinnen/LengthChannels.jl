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

        @test fullsizeof(lc) == l*sizeof(1)

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
        @test_throws InvalidStateException collect(lc)
        @test !isopen(lc)



        lc = LengthChannel{Int}(l, b) do ch
            for i = 1:5
                put!(ch, i)
            end
        end

        for e in 1:5
            @test e == first(lc)
        end
        sleep(0.1) # it seems to take a while to close it
        @test !isopen(lc)

    end

    @testset "Wrapping LengthChannel" begin
        @info "Testing Wrapping LengthChannel"

        lc = LengthChannel{Int}(l, b) do ch
            for i = 1:100
                put!(ch, i)
            end
        end
        wlc = LengthChannel{Float64}(x->Float64(x^2), lc)

        @test eltype(wlc) <: Float64

        @test length(wlc) == l
        cc = collect(wlc)
        @test length(cc) == l
        @test cc == (1:l).^2
        @test isopen(wlc)

        lc = LengthChannel{Int}(l, b) do ch
            for i = 1:100
                put!(ch, i)
            end
        end
        f(x) = x^2
        f(::Type) = Float64
        wlc = LengthChannel(f, lc)
        @test eltype(wlc) <: Float64

        @test length(wlc) == l
        cc = collect(wlc)
        @test length(cc) == l
        @test cc == (1:l).^2
        @test isopen(wlc)
    end
end

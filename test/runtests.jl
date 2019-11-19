using LengthChannels
using Test

@testset "LengthChannels.jl" begin
    l,b = 10, 4
    lc = LengthChannel{Int}(l, b) do ch
        for i = 1:100
            put!(ch, i)
        end
    end

    @test length(lc) == l
    cc = collect(lc)
    @test length(cc) == l
    @test cc == 1:l
    @test !isopen(lc)


    lc = LengthChannel{Int}(l, b, spawn=true) do ch
        for i = 1:100
            put!(ch, i)
        end
    end

    @test length(lc) == l
    cc = collect(lc)
    @test length(cc) == l
    @test cc == 1:l
    @test !isopen(lc)




    lc = LengthChannel(l, b) do ch
        for i = 1:100
            put!(ch, i)
        end
    end

    @test length(lc) == l
    cc = collect(lc)
    @test length(cc) == l
    @test cc == 1:l
    @test !isopen(lc)


    lc = LengthChannel(l, b)
    @test length(lc) == l
    put!(lc, 1)
    @test length(lc) == l

    @test take!(lc) == 1

    @test !isready(lc)


    lc = LengthChannel{Int}(l, b)
    @test length(lc) == l
    put!(lc, 1)
    @test length(lc) == l

    @test take!(lc) == 1

    @test !isready(lc)


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

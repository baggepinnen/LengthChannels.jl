# LengthChannels

[![Build Status](https://travis-ci.com/baggepinnen/LengthChannels.jl.svg?branch=master)](https://travis-ci.org/baggepinnen/LengthChannels.jl)
[![Coverage](https://codecov.io/gh//.jl/branch/master/graph/badge.svg)](https://codecov.io/gh//.jl)

This package defines a type `LengthChannel{T} <: AbstractChannel{T}` which simply adds information about the length of the channel when it is iterated. The constructor behaves the same as the constructor for `Channel`, but takes an additional integer specifying the length. When a `LengthChannel` is iterated, it continues until it has iterated the specified number of elements, after that the channel is closed, even if there are more elements put in the channel.

Examples:

```julia
using LengthChannels, Test
len,buf = 10,4
lc = LengthChannel{Int}(len, buf) do ch
    for i = 1:100
        put!(ch, i)
    end
end

@test length(lc) == len
cc = collect(lc)
@test length(cc) == len
@test cc == 1:l
@test !isopen(lc)
```
# LengthChannels.jl

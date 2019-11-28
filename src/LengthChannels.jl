module LengthChannels
export LengthChannel

"""
This package defines a type `LengthChannel{T} <: AbstractChannel{T}` which simply adds information about the length of the channel when it is iterated. The constructor behaves the same as the constructor for `Channel`, but takes an additional integer specifying the length. This length is not to be confused with the buffer size of the channel, referred to as `buf` in the example below. When a `LengthChannel` is iterated, it continues until it has iterated the specified number of elements, after that the channel is closed, even if there are more elements put in the channel.

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
@test isopen(lc)
```

The constructor to a `LengthChannel` further takes a keyword argument `autoclose=false (default)` which determines if the channel closes automatically after having iterated for the specified length. It might be useful to keep it open if you want to iterate the specified length several times. Just make sure the channel is still being populated.



## Use as buffered iterator for machine learning
A typical use-case for a channel with length is as a buffered dataset for training machine learning models. Here, an example that reads audio data from disk and does some light pre-processing before putting it in the channel
```julia
using LengthChannels, Flux, Random
files      = readdir(path_to_datafiles)
buffersize = 10
dataset = LengthChannel{Vector{Float32}}(length(files), buffersize, spawn=true) do ch
    while true
        for file in shuffle(files)
            data = read_from_disk(file)
            put!(ch, data)
        end
    end
end
```
a batch iterator suitable for training CNN models in Flux can be obtained like so
```julia
batchsize  = 16
buffersize = 10
files      = readdir(path_to_datafiles)
dataset = LengthChannel{Array{Float32,4}}(length(files)÷batchsize, buffersize, spawn=true) do ch
    batch = Array{Float32,4}(undef,height,width,nchannels,batchsize)
    bi = 1
    while true
        for file in shuffle(files)
            data = read_from_disk(file)
            batch[:,:,:,bi] .= data
            bi += 1
            if bi > batchsize
                bi = 1
                put!(ch, copy(batch))
            end
        end
    end
end
```
where `height,width,nchannels` are integers specifying the size of your data.
You can now send the `dataset` to `Flux.train!(loss, ps, dataset, opt)`
"""
struct LengthChannel{T} <: AbstractChannel{T}
    ch::Channel{T}
    l::Int
    autoclose::Bool
end

"""
    LengthChannel{T}(l::Int, args...; autoclose=false, kwargs...)

Construct a channel with length `l`
"""
function LengthChannel{T}(l::Int, args...; autoclose=false, kwargs...) where T
    ch = Channel{T}(args...; kwargs...)
    LengthChannel{T}(ch, l, autoclose)
end

function LengthChannel(l::Int, args...; autoclose=false, kwargs...)
    ch = Channel{Any}(args...; kwargs...)
    LengthChannel{Any}(ch, l, autoclose)
end

"""
    LengthChannel{T}(f::Function, l::Int, args...; autoclose=false, kwargs...)

Construct a channel with length `l`, using function `f` to populate the channel, see [`Channel`](@ref) for help using this constructor.
"""
function LengthChannel{T}(f::Function, l::Int, args...; autoclose=false, kwargs...) where T
    ch = Channel{T}(f, args...; kwargs...)
    LengthChannel{T}(ch, l, autoclose)
end

function LengthChannel(f::Function, l::Int, args...; autoclose=false, kwargs...)
    ch = Channel{Any}(f, args...; kwargs...)
    LengthChannel{Any}(ch, l, autoclose)
end

Base.length(lc::LengthChannel) = lc.l

for f in (bind, close, fetch, isopen, isready, lock, popfirst!, push!, put!, take!, trylock, unlock, wait, eltype)
    f = nameof(f)
    @eval Base.$f(lc::LengthChannel, args...; kwargs...) = $(f)(lc.ch, args...; kwargs...)
end

function Base.iterate(lc::LengthChannel, state=0)
    if state == length(lc) || !isopen(lc)
        lc.autoclose && close(lc)
        return nothing
    end
     (take!(lc),state+1)
end

end

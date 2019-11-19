module LengthChannels
export LengthChannel

struct LengthChannel{T} <: AbstractChannel{T}
    ch::Channel{T}
    l::Int
end
function LengthChannel{T}(l::Int, args...; kwargs...) where T
    ch = Channel{T}(args...; kwargs...)
    LengthChannel{T}(ch, l)
end

function LengthChannel(l::Int, args...; kwargs...)
    ch = Channel{Any}(args...; kwargs...)
    LengthChannel{Any}(ch, l)
end

function LengthChannel{T}(f::Function, l::Int, args...; kwargs...) where T
    ch = Channel{T}(f, args...; kwargs...)
    LengthChannel{T}(ch, l)
end

function LengthChannel(f::Function, l::Int, args...; kwargs...)
    ch = Channel{Any}(f, args...; kwargs...)
    LengthChannel{Any}(ch, l)
end

Base.length(lc::LengthChannel) = lc.l

for f in (bind, close, fetch, isopen, isready, lock, popfirst!, push!, put!, take!, trylock, unlock, wait)
    f = nameof(f)
    @eval Base.$f(lc::LengthChannel, args...; kwargs...) = $(f)(lc.ch, args...; kwargs...)
end

function Base.iterate(lc::LengthChannel, state=0)
    if state == length(lc)
        close(lc)
        return nothing
    end
     (take!(lc),state+1)
end

end

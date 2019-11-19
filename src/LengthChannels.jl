module LengthChannels
export LengthChannel

struct LengthChannel{T} <: AbstractChannel{T}
    ch::Channel{T}
    l::Int
    autoclose::Bool
end
function LengthChannel{T}(l::Int, args...; autoclose=false, kwargs...) where T
    ch = Channel{T}(args...; kwargs...)
    LengthChannel{T}(ch, l, autoclose)
end

function LengthChannel(l::Int, args...; autoclose=false, kwargs...)
    ch = Channel{Any}(args...; kwargs...)
    LengthChannel{Any}(ch, l, autoclose)
end

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

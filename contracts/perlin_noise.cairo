%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.bitwise import bitwise_and
from Math64x61 import (
    Math64x61_toFelt,
    Math64x61_fromFelt,
    Math64x61_div,
    Math64x61_mul,
    Math64x61_sqrt,
    Math64x61_add
)

struct Vec2D:
    member x : felt
    member y : felt
end

# 1/sqrt(2), in 64.61 fixed-point format
const HALF_SQRT_2 = 345

# pseudo-randomly returns 0, 1 , 2, or 3 based on the given seed.
func rand_2bits{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*}(seed1 : felt, seed2 : felt) -> (bit : felt):
    alloc_locals
    local pedersen_ptr : HashBuiltin* = pedersen_ptr 
    local bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
    let (hash) = hash2{hash_ptr=pedersen_ptr}(seed1, seed2)

    # bit-representation of 3 is 00...011, therefore ANDing with a hash yields the first 2 bits of the hash
    let (bit) = bitwise_and(hash, 3) 
    return (bit)
end

func dot_prod{range_check_ptr}(a : Vec2D, b : Vec2D) -> (res : felt):
    let (x) = Math64x61_mul(a.x, b.x)
    let (y) = Math64x61_mul(a.y, b.y)
    let (res) = Math64x61_add(x, y)
    return (res)
end

#func get_half_sqrt_2{range_check_ptr() -> (res : felt):

# x and y refer to an intersection of the gridlines of the perlin noise grid
#func selectVector{hash_ptr, range_check_ptr}(x : felt, y : felt) -> (res: (felt, felt)):

#end
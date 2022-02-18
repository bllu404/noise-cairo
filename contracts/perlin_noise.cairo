%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math import unsigned_div_rem
from Math64x61 import (
    Math64x61_toFelt,
    Math64x61_fromFelt,
    Math64x61_div,
    Math64x61_mul,
    Math64x61_sqrt,
    Math64x61_add,
    Math64x61_ONE
)

# 1/sqrt(2), in 64.61 fixed-point format
const HALF_SQRT2 = 1630477227105714176
const NEG_HALF_SQRT2 = -HALF_SQRT2

# pseudo-randomly returns 0, 1, 2, or 3 based on the given seed.
func rand_2bits{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*}(seed1, seed2, seed3) -> (bits):
    alloc_locals
    local pedersen_ptr : HashBuiltin* = pedersen_ptr 
    local bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
    let (first_hash) = hash2{hash_ptr=pedersen_ptr}(seed1, seed2)
    let (final_hash) = hash2{hash_ptr=pedersen_ptr}(first_hash, seed3)

    # bit-representation of 3 is 00...011, therefore ANDing with a hash yields the first 2 bits of the hash
    let (bits) = bitwise_and(final_hash, 3) 
    return (bits)
end

func dot_prod{range_check_ptr}(a : (felt, felt), b : (felt, felt)) -> (res):
    let (x) = Math64x61_mul(a[0], b[0])
    let (y) = Math64x61_mul(a[1], b[1])
    let (res) = Math64x61_add(x, y)
    return (res)
end


#func get_half_sqrt2{range_check_ptr}() -> (half_sqrt2):
#    alloc_locals
#    local range_check_ptr = range_check_ptr
#
#    let (two_64x61) = Math64x61_fromFelt(2)
#    let (sqrt2) = Math64x61_sqrt(two_64x61)
#    let (half_sqrt2) = Math64x61_div(Math64x61_ONE, sqrt2)
#    return (half_sqrt2)
#end

# x and y refer to an intersection of the gridlines of the perlin noise grid, seed
# 1 = 1/sqrt(2), -1 = -1/sqrt(2)
func select_vector{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*}(x, y, seed) -> (vec: (felt, felt)):
   alloc_locals
    let (choice) = rand_2bits(x,y,seed)

    if choice == 0:
        tempvar vec : (felt, felt) = (-1,-1)
    else: 
        if choice == 1:
            tempvar vec : (felt, felt) = (-1,1)
        else: 
            if choice == 2:
                tempvar vec : (felt, felt) = (1,-1)
            else:
                tempvar vec : (felt,felt) = (1,1)
            end 
        end 
    end

    return (vec)
end

# SCale represents the ratio of gridlines to coordinates. If scale == 1, then there is 1 gridline for every coordinate. 
# If scale == 100, then there is a gridline on every 100th coordinate. 
func get_nearest_gridlines{range_check_ptr}(x, y, scale) -> (lower_x, lower_y):
    let (lower_x, _) = unsigned_div_rem(x, scale)
    let (lower_y, _) = unsigned_div_rem(y, scale)
    return (lower_x, lower_y)
end



### Steps ###
# 1. Find the gridlines within which the given point lies
# 2. Compute the random vectors at each corner
# 3. Compute the offset vectors from each corner to the point
# 4. Compute the dot product of the random vector and the offset vectors for each corner
# 5. Calculate the linear interpolation between the pairs of dot products using the fade function

#func noise_custom{hash_ptr : HashBuiltin*, bitwise : BitwiseBuiltin*, range_check_ptr}(x, y, scale,seed):
#end 
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
    Math64x61_sub,
    Math64x61_pow,
    Math64x61_ONE,
    Math64x61_FRACT_PART
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

# Scale represents the ratio of gridlines to coordinates. If scale == 1, then there is 1 gridline for every coordinate. 
# If scale == 100, then there is a gridline on every 100th coordinate. 
func get_nearest_gridlines{range_check_ptr}(x, y, scale) -> (lower_x, lower_y):
    let (lower_x, _) = unsigned_div_rem(x, scale)
    let (lower_y, _) = unsigned_div_rem(y, scale)
    return (lower_x, lower_y)
end

# Returns the offset vector between a grid point and the point for which noise is being generated
func get_offset_vec{range_check_ptr}(point : (felt, felt), grid_point : (felt, felt)) -> (offset_vec: (felt, felt)):
    tempvar offset_vec : (felt, felt) = (point[0] - grid_point[0], point[1] - grid_point[1])
    return (offset_vec)
end


# a, b, and t should be in 64.61 fixed-point format
func linterp{range_check_ptr}(a, b, t) -> (res):
    let (diff) = Math64x61_sub(b, a)
    let (t_times_diff) = Math64x61_mul(t, diff)
    let (res) = Math64x61_add(a, t_times_diff)
    return (res)
end

func fade_func{range_check_ptr}(x) -> (res):
    let (x_pow3) = Math64x61_pow(x, 3)
    let (x_pow4) = Math64x61_mul(x_pow3, x)
    let (x_pow5) = Math64x61_mul(x_pow4, x)
    let (six_x_pow5) = Math64x61_mul(6*Math64x61_FRACT_PART, x_pow5)
    let (fifteen_x_pow4) = Math64x61_mul(15*Math64x61_FRACT_PART, x_pow4)
    let (ten_x_pow3) = Math64x61_mul(10*Math64x61_FRACT_PART, x_pow3)
    let (diff) = Math64x61_sub(six_x_pow5, fifteen_x_pow4)
    let (res) = Math64x61_add(diff, ten_x_pow3)
    return (res)
end


### Steps ###
# 1. Find the gridlines within which the given point lies
# 2. Compute the random vectors at each corner
# 3. Compute the offset vectors from each corner to the point
# 4. Compute the dot product of the random vector and the offset vectors for each corner
# 5. Calculate the linear interpolation between the pairs of dot products using the fade function

func noise_custom{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(point : (felt,felt), scale, seed) -> (res):
    alloc_locals
    let (lower_x, lower_y) = get_nearest_gridlines(point[0], point[1], scale)

    let upper_x = lower_x + 1
    let upper_y = lower_y + 1

    let lower_x_scaled = lower_x * scale
    let lower_y_scaled = lower_y * scale
    let upper_x_scaled = upper_x * scale
    let upper_y_scaled = upper_y * scale

    ######### Computing the random vector at each corner of the grid box #########
    let (lower_x_lower_y_randvec : (felt, felt)) = select_vector(lower_x, lower_y, seed)
    let (lower_x_upper_y_randvec : (felt, felt)) = select_vector(lower_x, upper_y, seed)
    let (upper_x_lower_y_randvec : (felt, felt)) = select_vector(upper_x, lower_y, seed)
    let (upper_x_upper_y_randvec : (felt, felt)) = select_vector(upper_x, upper_y, seed)

    ######### Computing the offset vectors #########
    let (lower_x_lower_y_offsetvec : (felt, felt)) = get_offset_vec(point, (lower_x_scaled, lower_y_scaled))
    let (lower_x_upper_y_offsetvec : (felt, felt)) = get_offset_vec(point, (lower_x_scaled, upper_y_scaled))
    let (upper_x_lower_y_offsetvec : (felt, felt)) = get_offset_vec(point, (upper_x_scaled, lower_y_scaled))
    let (upper_x_upper_y_offsetvec : (felt, felt)) = get_offset_vec(point, (upper_x_scaled, upper_y_scaled))

    ######### Computing the dot products #########
    let (dot_lower_x_lower_y) = dot_prod(lower_x_lower_y_randvec, lower_x_lower_y_offsetvec)
    let (dot_lower_x_upper_y) = dot_prod(lower_x_upper_y_randvec, lower_x_upper_y_offsetvec)
    let (dot_upper_x_lower_y) = dot_prod(upper_x_lower_y_randvec, upper_x_lower_y_offsetvec)
    let (dot_upper_x_upper_y) = dot_prod(upper_x_upper_y_randvec, upper_x_upper_y_offsetvec)

    ######### Computing bilinear interpolation of the dot products #########
    let point_64x61 : (felt,felt) = (Math64x61_fromFelt(point[0]).res, Math64x61_fromFelt(point[1]).res)
    let point_64x61_normalized : (felt, felt) = (Math64x61_div(point_64x61[0], scale).res, Math64x61_div(point_64x61[1], scale).res)

    let (linterp_lower_x) = linterp(dot_lower_x_lower_y, dot_lower_x_upper_y, fade_func(point_64x61_normalized[0] - lower_x).res)
    let (linterp_upper_x) = linterp(dot_upper_x_lower_y, dot_upper_x_upper_y, fade_func(point_64x61_normalized[0] - lower_x).res)
    let (linterp_final) = linterp(linterp_lower_x, linterp_upper_x, fade_func(point_64x61_normalized[1] - lower_y).res)

    return (res=linterp_final)
end 
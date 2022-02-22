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
    Math64x61_FRACT_PART,
    Math64x61_assert64x61
)

# 1/sqrt(2), in 64.61 fixed-point format
const HALF_SQRT2 = 1630477227105714176
const NEG_HALF_SQRT2 = -HALF_SQRT2
const Math64x61_NEG_ONE = -Math64x61_ONE
const Math64x61_TWO = 2 * Math64x61_FRACT_PART

# pseudo-randomly returns a felt in the range 0-7 based on the given seed.
func rand_3bits{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*}(seed1, seed2, seed3) -> (bits):
    alloc_locals
    local pedersen_ptr : HashBuiltin* = pedersen_ptr 
    local bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
    let (first_hash) = hash2{hash_ptr=pedersen_ptr}(seed1, seed2)
    let (final_hash) = hash2{hash_ptr=pedersen_ptr}(first_hash, seed3)

    # bit-representation of 7 is 00...0111, therefore ANDing with a hash yields the first 3 bits of the hash
    let (bits) = bitwise_and(final_hash, 7) 
    return (bits)
end

# a and b should be in 64.61 format, 
func dot_prod{range_check_ptr}(a : (felt, felt), b : (felt, felt)) -> (res):
    let (x) = Math64x61_mul(a[0], b[0])
    let (y) = Math64x61_mul(a[1], b[1])

    # Addition can be 'unsafe' here since a and b are guaranteed to be small enough so as to not overflow, given their sizes
    return (res=x+y)
end


#func get_half_sqrt2{range_check_ptr}() -> (half_sqrt2):
#    alloc_locals
#    local range_check_ptr = range_check_ptr
#
#    let (two_64x61) = Math64x61_fromFelt(2)
#    let (sqrt2) = Math64x61_sqrt(two_64x61)
#    return Math64x61_div(Math64x61_ONE, sqrt2)
#end

# x and y refer to an intersection of the gridlines of the perlin noise grid, seed is an additional variable for randomness
# 1 = 1/sqrt(2), -1 = -1/sqrt(2)
func select_vector{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*}(x, y, seed) -> (vec: (felt, felt)):
    alloc_locals
    let (choice) = rand_3bits(x,y,seed)

    # This is ugly but can't be put in `dw` array since some values are greater than PRIME//2. 
    if choice == 0:
        tempvar vec : (felt, felt) = (NEG_HALF_SQRT2, NEG_HALF_SQRT2)
    else: 
        if choice == 1:
            tempvar vec : (felt, felt) = (NEG_HALF_SQRT2, HALF_SQRT2)
        else: 
            if choice == 2:
                tempvar vec : (felt, felt) = (HALF_SQRT2, NEG_HALF_SQRT2)
            else:
                if choice == 3:
                    tempvar vec : (felt,felt) = (HALF_SQRT2, HALF_SQRT2)
                else:
                    if choice == 4:
                        tempvar vec : (felt,felt) = (Math64x61_ONE, 0)
                    else:
                        if choice == 5:
                            tempvar vec : (felt,felt) = (0, Math64x61_ONE)
                        else:
                            if choice == 6:
                                tempvar vec : (felt,felt) = (0, Math64x61_NEG_ONE)
                            else:
                                tempvar vec : (felt,felt) = (Math64x61_NEG_ONE, 0)
                            end 
                        end 
                    end 
                end
            end 
        end 
    end

    return (vec)
end

# Scale represents the ratio of gridlines to coordinates. If scale == 1, then there is 1 gridline for every coordinate. 
# If scale == 100, then there is a gridline on every 100th coordinate. 
func get_nearest_gridlines{range_check_ptr}(x, y, scale) -> (lower_x_64x61, lower_y_64x61):
    let (lower_x, _) = unsigned_div_rem(x, scale)
    let (lower_y, _) = unsigned_div_rem(y, scale)
    let (lower_x_64x61) = Math64x61_fromFelt(lower_x)
    let (lower_y_64x61) = Math64x61_fromFelt(lower_y)
    return (lower_x_64x61, lower_y_64x61)
end

# Returns the offset vector (in 64.61 format) between two vectors (64.61 format expected)
func get_offset_vec{range_check_ptr}(a : (felt, felt), b : (felt, felt)) -> (offset_vec_64x61: (felt, felt)):
    # Subtraction can be unsafe here since the diffs are guaranteed to not overflow in every case that this function is used
    let diff_x = a[0] - b[0]
    let diff_y = a[1] - b[0]
    return (offset_vec_64x61=(diff_x, diff_y))
end

func vec_to_vec64x61{range_check_ptr}(vec : (felt, felt)) -> (res: (felt, felt)):
    let (x_64x61) = Math64x61_fromFelt(vec[0])
    let (y_64x61) = Math64x61_fromFelt(vec[1])
    return (res=(x_64x61, y_64x61))
end

# vec and scale should be in 64.61 format
func scale_vec{range_check_ptr}(vec : (felt, felt), scale) -> (res: (felt, felt)):
    alloc_locals
    let (x_scaled) = Math64x61_div(vec[0], scale)
    let (y_scaled) = Math64x61_div(vec[1], scale)
    return (res=(x_scaled, y_scaled))
end

# a, b, and t should be in 64.61 fixed-point format
func linterp{range_check_ptr}(a, b, t) -> (res):
    # Subtraction can be unsafe here since b and a are both guaranteed to be "small" 
    let diff = b - a
    let (t_times_diff) = Math64x61_mul(t, diff)
    # Addition can be unsafe here for the same reason
    return (res = a + t_times_diff)
end

# x should be in 64.61 format
func fade_func{range_check_ptr}(x) -> (res):
    let (x_pow3) = Math64x61_pow(x, 3)
    let (x_pow4) = Math64x61_mul(x_pow3, x)
    let (x_pow5) = Math64x61_mul(x_pow4, x)

    let (six_x_pow5) = Math64x61_mul(6*Math64x61_FRACT_PART, x_pow5)
    let (fifteen_x_pow4) = Math64x61_mul(15*Math64x61_FRACT_PART, x_pow4)
    let (ten_x_pow3) = Math64x61_mul(10*Math64x61_FRACT_PART, x_pow3)

    #let diff = six_x_pow5 - fifteen_x_pow4
    return (res = six_x_pow5 - fifteen_x_pow4 + ten_x_pow3)
end


### Steps ###
# 1. Find the gridlines within which the given point lies
# 2. Compute the random vectors at each corner
# 3. Compute the offset vectors from each corner to the point
# 4. Compute the dot product of the random vector and the offset vectors for each corner
# 5. Calculate the linear interpolation between the pairs of dot products using the fade function


# Assumes point, scale, and seed are regular unsigned felts. Returns a felt in 64.61 signed format. 
# scale essentially represents the desired grid-box sidelength
func noise_custom{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(point : (felt,felt), scale, seed) -> (res):
    alloc_locals

    let (point_64x61) = vec_to_vec64x61(point)
    let (scale_64x61) = Math64x61_fromFelt(scale)

    # Scaling down the point vector so that, relative to it, each gridbox has a sidelength of 1. 
    let (point_64x61_scaled : (felt, felt)) = scale_vec(point_64x61, scale_64x61)
    
    let (lower_x_64x61, lower_y_64x61) = get_nearest_gridlines(point[0], point[1], scale)

    let (upper_x_64x61) = Math64x61_add(lower_x_64x61, Math64x61_ONE)
    let (upper_y_64x61) = Math64x61_add(lower_y_64x61, Math64x61_ONE)

    ######### Computing the random gradient vector at each grid node #########
    # Currently 8 hashes are computed, which is expensive. Is there an even cheaper PRNG? 
    let (lower_x_lower_y_randvec : (felt, felt)) = select_vector(lower_x_64x61, lower_y_64x61, seed)
    let (lower_x_upper_y_randvec : (felt, felt)) = select_vector(lower_x_64x61, upper_y_64x61, seed)
    let (upper_x_lower_y_randvec : (felt, felt)) = select_vector(upper_x_64x61, lower_y_64x61, seed)
    let (upper_x_upper_y_randvec : (felt, felt)) = select_vector(upper_x_64x61, upper_y_64x61, seed)

    ######### Computing the offset vectors #########
    let (lower_x_lower_y_offsetvec : (felt, felt)) = get_offset_vec(point_64x61_scaled, (lower_x_64x61, lower_y_64x61))
    let (lower_x_upper_y_offsetvec : (felt, felt)) = get_offset_vec(point_64x61_scaled, (lower_x_64x61, upper_y_64x61))
    let (upper_x_lower_y_offsetvec : (felt, felt)) = get_offset_vec(point_64x61_scaled, (upper_x_64x61, lower_y_64x61))
    let (upper_x_upper_y_offsetvec : (felt, felt)) = get_offset_vec(point_64x61_scaled, (upper_x_64x61, upper_y_64x61))

    ######### Computing dot products  #########
    let (dot_lower_x_lower_y) = dot_prod(lower_x_lower_y_randvec, lower_x_lower_y_offsetvec)
    let (dot_lower_x_upper_y) = dot_prod(lower_x_upper_y_randvec, lower_x_upper_y_offsetvec)
    let (dot_upper_x_lower_y) = dot_prod(upper_x_lower_y_randvec, upper_x_lower_y_offsetvec)
    let (dot_upper_x_upper_y) = dot_prod(upper_x_upper_y_randvec, upper_x_upper_y_offsetvec)

    #### 
    ######### Computing bilinear interpolation of the dot products #########
    let(diff1) = Math64x61_sub(point_64x61_scaled[0], lower_x_64x61)
    let(diff2) = Math64x61_sub(point_64x61_scaled[1], lower_y_64x61)

    let (faded1) = fade_func(diff1)
    let (faded2) = fade_func(diff2)

    let (linterp_lower_y) = linterp(dot_lower_x_lower_y, dot_upper_x_lower_y, faded1)
    let (linterp_upper_y) = linterp(dot_lower_x_upper_y, dot_upper_x_upper_y, faded1)
    let (linterp_final) = linterp(linterp_lower_y, linterp_upper_y, faded2)
    return(res=linterp_final)
end


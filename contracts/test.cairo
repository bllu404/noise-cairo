%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.hash import hash2
from Math64x61 import Math64x61_fromFelt
from perlin_noise import (
    rand_2bits, 
    select_vector, 
    get_nearest_gridlines,
    noise_custom,
    get_offset_vec,
    dot_prod,
    vec_to_vec64x61,
    fade_func,
    linterp,
    scale_vec
)

############# Utility functions #############

@view 
func get_rand_2bits{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*} (seed1, seed2, seed3) -> (bits): 
    return rand_2bits(seed1, seed2, seed3)
end

@view
func get_hash{pedersen_ptr : HashBuiltin*, range_check_ptr} (seed1, seed2) -> (hash):
    let (hash) = hash2{hash_ptr=pedersen_ptr}(seed1, seed2)
    return (hash)
end

@view 
func get_random_vector{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*} (x, y, seed) -> (res :(felt,felt)):
    return select_vector(x, y, seed)
end

#@view
#func half_sqrt2{range_check_ptr}() -> (half_sqrt):
#    return get_half_sqrt2()
#end

@view
func get_gridlines{range_check_ptr}(x, y, scale) -> (x_gridline, y_gridline):
    return get_nearest_gridlines(x, y, scale)
end

@view 
func get_offset{range_check_ptr}(a : (felt, felt), b : (felt, felt)) -> (offset_vec_64x61: (felt, felt)):
    return get_offset_vec(a, b)
end

@view 
func get_dot_prod{range_check_ptr}(a : (felt, felt), b : (felt, felt)) -> (res):
    let (a_64x61) = vec_to_vec64x61(a)
    let (b_64x61) = vec_to_vec64x61(b)
    return dot_prod(a_64x61, b_64x61)
end

@view
func get_fade_func{range_check_ptr}(x) -> (res):
    return fade_func(x)
end

@view 
func get_linterp{range_check_ptr}(a, b, t) -> (res):
    return linterp(a,b,t)
end

@view 
func scaled_point{range_check_ptr}(point : (felt, felt), scale) -> (res : (felt, felt)):
    return scale_vec(point, scale)
end 

@view 
func get_noise{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x, y) -> (res):
    let (noise_val) = noise_custom((x, y), 100, 69)
    return (res=noise_val)
end


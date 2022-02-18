%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.hash import hash2
from perlin_noise import rand_2bits, get_half_sqrt2, select_vector, Vec2D

############# Utility functions #############

@view 
func get_rand_2bits{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*} (seed1, seed2, seed3) -> (bits): 
    let (bits) = rand_2bits(seed1, seed2, seed3)
    return (bits)
end

@view
func get_hash{pedersen_ptr : HashBuiltin*, range_check_ptr} (seed1, seed2) -> (hash):

    let (hash) = hash2{hash_ptr=pedersen_ptr}(seed1, seed2)
    return (hash)
end

@view 
func get_random_vector{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*} (x, y, seed) -> (vec : Vec2D):
    let (vec : Vec2D) = select_vector(x, y, seed)
    return (vec)
end
@view
func half_sqrt2{range_check_ptr} () -> (half_sqrt):
    let (half_sqrt) = get_half_sqrt2()
    return (half_sqrt)
end
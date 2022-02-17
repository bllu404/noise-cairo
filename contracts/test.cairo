%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.hash import hash2
from perlin_noise import rand_2bits

############# Utility functions #############

@view 
func get_rand_2bits{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*} (seed1 : felt, seed2 : felt) -> (bits : felt): 
    let (bits) = rand_2bits(seed1, seed2)
    return (bits)
end

@view
func get_hash{pedersen_ptr : HashBuiltin*, range_check_ptr} (seed1 : felt, seed2 : felt) -> (hash):

    let (hash) = hash2{hash_ptr=pedersen_ptr}(seed1, seed2)
    return (hash)
end
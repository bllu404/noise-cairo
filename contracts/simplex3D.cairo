%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.registers import get_label_location
from permutation_table import p 

from Math64x61 import (
    Math64x61_fromFelt,
    Math64x61_toFelt,
    Math64x61_div_unsafe,
    Math64x61_mul_unsafe,
    Math64x61_add,
    Math64x61_ONE,
    Math64x61_FRACT_PART
)

using Point = (x : felt, y : felt, z : felt)

const F = 768614336404564650 # 1/3 in 64.61 format - Factor used to transform (x,y,z) coordinates into skewed coordinate space
const G = 384307168202282325 #1/6 in 64.61 format - Factor used to transform skewed coordinates into (x,y,z) (Euclidean) coordinates 

const R_SQUARED = 1383505805528216371 # 0.6

func dot{range_check_ptr}(a : Point, b : Point) -> (res):
    let (x) = Math64x61_mul_unsafe(a[0], b[0])
    let (y) = Math64x61_mul_unsafe(a[1], b[1])
    let (z) = Math64x61_mul_unsafe(a[2], b[2])
    return (res = x + y + z)
end

# Returns only the integer part of a 64.61 bit number, in 64.61 bit format
func floor{range_check_ptr}(a) -> (res):
    let (a_felt) = Math64x61_toFelt(a)
    return (res = a_felt * Math64x61_FRACT_PART)
end

@view
func noise3D_custom{range_check_ptr}(x,y,z, scale, seed) -> (noise):
    alloc_locals
    let (x_64x61) = Math64x61_fromFelt(x)
    let (y_64x61) = Math64x61_fromFelt(y)
    let (z_64x61) = Math64x61_fromFelt(z)
    let (scale_64x61) = Math64x61_fromFelt(scale)

    let (x_scaled) = Math64x61_div_unsafe(x_64x61, scale_64x61)
    let (y_scaled) = Math64x61_div_unsafe(y_64x61, scale_64x61)
    let (z_scaled) = Math64x61_div_unsafe(z_64x61, scale_64x61)

    let (skew_factor) = Math64x61_mul_unsafe(x_scaled + y_scaled + z_scaled, F)

    let (i) = floor(x_scaled + skew_factor)
    let (j) = floor(y_scaled + skew_factor)
    let (k) = floor(z_scaled + skew_factor)

    let (unskew_factor) = Math64x61_mul_unsafe(i + j + k, G)

    # Getting displacement vector from origin of the cube to point
    tempvar x0 = x_scaled - i + unskew_factor
    tempvar y0 = y_scaled - j + unskew_factor
    tempvar z0 = z_scaled - k + unskew_factor

    local i1
    local j1
    local k1
    local i2
    local j2
    local k2

    # Traversing the cube to find the simplex the point is in
    let (temp) = is_le(x0, y0) 
    if temp != 0:
        let (temp) = is_le(y0, z0)
        if temp != 0:
            assert i1 = 0
            assert j1 = 0
            assert k1 = 1

            assert i2 = 0
            assert j2 = 1
            assert k2 = 1
        else:
            let (temp) = is_le(x0, z0)
            if temp != 0:
                assert i1 = 0
                assert j1 = 1
                assert k1 = 0

                assert i2 = 0
                assert j2 = 1
                assert k2 = 1
            else:
                assert i1 = 0
                assert j1 = 1
                assert k1 = 0

                assert i2 = 1
                assert j2 = 1
                assert k2 = 0
            end
        end
    else:
        let (temp) = is_le(z0, y0)
        if temp != 0:
            assert i1 = 1
            assert j1 = 0
            assert k1 = 0

            assert i2 = 1
            assert j2 = 1
            assert k2 = 0
        else:
            let (temp) = is_le(z0, x0)
            if temp != 0:
                assert i1 = 1
                assert j1 = 0
                assert k1 = 0

                assert i2 = 1
                assert j2 = 0
                assert k2 = 1
            else:
                assert i1 = 0
                assert j1 = 0
                assert k1 = 1

                assert i2 = 1
                assert j2 = 0
                assert k2 = 1
            end
        end
    end

    # Calculating the displacement vectors between the input point and the rest of the simplex vertices
    tempvar x1 = x0 - i1 + G 
    tempvar y1 = y0 - j1 + G 
    tempvar z1 = z0 - k1 + G 

    tempvar x2 = x0 - i2 + 2*G 
    tempvar y2 = y0 - j2 + 2*G 
    tempvar z2 = z0 - k2 + 2*G

    tempvar x3 = x0 - 1 + 3*G 
    tempvar y3 = y0 - 1 + 3*G 
    tempvar z3 = z0 - 1 + 3*G

    # Getting the gradient vectors of each vertex of the simplex.
    let (g0 : Point) = select_vector(i,j,k, seed)
    let (g1 : Point) = select_vector(i + i1,j + j1,k + k1, seed)
    let (g2 : Point) = select_vector(i + i2,j + j2,k + k2, seed)
    let (g3 : Point) = select_vector(i + 1,j + 1,k + 1, seed)

    # Calculating the contribution of each vertex
    let (n0) = get_contribution(x0, y0, z0, g0)
    let (n1) = get_contribution(x1, y1, z1, g1)
    let (n2) = get_contribution(x2, y2, z2, g2)
    let (n3) = get_contribution(x3, y3, z3, g3)

    # Scaling sum by 32 so the noise has a range of [-1,1]
    return(noise=32*(n0 + n1 + n2 + n3)) 
end

func get_contribution{range_check_ptr}(x,y,z, g : Point) -> (contribution):
    alloc_locals
    let (x_squared) = Math64x61_mul_unsafe(x,x)
    let (y_squared) = Math64x61_mul_unsafe(y,y)
    let (z_squared) = Math64x61_mul_unsafe(z,z)

    tempvar t = R_SQUARED - x_squared - y_squared - z_squared

    let (temp) = is_le(t, 0)
    if temp != 0:
        return (contribution=0)
    else:
        let (t_squared) = Math64x61_mul_unsafe(t,t)
        let (t_pow4) = Math64x61_mul_unsafe(t_squared, t_squared)
        let (dot_prod) = dot((x,y,z), g)

        return Math64x61_mul_unsafe(dot_prod, t_pow4)
    end
end

func rand_num{range_check_ptr}(seed1, seed2, seed3, seed4) -> (num):
    let (_, seed1_mod) = unsigned_div_rem(seed1, 256)

    let (p1) = p(seed1_mod)
    let (_, temp1) = unsigned_div_rem(p1 + seed2, 256)
    let (p2) = p(temp1)
    let (_, temp2) = unsigned_div_rem(p2 + seed3, 256)
    let (p3) = p(temp2)
    let (_, temp3) = unsigned_div_rem(p3 + seed4, 256)
    let (p4) = p(temp2)
    let (_, num) = unsigned_div_rem(p3, 12)
    return (num)
end

func select_vector{range_check_ptr}(x, y, z, seed) -> (vec: Point):
    alloc_locals
    let (choice) = rand_num(x,y,z, seed)

    let(gradients_address) = get_label_location(gradients_start)
    return(vec=(x=[gradients_address + 3*choice], y=[gradients_address + 3*choice + 1], z=[gradients_address + 3*choice + 2]))

    gradients_start:
    dw 1
    dw 1
    dw 0

    dw -1
    dw 1
    dw 0

    dw 1
    dw -1
    dw 0
    
    dw -1
    dw -1
    dw 0

    dw 1
    dw 0 
    dw 1

    dw -1 
    dw 0 
    dw 1 

    dw 1 
    dw 0
    dw -1

    dw -1
    dw 0
    dw -1

    dw 0
    dw 1
    dw 1
    
    dw 0
    dw -1
    dw -1

    dw 0
    dw 1
    dw -1

    dw 0 
    dw -1
    dw 1
end
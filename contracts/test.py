import os
import pytest
from math import sqrt
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "test.cairo")


# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.

FRACT_PART = 2**61
ERROR = 1/10_000
CAIRO_PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
HALF_PRIME = CAIRO_PRIME // 2
HALF_SQRT2 = 1/sqrt(2)

# Gets the integer lift of a felt
def get_lift(x):
    return x if x < 2**128 else x - CAIRO_PRIME

# Gets integer lift of a 2d vector tuple
def get_vec_lift(x):
    x_0 = get_lift(x[0])
    x_1 = get_lift(x[1])
    return (x_0, x_1)

@pytest.mark.asyncio
async def test_perlin_noise():
    
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE
    )

    ###### Testing the PRNG ######
    '''
    print("\n\nPRNG Test\n")
    sum = 0
    loop_iters = 50

    for i in range(loop_iters):
        result = await contract.get_rand_2bits(seed1=i, seed2=i, seed3=i).call()
        sum += result.result.bits

    avg = sum/loop_iters
    print(avg)
    assert(avg <= 1.6 and avg >= 1,4)
    '''

    ###### Testing vector selection
    '''
    print("\n\nVector Selection Test\n")
    for i in range(5):
        res = await contract.get_random_vector(i, i+1, 5).call()
        vec = res.result.res 
        vec_reg_representation = ((vec[0] if vec[0] < HALF_PRIME else vec[0] - CAIRO_PRIME)/FRACT_PART, (vec[1] if vec[1] < HALF_PRIME else vec[1] - CAIRO_PRIME)/FRACT_PART)
        print(f"({vec_reg_representation[0]}, {vec_reg_representation[1]})")
        
        assert(abs(vec_reg_representation[0]) > HALF_SQRT2 - ERROR and abs(vec_reg_representation[0]) < HALF_SQRT2 + ERROR)
        assert(abs(vec_reg_representation[1]) > HALF_SQRT2 - ERROR and abs(vec_reg_representation[1]) < HALF_SQRT2 + ERROR)
    '''


    #### Testing gridline getter
    '''
    print("\n\nNearest Gridlines Test\n")
    case1 = (await contract.get_gridlines(5, 6, 1).call()).result
    case2 = (await contract.get_gridlines(5, 6, 100).call()).result
    case3 = (await contract.get_gridlines(599, 600, 100).call()).result
    case4 = (await contract.get_gridlines(600, 599, 100).call()).result

    assert(case1.x_gridline == 5 and case1.y_gridline == 6)
    assert(case2.x_gridline == 0 and case2.y_gridline == 0)
    assert(case3.x_gridline == 5 and case3.y_gridline == 6)
    assert(case4.x_gridline == 6 and case4.y_gridline == 5)
    '''

    '''
    #### Testing offset vector function
    print()

    case1 = (await contract.get_offset((1,2), (1,2)).call()).result.offset_vec_64x61
    case2 = (await contract.get_offset((1,2), (5,7)).call()).result.offset_vec_64x61
    case3 = (await contract.get_offset((5,7), (1,2)).call()).result.offset_vec_64x61

    print(f"{case1[0]/2**61}, {case1[1]/2**61}")
    assert(get_vec_lift(case1) == (0,0))
    assert(get_vec_lift(case2) == (-4*2**61, -5*2**61))
    assert(get_vec_lift(case3) == (4*2**61, 5*2**61))
    '''

    
    #### Testing noise function
    '''
    print()
    #### Testing Noise Function
    for i in range(30):
        noiseVal = await contract.get_noise(0,5+5*i).call()
        print(f"{5*i}: {noiseVal.result.res/FRACT_PART}")

    for i in range(20):
        noiseVal = await contract.get_noise(0,90+i).call()
        print(f"{90+i}: {noiseVal.result.res/FRACT_PART}")
    '''



    

    
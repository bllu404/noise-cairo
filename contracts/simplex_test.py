import os
import pytest
from math import sqrt, floor
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "simplex3D.cairo")


# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.

FRACT_PART = 2**61
ERROR = 1/10_000
ERROR_FIXED_POINT = 2**16
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

def get_decimal_num(x):
    return get_lift(x)/FRACT_PART

@pytest.mark.asyncio
async def test_perlin_noise():
    
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE
    )

    print()

    test = await contract.noise3D_custom(100,100,100, 200, 69).invoke()
    #test = await contract.get_hash(5,6).call()
    print(f"Output: {get_decimal_num(test.result.noise)}")
    print(f"Num steps: {test.call_info.execution_resources.n_steps}")
    


    

    
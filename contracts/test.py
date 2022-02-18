import os
import pytest

from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "test.cairo")


# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.

HALF_MAX_VAL = 2**250
@pytest.mark.asyncio
async def test_rand_2bits():
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    print()
    '''
    sum = 0
    loop_iters = 50

    for i in range(loop_iters):
        result = await contract.get_rand_2bits(seed1=i, seed2=i, seed3=i).call()
        sum += result.result.bits

    print(sum/loop_iters)
    '''
    half_sqrt2 = await contract.half_sqrt2().call()
    print(half_sqrt2.result.half_sqrt)
    
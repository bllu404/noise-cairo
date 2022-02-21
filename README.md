# Perlin Noise in Cairo

## How to use
Add  `perlin_noise.cairo` and its dependency `Math64x61.cairo` to your project folder, and import `noise_custom` into your project as follows

```
from perlin_noise import noise_custom
```

Then define a new function with your desired parameters:
```
func my_noise{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x, y) -> (noise):
    let (noise) = noise_custom((x, y), 100, 69)
    return (noise)
end
```

## About the function
- `noise_custom` takes 3 parameters: `point`, `scale`, and `seed`. 

- `seed` can be any felt, and is used to randomize the noise function. 

- `point` is a tuple of two felts: `(felt, felt)`, and should NOT be in 64.61 format. Note that both `point[0]` and `point[1]` should be less than 2^64, as they are converted to 64.61 values and may overflow otherwise. 

- `scale` should be a regular (i.e., not in 64.61 format) unsigned felt. `scale` determines the side lengths of the squares of the grid used to in the noise function. Practically speaking, the larger `scale` is, the more 'slowly' the noise function varies, and the smaller it is, the faster the noise function varies. So if `scale` is very large, the difference between `noise(x,y)` and `noise(x, y+1)` would very small, and if `scale` is very small the difference between them would be larger.

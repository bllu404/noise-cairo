# Noise in Cairo

## 2D Perlin Noise - How To Use
Add  `perlin2D.cairo` and [its dependency](https://github.com/influenceth/cairo-math-64x61/blob/master/contracts/Math64x61.cairo) `Math64x61.cairo` to your project folder, and import `noise2D_custom` into your project as follows

```
from perlin2D import noise2D_custom
```

Then define a new function with your desired parameters:
```
func my_noise{pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x, y) -> (noise):
    let (noise) = noise2D_custom((x, y), 100, 69)
    return (noise)
end
```

## About `noise2D_custom`
- `noise2D_custom` takes 3 parameters: `point`, `scale`, and `seed`. 

- `seed` can be any felt, and is used to randomize the noise function. 

- `point` is a tuple of two felts: `(felt, felt)`, and should NOT be in 64.61 format. Note that both `point[0]` and `point[1]` should be less than 2^64, as they are converted to 64.61 values and may overflow otherwise. 

- `scale` should be a regular (i.e., not in 64.61 format) unsigned felt. `scale` determines the side lengths of the squares of the grid used to in the noise function. Practically speaking, the larger `scale` is, the more 'slowly' the noise function varies, and the smaller it is, the faster the noise function varies. So if `scale` is very large, the difference between `noise(x,y)` and `noise(x, y+1)` would very small, and if `scale` is very small the difference between them would be larger.

- This noise function currently outputs values approximately in the range [-0.707106, 0.707106]. This can easily be normalized to a range of [-1, 1] by multiplying the final output by sqrt(2), or ~1.41421, but this is not done in the function itself for efficiency. 

<br>
<hr>
<br>

# 3D Simplex Noise - How to use
Add  `simplex3D.cairo` and [its dependency](https://github.com/influenceth/cairo-math-64x61/blob/master/contracts/Math64x61.cairo) `Math64x61.cairo` to your project folder, and import `noise3D_custom` into your project as follows:

```
from simplex3D import noise3D_custom
```

Then define a new function with your desired parameters:

```
func my_noise{range_check_ptr}(x, y, z) -> (noise):
    let (noise) = noise3D_custom(x,y,z, 100, 69)
    return (noise)
end
```

<br>

# About `noise3D_custom`
- `noise3D_custom` takes 5 parameters: the coordinate of a point – `x`, `y`, `z`, a scale factor `scale`, and a seed `seed`
- `x`, `y` and `z` should all be less than 2^64, as they are converted to 64.61 bit values and may overflow otherwise. Their upper bound may need to be even less than 2^64, depending on the scale factor you choose. They can be signed (and should be greater than -2^64 in this case).

- `scale` behaves exactly the same as in `noise2D_custom`.

- `seed` behaves exactly the same as in `noise2D_custom`

- noise3D_custom outputs values between -1 and 1, in 64.61 format. 



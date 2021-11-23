enum {
    INTER_BITS = 5,
    INTER_TAB_SIZE = 1 << INTER_BITS
};

__constant float coeffs[64] = {
    1.000000f, 0.000000f, 0.968750f, 0.031250f, 0.937500f, 0.062500f, 0.906250f, 0.093750f, 0.875000f, 0.125000f, 0.843750f, 0.156250f,
    0.812500f, 0.187500f, 0.781250f, 0.218750f, 0.750000f, 0.250000f, 0.718750f, 0.281250f, 0.687500f, 0.312500f, 0.656250f, 0.343750f,
    0.625000f, 0.375000f, 0.593750f, 0.406250f, 0.562500f, 0.437500f, 0.531250f, 0.468750f, 0.500000f, 0.500000f, 0.468750f, 0.531250f,
    0.437500f, 0.562500f, 0.406250f, 0.593750f, 0.375000f, 0.625000f, 0.343750f, 0.656250f, 0.312500f, 0.687500f, 0.281250f, 0.718750f,
    0.250000f, 0.750000f, 0.218750f, 0.781250f, 0.187500f, 0.812500f, 0.156250f, 0.843750f, 0.125000f, 0.875000f, 0.093750f, 0.906250f,
    0.062500f, 0.937500f, 0.031250f, 0.968750f
};
/*
float2 distort_back(float2 point, float2 f, float2 c, float4 k) {
    // To relative coordinates
    float x = (point.x - c.x) / f.x;
    float y = (point.y - c.y) / f.y;

    float r2 = x*x + y*y;

    float k1 = k.x;
    float k2 = k.y;
    float p1 = k.z;
    float p2 = k.w;

    // Radial distorsion
    float xDistort = x * (1.0 + k1 * r2 + k2 * r2 * r2);
    float yDistort = y * (1.0 + k1 * r2 + k2 * r2 * r2);

    // Tangential distorsion
    xDistort = xDistort + (2.0 * p1 * x * y + p2 * (r2 + 2.0 * x * x));
    yDistort = yDistort + (p1 * (r2 + 2.0 * y * y) + 2.0 * p2 * x * y);

    // Back to absolute coordinates.
    xDistort = xDistort * f.x + c.x;
    yDistort = yDistort * f.y + c.y;

    return (float2)(xDistort, yDistort);
}*/

__kernel void undistort_image(__global const DATA_TYPE *srcptr, __global DATA_TYPE *dstptr, ushort width, ushort height, ushort stride, __global const float *undistortion_params, ushort params_count, DATA_TYPEF bg) {
    int x = get_global_id(0);
    int y = get_global_id(1);

    float2 f = vload2(0, &undistortion_params[0]);
    float2 c = vload2(0, &undistortion_params[2]);
    float4 k = vload4(0, &undistortion_params[4]);

    if (x < width && y < height) {
        __global const float *params = &undistortion_params[min((y + 1), params_count - 1) * 9];

        float _x = y * params[1] + params[2] + (x * params[0]);
        float _y = y * params[4] + params[5] + (x * params[3]);
        float _w = y * params[7] + params[8] + (x * params[6]);

        if (_w > 0) {

            float2 pos = (float2)(_x, _y) / _w;

            float r = length(pos);
            /*if (r > 3.0) { // TODO check this
                dstptr[x + y*width] = convert_uchar4(bg);
                return;
            }*/
            float theta = atan(r);

            float theta2 = theta*theta, theta4 = theta2*theta2, theta6 = theta4*theta2, theta8 = theta4*theta4;

            float theta_d = theta * (1.0 + dot(k, (float4)(theta2, theta4, theta6, theta8)));

            float scale = r == 0? 1.0 : theta_d / r;
            float2 uv = f * pos * scale + c;
            
            int sx = convert_int_sat_rtz(0.5f + uv.x * INTER_TAB_SIZE) >> INTER_BITS;
            int sy = convert_int_sat_rtz(0.5f + uv.y * INTER_TAB_SIZE) >> INTER_BITS;

            __constant float *coeffs_x = &coeffs[((convert_int_rte(uv.x * INTER_TAB_SIZE) & (INTER_TAB_SIZE - 1)) << 1)];
            __constant float *coeffs_y = &coeffs[((convert_int_rte(uv.y * INTER_TAB_SIZE) & (INTER_TAB_SIZE - 1)) << 1)];

            DATA_TYPEF sum = 0;
            int src_index = sy * stride + sx;

            #pragma unroll
            for (int yp = 0; yp < 2; ++yp) {
                if (sy + yp >= 0 && sy + yp < height) {
                    DATA_TYPEF xsum = ((sx + 0 >= 0 && sx + 0 < width? DATA_CONVERTF(srcptr[src_index + 0]) : bg) * coeffs_x[0]) + 
                                      ((sx + 1 >= 0 && sx + 1 < width? DATA_CONVERTF(srcptr[src_index + 1]) : bg) * coeffs_x[1]);
                    sum += xsum * coeffs_y[yp];
                } else {
                    sum += bg * coeffs_y[yp];
                }
                src_index += stride;
            }

            dstptr[x + y*stride] = DATA_CONVERT(sum);
        } else {
            dstptr[x + y*stride] = DATA_CONVERT(bg);
        }
    }
}
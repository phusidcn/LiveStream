//
//  LowContract.metal
//  LiveStream
//
//  Created by Thang on 3/10/2019.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void lowContract(texture2d<half, access::read>  inputTexture  [[ texture(0) ]],
                       texture2d<half, access::write> outputTexture [[ texture(1) ]],
                       uint2 gid [[thread_position_in_grid]])
{
    // Don't read or write outside of the texture.
    if ((gid.x >= inputTexture.get_width()) || (gid.y >= inputTexture.get_height())) {
        return;
    }
    
    half4 inputColor = inputTexture.read(gid);
    
    // Set the output color to the input color, excluding the green component.
    half4 outputColor = half4(inputColor.rgb - half3(0.5)*0.1 + half3(0.5), inputColor.a);
    
    outputTexture.write(outputColor, gid);
}

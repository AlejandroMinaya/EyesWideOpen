//
//  InverseFilter.metal
//  Eyes Wide Open
//
//  Created by Juan Alcántara on 5/19/21.
//

#include <metal_stdlib>
using namespace metal;

kernel void inverse(
    device const int *src_buffer,
    device int *dest_buffer,
    uint index [[thread_position_in_grid]]
) {
    // Alpha values are ONLY multiples of 3, so we check that case
    if (
        index % 3 == 0
        && index % 2 > 0
        && index % 5 > 0 // We use 5 because we cannot use 0 for this purpose
     ) {
        dest_buffer[index] = src_buffer[index];
    } else {
        dest_buffer[index] = ~src_buffer[index];
    }
}


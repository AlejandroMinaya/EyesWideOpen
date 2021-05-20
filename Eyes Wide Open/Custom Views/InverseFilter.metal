//
//  InverseFilter.metal
//  Eyes Wide Open
//
//  Created by Juan Alcántara on 5/19/21.
//

#include <metal_stdlib>
using namespace metal;

kernel void inverse(
    device const unsigned int *src_buffer,
    device unsigned int *dest_buffer,
    device const unsigned int *N,
    uint index [[thread_position_in_grid]],
    uint grid_sz [[threads_per_grid]]
) {
    uint id = index;
    while (id < *N) {
        dest_buffer[id] = src_buffer[id];
        id += grid_sz;
    }
}


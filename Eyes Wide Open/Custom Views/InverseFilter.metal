//
//  InverseFilter.metal
//  Eyes Wide Open
//
//  Created by Juan Alcántara on 5/19/21.
//

#include <metal_stdlib>
using namespace metal;

kernel void inverse(
    device const uint8_t *src_buffer,
    device uint8_t *dest_buffer,
    device const unsigned int *N,
    uint index [[thread_position_in_grid]],
    uint grid_sz [[threads_per_grid]]
) {
    uint id = index;
    while (id < *N) {
        if (id % 4 < 3) {
            dest_buffer[id] = ~src_buffer[id];
        } else {
            dest_buffer[id] = src_buffer[id];
        }
        id += grid_sz;
    }
    return;
}


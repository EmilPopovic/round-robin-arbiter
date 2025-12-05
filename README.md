# Round-Robin Arbiter

A parameterizable round-robin bus arbiter implemented in SystemVerilog. The arbiter grants access to requesting ports in a fair, rotating manner while supporting grant holding for active requests.

## Features

- **Parameterizable port count** - Configure any number of ports via `PORTS` parameter
- **Zero-cycle or registered output** - Choose between combinational (`ZERO_CYCLE=1`) or registered (`ZERO_CYCLE=0`) grant output
- **Grant holding** - Maintains grant to a port while its request remains active
- **Fair arbitration** - Rotates priority starting from the last granted port

## Module Interface

```systemverilog
module round_robin_arbiter #(
    parameter PORTS = 2,      // Number of requesting ports
    parameter ZERO_CYCLE = 1  // 1: combinational output, 0: registered output
)(
    input  logic i_clk,                  // Clock
    input  logic i_rstn,                 // Active-low reset
    input  logic [PORTS-1:0] i_req_vec,  // Request vector
    output logic [PORTS-1:0] o_grant_vec // Grant vector (one-hot)
);
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `PORTS` | 2 | Number of ports competing for access |
| `ZERO_CYCLE` | 1 | When 1, grant updates combinationally; when 0, grant is registered |

## Behavior

1. **Idle**: When no requests are active, `o_grant_vec` is `0`
2. **Grant**: When requests are present, exactly one port is granted
3. **Hold**: If the currently granted port still has its request active, it retains the grant
4. **Rotate**: When the granted port releases its request, the next requesting port (in round-robin order) receives the grant

## Architecture

The arbiter uses a masked priority encoder that pivots around the last granted index:

```text
round_robin_arbiter
├── masked_priority_encoder
│   ├── priority_encoder (left half)
│   └── priority_encoder (right half)
```

The masked encoder splits the request vector at the pivot point and prioritizes requests after the current grant, wrapping around to earlier indices if none are found.

## File Structure

```text
├── rtl/
│   ├── round_robin_arbiter.sv      # Top-level arbiter
│   ├── masked_priority_encoder.sv  # Encoder with pivot support
│   └── priority_encoder.sv         # Basic priority encoder
├── sim/
│   └── tb_round_robin_arbiter.sv   # Testbench
└── scripts/
    └── create_project.tcl          # Vivado project script
```

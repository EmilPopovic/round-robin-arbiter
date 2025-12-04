module round_robin_arbiter #(
    parameter PORTS=2
)(
    input  logic             i_clk,
    input  logic             i_rstn,
    input  logic [PORTS-1:0] i_req,
    output logic [PORTS-1:0] o_grant
);

typedef enum logic {
    S_IDLE  = 1'b0,
    S_GRANT = 1'b1
} state_e;

state_e r_state;
state_e w_next_state;

logic [$clog2(PORTS)-1:0] r_grant_vec;
logic [$clog2(PORTS)-1:0] w_idx;
logic [$clog2(PORTS)-1:0] w_next_grant_idx;
logic w_next_valid;
logic w_switch_master;

masked_priority_encoder #(PORTS, 1) masked_encoder (
    .i_vec   (i_req),
    .i_idx   (w_idx),
    .o_idx   (w_next_grant_idx),
    .o_valid (w_next_valid)
);

always_ff @(posedge i_clk) begin
    if (!i_rstn) begin
        r_state     <= S_IDLE;
        r_grant_vec <= '0;
    end

    else begin
        r_state <= w_next_state;

        if (r_state == S_IDLE && w_next_valid || r_state == S_GRANT && w_switch_master)
            r_grant_vec <= PORTS'(1) << w_next_grant_idx;
        else
            r_grant_vec <= '0;
    end
end

always_comb begin
    w_next_state    = r_state;
    w_switch_master = 0;

    unique case (r_state)

        S_IDLE: begin
            w_next_state = (w_next_valid) ? S_GRANT : S_IDLE;
        end

        S_GRANT: begin

        end
    endcase
end

endmodule

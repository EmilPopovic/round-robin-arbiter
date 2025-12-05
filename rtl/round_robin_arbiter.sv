module round_robin_arbiter #(
    parameter PORTS=2
)(
    input  logic             i_clk,
    input  logic             i_rstn,
    input  logic [PORTS-1:0] i_req_vec,
    output logic [PORTS-1:0] o_grant_vec
);

logic r_has_grant;
logic [$clog2(PORTS)-1:0] r_grant_idx;
logic [$clog2(PORTS)-1:0] w_next_grant_idx;
logic w_has_req;

masked_priority_encoder #(PORTS, 1) masked_encoder (
    .i_vec   (i_req_vec),
    .i_idx   (r_grant_idx),
    .o_idx   (w_next_grant_idx),
    .o_valid (w_has_req)
);

always_ff @(posedge i_clk) begin
    if (!i_rstn) begin
        r_has_grant <= 0;
        r_grant_idx <= '0;
        o_grant_vec <= '0;
    end

    else begin
        r_has_grant <= w_has_req;

        // Grant a new master if there is a request and either of the following is true:
        // a) No master is currently granted
        // b) The currently granted master has released request
        if ((!r_has_grant || r_has_grant && i_req_vec[r_grant_idx]) && w_has_req) begin
            r_grant_idx <= w_next_grant_idx;
            o_grant_vec <= PORTS'(1) << w_next_grant_idx;
        end
        
        else begin
            r_grant_idx <= '0;
            o_grant_vec <= '0;
        end
    end
end

endmodule

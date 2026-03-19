/* Leonard Yan, 62737249 */

`timescale 1ns / 1ns

typedef struct packed {
    logic [31:0] dividend;
    logic [31:0] divisor;
    logic [31:0] remainder;
    logic [31:0] quotient;
} stage_t;

module DividerUnsignedPipelined (
    input  wire        clk, 
    input  wire        rst, 
    input  wire        stall,
    input  wire [31:0] i_dividend,
    input  wire [31:0] i_divisor,
    output logic [31:0] o_remainder,
    output logic [31:0] o_quotient
);

    stage_t stage[9];

    assign stage[0].dividend  = i_dividend;
    assign stage[0].divisor   = i_divisor; 
    assign stage[0].remainder = 32'b0;
    assign stage[0].quotient  = 32'b0;

    genvar s;
    generate
    for (s = 0; s < 8; s++) begin : stage_block

        wire [31:0] d1, d2, d3, d4;
        wire [31:0] r1, r2, r3, r4;
        wire [31:0] q1, q2, q3, q4;

        DividerOneIter i0(stage[s].dividend, stage[s].divisor, stage[s].remainder, stage[s].quotient, d1, r1, q1);
        DividerOneIter i1(d1, stage[s].divisor, r1, q1, d2, r2, q2);
        DividerOneIter i2(d2, stage[s].divisor, r2, q2, d3, r3, q3);
        DividerOneIter i3(d3, stage[s].divisor, r3, q3, d4, r4, q4);

        always_ff @(posedge clk) begin
            if (rst) begin
                stage[s+1] <= '0;
            end else if (!stall) begin 
                stage[s+1].dividend  <= d4;
                stage[s+1].divisor   <= stage[s].divisor; 
                stage[s+1].remainder <= r4;
                stage[s+1].quotient  <= q4;
            end
        end

    end
    endgenerate

    assign o_remainder = stage_block[7].r4;
    assign o_quotient  = stage_block[7].q4;

endmodule

module DividerOneIter (
    input  wire [31:0] i_dividend,
    input  wire [31:0] i_divisor,
    input  wire [31:0] i_remainder,
    input  wire [31:0] i_quotient,
    output wire [31:0] o_dividend,
    output wire [31:0] o_remainder,
    output wire [31:0] o_quotient
);

    logic [31:0] r_shift;
    logic        lt;
    logic [31:0] q0, q1;
    logic [31:0] r_sub;

    assign r_shift = {i_remainder[30:0], i_dividend[31]};
    assign lt      = (r_shift < i_divisor);

    assign q0    = {i_quotient[30:0], 1'b0};
    assign q1    = {i_quotient[30:0], 1'b1};
    assign r_sub = r_shift - i_divisor;

    assign o_quotient  = lt ? q0 : q1;
    assign o_remainder = lt ? r_shift : r_sub;
    assign o_dividend  = {i_dividend[30:0], 1'b0};

endmodule

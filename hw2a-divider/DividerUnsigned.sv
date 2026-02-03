/* Leonard Yan, 62737249 */

`timescale 1ns / 1ns

// quotient = dividend / divisor

module DividerUnsigned (
    input  wire [31:0] i_dividend,
    input  wire [31:0] i_divisor,
    output wire [31:0] o_remainder,
    output wire [31:0] o_quotient
);

    wire [31:0] dvd[33];
    wire [31:0] rem[33];
    wire [31:0] quo[33];

    assign dvd[0] = i_dividend;
    assign rem[0] = 32'b0;
    assign quo[0] = 32'b0;

    genvar i;
    for (i = 0; i < 32; i = i + 1) begin
            DividerOneIter f(.i_dividend(dvd[i]), .i_divisor(i_divisor), .i_remainder(rem[i]), .i_quotient(quo[i]),
                .o_dividend(dvd[i+1]), .o_remainder(rem[i+1]), .o_quotient(quo[i+1])
            );
    end

    assign o_remainder = rem[32];
    assign o_quotient  = quo[32];

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
  /*
    for (int i = 0; i < 32; i++) {
        remainder = (remainder << 1) | ((dividend >> 31) & 0x1);
        if (remainder < divisor) {
            quotient = (quotient << 1);
        } else {
            quotient = (quotient << 1) | 0x1;
            remainder = remainder - divisor;
        }
        dividend = dividend << 1;
    }
    */

    logic [31:0] r_shift;
    logic lt;
    logic [31:0] q0, q1;
    logic [31:0] r_sub;

    assign r_shift = {i_remainder[30:0], i_dividend[31]};
    assign lt = (r_shift < i_divisor);

    assign q0 = {i_quotient[30:0], 1'b0};
    assign q1 = {i_quotient[30:0], 1'b1};
    assign r_sub = r_shift - i_divisor;

    assign o_quotient = lt ? q0 : q1;
    assign o_remainder = lt ? r_shift : r_sub;
    assign o_dividend = {i_dividend[30:0], 1'b0};

endmodule

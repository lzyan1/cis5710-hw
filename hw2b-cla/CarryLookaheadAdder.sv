`timescale 1ns / 1ps

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits internally would generate a carry-out (independent of cin)
 * @param pout whether these 4 bits internally would propagate an incoming carry from cin
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);

   assign cout[0] = gin[0] | (pin[0] & cin);
   assign cout[1] = gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)));
   assign cout[2] = gin[2] | (pin[2] & (gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)))));

   assign pout = pin[0] & pin[1] & pin[2] & pin[3];
   assign gout = gin[3] | (gin[2] & pin[3]) | (gin[1] & pin[2] & pin[3]) | (gin[0] & pin[1] & pin[2] & pin[3]);

endmodule

/** Same as gp4 but for an 8-bit window instead */
module gp8(input wire [7:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [6:0] cout);

   assign cout[0] = gin[0] | (pin[0] & cin);
   assign cout[1] = gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)));
   assign cout[2] = gin[2] | (pin[2] & (gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)))));
   assign cout[3] = gin[3] | (pin[3] & (gin[2] | (pin[2] & (gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)))))));
   assign cout[4] = gin[4] | (pin[4] & (gin[3] | (pin[3] & (gin[2] | (pin[2] & (gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)))))))));
   assign cout[5] = gin[5] | (pin[5] & (gin[4] | (pin[4] & (gin[3] | (pin[3] & (gin[2] | (pin[2] & (gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)))))))))));
   assign cout[6] = gin[6] | (pin[6] & (gin[5] | (pin[5] & (gin[4] | (pin[4] & (gin[3] | (pin[3] & (gin[2] | (pin[2] & (gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)))))))))))));

   assign pout = &pin;
   assign gout = gin[7]
               | (pin[7] & gin[6])
               | (pin[7] & pin[6] & gin[5])
               | (pin[7] & pin[6] & pin[5] & gin[4])
               | (pin[7] & pin[6] & pin[5] & pin[4] & gin[3])
               | (pin[7] & pin[6] & pin[5] & pin[4] & pin[3] & gin[2])
               | (pin[7] & pin[6] & pin[5] & pin[4] & pin[3] & pin[2] & gin[1])
               | (pin[7] & pin[6] & pin[5] & pin[4] & pin[3] & pin[2] & pin[1] & gin[0]);

endmodule

module CarryLookaheadAdder
  (input wire [31:0]  a, b,
   input wire         cin,
   output wire [31:0] sum);

   wire [31:0] g, p;

   genvar i;
   generate
      for (i = 0; i < 32; i = i + 1) begin : GEN_GP1
         gp1 u_gp1(.a(a[i]), .b(b[i]), .g(g[i]), .p(p[i]));
      end
   endgenerate

   wire [7:0] g4, p4;
   wire [2:0] cout4 [7:0];

   wire [7:0] c4;
   assign c4[0] = cin;

   wire [6:0] c4_between; 
   wire gout32, pout32;

   gp8 u_gp8_blocks(.gin(g4), .pin(p4), .cin(cin), .gout(gout32), .pout(pout32), .cout(c4_between));

   genvar bi;
   generate
      for (bi = 1; bi < 8; bi = bi + 1) begin : GEN_BLOCK_CIN
         assign c4[bi] = c4_between[bi-1];
      end
   endgenerate

   genvar k;
   generate
      for (k = 0; k < 8; k = k + 1) begin : GEN_GP4
         gp4 u_gp4(
            .gin(g[4*k + 3 : 4*k]),
            .pin(p[4*k + 3 : 4*k]),
            .cin(c4[k]),
            .gout(g4[k]),
            .pout(p4[k]),
            .cout(cout4[k])
         );
      end
   endgenerate

   wire [31:0] cbit;
   assign cbit[0] = cin;

   generate
      for (k = 0; k < 8; k = k + 1) begin : GEN_BIT_CARRIES
         if (k == 0) begin : GEN_NIB0
            assign cbit[1] = cout4[0][0];
            assign cbit[2] = cout4[0][1];
            assign cbit[3] = cout4[0][2];
         end else begin : GEN_NIBK
            assign cbit[4*k + 0] = c4[k];
            assign cbit[4*k + 1] = cout4[k][0];
            assign cbit[4*k + 2] = cout4[k][1];
            assign cbit[4*k + 3] = cout4[k][2];
         end
      end
   endgenerate

   generate
      for (i = 0; i < 32; i = i + 1) begin : GEN_SUM
         assign sum[i] = a[i] ^ b[i] ^ cbit[i];
      end
   endgenerate

endmodule

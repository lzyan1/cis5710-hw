module gp1 (
	a,
	b,
	g,
	p
);
	input wire a;
	input wire b;
	output wire g;
	output wire p;
	assign g = a & b;
	assign p = a | b;
endmodule
module gp4 (
	gin,
	pin,
	cin,
	gout,
	pout,
	cout
);
	input wire [3:0] gin;
	input wire [3:0] pin;
	input wire cin;
	output wire gout;
	output wire pout;
	output wire [2:0] cout;
	assign cout[0] = gin[0] | (pin[0] & cin);
	assign cout[1] = gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)));
	assign cout[2] = gin[2] | (pin[2] & (gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)))));
	assign pout = ((pin[0] & pin[1]) & pin[2]) & pin[3];
	assign gout = ((gin[3] | (gin[2] & pin[3])) | ((gin[1] & pin[2]) & pin[3])) | (((gin[0] & pin[1]) & pin[2]) & pin[3]);
endmodule
module gp8 (
	gin,
	pin,
	cin,
	gout,
	pout,
	cout
);
	input wire [7:0] gin;
	input wire [7:0] pin;
	input wire cin;
	output wire gout;
	output wire pout;
	output wire [6:0] cout;
	assign cout[0] = gin[0] | (pin[0] & cin);
	assign cout[1] = gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)));
	assign cout[2] = gin[2] | (pin[2] & (gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)))));
	assign cout[3] = gin[3] | (pin[3] & (gin[2] | (pin[2] & (gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)))))));
	assign cout[4] = gin[4] | (pin[4] & (gin[3] | (pin[3] & (gin[2] | (pin[2] & (gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)))))))));
	assign cout[5] = gin[5] | (pin[5] & (gin[4] | (pin[4] & (gin[3] | (pin[3] & (gin[2] | (pin[2] & (gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)))))))))));
	assign cout[6] = gin[6] | (pin[6] & (gin[5] | (pin[5] & (gin[4] | (pin[4] & (gin[3] | (pin[3] & (gin[2] | (pin[2] & (gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)))))))))))));
	assign pout = &pin;
	assign gout = ((((((gin[7] | (pin[7] & gin[6])) | ((pin[7] & pin[6]) & gin[5])) | (((pin[7] & pin[6]) & pin[5]) & gin[4])) | ((((pin[7] & pin[6]) & pin[5]) & pin[4]) & gin[3])) | (((((pin[7] & pin[6]) & pin[5]) & pin[4]) & pin[3]) & gin[2])) | ((((((pin[7] & pin[6]) & pin[5]) & pin[4]) & pin[3]) & pin[2]) & gin[1])) | (((((((pin[7] & pin[6]) & pin[5]) & pin[4]) & pin[3]) & pin[2]) & pin[1]) & gin[0]);
endmodule
module CarryLookaheadAdder (
	a,
	b,
	cin,
	sum
);
	input wire [31:0] a;
	input wire [31:0] b;
	input wire cin;
	output wire [31:0] sum;
	wire [31:0] g;
	wire [31:0] p;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < 32; _gv_i_1 = _gv_i_1 + 1) begin : GEN_GP1
			localparam i = _gv_i_1;
			gp1 u_gp1(
				.a(a[i]),
				.b(b[i]),
				.g(g[i]),
				.p(p[i])
			);
		end
	endgenerate
	wire [7:0] g4;
	wire [7:0] p4;
	wire [2:0] cout4 [7:0];
	wire [7:0] c4;
	assign c4[0] = cin;
	wire [6:0] c4_between;
	wire gout32;
	wire pout32;
	gp8 u_gp8_blocks(
		.gin(g4),
		.pin(p4),
		.cin(cin),
		.gout(gout32),
		.pout(pout32),
		.cout(c4_between)
	);
	genvar _gv_bi_1;
	generate
		for (_gv_bi_1 = 1; _gv_bi_1 < 8; _gv_bi_1 = _gv_bi_1 + 1) begin : GEN_BLOCK_CIN
			localparam bi = _gv_bi_1;
			assign c4[bi] = c4_between[bi - 1];
		end
	endgenerate
	genvar _gv_k_1;
	generate
		for (_gv_k_1 = 0; _gv_k_1 < 8; _gv_k_1 = _gv_k_1 + 1) begin : GEN_GP4
			localparam k = _gv_k_1;
			gp4 u_gp4(
				.gin(g[(4 * k) + 3:4 * k]),
				.pin(p[(4 * k) + 3:4 * k]),
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
		for (_gv_k_1 = 0; _gv_k_1 < 8; _gv_k_1 = _gv_k_1 + 1) begin : GEN_BIT_CARRIES
			localparam k = _gv_k_1;
			if (k == 0) begin : GEN_NIB0
				assign cbit[1] = cout4[0][0];
				assign cbit[2] = cout4[0][1];
				assign cbit[3] = cout4[0][2];
			end
			else begin : GEN_NIBK
				assign cbit[(4 * k) + 0] = c4[k];
				assign cbit[(4 * k) + 1] = cout4[k][0];
				assign cbit[(4 * k) + 2] = cout4[k][1];
				assign cbit[(4 * k) + 3] = cout4[k][2];
			end
		end
		for (_gv_i_1 = 0; _gv_i_1 < 32; _gv_i_1 = _gv_i_1 + 1) begin : GEN_SUM
			localparam i = _gv_i_1;
			assign sum[i] = (a[i] ^ b[i]) ^ cbit[i];
		end
	endgenerate
endmodule
module SystemDemo (
	external_clk_25MHz,
	btn,
	led
);
	reg _sv2v_0;
	input wire external_clk_25MHz;
	input wire [6:0] btn;
	output reg [7:0] led;
	reg [31:0] ab;
	wire [15:0] a;
	wire [15:0] b;
	wire [31:0] expected_sum;
	wire [31:0] actual_sum;
	wire rst = ~btn[0];
	reg error;
	wire [2:0] chunk = ab[31:29];
	reg [7:0] completed;
	CarryLookaheadAdder cla_inst(
		.a(a),
		.b(b),
		.cin(1'b0),
		.sum(actual_sum)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		a = ab[31:16];
		b = ab[15:0];
		expected_sum = a + b;
	end
	always @(posedge external_clk_25MHz)
		if (rst) begin
			ab <= 32'd0;
			error <= 1'b0;
			completed <= 8'd0;
		end
		else if (!error) begin
			if (actual_sum != expected_sum)
				error <= 1'b1;
			else begin
				ab <= ab + 1;
				if (ab[28:0] == 29'h1fffffff)
					completed[chunk] <= 1'b1;
			end
		end
	reg [23:0] blink;
	always @(posedge external_clk_25MHz)
		if (rst)
			blink <= 0;
		else
			blink <= blink + 1;
	always @(*) begin
		if (_sv2v_0)
			;
		if (error)
			led = completed;
		else
			led = completed | ({7'd0, blink[23]} << chunk);
	end
	initial _sv2v_0 = 0;
endmodule
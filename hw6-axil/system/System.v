`default_nettype none
module MyClockGen (
	input_clk_25MHz,
	clk_125MHz,
	clk_25MHz,
	clk_proc,
	locked
);
	input input_clk_25MHz;
	output wire clk_125MHz;
	output wire clk_25MHz;
	output wire clk_proc;
	output wire locked;
	wire clkfb;
	(* FREQUENCY_PIN_CLKI = "25" *) (* FREQUENCY_PIN_CLKOP = "125" *) (* FREQUENCY_PIN_CLKOS = "25" *) (* FREQUENCY_PIN_CLKOS2 = "20.1613" *) (* ICP_CURRENT = "12" *) (* LPF_RESISTOR = "8" *) (* MFG_ENABLE_FILTEROPAMP = "1" *) (* MFG_GMCREF_SEL = "2" *) EHXPLLL #(
		.PLLRST_ENA("DISABLED"),
		.INTFB_WAKE("DISABLED"),
		.STDBY_ENABLE("DISABLED"),
		.DPHASE_SOURCE("DISABLED"),
		.OUTDIVIDER_MUXA("DIVA"),
		.OUTDIVIDER_MUXB("DIVB"),
		.OUTDIVIDER_MUXC("DIVC"),
		.OUTDIVIDER_MUXD("DIVD"),
		.CLKI_DIV(1),
		.CLKOP_ENABLE("ENABLED"),
		.CLKOP_DIV(5),
		.CLKOP_CPHASE(2),
		.CLKOP_FPHASE(0),
		.CLKOS_ENABLE("ENABLED"),
		.CLKOS_DIV(25),
		.CLKOS_CPHASE(2),
		.CLKOS_FPHASE(0),
		.CLKOS2_ENABLE("ENABLED"),
		.CLKOS2_DIV(31),
		.CLKOS2_CPHASE(2),
		.CLKOS2_FPHASE(0),
		.FEEDBK_PATH("INT_OP"),
		.CLKFB_DIV(5)
	) pll_i(
		.RST(1'b0),
		.STDBY(1'b0),
		.CLKI(input_clk_25MHz),
		.CLKOP(clk_125MHz),
		.CLKOS(clk_25MHz),
		.CLKOS2(clk_proc),
		.CLKFB(clkfb),
		.CLKINTFB(clkfb),
		.PHASESEL0(1'b0),
		.PHASESEL1(1'b0),
		.PHASEDIR(1'b1),
		.PHASESTEP(1'b1),
		.PHASELOADREG(1'b1),
		.PLLWAKESYNC(1'b0),
		.ENCLKOP(1'b0),
		.LOCK(locked)
	);
endmodule
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
module DividerUnsignedPipelined (
	clk,
	rst,
	stall,
	i_dividend,
	i_divisor,
	o_remainder,
	o_quotient
);
	input wire clk;
	input wire rst;
	input wire stall;
	input wire [31:0] i_dividend;
	input wire [31:0] i_divisor;
	output wire [31:0] o_remainder;
	output wire [31:0] o_quotient;
	reg [127:0] stage [0:8];
	wire [32:1] sv2v_tmp_6804F;
	assign sv2v_tmp_6804F = i_dividend;
	always @(*) stage[0][127-:32] = sv2v_tmp_6804F;
	wire [32:1] sv2v_tmp_13CA0;
	assign sv2v_tmp_13CA0 = i_divisor;
	always @(*) stage[0][95-:32] = sv2v_tmp_13CA0;
	wire [32:1] sv2v_tmp_A6EAC;
	assign sv2v_tmp_A6EAC = 32'b00000000000000000000000000000000;
	always @(*) stage[0][63-:32] = sv2v_tmp_A6EAC;
	wire [32:1] sv2v_tmp_ECDDB;
	assign sv2v_tmp_ECDDB = 32'b00000000000000000000000000000000;
	always @(*) stage[0][31-:32] = sv2v_tmp_ECDDB;
	genvar _gv_s_1;
	generate
		for (_gv_s_1 = 0; _gv_s_1 < 8; _gv_s_1 = _gv_s_1 + 1) begin : stage_block
			localparam s = _gv_s_1;
			wire [31:0] d1;
			wire [31:0] d2;
			wire [31:0] d3;
			wire [31:0] d4;
			wire [31:0] r1;
			wire [31:0] r2;
			wire [31:0] r3;
			wire [31:0] r4;
			wire [31:0] q1;
			wire [31:0] q2;
			wire [31:0] q3;
			wire [31:0] q4;
			DividerOneIter i0(
				.i_dividend(stage[s][127-:32]),
				.i_divisor(stage[s][95-:32]),
				.i_remainder(stage[s][63-:32]),
				.i_quotient(stage[s][31-:32]),
				.o_dividend(d1),
				.o_remainder(r1),
				.o_quotient(q1)
			);
			DividerOneIter i1(
				.i_dividend(d1),
				.i_divisor(stage[s][95-:32]),
				.i_remainder(r1),
				.i_quotient(q1),
				.o_dividend(d2),
				.o_remainder(r2),
				.o_quotient(q2)
			);
			DividerOneIter i2(
				.i_dividend(d2),
				.i_divisor(stage[s][95-:32]),
				.i_remainder(r2),
				.i_quotient(q2),
				.o_dividend(d3),
				.o_remainder(r3),
				.o_quotient(q3)
			);
			DividerOneIter i3(
				.i_dividend(d3),
				.i_divisor(stage[s][95-:32]),
				.i_remainder(r3),
				.i_quotient(q3),
				.o_dividend(d4),
				.o_remainder(r4),
				.o_quotient(q4)
			);
			always @(posedge clk)
				if (rst)
					stage[s + 1] <= 1'sb0;
				else if (!stall) begin
					stage[s + 1][127-:32] <= d4;
					stage[s + 1][95-:32] <= stage[s][95-:32];
					stage[s + 1][63-:32] <= r4;
					stage[s + 1][31-:32] <= q4;
				end
		end
	endgenerate
	assign o_remainder = stage_block[7].r4;
	assign o_quotient = stage_block[7].q4;
endmodule
module DividerOneIter (
	i_dividend,
	i_divisor,
	i_remainder,
	i_quotient,
	o_dividend,
	o_remainder,
	o_quotient
);
	input wire [31:0] i_dividend;
	input wire [31:0] i_divisor;
	input wire [31:0] i_remainder;
	input wire [31:0] i_quotient;
	output wire [31:0] o_dividend;
	output wire [31:0] o_remainder;
	output wire [31:0] o_quotient;
	wire [31:0] r_shift;
	wire lt;
	wire [31:0] q0;
	wire [31:0] q1;
	wire [31:0] r_sub;
	assign r_shift = {i_remainder[30:0], i_dividend[31]};
	assign lt = r_shift < i_divisor;
	assign q0 = {i_quotient[30:0], 1'b0};
	assign q1 = {i_quotient[30:0], 1'b1};
	assign r_sub = r_shift - i_divisor;
	assign o_quotient = (lt ? q0 : q1);
	assign o_remainder = (lt ? r_shift : r_sub);
	assign o_dividend = {i_dividend[30:0], 1'b0};
endmodule
`default_nettype none
`default_nettype none
module skidbuffer (
	i_clk,
	i_reset,
	i_valid,
	o_ready,
	i_data,
	o_valid,
	i_ready,
	o_data
);
	parameter [0:0] OPT_LOWPOWER = 0;
	parameter [0:0] OPT_OUTREG = 1;
	parameter [0:0] OPT_PASSTHROUGH = 0;
	parameter DW = 8;
	parameter [0:0] OPT_INITIAL = 1'b1;
	input wire i_clk;
	input wire i_reset;
	input wire i_valid;
	output wire o_ready;
	input wire [DW - 1:0] i_data;
	output wire o_valid;
	input wire i_ready;
	output reg [DW - 1:0] o_data;
	wire [DW - 1:0] w_data;
	generate
		if (OPT_PASSTHROUGH) begin : PASSTHROUGH
			assign {o_valid, o_ready} = {i_valid, i_ready};
			always @(*)
				if (!i_valid && OPT_LOWPOWER)
					o_data = 0;
				else
					o_data = i_data;
			assign w_data = 0;
			wire unused_passthrough;
			assign unused_passthrough = &{1'b0, i_clk, i_reset};
		end
		else begin : LOGIC
			reg r_valid;
			reg [DW - 1:0] r_data;
			initial if (OPT_INITIAL)
				r_valid = 0;
			always @(posedge i_clk)
				if (i_reset)
					r_valid <= 0;
				else if ((i_valid && o_ready) && (o_valid && !i_ready))
					r_valid <= 1;
				else if (i_ready)
					r_valid <= 0;
			initial if (OPT_INITIAL)
				r_data = 0;
			always @(posedge i_clk)
				if (OPT_LOWPOWER && i_reset)
					r_data <= 0;
				else if (OPT_LOWPOWER && (!o_valid || i_ready))
					r_data <= 0;
				else if (((!OPT_LOWPOWER || !OPT_OUTREG) || i_valid) && o_ready)
					r_data <= i_data;
			assign w_data = r_data;
			assign o_ready = !r_valid;
			if (!OPT_OUTREG) begin : NET_OUTPUT
				assign o_valid = !i_reset && (i_valid || r_valid);
				always @(*)
					if (r_valid)
						o_data = r_data;
					else if (!OPT_LOWPOWER || i_valid)
						o_data = i_data;
					else
						o_data = 0;
			end
			else begin : REG_OUTPUT
				reg ro_valid;
				initial if (OPT_INITIAL)
					ro_valid = 0;
				always @(posedge i_clk)
					if (i_reset)
						ro_valid <= 0;
					else if (!o_valid || i_ready)
						ro_valid <= i_valid || r_valid;
				assign o_valid = ro_valid;
				initial if (OPT_INITIAL)
					o_data = 0;
				always @(posedge i_clk)
					if (OPT_LOWPOWER && i_reset)
						o_data <= 0;
					else if (!o_valid || i_ready) begin
						if (r_valid)
							o_data <= r_data;
						else if (!OPT_LOWPOWER || i_valid)
							o_data <= i_data;
						else
							o_data <= 0;
					end
			end
		end
	endgenerate
	wire unused;
	assign unused = &{1'b0, w_data};
endmodule
module Disasm (
	insn,
	disasm
);
	parameter PREFIX = "D";
	input wire [31:0] insn;
	output wire [255:0] disasm;
endmodule
module RegFile (
	rd,
	rd_data,
	rs1,
	rs1_data,
	rs2,
	rs2_data,
	clk,
	we,
	rst
);
	reg _sv2v_0;
	input wire [4:0] rd;
	input wire [31:0] rd_data;
	input wire [4:0] rs1;
	output reg [31:0] rs1_data;
	input wire [4:0] rs2;
	output reg [31:0] rs2_data;
	input wire clk;
	input wire we;
	input wire rst;
	localparam signed [31:0] NumRegs = 32;
	reg [31:0] regs [0:31];
	always @(*) begin
		if (_sv2v_0)
			;
		if (rs1 == 5'd0)
			rs1_data = 32'd0;
		else if ((we && (rd == rs1)) && (rd != 5'd0))
			rs1_data = rd_data;
		else
			rs1_data = regs[rs1];
		if (rs2 == 5'd0)
			rs2_data = 32'd0;
		else if ((we && (rd == rs2)) && (rd != 5'd0))
			rs2_data = rd_data;
		else
			rs2_data = regs[rs2];
	end
	integer j;
	always @(posedge clk)
		if (rst)
			for (j = 0; j < NumRegs; j = j + 1)
				regs[j] <= 32'd0;
		else begin
			if (we && (rd != 5'd0))
				regs[rd] <= rd_data;
			regs[0] <= 32'd0;
		end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module SystemResourceCheck (
	external_clk_25MHz,
	btn,
	led
);
	input wire external_clk_25MHz;
	input wire [6:0] btn;
	output wire [7:0] led;
	wire clk;
	wire clk_locked;
	wire ignore0;
	wire ignore1;
	MyClockGen clock_gen(
		.input_clk_25MHz(external_clk_25MHz),
		.clk_125MHz(ignore0),
		.clk_25MHz(ignore1),
		.clk_proc(clk),
		.locked(clk_locked)
	);
	wire rst = !clk_locked;
	generate
		if (1) begin : axil_mem_ro
			localparam signed [31:0] ADDR_WIDTH = 32;
			localparam signed [31:0] DATA_WIDTH = 32;
			wire ARREADY;
			wire ARVALID;
			wire [31:0] ARADDR;
			wire [2:0] ARPROT;
			wire RREADY;
			wire RVALID;
			wire [31:0] RDATA;
			wire [1:0] RRESP;
			wire AWREADY;
			wire AWVALID;
			wire [31:0] AWADDR;
			wire [2:0] AWPROT;
			wire WREADY;
			wire WVALID;
			wire [31:0] WDATA;
			wire [3:0] WSTRB;
			wire BREADY;
			wire BVALID;
			wire [1:0] BRESP;
		end
		if (1) begin : axil_mem_rw
			localparam signed [31:0] ADDR_WIDTH = 32;
			localparam signed [31:0] DATA_WIDTH = 32;
			wire ARREADY;
			wire ARVALID;
			wire [31:0] ARADDR;
			wire [2:0] ARPROT;
			wire RREADY;
			wire RVALID;
			wire [31:0] RDATA;
			wire [1:0] RRESP;
			wire AWREADY;
			wire AWVALID;
			wire [31:0] AWADDR;
			wire [2:0] AWPROT;
			wire WREADY;
			wire WVALID;
			wire [31:0] WDATA;
			wire [3:0] WSTRB;
			wire BREADY;
			wire BVALID;
			wire [1:0] BRESP;
		end
	endgenerate
	localparam _param_F80E1_OPT_SKIDBUFFER = 1;
	localparam _param_F80E1_OPT_LOWPOWER = 0;
	localparam _param_F80E1_NUM_WORDS = 128;
	generate
		if (1) begin : memory
			localparam [0:0] OPT_SKIDBUFFER = _param_F80E1_OPT_SKIDBUFFER;
			localparam [0:0] OPT_LOWPOWER = _param_F80E1_OPT_LOWPOWER;
			localparam NUM_WORDS = _param_F80E1_NUM_WORDS;
			wire ACLK;
			wire ARESETn;
			localparam ADDRLSB = 2;
			wire i_reset = !ARESETn;
			wire axil_write_ready;
			wire [29:0] awskd_addr;
			wire [31:0] wskd_data;
			wire [3:0] wskd_strb;
			reg axil_bvalid;
			wire axil_read_ready;
			wire [29:0] arskd_addr;
			reg [31:0] axil_read_data;
			reg axil_read_valid;
			wire t_axil_read_ready;
			wire [29:0] t_arskd_addr;
			reg [31:0] t_axil_read_data;
			reg t_axil_read_valid;
			localparam signed [31:0] AddrLsb = 2;
			localparam signed [31:0] AddrMsb = 8;
			reg [31:0] mem_array [0:127];
			if (OPT_SKIDBUFFER) begin : SKIDBUFFER_WRITE
				wire awskd_valid;
				wire wskd_valid;
				skidbuffer #(
					.OPT_OUTREG(0),
					.OPT_LOWPOWER(OPT_LOWPOWER),
					.DW(30)
				) axilawskid(
					.i_clk(ACLK),
					.i_reset(i_reset),
					.i_valid(SystemResourceCheck.axil_mem_rw.AWVALID),
					.o_ready(SystemResourceCheck.axil_mem_rw.AWREADY),
					.i_data(SystemResourceCheck.axil_mem_rw.AWADDR[31:ADDRLSB]),
					.o_valid(awskd_valid),
					.i_ready(axil_write_ready),
					.o_data(awskd_addr)
				);
				skidbuffer #(
					.OPT_OUTREG(0),
					.OPT_LOWPOWER(OPT_LOWPOWER),
					.DW(36)
				) axilwskid(
					.i_clk(ACLK),
					.i_reset(i_reset),
					.i_valid(SystemResourceCheck.axil_mem_rw.WVALID),
					.o_ready(SystemResourceCheck.axil_mem_rw.WREADY),
					.i_data({SystemResourceCheck.axil_mem_rw.WDATA, SystemResourceCheck.axil_mem_rw.WSTRB}),
					.o_valid(wskd_valid),
					.i_ready(axil_write_ready),
					.o_data({wskd_data, wskd_strb})
				);
				assign axil_write_ready = (awskd_valid && wskd_valid) && (!SystemResourceCheck.axil_mem_rw.BVALID || SystemResourceCheck.axil_mem_rw.BREADY);
			end
			else begin : SIMPLE_WRITES
				reg axil_awready;
				initial axil_awready = 1'b0;
				always @(posedge ACLK)
					if (!ARESETn)
						axil_awready <= 1'b0;
					else
						axil_awready <= (!axil_awready && (SystemResourceCheck.axil_mem_rw.AWVALID && SystemResourceCheck.axil_mem_rw.WVALID)) && (!SystemResourceCheck.axil_mem_rw.BVALID || SystemResourceCheck.axil_mem_rw.BREADY);
				assign SystemResourceCheck.axil_mem_rw.AWREADY = axil_awready;
				assign SystemResourceCheck.axil_mem_rw.WREADY = axil_awready;
				assign awskd_addr = SystemResourceCheck.axil_mem_rw.AWADDR[31:ADDRLSB];
				assign wskd_data = SystemResourceCheck.axil_mem_rw.WDATA;
				assign wskd_strb = SystemResourceCheck.axil_mem_rw.WSTRB;
				assign axil_write_ready = axil_awready;
			end
			initial axil_bvalid = 0;
			always @(posedge ACLK)
				if (i_reset)
					axil_bvalid <= 0;
				else if (axil_write_ready)
					axil_bvalid <= 1;
				else if (SystemResourceCheck.axil_mem_rw.BREADY)
					axil_bvalid <= 0;
			assign SystemResourceCheck.axil_mem_rw.BVALID = axil_bvalid;
			assign SystemResourceCheck.axil_mem_rw.BRESP = 2'b00;
			if (OPT_SKIDBUFFER) begin : SKIDBUFFER_READ
				wire arskd_valid;
				skidbuffer #(
					.OPT_OUTREG(0),
					.OPT_LOWPOWER(OPT_LOWPOWER),
					.DW(30)
				) axilarskid(
					.i_clk(ACLK),
					.i_reset(i_reset),
					.i_valid(SystemResourceCheck.axil_mem_rw.ARVALID),
					.o_ready(SystemResourceCheck.axil_mem_rw.ARREADY),
					.i_data(SystemResourceCheck.axil_mem_rw.ARADDR[31:ADDRLSB]),
					.o_valid(arskd_valid),
					.i_ready(axil_read_ready),
					.o_data(arskd_addr)
				);
				assign axil_read_ready = arskd_valid && (!axil_read_valid || SystemResourceCheck.axil_mem_rw.RREADY);
			end
			else begin : SIMPLE_READS
				reg axil_arready;
				always @(*) axil_arready = !SystemResourceCheck.axil_mem_rw.RVALID;
				assign arskd_addr = SystemResourceCheck.axil_mem_rw.ARADDR[31:ADDRLSB];
				assign SystemResourceCheck.axil_mem_rw.ARREADY = axil_arready;
				assign axil_read_ready = SystemResourceCheck.axil_mem_rw.ARVALID && SystemResourceCheck.axil_mem_rw.ARREADY;
			end
			initial axil_read_valid = 1'b0;
			always @(posedge ACLK)
				if (i_reset)
					axil_read_valid <= 1'b0;
				else if (axil_read_ready)
					axil_read_valid <= 1'b1;
				else if (SystemResourceCheck.axil_mem_rw.RREADY)
					axil_read_valid <= 1'b0;
			assign SystemResourceCheck.axil_mem_rw.RVALID = axil_read_valid;
			assign SystemResourceCheck.axil_mem_rw.RDATA = axil_read_data;
			assign SystemResourceCheck.axil_mem_rw.RRESP = 2'b00;
			if (OPT_SKIDBUFFER) begin : T_SKIDBUFFER_READ
				wire t_arskd_valid;
				skidbuffer #(
					.OPT_OUTREG(0),
					.OPT_LOWPOWER(OPT_LOWPOWER),
					.DW(30)
				) axilarskid(
					.i_clk(ACLK),
					.i_reset(i_reset),
					.i_valid(SystemResourceCheck.axil_mem_ro.ARVALID),
					.o_ready(SystemResourceCheck.axil_mem_ro.ARREADY),
					.i_data(SystemResourceCheck.axil_mem_ro.ARADDR[31:ADDRLSB]),
					.o_valid(t_arskd_valid),
					.i_ready(t_axil_read_ready),
					.o_data(t_arskd_addr)
				);
				assign t_axil_read_ready = t_arskd_valid && (!t_axil_read_valid || SystemResourceCheck.axil_mem_ro.RREADY);
			end
			else begin : T_SIMPLE_READS
				reg t_axil_arready;
				always @(*) t_axil_arready = !SystemResourceCheck.axil_mem_ro.RVALID;
				assign t_arskd_addr = SystemResourceCheck.axil_mem_ro.ARADDR[31:ADDRLSB];
				assign SystemResourceCheck.axil_mem_ro.ARREADY = t_axil_arready;
				assign t_axil_read_ready = SystemResourceCheck.axil_mem_ro.ARVALID && SystemResourceCheck.axil_mem_ro.ARREADY;
			end
			initial t_axil_read_valid = 1'b0;
			always @(posedge ACLK)
				if (i_reset)
					t_axil_read_valid <= 1'b0;
				else if (t_axil_read_ready)
					t_axil_read_valid <= 1'b1;
				else if (SystemResourceCheck.axil_mem_ro.RREADY)
					t_axil_read_valid <= 1'b0;
			assign SystemResourceCheck.axil_mem_ro.RVALID = t_axil_read_valid;
			assign SystemResourceCheck.axil_mem_ro.RDATA = t_axil_read_data;
			assign SystemResourceCheck.axil_mem_ro.RRESP = 2'b00;
			always @(posedge ACLK)
				if (i_reset)
					;
				else if (axil_write_ready) begin
					if (wskd_strb[0])
						mem_array[awskd_addr[6:0]][7:0] <= wskd_data[7:0];
					if (wskd_strb[1])
						mem_array[awskd_addr[6:0]][15:8] <= wskd_data[15:8];
					if (wskd_strb[2])
						mem_array[awskd_addr[6:0]][23:16] <= wskd_data[23:16];
					if (wskd_strb[3])
						mem_array[awskd_addr[6:0]][31:24] <= wskd_data[31:24];
				end
			initial begin
				axil_read_data = 0;
				t_axil_read_data = 0;
			end
			always @(posedge ACLK) begin
				if (!SystemResourceCheck.axil_mem_rw.RVALID || SystemResourceCheck.axil_mem_rw.RREADY)
					axil_read_data <= mem_array[arskd_addr[6:0]];
				if (!SystemResourceCheck.axil_mem_ro.RVALID || SystemResourceCheck.axil_mem_ro.RREADY)
					t_axil_read_data <= mem_array[t_arskd_addr[6:0]];
			end
		end
	endgenerate
	assign memory.ACLK = clk;
	assign memory.ARESETn = ~rst;
	wire [31:0] trace_completed_pc;
	wire [31:0] trace_completed_insn;
	wire [31:0] trace_completed_cycle_status;
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	generate
		if (1) begin : datapath
			reg _sv2v_0;
			wire clk;
			wire rst;
			wire halt;
			wire [31:0] trace_completed_pc;
			wire [31:0] trace_completed_insn;
			wire [31:0] trace_completed_cycle_status;
			localparam [6:0] OpcodeLoad = 7'b0000011;
			localparam [6:0] OpcodeStore = 7'b0100011;
			localparam [6:0] OpcodeBranch = 7'b1100011;
			localparam [6:0] OpcodeJalr = 7'b1100111;
			localparam [6:0] OpcodeMiscMem = 7'b0001111;
			localparam [6:0] OpcodeJal = 7'b1101111;
			localparam [6:0] OpcodeRegImm = 7'b0010011;
			localparam [6:0] OpcodeRegReg = 7'b0110011;
			localparam [6:0] OpcodeEnviron = 7'b1110011;
			localparam [6:0] OpcodeAuipc = 7'b0010111;
			localparam [6:0] OpcodeLui = 7'b0110111;
			reg [31:0] cycles_current;
			always @(posedge clk)
				if (rst)
					cycles_current <= 0;
				else
					cycles_current <= cycles_current + 1;
			reg x_branch_taken;
			reg [31:0] x_branch_target;
			wire d_load_use_stall;
			wire d_div_stall;
			wire pipeline_stall = d_load_use_stall || d_div_stall;
			reg [31:0] f_pc_current;
			reg [31:0] f_cycle_status;
			assign SystemResourceCheck.axil_mem_ro.ARADDR = f_pc_current;
			assign SystemResourceCheck.axil_mem_ro.ARVALID = !pipeline_stall && !x_branch_taken;
			assign SystemResourceCheck.axil_mem_ro.ARPROT = 3'b000;
			assign SystemResourceCheck.axil_mem_ro.RREADY = !pipeline_stall;
			assign SystemResourceCheck.axil_mem_ro.AWADDR = 32'd0;
			assign SystemResourceCheck.axil_mem_ro.AWVALID = 1'b0;
			assign SystemResourceCheck.axil_mem_ro.AWPROT = 3'b000;
			assign SystemResourceCheck.axil_mem_ro.WDATA = 32'd0;
			assign SystemResourceCheck.axil_mem_ro.WSTRB = 4'b0000;
			assign SystemResourceCheck.axil_mem_ro.WVALID = 1'b0;
			assign SystemResourceCheck.axil_mem_ro.BREADY = 1'b1;
			wire imem_ar_fire = SystemResourceCheck.axil_mem_ro.ARVALID && SystemResourceCheck.axil_mem_ro.ARREADY;
			wire imem_r_fire = SystemResourceCheck.axil_mem_ro.RVALID && SystemResourceCheck.axil_mem_ro.RREADY;
			always @(posedge clk)
				if (rst) begin
					f_pc_current <= 32'd0;
					f_cycle_status <= 32'd1;
				end
				else begin
					f_cycle_status <= 32'd1;
					if (x_branch_taken)
						f_pc_current <= x_branch_target;
					else if (pipeline_stall)
						f_pc_current <= f_pc_current;
					else if (imem_ar_fire)
						f_pc_current <= f_pc_current + 32'd4;
					else
						f_pc_current <= f_pc_current;
				end
			reg [63:0] g_state;
			always @(posedge clk)
				if (rst)
					g_state <= 64'h0000000000000004;
				else if (x_branch_taken)
					g_state <= 64'h0000000000000008;
				else if (pipeline_stall)
					g_state <= g_state;
				else if (imem_ar_fire)
					g_state <= {f_pc_current, f_cycle_status};
				else
					g_state <= g_state;
			wire [255:0] g_disasm;
			Disasm #(.PREFIX("G")) disasm_0g(
				.insn(SystemResourceCheck.axil_mem_ro.RDATA),
				.disasm(g_disasm)
			);
			reg [95:0] decode_state;
			always @(posedge clk)
				if (rst)
					decode_state <= 96'h000000000000000000000004;
				else if (x_branch_taken)
					decode_state <= 96'h000000000000000000000008;
				else if (pipeline_stall)
					decode_state <= decode_state;
				else if (imem_r_fire)
					decode_state <= {sv2v_cast_32(g_state[63-:32]), sv2v_cast_32(SystemResourceCheck.axil_mem_ro.RDATA), sv2v_cast_32(g_state[31-:32])};
				else
					decode_state <= decode_state;
			wire [255:0] d_disasm;
			Disasm #(.PREFIX("D")) disasm_1decode(
				.insn(decode_state[63-:32]),
				.disasm(d_disasm)
			);
			wire [6:0] d_opcode = decode_state[38:32];
			wire [4:0] d_rd = decode_state[43:39];
			wire [2:0] d_funct3 = decode_state[46:44];
			wire [4:0] d_rs1 = decode_state[51:47];
			wire [4:0] d_rs2 = decode_state[56:52];
			wire [6:0] d_funct7 = decode_state[63:57];
			wire [11:0] d_imm_i = decode_state[63:52];
			wire [11:0] d_imm_s;
			assign d_imm_s[11:5] = d_funct7;
			assign d_imm_s[4:0] = d_rd;
			wire [12:0] d_imm_b;
			assign {d_imm_b[12], d_imm_b[10:5]} = d_funct7;
			assign {d_imm_b[4:1], d_imm_b[11]} = d_rd;
			assign d_imm_b[0] = 1'b0;
			wire [20:0] d_imm_j;
			assign {d_imm_j[20], d_imm_j[10:1], d_imm_j[11], d_imm_j[19:12], d_imm_j[0]} = {decode_state[63:44], 1'b0};
			wire [31:0] d_imm_i_sext = {{20 {d_imm_i[11]}}, d_imm_i};
			wire [31:0] d_imm_b_sext = {{19 {d_imm_b[12]}}, d_imm_b};
			wire [31:0] d_imm_j_sext = {{11 {d_imm_j[20]}}, d_imm_j};
			wire [31:0] d_imm_u = {decode_state[63:44], 12'b000000000000};
			wire [31:0] d_imm_s_sext = {{20 {d_imm_s[11]}}, d_imm_s};
			reg [335:0] execute_state;
			wire x_is_load_in_exec = execute_state[278:272] == OpcodeLoad;
			reg d_uses_rs1;
			reg d_uses_rs2;
			always @(*) begin
				if (_sv2v_0)
					;
				d_uses_rs1 = 1'b0;
				d_uses_rs2 = 1'b0;
				case (d_opcode)
					OpcodeLoad, OpcodeRegImm, OpcodeJalr: d_uses_rs1 = 1'b1;
					OpcodeStore, OpcodeBranch, OpcodeRegReg: begin
						d_uses_rs1 = 1'b1;
						d_uses_rs2 = 1'b1;
					end
					default: begin
						d_uses_rs1 = 1'b0;
						d_uses_rs2 = 1'b0;
					end
				endcase
			end
			assign d_load_use_stall = ((!x_branch_taken && x_is_load_in_exec) && (execute_state[229-:5] != 5'd0)) && ((d_uses_rs1 && (execute_state[229-:5] == d_rs1)) || (d_uses_rs2 && (execute_state[229-:5] == d_rs2)));
			wire [31:0] d_rs1_data;
			wire [31:0] d_rs2_data;
			wire w_rf_we;
			wire [4:0] w_rd;
			wire [31:0] w_rd_data;
			RegFile rf(
				.clk(clk),
				.rst(rst),
				.we(w_rf_we),
				.rd(w_rd),
				.rd_data(w_rd_data),
				.rs1(d_rs1),
				.rs2(d_rs2),
				.rs1_data(d_rs1_data),
				.rs2_data(d_rs2_data)
			);
			reg d_rf_we;
			always @(*) begin
				if (_sv2v_0)
					;
				case (d_opcode)
					OpcodeBranch, OpcodeStore, OpcodeMiscMem, OpcodeEnviron: d_rf_we = 1'b0;
					default: d_rf_we = 1'b1;
				endcase
			end
			always @(posedge clk)
				if (rst)
					execute_state <= 336'h4000000000000000000000000000000000000000000000000000000000000;
				else if (x_branch_taken)
					execute_state <= 336'h8000000000000000000000000000000000000000000000000000000000000;
				else if (d_div_stall)
					execute_state <= 336'h2000000000000000000000000000000000000000000000000000000000000;
				else if (d_load_use_stall)
					execute_state <= 336'h10000000000000000000000000000000000000000000000000000000000000;
				else
					execute_state <= {sv2v_cast_32(decode_state[95-:32]), sv2v_cast_32(decode_state[63-:32]), sv2v_cast_32(decode_state[31-:32]), d_rs1, d_rs2, d_rd, d_rs1_data, d_rs2_data, d_imm_i_sext, d_imm_b_sext, d_imm_j_sext, d_imm_s_sext, d_imm_u, d_rf_we};
			wire [255:0] x_disasm;
			Disasm #(.PREFIX("X")) disasm_2execute(
				.insn(execute_state[303-:32]),
				.disasm(x_disasm)
			);
			wire [6:0] x_opcode = execute_state[278:272];
			wire [2:0] x_funct3 = execute_state[286:284];
			wire [6:0] x_funct7 = execute_state[303:297];
			wire [4:0] x_imm_shamt = execute_state[296:292];
			reg [203:0] memory_state;
			reg [134:0] writeback_state;
			reg [31:0] x_rs1;
			reg [31:0] x_rs2;
			reg [31:0] m_rd_data;
			reg x_is_load;
			reg x_is_store;
			reg [2:0] x_mem_funct3;
			reg [31:0] x_mem_addr;
			reg [31:0] x_store_data;
			always @(*) begin
				if (_sv2v_0)
					;
				if ((memory_state[70] && (memory_state[107-:5] != 5'd0)) && (memory_state[107-:5] == execute_state[239-:5]))
					x_rs1 = m_rd_data;
				else if ((writeback_state[1] && (writeback_state[38-:5] != 5'd0)) && (writeback_state[38-:5] == execute_state[239-:5]))
					x_rs1 = writeback_state[33-:32];
				else
					x_rs1 = execute_state[224-:32];
				if ((memory_state[70] && (memory_state[107-:5] != 5'd0)) && (memory_state[107-:5] == execute_state[234-:5]))
					x_rs2 = m_rd_data;
				else if ((writeback_state[1] && (writeback_state[38-:5] != 5'd0)) && (writeback_state[38-:5] == execute_state[234-:5]))
					x_rs2 = writeback_state[33-:32];
				else
					x_rs2 = execute_state[192-:32];
			end
			reg [31:0] x_alu_a;
			reg [31:0] x_alu_b;
			reg x_alu_cin;
			wire [31:0] x_alu_sum;
			CarryLookaheadAdder u_cla(
				.a(x_alu_a),
				.b(x_alu_b),
				.cin(x_alu_cin),
				.sum(x_alu_sum)
			);
			reg [31:0] div_op_a;
			reg [31:0] div_op_b;
			wire [31:0] x_div_quotient;
			wire [31:0] x_div_remainder;
			always @(*) begin
				if (_sv2v_0)
					;
				if ((x_funct3 == 3'b100) || (x_funct3 == 3'b110)) begin
					div_op_a = (x_rs1[31] ? ~x_rs1 + 32'd1 : x_rs1);
					div_op_b = (x_rs2[31] ? ~x_rs2 + 32'd1 : x_rs2);
				end
				else begin
					div_op_a = x_rs1;
					div_op_b = x_rs2;
				end
			end
			DividerUnsignedPipelined u_div(
				.clk(clk),
				.rst(rst),
				.stall(1'b0),
				.i_dividend(div_op_a),
				.i_divisor(div_op_b),
				.o_quotient(x_div_quotient),
				.o_remainder(x_div_remainder)
			);
			wire x_is_div_op = ((x_opcode == OpcodeRegReg) && (x_funct7 == 7'd1)) && ((((x_funct3 == 3'b100) || (x_funct3 == 3'b101)) || (x_funct3 == 3'b110)) || (x_funct3 == 3'b111));
			reg [170:0] div_q [0:6];
			always @(posedge clk)
				if (rst) begin : sv2v_autoblock_1
					reg signed [31:0] i;
					for (i = 0; i < 7; i = i + 1)
						div_q[i] <= 1'sb0;
				end
				else begin
					begin : sv2v_autoblock_2
						reg signed [31:0] i;
						for (i = 6; i > 0; i = i - 1)
							div_q[i] <= div_q[i - 1];
					end
					if (x_is_div_op)
						div_q[0] <= {1'b1, sv2v_cast_32(execute_state[335-:32]), sv2v_cast_32(execute_state[303-:32]), sv2v_cast_32(execute_state[271-:32]), sv2v_cast_5(execute_state[229-:5]), x_funct3, x_rs1[31], x_rs2[31], x_rs1, x_rs2};
					else
						div_q[0] <= 1'sb0;
				end
			wire d_is_div_op = ((d_opcode == OpcodeRegReg) && (d_funct7 == 7'd1)) && ((((d_funct3 == 3'b100) || (d_funct3 == 3'b101)) || (d_funct3 == 3'b110)) || (d_funct3 == 3'b111));
			wire div_inflight = (((((x_is_div_op || div_q[0][170]) || div_q[1][170]) || div_q[2][170]) || div_q[3][170]) || div_q[4][170]) || div_q[5][170];
			wire d_div_dependent = (((((((x_is_div_op && (execute_state[229-:5] != 5'd0)) && ((execute_state[229-:5] == d_rs1) || (execute_state[229-:5] == d_rs2))) || ((div_q[0][170] && (div_q[0][73-:5] != 5'd0)) && ((div_q[0][73-:5] == d_rs1) || (div_q[0][73-:5] == d_rs2)))) || ((div_q[1][170] && (div_q[1][73-:5] != 5'd0)) && ((div_q[1][73-:5] == d_rs1) || (div_q[1][73-:5] == d_rs2)))) || ((div_q[2][170] && (div_q[2][73-:5] != 5'd0)) && ((div_q[2][73-:5] == d_rs1) || (div_q[2][73-:5] == d_rs2)))) || ((div_q[3][170] && (div_q[3][73-:5] != 5'd0)) && ((div_q[3][73-:5] == d_rs1) || (div_q[3][73-:5] == d_rs2)))) || ((div_q[4][170] && (div_q[4][73-:5] != 5'd0)) && ((div_q[4][73-:5] == d_rs1) || (div_q[4][73-:5] == d_rs2)))) || ((div_q[5][170] && (div_q[5][73-:5] != 5'd0)) && ((div_q[5][73-:5] == d_rs1) || (div_q[5][73-:5] == d_rs2)));
			assign d_div_stall = (!x_branch_taken && div_inflight) && (d_is_div_op ? d_div_dependent : 1'b1);
			reg [31:0] div_result;
			always @(*) begin : sv2v_autoblock_3
				reg div_by_zero;
				reg signed_overflow;
				reg [31:0] q_u;
				reg [31:0] r_u;
				reg [31:0] q_s;
				reg [31:0] r_s;
				if (_sv2v_0)
					;
				div_result = 32'd0;
				div_by_zero = 1'b0;
				signed_overflow = 1'b0;
				q_u = 32'd0;
				r_u = 32'd0;
				q_s = 32'd0;
				r_s = 32'd0;
				if (div_q[6][170]) begin
					div_by_zero = div_q[6][31-:32] == 32'd0;
					signed_overflow = (div_q[6][63-:32] == 32'h80000000) && (div_q[6][31-:32] == 32'hffffffff);
					q_u = x_div_quotient;
					r_u = x_div_remainder;
					q_s = (div_q[6][65] ^ div_q[6][64] ? ~q_u + 32'd1 : q_u);
					r_s = (div_q[6][65] ? ~r_u + 32'd1 : r_u);
					case (div_q[6][68-:3])
						3'b100: div_result = (div_by_zero ? 32'hffffffff : (signed_overflow ? 32'h80000000 : q_s));
						3'b101: div_result = (div_by_zero ? 32'hffffffff : x_div_quotient);
						3'b110: div_result = (div_by_zero ? div_q[6][63-:32] : (signed_overflow ? 32'd0 : r_s));
						3'b111: div_result = (div_by_zero ? div_q[6][63-:32] : x_div_remainder);
						default: div_result = 32'd0;
					endcase
				end
			end
			reg [31:0] x_rd_data;
			reg x_rf_we;
			reg x_halt;
			wire signed [31:0] x_s_rs1 = $signed(x_rs1);
			wire signed [31:0] x_s_rs2 = $signed(x_rs2);
			wire signed [31:0] x_s_imm_i = $signed(execute_state[160-:32]);
			always @(*) begin
				if (_sv2v_0)
					;
				x_alu_a = x_rs1;
				x_alu_b = x_rs2;
				x_alu_cin = 1'b0;
				x_rd_data = 32'd0;
				x_rf_we = execute_state[0];
				x_halt = 1'b0;
				x_branch_taken = 1'b0;
				x_branch_target = 32'd0;
				x_is_load = 1'b0;
				x_is_store = 1'b0;
				x_mem_funct3 = 3'd0;
				x_mem_addr = 32'd0;
				x_store_data = 32'd0;
				case (x_opcode)
					OpcodeLui: x_rd_data = execute_state[32-:32];
					OpcodeAuipc: x_rd_data = execute_state[335-:32] + execute_state[32-:32];
					OpcodeJal: begin
						x_rd_data = execute_state[335-:32] + 32'd4;
						x_branch_taken = 1'b1;
						x_branch_target = execute_state[335-:32] + execute_state[96-:32];
					end
					OpcodeJalr: begin
						x_alu_a = x_rs1;
						x_alu_b = execute_state[160-:32];
						x_alu_cin = 1'b0;
						x_rd_data = execute_state[335-:32] + 32'd4;
						x_branch_taken = 1'b1;
						x_branch_target = {x_alu_sum[31:1], 1'b0};
					end
					OpcodeRegImm:
						case (x_funct3)
							3'b000: begin
								x_alu_a = x_rs1;
								x_alu_b = execute_state[160-:32];
								x_alu_cin = 1'b0;
								x_rd_data = x_alu_sum;
							end
							3'b010: x_rd_data = (x_s_rs1 < x_s_imm_i ? 32'd1 : 32'd0);
							3'b011: x_rd_data = (x_rs1 < execute_state[160-:32] ? 32'd1 : 32'd0);
							3'b100: x_rd_data = x_rs1 ^ execute_state[160-:32];
							3'b110: x_rd_data = x_rs1 | execute_state[160-:32];
							3'b111: x_rd_data = x_rs1 & execute_state[160-:32];
							3'b001: x_rd_data = x_rs1 << x_imm_shamt;
							3'b101:
								if (x_funct7 == 7'b0100000)
									x_rd_data = $signed(x_rs1) >>> x_imm_shamt;
								else
									x_rd_data = x_rs1 >> x_imm_shamt;
							default: x_rf_we = 1'b0;
						endcase
					OpcodeRegReg:
						if (x_funct7 == 7'd0)
							case (x_funct3)
								3'b000: begin
									x_alu_a = x_rs1;
									x_alu_b = x_rs2;
									x_alu_cin = 1'b0;
									x_rd_data = x_alu_sum;
								end
								3'b001: x_rd_data = x_rs1 << x_rs2[4:0];
								3'b010: x_rd_data = (x_s_rs1 < x_s_rs2 ? 32'd1 : 32'd0);
								3'b011: x_rd_data = (x_rs1 < x_rs2 ? 32'd1 : 32'd0);
								3'b100: x_rd_data = x_rs1 ^ x_rs2;
								3'b101: x_rd_data = x_rs1 >> x_rs2[4:0];
								3'b110: x_rd_data = x_rs1 | x_rs2;
								3'b111: x_rd_data = x_rs1 & x_rs2;
								default: x_rf_we = 1'b0;
							endcase
						else if (x_funct7 == 7'b0100000)
							case (x_funct3)
								3'b000: begin
									x_alu_a = x_rs1;
									x_alu_b = ~x_rs2;
									x_alu_cin = 1'b1;
									x_rd_data = x_alu_sum;
								end
								3'b101: x_rd_data = $signed(x_rs1) >>> x_rs2[4:0];
								default: x_rf_we = 1'b0;
							endcase
						else if (x_funct7 == 7'd1) begin : sv2v_autoblock_4
							reg [63:0] u_prod;
							reg signed [63:0] s_prod;
							u_prod = 64'd0;
							s_prod = 64'd0;
							case (x_funct3)
								3'b000: begin
									u_prod = $unsigned(x_rs1) * $unsigned(x_rs2);
									x_rd_data = u_prod[31:0];
								end
								3'b001: begin
									s_prod = $signed(x_rs1) * $signed(x_rs2);
									x_rd_data = s_prod[63:32];
								end
								3'b010: begin
									s_prod = $signed(x_rs1) * $signed({1'b0, x_rs2});
									x_rd_data = s_prod[63:32];
								end
								3'b011: begin
									u_prod = $unsigned(x_rs1) * $unsigned(x_rs2);
									x_rd_data = u_prod[63:32];
								end
								3'b100, 3'b101, 3'b110, 3'b111: x_rf_we = 1'b0;
								default: x_rf_we = 1'b0;
							endcase
						end
						else
							x_rf_we = 1'b0;
					OpcodeBranch: begin
						x_rf_we = 1'b0;
						begin : sv2v_autoblock_5
							reg take;
							take = 1'b0;
							case (x_funct3)
								3'b000: take = x_rs1 == x_rs2;
								3'b001: take = x_rs1 != x_rs2;
								3'b100: take = x_s_rs1 < x_s_rs2;
								3'b101: take = x_s_rs1 >= x_s_rs2;
								3'b110: take = x_rs1 < x_rs2;
								3'b111: take = x_rs1 >= x_rs2;
								default: take = 1'b0;
							endcase
							if (take) begin
								x_branch_taken = 1'b1;
								x_branch_target = execute_state[335-:32] + execute_state[128-:32];
							end
						end
					end
					OpcodeEnviron: begin
						if (execute_state[303:279] == 25'd0)
							x_halt = 1'b1;
						x_rf_we = 1'b0;
					end
					OpcodeMiscMem: x_rf_we = 1'b0;
					OpcodeLoad: begin
						x_alu_a = x_rs1;
						x_alu_b = execute_state[160-:32];
						x_alu_cin = 1'b0;
						x_mem_addr = x_alu_sum;
						x_mem_funct3 = x_funct3;
						x_is_load = 1'b1;
						x_rf_we = 1'b1;
					end
					OpcodeStore: begin
						x_alu_a = x_rs1;
						x_alu_b = execute_state[64-:32];
						x_alu_cin = 1'b0;
						x_mem_addr = x_alu_sum;
						x_mem_funct3 = x_funct3;
						x_is_store = 1'b1;
						x_store_data = x_rs2;
						x_rf_we = 1'b0;
					end
					default: x_rf_we = 1'b0;
				endcase
			end
			always @(posedge clk)
				if (rst)
					memory_state <= 204'h000000000000000000000004000000000000000000000000000;
				else if (div_q[6][170])
					memory_state <= {sv2v_cast_32(div_q[6][169-:32]), sv2v_cast_32(div_q[6][137-:32]), sv2v_cast_32(div_q[6][105-:32]), sv2v_cast_5(div_q[6][73-:5]), div_result, div_q[6][73-:5] != 5'd0, 70'h000000000000000000};
				else if (x_is_div_op)
					memory_state <= 204'h000000000000000000000002000000000000000000000000000;
				else
					memory_state <= {sv2v_cast_32(execute_state[335-:32]), sv2v_cast_32(execute_state[303-:32]), sv2v_cast_32(execute_state[271-:32]), sv2v_cast_5(execute_state[229-:5]), x_rd_data, x_rf_we, x_halt, x_is_load, x_is_store, x_mem_funct3, x_mem_addr, x_store_data};
			wire [255:0] m_disasm;
			Disasm #(.PREFIX("M")) disasm_3memory(
				.insn(memory_state[171-:32]),
				.disasm(m_disasm)
			);
			reg [31:0] x_dmem_addr_aligned;
			reg [31:0] x_dmem_wdata;
			reg [3:0] x_dmem_wstrb;
			wire [31:0] load_data_from_dmem = SystemResourceCheck.axil_mem_rw.RDATA;
			reg [7:0] m_load_byte;
			reg [15:0] m_load_half;
			always @(*) begin
				if (_sv2v_0)
					;
				x_dmem_addr_aligned = {x_mem_addr[31:2], 2'b00};
				x_dmem_wdata = 32'd0;
				x_dmem_wstrb = 4'b0000;
				if (x_is_store)
					case (x_mem_funct3)
						3'b000:
							case (x_mem_addr[1:0])
								2'b00: begin
									x_dmem_wstrb = 4'b0001;
									x_dmem_wdata = {24'd0, x_store_data[7:0]};
								end
								2'b01: begin
									x_dmem_wstrb = 4'b0010;
									x_dmem_wdata = {16'd0, x_store_data[7:0], 8'd0};
								end
								2'b10: begin
									x_dmem_wstrb = 4'b0100;
									x_dmem_wdata = {8'd0, x_store_data[7:0], 16'd0};
								end
								2'b11: begin
									x_dmem_wstrb = 4'b1000;
									x_dmem_wdata = {x_store_data[7:0], 24'd0};
								end
							endcase
						3'b001:
							case (x_mem_addr[1])
								1'b0: begin
									x_dmem_wstrb = 4'b0011;
									x_dmem_wdata = {16'd0, x_store_data[15:0]};
								end
								1'b1: begin
									x_dmem_wstrb = 4'b1100;
									x_dmem_wdata = {x_store_data[15:0], 16'd0};
								end
							endcase
						3'b010: begin
							x_dmem_wstrb = 4'b1111;
							x_dmem_wdata = x_store_data;
						end
						default: begin
							x_dmem_wstrb = 4'b0000;
							x_dmem_wdata = 32'd0;
						end
					endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				m_rd_data = memory_state[102-:32];
				m_load_byte = 8'd0;
				m_load_half = 16'd0;
				if (memory_state[68]) begin
					case (memory_state[33:32])
						2'b00: m_load_byte = load_data_from_dmem[7:0];
						2'b01: m_load_byte = load_data_from_dmem[15:8];
						2'b10: m_load_byte = load_data_from_dmem[23:16];
						2'b11: m_load_byte = load_data_from_dmem[31:24];
					endcase
					case (memory_state[33])
						1'b0: m_load_half = load_data_from_dmem[15:0];
						1'b1: m_load_half = load_data_from_dmem[31:16];
					endcase
					case (memory_state[66-:3])
						3'b000: m_rd_data = {{24 {m_load_byte[7]}}, m_load_byte};
						3'b001: m_rd_data = {{16 {m_load_half[15]}}, m_load_half};
						3'b010: m_rd_data = load_data_from_dmem;
						3'b100: m_rd_data = {24'd0, m_load_byte};
						3'b101: m_rd_data = {16'd0, m_load_half};
						default: m_rd_data = memory_state[102-:32];
					endcase
				end
			end
			assign SystemResourceCheck.axil_mem_rw.ARADDR = x_dmem_addr_aligned;
			assign SystemResourceCheck.axil_mem_rw.ARVALID = x_is_load;
			assign SystemResourceCheck.axil_mem_rw.ARPROT = 3'b000;
			assign SystemResourceCheck.axil_mem_rw.RREADY = 1'b1;
			assign SystemResourceCheck.axil_mem_rw.AWADDR = x_dmem_addr_aligned;
			assign SystemResourceCheck.axil_mem_rw.AWVALID = x_is_store;
			assign SystemResourceCheck.axil_mem_rw.AWPROT = 3'b000;
			assign SystemResourceCheck.axil_mem_rw.WDATA = x_dmem_wdata;
			assign SystemResourceCheck.axil_mem_rw.WSTRB = x_dmem_wstrb;
			assign SystemResourceCheck.axil_mem_rw.WVALID = x_is_store;
			assign SystemResourceCheck.axil_mem_rw.BREADY = 1'b1;
			always @(posedge clk)
				if (rst)
					writeback_state <= 135'h0000000000000000000000020000000000;
				else
					writeback_state <= {sv2v_cast_32(memory_state[203-:32]), sv2v_cast_32(memory_state[171-:32]), sv2v_cast_32(memory_state[139-:32]), sv2v_cast_5(memory_state[107-:5]), m_rd_data, memory_state[70], memory_state[69]};
			wire [255:0] w_disasm;
			Disasm #(.PREFIX("W")) disasm_4writeback(
				.insn(writeback_state[102-:32]),
				.disasm(w_disasm)
			);
			assign w_rf_we = writeback_state[1];
			assign w_rd = writeback_state[38-:5];
			assign w_rd_data = writeback_state[33-:32];
			assign halt = writeback_state[0];
			assign trace_completed_pc = writeback_state[134-:32];
			assign trace_completed_insn = writeback_state[102-:32];
			assign trace_completed_cycle_status = writeback_state[70-:32];
			initial _sv2v_0 = 0;
		end
	endgenerate
	assign datapath.clk = clk;
	assign datapath.rst = rst;
	assign led[0] = datapath.halt;
	assign trace_completed_pc = datapath.trace_completed_pc;
	assign trace_completed_insn = datapath.trace_completed_insn;
	assign trace_completed_cycle_status = datapath.trace_completed_cycle_status;
endmodule
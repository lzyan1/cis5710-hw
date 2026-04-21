module MyClockGen (
	input_clk_25MHz,
	clk_proc,
	locked
);
	input input_clk_25MHz;
	output wire clk_proc;
	output wire locked;
	wire clkfb;
	(* FREQUENCY_PIN_CLKI = "25" *) (* FREQUENCY_PIN_CLKOP = "10" *) (* ICP_CURRENT = "12" *) (* LPF_RESISTOR = "8" *) (* MFG_ENABLE_FILTEROPAMP = "1" *) (* MFG_GMCREF_SEL = "2" *) EHXPLLL #(
		.PLLRST_ENA("DISABLED"),
		.INTFB_WAKE("DISABLED"),
		.STDBY_ENABLE("DISABLED"),
		.DPHASE_SOURCE("DISABLED"),
		.OUTDIVIDER_MUXA("DIVA"),
		.OUTDIVIDER_MUXB("DIVB"),
		.OUTDIVIDER_MUXC("DIVC"),
		.OUTDIVIDER_MUXD("DIVD"),
		.CLKI_DIV(5),
		.CLKOP_ENABLE("ENABLED"),
		.CLKOP_DIV(60),
		.CLKOP_CPHASE(30),
		.CLKOP_FPHASE(0),
		.FEEDBK_PATH("INT_OP"),
		.CLKFB_DIV(2)
	) pll_i(
		.RST(1'b0),
		.STDBY(1'b0),
		.CLKI(input_clk_25MHz),
		.CLKOP(clk_proc),
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
module Disasm (
	insn,
	disasm
);
	parameter signed [7:0] PREFIX = "D";
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
module DatapathPipelined (
	clk,
	rst,
	pc_to_imem,
	insn_from_imem,
	addr_to_dmem,
	load_data_from_dmem,
	store_data_to_dmem,
	store_we_to_dmem,
	halt,
	trace_completed_pc,
	trace_completed_insn,
	trace_completed_cycle_status
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	output wire [31:0] pc_to_imem;
	input wire [31:0] insn_from_imem;
	output reg [31:0] addr_to_dmem;
	input wire [31:0] load_data_from_dmem;
	output reg [31:0] store_data_to_dmem;
	output reg [3:0] store_we_to_dmem;
	output wire halt;
	output wire [31:0] trace_completed_pc;
	output wire [31:0] trace_completed_insn;
	output wire [31:0] trace_completed_cycle_status;
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
	reg [31:0] f_pc_current;
	reg [31:0] f_cycle_status;
	reg x_branch_taken;
	reg [31:0] x_branch_target;
	reg [95:0] decode_state;
	wire [4:0] d_rs1 = decode_state[51:47];
	wire [4:0] d_rs2 = decode_state[56:52];
	reg [170:0] div_q [0:6];
	reg [335:0] execute_state;
	wire [2:0] x_funct3 = execute_state[286:284];
	wire [6:0] x_funct7 = execute_state[303:297];
	wire [6:0] x_opcode = execute_state[278:272];
	wire x_is_div_op = ((x_opcode == OpcodeRegReg) && (x_funct7 == 7'd1)) && ((((x_funct3 == 3'b100) || (x_funct3 == 3'b101)) || (x_funct3 == 3'b110)) || (x_funct3 == 3'b111));
	wire d_div_dependent = (((((((x_is_div_op && (execute_state[229-:5] != 5'd0)) && ((execute_state[229-:5] == d_rs1) || (execute_state[229-:5] == d_rs2))) || ((div_q[0][170] && (div_q[0][73-:5] != 5'd0)) && ((div_q[0][73-:5] == d_rs1) || (div_q[0][73-:5] == d_rs2)))) || ((div_q[1][170] && (div_q[1][73-:5] != 5'd0)) && ((div_q[1][73-:5] == d_rs1) || (div_q[1][73-:5] == d_rs2)))) || ((div_q[2][170] && (div_q[2][73-:5] != 5'd0)) && ((div_q[2][73-:5] == d_rs1) || (div_q[2][73-:5] == d_rs2)))) || ((div_q[3][170] && (div_q[3][73-:5] != 5'd0)) && ((div_q[3][73-:5] == d_rs1) || (div_q[3][73-:5] == d_rs2)))) || ((div_q[4][170] && (div_q[4][73-:5] != 5'd0)) && ((div_q[4][73-:5] == d_rs1) || (div_q[4][73-:5] == d_rs2)))) || ((div_q[5][170] && (div_q[5][73-:5] != 5'd0)) && ((div_q[5][73-:5] == d_rs1) || (div_q[5][73-:5] == d_rs2)));
	wire [2:0] d_funct3 = decode_state[46:44];
	wire [6:0] d_funct7 = decode_state[63:57];
	wire [6:0] d_opcode = decode_state[38:32];
	wire d_is_div_op = ((d_opcode == OpcodeRegReg) && (d_funct7 == 7'd1)) && ((((d_funct3 == 3'b100) || (d_funct3 == 3'b101)) || (d_funct3 == 3'b110)) || (d_funct3 == 3'b111));
	wire div_inflight = (((((x_is_div_op || div_q[0][170]) || div_q[1][170]) || div_q[2][170]) || div_q[3][170]) || div_q[4][170]) || div_q[5][170];
	wire d_div_stall = (!x_branch_taken && div_inflight) && (d_is_div_op ? d_div_dependent : 1'b1);
	reg d_uses_rs1;
	reg d_uses_rs2;
	wire x_is_load_in_exec = execute_state[278:272] == OpcodeLoad;
	wire d_load_use_stall = ((!x_branch_taken && x_is_load_in_exec) && (execute_state[229-:5] != 5'd0)) && ((d_uses_rs1 && (execute_state[229-:5] == d_rs1)) || ((d_uses_rs2 && (execute_state[229-:5] == d_rs2)) && (d_opcode != OpcodeStore)));
	always @(posedge clk)
		if (rst) begin
			f_pc_current <= 32'd0;
			f_cycle_status <= 32'd1;
		end
		else begin
			f_cycle_status <= 32'd1;
			if (x_branch_taken)
				f_pc_current <= x_branch_target;
			else if (d_load_use_stall || d_div_stall)
				f_pc_current <= f_pc_current;
			else
				f_pc_current <= f_pc_current + 32'd4;
		end
	assign pc_to_imem = f_pc_current;
	wire [31:0] f_insn = insn_from_imem;
	wire [255:0] f_disasm;
	Disasm #(.PREFIX("F")) disasm_0fetch(
		.insn(f_insn),
		.disasm(f_disasm)
	);
	wire flush_fd = x_branch_taken;
	always @(posedge clk)
		if (rst)
			decode_state <= 96'h000000000000000000000004;
		else if (flush_fd)
			decode_state <= 96'h000000000000000000000008;
		else if (d_load_use_stall || d_div_stall)
			decode_state <= decode_state;
		else
			decode_state <= {f_pc_current, f_insn, f_cycle_status};
	wire [255:0] d_disasm;
	Disasm #(.PREFIX("D")) disasm_1decode(
		.insn(decode_state[63-:32]),
		.disasm(d_disasm)
	);
	wire [4:0] d_rd = decode_state[43:39];
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
			OpcodeBranch, OpcodeStore, OpcodeMiscMem: d_rf_we = 1'b0;
			OpcodeEnviron: d_rf_we = 1'b0;
			default: d_rf_we = 1'b1;
		endcase
	end
	wire flush_dx = x_branch_taken;
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	always @(posedge clk)
		if (rst)
			execute_state <= 336'h4000000000000000000000000000000000000000000000000000000000000;
		else if (flush_dx)
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
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
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
	reg [7:0] m_load_byte;
	reg [15:0] m_load_half;
	wire [4:0] m_store_rs2 = memory_state[164:160];
	reg [31:0] m_store_data;
	always @(*) begin
		if (_sv2v_0)
			;
		if (((memory_state[67] && writeback_state[1]) && (writeback_state[38-:5] != 5'd0)) && (writeback_state[38-:5] == m_store_rs2))
			m_store_data = writeback_state[33-:32];
		else
			m_store_data = memory_state[31-:32];
	end
	always @(*) begin
		if (_sv2v_0)
			;
		m_rd_data = memory_state[102-:32];
		addr_to_dmem = 32'd0;
		store_data_to_dmem = 32'd0;
		store_we_to_dmem = 4'b0000;
		m_load_byte = 8'd0;
		m_load_half = 16'd0;
		if (memory_state[68]) begin
			addr_to_dmem = {memory_state[63:34], 2'b00};
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
		else if (memory_state[67]) begin
			addr_to_dmem = {memory_state[63:34], 2'b00};
			case (memory_state[66-:3])
				3'b000:
					case (memory_state[33:32])
						2'b00: begin
							store_we_to_dmem = 4'b0001;
							store_data_to_dmem = {24'd0, m_store_data[7:0]};
						end
						2'b01: begin
							store_we_to_dmem = 4'b0010;
							store_data_to_dmem = {16'd0, m_store_data[7:0], 8'd0};
						end
						2'b10: begin
							store_we_to_dmem = 4'b0100;
							store_data_to_dmem = {8'd0, m_store_data[7:0], 16'd0};
						end
						2'b11: begin
							store_we_to_dmem = 4'b1000;
							store_data_to_dmem = {m_store_data[7:0], 24'd0};
						end
					endcase
				3'b001:
					case (memory_state[33])
						1'b0: begin
							store_we_to_dmem = 4'b0011;
							store_data_to_dmem = {16'd0, m_store_data[15:0]};
						end
						1'b1: begin
							store_we_to_dmem = 4'b1100;
							store_data_to_dmem = {m_store_data[15:0], 16'd0};
						end
					endcase
				3'b010: begin
					store_we_to_dmem = 4'b1111;
					store_data_to_dmem = m_store_data;
				end
				default: begin
					store_we_to_dmem = 4'b0000;
					store_data_to_dmem = 32'd0;
				end
			endcase
		end
	end
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
endmodule
module MemorySingleCycle (
	rst,
	clk,
	pc_to_imem,
	insn_from_imem,
	addr_to_dmem,
	load_data_from_dmem,
	store_data_to_dmem,
	store_we_to_dmem
);
	reg _sv2v_0;
	parameter signed [31:0] NUM_WORDS = 512;
	input wire rst;
	input wire clk;
	input wire [31:0] pc_to_imem;
	output reg [31:0] insn_from_imem;
	input wire [31:0] addr_to_dmem;
	output reg [31:0] load_data_from_dmem;
	input wire [31:0] store_data_to_dmem;
	input wire [3:0] store_we_to_dmem;
	reg [31:0] mem_array [0:NUM_WORDS - 1];
	initial $readmemh("mem_initial_contents.hex", mem_array);
	always @(*)
		if (_sv2v_0)
			;
	localparam signed [31:0] AddrMsb = $clog2(NUM_WORDS) + 1;
	localparam signed [31:0] AddrLsb = 2;
	always @(negedge clk)
		if (rst)
			;
		else
			insn_from_imem <= mem_array[{pc_to_imem[AddrMsb:AddrLsb]}];
	always @(negedge clk)
		if (rst)
			;
		else begin
			if (store_we_to_dmem[0])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][7:0] <= store_data_to_dmem[7:0];
			if (store_we_to_dmem[1])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][15:8] <= store_data_to_dmem[15:8];
			if (store_we_to_dmem[2])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][23:16] <= store_data_to_dmem[23:16];
			if (store_we_to_dmem[3])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][31:24] <= store_data_to_dmem[31:24];
			load_data_from_dmem <= mem_array[{addr_to_dmem[AddrMsb:AddrLsb]}];
		end
	initial _sv2v_0 = 0;
endmodule
module SystemDemo (
	external_clk_25MHz,
	btn,
	led,
	gp
);
	input wire external_clk_25MHz;
	input wire [6:0] btn;
	output wire [7:0] led;
	output wire [27:0] gp;
	localparam signed [31:0] MmapGpioStart = 32'hff001000;
	localparam signed [31:0] LastGpioIndex = 27;
	localparam signed [31:0] MmapGpioEnd = MmapGpioStart + LastGpioIndex;
	localparam signed [31:0] MmapLeds = 32'hff002000;
	localparam signed [31:0] MmapButtons = 32'hff003000;
	wire clk_proc;
	wire clk_locked;
	MyClockGen clock_gen(
		.input_clk_25MHz(external_clk_25MHz),
		.clk_proc(clk_proc),
		.locked(clk_locked)
	);
	wire [31:0] pc_to_imem;
	wire [31:0] insn_from_imem;
	wire [31:0] mem_data_addr;
	wire [31:0] mem_data_loaded_value;
	wire [31:0] mem_data_to_write;
	wire [3:0] mem_data_we;
	wire [31:0] trace_writeback_pc;
	wire [31:0] trace_writeback_insn;
	wire [31:0] trace_writeback_cycle_status;
	wire is_gpio_write = (mem_data_we != 0) && ((MmapGpioStart <= mem_data_addr) && (mem_data_addr <= MmapGpioEnd));
	wire is_led_write = (mem_data_we != 0) && (mem_data_addr == MmapLeds);
	wire is_button_read = mem_data_addr == MmapButtons;
	reg [7:0] led_reg;
	reg [27:0] gpio_reg;
	always @(posedge clk_proc)
		if (!clk_locked) begin
			led_reg <= 0;
			gpio_reg <= 0;
		end
		else if (is_gpio_write)
			gpio_reg[mem_data_addr - MmapGpioStart] <= mem_data_to_write[0];
		else if (is_led_write)
			led_reg <= mem_data_to_write[7:0];
	assign gp = gpio_reg;
	assign led = led_reg;
	MemorySingleCycle #(.NUM_WORDS(1024)) memory(
		.rst(!clk_locked),
		.clk(clk_proc),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.load_data_from_dmem(mem_data_loaded_value),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem((is_gpio_write ? 4'd0 : mem_data_we))
	);
	DatapathPipelined datapath(
		.clk(clk_proc),
		.rst(!clk_locked),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem(mem_data_we),
		.load_data_from_dmem(mem_data_loaded_value),
		.halt(),
		.trace_completed_pc(trace_writeback_pc),
		.trace_completed_insn(trace_writeback_insn),
		.trace_completed_cycle_status(trace_writeback_cycle_status)
	);
endmodule
module MyClockGen (
	input_clk_25MHz,
	clk_proc,
	locked
);
	input input_clk_25MHz;
	output wire clk_proc;
	output wire locked;
	wire clkfb;
	(* FREQUENCY_PIN_CLKI = "25" *) (* FREQUENCY_PIN_CLKOP = "20" *) (* ICP_CURRENT = "12" *) (* LPF_RESISTOR = "8" *) (* MFG_ENABLE_FILTEROPAMP = "1" *) (* MFG_GMCREF_SEL = "2" *) EHXPLLL #(
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
		.CLKOP_DIV(30),
		.CLKOP_CPHASE(15),
		.CLKOP_FPHASE(0),
		.FEEDBK_PATH("INT_OP"),
		.CLKFB_DIV(4)
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
	output wire [31:0] addr_to_dmem;
	input wire [31:0] load_data_from_dmem;
	output wire [31:0] store_data_to_dmem;
	output wire [3:0] store_we_to_dmem;
	output wire halt;
	output wire [31:0] trace_completed_pc;
	output wire [31:0] trace_completed_insn;
	output wire [31:0] trace_completed_cycle_status;
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
	always @(posedge clk)
		if (rst) begin
			f_pc_current <= 32'd0;
			f_cycle_status <= 32'd1;
		end
		else begin
			f_cycle_status <= 32'd1;
			if (x_branch_taken)
				f_pc_current <= x_branch_target;
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
	reg [95:0] decode_state;
	wire flush_fd = x_branch_taken;
	always @(posedge clk)
		if (rst)
			decode_state <= 96'h000000000000000000000004;
		else if (flush_fd)
			decode_state <= 96'h000000000000000000000008;
		else
			decode_state <= {f_pc_current, f_insn, f_cycle_status};
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
	reg [303:0] execute_state;
	wire flush_dx = x_branch_taken;
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	always @(posedge clk)
		if (rst)
			execute_state <= 304'h40000000000000000000000000000000000000000000000000000;
		else if (flush_dx)
			execute_state <= 304'h80000000000000000000000000000000000000000000000000000;
		else
			execute_state <= {sv2v_cast_32(decode_state[95-:32]), sv2v_cast_32(decode_state[63-:32]), sv2v_cast_32(decode_state[31-:32]), d_rs1, d_rs2, d_rd, d_rs1_data, d_rs2_data, d_imm_i_sext, d_imm_b_sext, d_imm_j_sext, d_imm_u, d_rf_we};
	wire [255:0] x_disasm;
	Disasm #(.PREFIX("X")) disasm_2execute(
		.insn(execute_state[271-:32]),
		.disasm(x_disasm)
	);
	wire [6:0] x_opcode = execute_state[246:240];
	wire [2:0] x_funct3 = execute_state[254:252];
	wire [6:0] x_funct7 = execute_state[271:265];
	wire [4:0] x_imm_shamt = execute_state[264:260];
	reg [134:0] memory_state;
	reg [133:0] writeback_state;
	reg [31:0] x_rs1;
	reg [31:0] x_rs2;
	always @(*) begin
		if (_sv2v_0)
			;
		if ((memory_state[1] && (memory_state[38-:5] != 5'd0)) && (memory_state[38-:5] == execute_state[207-:5]))
			x_rs1 = memory_state[33-:32];
		else if ((writeback_state[0] && (writeback_state[37-:5] != 5'd0)) && (writeback_state[37-:5] == execute_state[207-:5]))
			x_rs1 = writeback_state[32-:32];
		else
			x_rs1 = execute_state[192-:32];
		if ((memory_state[1] && (memory_state[38-:5] != 5'd0)) && (memory_state[38-:5] == execute_state[202-:5]))
			x_rs2 = memory_state[33-:32];
		else if ((writeback_state[0] && (writeback_state[37-:5] != 5'd0)) && (writeback_state[37-:5] == execute_state[202-:5]))
			x_rs2 = writeback_state[32-:32];
		else
			x_rs2 = execute_state[160-:32];
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
	reg [31:0] x_rd_data;
	reg x_rf_we;
	reg x_halt;
	wire signed [31:0] x_s_rs1 = $signed(x_rs1);
	wire signed [31:0] x_s_rs2 = $signed(x_rs2);
	wire signed [31:0] x_s_imm_i = $signed(execute_state[128-:32]);
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
		case (x_opcode)
			OpcodeLui: x_rd_data = execute_state[32-:32];
			OpcodeAuipc: x_rd_data = execute_state[303-:32] + execute_state[32-:32];
			OpcodeJal: begin
				x_rd_data = execute_state[303-:32] + 32'd4;
				x_branch_taken = 1'b1;
				x_branch_target = execute_state[303-:32] + execute_state[64-:32];
			end
			OpcodeJalr: begin
				x_alu_a = x_rs1;
				x_alu_b = execute_state[128-:32];
				x_alu_cin = 1'b0;
				x_rd_data = execute_state[303-:32] + 32'd4;
				x_branch_taken = 1'b1;
				x_branch_target = {x_alu_sum[31:1], 1'b0};
			end
			OpcodeRegImm:
				case (x_funct3)
					3'b000: begin
						x_alu_a = x_rs1;
						x_alu_b = execute_state[128-:32];
						x_alu_cin = 1'b0;
						x_rd_data = x_alu_sum;
					end
					3'b010: x_rd_data = (x_s_rs1 < x_s_imm_i ? 32'd1 : 32'd0);
					3'b011: x_rd_data = (x_rs1 < execute_state[128-:32] ? 32'd1 : 32'd0);
					3'b100: x_rd_data = x_rs1 ^ execute_state[128-:32];
					3'b110: x_rd_data = x_rs1 | execute_state[128-:32];
					3'b111: x_rd_data = x_rs1 & execute_state[128-:32];
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
				else if (x_funct7 == 7'd1) begin : sv2v_autoblock_1
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
						default: x_rf_we = 1'b0;
					endcase
				end
				else
					x_rf_we = 1'b0;
			OpcodeBranch: begin
				x_rf_we = 1'b0;
				begin : sv2v_autoblock_2
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
						x_branch_target = execute_state[303-:32] + execute_state[96-:32];
					end
				end
			end
			OpcodeEnviron: begin
				if (execute_state[271:247] == 25'd0)
					x_halt = 1'b1;
				x_rf_we = 1'b0;
			end
			OpcodeMiscMem: x_rf_we = 1'b0;
			default: x_rf_we = 1'b0;
		endcase
	end
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	always @(posedge clk)
		if (rst)
			memory_state <= 135'h0000000000000000000000020000000000;
		else
			memory_state <= {sv2v_cast_32(execute_state[303-:32]), sv2v_cast_32(execute_state[271-:32]), sv2v_cast_32(execute_state[239-:32]), sv2v_cast_5(execute_state[197-:5]), x_rd_data, x_rf_we, x_halt};
	wire [255:0] m_disasm;
	Disasm #(.PREFIX("M")) disasm_3memory(
		.insn(memory_state[102-:32]),
		.disasm(m_disasm)
	);
	assign addr_to_dmem = 32'd0;
	assign store_data_to_dmem = 32'd0;
	assign store_we_to_dmem = 4'b0000;
	assign halt = memory_state[0];
	always @(posedge clk)
		if (rst)
			writeback_state <= 134'h0000000000000000000000010000000000;
		else
			writeback_state <= {sv2v_cast_32(memory_state[134-:32]), sv2v_cast_32(memory_state[102-:32]), sv2v_cast_32(memory_state[70-:32]), sv2v_cast_5(memory_state[38-:5]), sv2v_cast_32(memory_state[33-:32]), memory_state[1]};
	wire [255:0] w_disasm;
	Disasm #(.PREFIX("W")) disasm_4writeback(
		.insn(writeback_state[101-:32]),
		.disasm(w_disasm)
	);
	assign w_rf_we = writeback_state[0];
	assign w_rd = writeback_state[37-:5];
	assign w_rd_data = writeback_state[32-:32];
	assign trace_completed_pc = writeback_state[133-:32];
	assign trace_completed_insn = writeback_state[101-:32];
	assign trace_completed_cycle_status = writeback_state[69-:32];
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
module SystemResourceCheck (
	external_clk_25MHz,
	btn,
	led
);
	input wire external_clk_25MHz;
	input wire [6:0] btn;
	output wire [7:0] led;
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
	MemorySingleCycle #(.NUM_WORDS(128)) memory(
		.rst(!clk_locked),
		.clk(clk_proc),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.load_data_from_dmem(mem_data_loaded_value),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem(mem_data_we)
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
		.halt(led[0]),
		.trace_completed_pc(trace_writeback_pc),
		.trace_completed_insn(trace_writeback_insn),
		.trace_completed_cycle_status(trace_writeback_cycle_status)
	);
endmodule
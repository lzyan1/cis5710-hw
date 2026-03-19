module MyClockGen (
	input_clk_25MHz,
	clk_proc,
	clk_mem,
	locked
);
	input input_clk_25MHz;
	output wire clk_proc;
	output wire clk_mem;
	output wire locked;
	wire clkfb;
	(* FREQUENCY_PIN_CLKI = "25" *) (* FREQUENCY_PIN_CLKOP = "3.57143" *) (* FREQUENCY_PIN_CLKOS = "3.50932" *) (* ICP_CURRENT = "12" *) (* LPF_RESISTOR = "8" *) (* MFG_ENABLE_FILTEROPAMP = "1" *) (* MFG_GMCREF_SEL = "2" *) EHXPLLL #(
		.PLLRST_ENA("DISABLED"),
		.INTFB_WAKE("DISABLED"),
		.STDBY_ENABLE("DISABLED"),
		.DPHASE_SOURCE("DISABLED"),
		.OUTDIVIDER_MUXA("DIVA"),
		.OUTDIVIDER_MUXB("DIVB"),
		.OUTDIVIDER_MUXC("DIVC"),
		.OUTDIVIDER_MUXD("DIVD"),
		.CLKI_DIV(7),
		.CLKOP_ENABLE("ENABLED"),
		.CLKOP_DIV(113),
		.CLKOP_CPHASE(56),
		.CLKOP_FPHASE(0),
		.CLKOS_ENABLE("ENABLED"),
		.CLKOS_DIV(115),
		.CLKOS_CPHASE(84),
		.CLKOS_FPHASE(5),
		.FEEDBK_PATH("INT_OP"),
		.CLKFB_DIV(1)
	) pll_i(
		.RST(1'b0),
		.STDBY(1'b0),
		.CLKI(input_clk_25MHz),
		.CLKOP(clk_proc),
		.CLKOS(clk_mem),
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
module DividerUnsigned (
	i_dividend,
	i_divisor,
	o_remainder,
	o_quotient
);
	input wire [31:0] i_dividend;
	input wire [31:0] i_divisor;
	output wire [31:0] o_remainder;
	output wire [31:0] o_quotient;
	wire [31:0] dvd [0:32];
	wire [31:0] rem [0:32];
	wire [31:0] quo [0:32];
	assign dvd[0] = i_dividend;
	assign rem[0] = 32'b00000000000000000000000000000000;
	assign quo[0] = 32'b00000000000000000000000000000000;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < 32; _gv_i_1 = _gv_i_1 + 1) begin : genblk1
			localparam i = _gv_i_1;
			DividerOneIter f(
				.i_dividend(dvd[i]),
				.i_divisor(i_divisor),
				.i_remainder(rem[i]),
				.i_quotient(quo[i]),
				.o_dividend(dvd[i + 1]),
				.o_remainder(rem[i + 1]),
				.o_quotient(quo[i + 1])
			);
		end
	endgenerate
	assign o_remainder = rem[32];
	assign o_quotient = quo[32];
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
	genvar _gv_i_2;
	generate
		for (_gv_i_2 = 0; _gv_i_2 < 32; _gv_i_2 = _gv_i_2 + 1) begin : GEN_GP1
			localparam i = _gv_i_2;
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
		for (_gv_i_2 = 0; _gv_i_2 < 32; _gv_i_2 = _gv_i_2 + 1) begin : GEN_SUM
			localparam i = _gv_i_2;
			assign sum[i] = (a[i] ^ b[i]) ^ cbit[i];
		end
	endgenerate
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
		rs1_data = (rs1 == 5'd0 ? 32'd0 : regs[rs1]);
		rs2_data = (rs2 == 5'd0 ? 32'd0 : regs[rs2]);
	end
	integer i;
	always @(posedge clk)
		if (rst)
			for (i = 0; i < NumRegs; i = i + 1)
				regs[i] <= 32'd0;
		else begin
			if (we && (rd != 5'd0))
				regs[rd] <= rd_data;
			regs[0] <= 32'd0;
		end
	initial _sv2v_0 = 0;
endmodule
module DatapathSingleCycle (
	clk,
	rst,
	halt,
	pc_to_imem,
	insn_from_imem,
	addr_to_dmem,
	load_data_from_dmem,
	store_data_to_dmem,
	store_we_to_dmem,
	trace_completed_pc,
	trace_completed_insn,
	trace_completed_cycle_status
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	output reg halt;
	output wire [31:0] pc_to_imem;
	input wire [31:0] insn_from_imem;
	output reg [31:0] addr_to_dmem;
	input wire [31:0] load_data_from_dmem;
	output reg [31:0] store_data_to_dmem;
	output reg [3:0] store_we_to_dmem;
	output reg [31:0] trace_completed_pc;
	output reg [31:0] trace_completed_insn;
	output reg [31:0] trace_completed_cycle_status;
	wire [6:0] insn_funct7;
	wire [4:0] insn_rs2;
	wire [4:0] insn_rs1;
	wire [2:0] insn_funct3;
	wire [4:0] insn_rd;
	wire [6:0] insn_opcode;
	assign {insn_funct7, insn_rs2, insn_rs1, insn_funct3, insn_rd, insn_opcode} = insn_from_imem;
	wire [11:0] imm_i;
	assign imm_i = insn_from_imem[31:20];
	wire [4:0] imm_shamt = insn_from_imem[24:20];
	wire [11:0] imm_s;
	assign imm_s[11:5] = insn_funct7;
	assign imm_s[4:0] = insn_rd;
	wire [12:0] imm_b;
	assign {imm_b[12], imm_b[10:5]} = insn_funct7;
	assign {imm_b[4:1], imm_b[11]} = insn_rd;
	assign imm_b[0] = 1'b0;
	wire [20:0] imm_j;
	assign {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12], imm_j[0]} = {insn_from_imem[31:12], 1'b0};
	wire [31:0] imm_i_sext = {{20 {imm_i[11]}}, imm_i[11:0]};
	wire [31:0] imm_s_sext = {{20 {imm_s[11]}}, imm_s[11:0]};
	wire [31:0] imm_b_sext = {{19 {imm_b[12]}}, imm_b[12:0]};
	wire [31:0] imm_j_sext = {{11 {imm_j[20]}}, imm_j[20:0]};
	localparam [6:0] OpLoad = 7'b0000011;
	localparam [6:0] OpStore = 7'b0100011;
	localparam [6:0] OpBranch = 7'b1100011;
	localparam [6:0] OpJalr = 7'b1100111;
	localparam [6:0] OpMiscMem = 7'b0001111;
	localparam [6:0] OpJal = 7'b1101111;
	localparam [6:0] OpRegImm = 7'b0010011;
	localparam [6:0] OpRegReg = 7'b0110011;
	localparam [6:0] OpEnviron = 7'b1110011;
	localparam [6:0] OpAuipc = 7'b0010111;
	localparam [6:0] OpLui = 7'b0110111;
	wire insn_lui = insn_opcode == OpLui;
	wire insn_auipc = insn_opcode == OpAuipc;
	wire insn_jal = insn_opcode == OpJal;
	wire insn_jalr = insn_opcode == OpJalr;
	wire insn_beq = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b000);
	wire insn_bne = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b001);
	wire insn_blt = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b100);
	wire insn_bge = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b101);
	wire insn_bltu = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b110);
	wire insn_bgeu = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b111);
	wire insn_lb = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b000);
	wire insn_lh = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b001);
	wire insn_lw = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b010);
	wire insn_lbu = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b100);
	wire insn_lhu = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b101);
	wire insn_sb = (insn_opcode == OpStore) && (insn_from_imem[14:12] == 3'b000);
	wire insn_sh = (insn_opcode == OpStore) && (insn_from_imem[14:12] == 3'b001);
	wire insn_sw = (insn_opcode == OpStore) && (insn_from_imem[14:12] == 3'b010);
	wire insn_addi = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b000);
	wire insn_slti = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b010);
	wire insn_sltiu = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b011);
	wire insn_xori = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b100);
	wire insn_ori = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b110);
	wire insn_andi = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b111);
	wire insn_slli = ((insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b001)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_srli = ((insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b101)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_srai = ((insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b101)) && (insn_from_imem[31:25] == 7'b0100000);
	wire insn_add = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b000)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_sub = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b000)) && (insn_from_imem[31:25] == 7'b0100000);
	wire insn_sll = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b001)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_slt = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b010)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_sltu = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b011)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_xor = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b100)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_srl = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b101)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_sra = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b101)) && (insn_from_imem[31:25] == 7'b0100000);
	wire insn_or = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b110)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_and = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b111)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_mul = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b000);
	wire insn_mulh = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b001);
	wire insn_mulhsu = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b010);
	wire insn_mulhu = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b011);
	wire insn_div = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b100);
	wire insn_divu = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b101);
	wire insn_rem = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b110);
	wire insn_remu = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b111);
	wire insn_ecall = (insn_opcode == OpEnviron) && (insn_from_imem[31:7] == 25'd0);
	wire insn_fence = insn_opcode == OpMiscMem;
	reg [31:0] pcNext;
	reg [31:0] pcCurrent;
	always @(posedge clk)
		if (rst)
			pcCurrent <= 32'd0;
		else
			pcCurrent <= pcNext;
	assign pc_to_imem = pcCurrent;
	reg [31:0] cycles_current;
	reg [31:0] num_insns_current;
	always @(posedge clk)
		if (rst) begin
			cycles_current <= 0;
			num_insns_current <= 0;
		end
		else begin
			cycles_current <= cycles_current + 1;
			num_insns_current <= num_insns_current + 1;
		end
	reg rf_we;
	reg [4:0] rf_rd;
	reg [31:0] rf_wdata;
	wire [31:0] rs1_data;
	wire [31:0] rs2_data;
	RegFile rf(
		.clk(clk),
		.rst(rst),
		.we(rf_we),
		.rd(rf_rd),
		.rd_data(rf_wdata),
		.rs1(insn_rs1),
		.rs2(insn_rs2),
		.rs1_data(rs1_data),
		.rs2_data(rs2_data)
	);
	reg illegal_insn;
	wire [31:0] lui_imm = {insn_from_imem[31:12], 12'b000000000000};
	wire [4:0] shamt_reg = rs2_data[4:0];
	wire signed [31:0] s_rs1 = $signed(rs1_data);
	wire signed [31:0] s_rs2 = $signed(rs2_data);
	wire signed [31:0] s_imm_i = $signed(imm_i_sext);
	reg [31:0] alu_a;
	reg [31:0] alu_b;
	reg alu_cin;
	wire [31:0] alu_sum;
	reg [31:0] div_a;
	reg [31:0] div_b;
	wire [31:0] div_q;
	wire [31:0] div_r;
	CarryLookaheadAdder u_cla(
		.a(alu_a),
		.b(alu_b),
		.cin(alu_cin),
		.sum(alu_sum)
	);
	DividerUnsigned u_divu(
		.i_dividend(div_a),
		.i_divisor(div_b),
		.o_quotient(div_q),
		.o_remainder(div_r)
	);
	reg [31:0] eff_addr;
	reg [31:0] aligned_addr;
	reg [1:0] addr_off;
	reg [7:0] load_byte;
	reg [15:0] load_half;
	reg [31:0] shifted;
	always @(*) begin
		if (_sv2v_0)
			;
		alu_a = rs1_data;
		alu_b = rs2_data;
		alu_cin = 1'b0;
		if (insn_addi)
			alu_b = imm_i_sext;
		if (insn_sub) begin
			alu_b = ~rs2_data;
			alu_cin = 1'b1;
		end
		div_a = rs1_data;
		div_b = rs2_data;
		if (insn_div || insn_rem) begin
			div_a = (rs1_data[31] ? ~rs1_data + 1 : rs1_data);
			div_b = (rs2_data[31] ? ~rs2_data + 1 : rs2_data);
		end
		illegal_insn = 1'b0;
		trace_completed_pc = pcCurrent;
		trace_completed_insn = insn_from_imem;
		trace_completed_cycle_status = 32'd1;
		addr_to_dmem = 32'd0;
		store_data_to_dmem = 32'd0;
		store_we_to_dmem = 4'b0000;
		pcNext = pcCurrent + 32'd4;
		rf_we = 1'b0;
		rf_rd = insn_rd;
		rf_wdata = 32'd0;
		halt = 1'b0;
		eff_addr = 32'd0;
		aligned_addr = 32'd0;
		addr_off = 2'b00;
		load_byte = 8'd0;
		load_half = 16'd0;
		case (insn_opcode)
			OpMiscMem:
				if (!insn_fence)
					illegal_insn = 1'b1;
			OpEnviron:
				if (insn_ecall)
					halt = 1'b1;
				else
					illegal_insn = 1'b1;
			OpLui: begin
				rf_we = 1'b1;
				rf_wdata = lui_imm;
			end
			OpAuipc: begin
				rf_we = 1'b1;
				rf_wdata = pcCurrent + lui_imm;
			end
			OpJal: begin
				rf_we = 1'b1;
				rf_wdata = pcCurrent + 32'd4;
				pcNext = pcCurrent + imm_j_sext;
			end
			OpJalr: begin
				rf_we = 1'b1;
				rf_wdata = pcCurrent + 32'd4;
				pcNext = (rs1_data + imm_i_sext) & 32'hfffffffe;
			end
			OpRegImm:
				case (insn_funct3)
					3'b000: begin
						rf_we = 1'b1;
						rf_wdata = alu_sum;
					end
					3'b010: begin
						rf_we = 1'b1;
						rf_wdata = (s_rs1 < s_imm_i ? 32'd1 : 32'd0);
					end
					3'b011: begin
						rf_we = 1'b1;
						rf_wdata = (rs1_data < imm_i_sext ? 32'd1 : 32'd0);
					end
					3'b100: begin
						rf_we = 1'b1;
						rf_wdata = rs1_data ^ imm_i_sext;
					end
					3'b110: begin
						rf_we = 1'b1;
						rf_wdata = rs1_data | imm_i_sext;
					end
					3'b111: begin
						rf_we = 1'b1;
						rf_wdata = rs1_data & imm_i_sext;
					end
					3'b001:
						if (insn_from_imem[31:25] == 7'd0) begin
							rf_we = 1'b1;
							rf_wdata = rs1_data << imm_shamt;
						end
						else
							illegal_insn = 1'b1;
					3'b101:
						if (insn_from_imem[31:25] == 7'd0) begin
							rf_we = 1'b1;
							rf_wdata = rs1_data >> imm_shamt;
						end
						else if (insn_from_imem[31:25] == 7'b0100000) begin
							rf_we = 1'b1;
							rf_wdata = $signed(rs1_data) >>> imm_shamt;
						end
						else
							illegal_insn = 1'b1;
					default: illegal_insn = 1'b1;
				endcase
			OpRegReg:
				if (insn_funct7 == 7'd0)
					case (insn_funct3)
						3'b000: begin
							rf_we = 1'b1;
							rf_wdata = alu_sum;
						end
						3'b001: begin
							rf_we = 1'b1;
							rf_wdata = rs1_data << shamt_reg;
						end
						3'b010: begin
							rf_we = 1'b1;
							rf_wdata = (s_rs1 < s_rs2 ? 32'd1 : 32'd0);
						end
						3'b011: begin
							rf_we = 1'b1;
							rf_wdata = (rs1_data < rs2_data ? 32'd1 : 32'd0);
						end
						3'b100: begin
							rf_we = 1'b1;
							rf_wdata = rs1_data ^ rs2_data;
						end
						3'b101: begin
							rf_we = 1'b1;
							rf_wdata = rs1_data >> shamt_reg;
						end
						3'b110: begin
							rf_we = 1'b1;
							rf_wdata = rs1_data | rs2_data;
						end
						3'b111: begin
							rf_we = 1'b1;
							rf_wdata = rs1_data & rs2_data;
						end
						default: illegal_insn = 1'b1;
					endcase
				else if (insn_funct7 == 7'b0100000)
					case (insn_funct3)
						3'b000: begin
							rf_we = 1'b1;
							rf_wdata = alu_sum;
						end
						3'b101: begin
							rf_we = 1'b1;
							rf_wdata = $signed(rs1_data) >>> shamt_reg;
						end
						default: illegal_insn = 1'b1;
					endcase
				else if (insn_funct7 == 7'd1) begin : sv2v_autoblock_1
					reg [63:0] prod;
					reg signed [63:0] s_prod;
					reg signed [31:0] s_a32;
					reg signed [31:0] s_b32;
					reg [63:0] u_prod;
					prod = 64'd0;
					s_prod = 64'd0;
					u_prod = 64'd0;
					s_a32 = $signed(rs1_data);
					s_b32 = $signed(rs2_data);
					rf_we = 1'b1;
					(* full_case, parallel_case *)
					case (insn_funct3)
						3'b000: begin
							u_prod = $unsigned(rs1_data) * $unsigned(rs2_data);
							rf_wdata = u_prod[31:0];
						end
						3'b001: begin
							s_prod = $signed(s_a32) * $signed(s_b32);
							rf_wdata = s_prod[63:32];
						end
						3'b010: begin
							s_prod = $signed(s_a32) * $signed({1'b0, rs2_data});
							rf_wdata = s_prod[63:32];
						end
						3'b011: begin
							u_prod = $unsigned(rs1_data) * $unsigned(rs2_data);
							rf_wdata = u_prod[63:32];
						end
						3'b100, 3'b101, 3'b110, 3'b111: begin : sv2v_autoblock_2
							reg div_by_zero;
							reg signed_overflow;
							reg a_neg;
							reg b_neg;
							reg [31:0] a_abs;
							reg [31:0] b_abs;
							reg [31:0] q_u;
							reg [31:0] r_u;
							reg [31:0] q_s;
							reg [31:0] r_s;
							div_by_zero = rs2_data == 32'd0;
							signed_overflow = (rs1_data == 32'h80000000) && (rs2_data == 32'hffffffff);
							a_neg = rs1_data[31];
							b_neg = rs2_data[31];
							a_abs = (a_neg ? ~rs1_data + 32'd1 : rs1_data);
							b_abs = (b_neg ? ~rs2_data + 32'd1 : rs2_data);
							q_u = div_q;
							r_u = div_r;
							q_s = (a_neg ^ b_neg ? ~q_u + 32'd1 : q_u);
							r_s = (a_neg ? ~r_u + 32'd1 : r_u);
							(* full_case, parallel_case *)
							case (insn_funct3)
								3'b100:
									if (div_by_zero)
										rf_wdata = 32'hffffffff;
									else if (signed_overflow)
										rf_wdata = 32'h80000000;
									else
										rf_wdata = q_s;
								3'b101:
									if (div_by_zero)
										rf_wdata = 32'hffffffff;
									else
										rf_wdata = div_q;
								3'b110:
									if (div_by_zero)
										rf_wdata = rs1_data;
									else if (signed_overflow)
										rf_wdata = 32'd0;
									else
										rf_wdata = r_s;
								3'b111:
									if (div_by_zero)
										rf_wdata = rs1_data;
									else
										rf_wdata = div_r;
								default: begin
									illegal_insn = 1'b1;
									rf_we = 1'b0;
								end
							endcase
						end
						default: begin
							illegal_insn = 1'b1;
							rf_we = 1'b0;
						end
					endcase
				end
				else
					illegal_insn = 1'b1;
			OpBranch: begin : sv2v_autoblock_3
				reg take_branch;
				take_branch = 1'b0;
				(* full_case, parallel_case *)
				case (insn_funct3)
					3'b000: take_branch = rs1_data == rs2_data;
					3'b001: take_branch = rs1_data != rs2_data;
					3'b100: take_branch = s_rs1 < s_rs2;
					3'b101: take_branch = s_rs1 >= s_rs2;
					3'b110: take_branch = rs1_data < rs2_data;
					3'b111: take_branch = rs1_data >= rs2_data;
					default: illegal_insn = 1'b1;
				endcase
				if (!illegal_insn && take_branch)
					pcNext = pcCurrent + imm_b_sext;
			end
			OpLoad: begin
				eff_addr = rs1_data + imm_i_sext;
				aligned_addr = {eff_addr[31:2], 2'b00};
				addr_off = eff_addr[1:0];
				addr_to_dmem = aligned_addr;
				shifted = load_data_from_dmem >> (8 * addr_off);
				load_byte = shifted[7:0];
				shifted = load_data_from_dmem >> (16 * addr_off[1]);
				load_half = shifted[15:0];
				rf_we = 1'b1;
				(* full_case, parallel_case *)
				case (insn_funct3)
					3'b000: rf_wdata = {{24 {load_byte[7]}}, load_byte};
					3'b001:
						if (addr_off[0] != 1'b0) begin
							illegal_insn = 1'b1;
							rf_we = 1'b0;
						end
						else
							rf_wdata = {{16 {load_half[15]}}, load_half};
					3'b010:
						if (addr_off != 2'b00) begin
							illegal_insn = 1'b1;
							rf_we = 1'b0;
						end
						else
							rf_wdata = load_data_from_dmem;
					3'b100: rf_wdata = {24'd0, load_byte};
					3'b101:
						if (addr_off[0] != 1'b0) begin
							illegal_insn = 1'b1;
							rf_we = 1'b0;
						end
						else
							rf_wdata = {16'd0, load_half};
					default: begin
						illegal_insn = 1'b1;
						rf_we = 1'b0;
					end
				endcase
			end
			OpStore: begin
				eff_addr = rs1_data + imm_s_sext;
				aligned_addr = {eff_addr[31:2], 2'b00};
				addr_off = eff_addr[1:0];
				addr_to_dmem = aligned_addr;
				(* full_case, parallel_case *)
				case (insn_funct3)
					3'b000: begin
						store_we_to_dmem = 4'b0001 << addr_off;
						store_data_to_dmem = {4 {rs2_data[7:0]}};
					end
					3'b001:
						if (addr_off[0] != 1'b0)
							illegal_insn = 1'b1;
						else begin
							store_we_to_dmem = 4'b0011 << addr_off;
							store_data_to_dmem = {2 {rs2_data[15:0]}};
						end
					3'b010:
						if (addr_off != 2'b00)
							illegal_insn = 1'b1;
						else begin
							store_we_to_dmem = 4'b1111;
							store_data_to_dmem = rs2_data;
						end
					default: illegal_insn = 1'b1;
				endcase
			end
			default: illegal_insn = 1'b1;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module MemorySingleCycle (
	rst,
	clock_mem,
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
	input wire clock_mem;
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
	always @(posedge clock_mem)
		if (rst)
			;
		else
			insn_from_imem <= mem_array[{pc_to_imem[AddrMsb:AddrLsb]}];
	always @(negedge clock_mem)
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
`default_nettype none
module debouncer (
	i_clk,
	i_in,
	o_debounced,
	o_debug
);
	parameter NIN = 21;
	parameter LGWAIT = 17;
	input wire i_clk;
	input wire [NIN - 1:0] i_in;
	output reg [NIN - 1:0] o_debounced;
	output wire [30:0] o_debug;
	reg different;
	reg ztimer;
	reg [NIN - 1:0] r_in;
	reg [NIN - 1:0] q_in;
	reg [NIN - 1:0] r_last;
	reg [LGWAIT - 1:0] timer;
	initial q_in = 0;
	initial r_in = 0;
	initial different = 0;
	always @(posedge i_clk) q_in <= i_in;
	always @(posedge i_clk) r_in <= q_in;
	always @(posedge i_clk) r_last <= r_in;
	initial ztimer = 1'b1;
	initial timer = 0;
	always @(posedge i_clk)
		if (ztimer && different) begin
			timer <= {LGWAIT {1'b1}};
			ztimer <= 1'b0;
		end
		else if (!ztimer) begin
			timer <= timer - 1'b1;
			ztimer <= timer[LGWAIT - 1:1] == 0;
		end
		else begin
			ztimer <= 1'b1;
			timer <= 0;
		end
	always @(posedge i_clk) different <= (different && !ztimer) || (r_in != o_debounced);
	initial o_debounced = {NIN {1'b0}};
	always @(posedge i_clk)
		if (ztimer)
			o_debounced <= r_last;
	reg trigger;
	initial trigger = 1'b0;
	always @(posedge i_clk) trigger <= (((!ztimer && !different) && !(|i_in)) && (timer[LGWAIT - 1:2] == 0)) && timer[1];
	wire [30:0] debug;
	assign debug[30] = ztimer;
	assign debug[29] = trigger;
	assign debug[28] = 1'b0;
	generate
		if (NIN >= 14) begin : genblk1
			assign debug[27:14] = o_debounced[13:0];
			assign debug[13:0] = r_in[13:0];
		end
		else begin : genblk1
			assign debug[27:14 + NIN] = 0;
			assign debug[(14 + NIN) - 1:14] = o_debounced;
			assign debug[13:NIN] = 0;
			assign debug[NIN - 1:0] = r_in;
		end
	endgenerate
	assign o_debug = debug;
endmodule
module SystemDemo (
	external_clk_25MHz,
	btn,
	led
);
	input wire external_clk_25MHz;
	input wire [6:0] btn;
	output wire [7:0] led;
	localparam signed [31:0] MmapButtons = 32'hff001000;
	localparam signed [31:0] MmapLeds = 32'hff002000;
	wire rst_button_n;
	wire [30:0] ignore;
	wire clk_proc;
	debouncer #(.NIN(1)) db(
		.i_clk(clk_proc),
		.i_in(btn[0]),
		.o_debounced(rst_button_n),
		.o_debug(ignore)
	);
	wire clk_mem;
	wire clk_locked;
	MyClockGen clock_gen(
		.input_clk_25MHz(external_clk_25MHz),
		.clk_proc(clk_proc),
		.clk_mem(clk_mem),
		.locked(clk_locked)
	);
	wire rst = !rst_button_n || !clk_locked;
	wire [31:0] pc_to_imem;
	wire [31:0] insn_from_imem;
	wire [31:0] mem_data_addr;
	wire [31:0] mem_data_loaded_value;
	wire [31:0] mem_data_to_write;
	wire [3:0] mem_data_we;
	reg [7:0] led_state;
	assign led = led_state;
	always @(posedge clk_mem)
		if (rst)
			led_state <= 0;
		else if ((mem_data_addr == MmapLeds) && (mem_data_we[0] == 1))
			led_state <= mem_data_to_write[7:0];
	MemorySingleCycle #(.NUM_WORDS(1024)) memory(
		.rst(rst),
		.clock_mem(clk_mem),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.load_data_from_dmem(mem_data_loaded_value),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem((mem_data_addr == MmapLeds ? 4'd0 : mem_data_we))
	);
	wire halt;
	DatapathSingleCycle datapath(
		.clk(clk_proc),
		.rst(rst),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem(mem_data_we),
		.load_data_from_dmem((mem_data_addr == MmapButtons ? {25'd0, btn} : mem_data_loaded_value)),
		.halt(halt)
	);
endmodule
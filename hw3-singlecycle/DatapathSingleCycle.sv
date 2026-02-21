`timescale 1ns / 1ns

// registers are 32 bits in RV32
`define REG_SIZE 31:0

// insns are 32 bits in RV32IM
`define INSN_SIZE 31:0

// RV opcodes are 7 bits
`define OPCODE_SIZE 6:0

`include "../hw2a-divider/DividerUnsigned.sv"
`include "../hw2b-cla/CarryLookaheadAdder.sv"
`include "cycle_status.sv"

module RegFile (
    input logic [4:0] rd,
    input logic [`REG_SIZE] rd_data,
    input logic [4:0] rs1,
    output logic [`REG_SIZE] rs1_data,
    input logic [4:0] rs2,
    output logic [`REG_SIZE] rs2_data,

    input logic clk,
    input logic we,
    input logic rst
);
  localparam int NumRegs = 32;
  logic [`REG_SIZE] regs[NumRegs];

  always_comb begin
    rs1_data = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    rs2_data = (rs2 == 5'd0) ? 32'd0 : regs[rs2];
  end

  integer i;
  always_ff @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < NumRegs; i = i + 1) begin
        regs[i] <= 32'd0;
      end
    end else begin
      if (we && (rd != 5'd0)) begin
        regs[rd] <= rd_data;
      end
      regs[0] <= 32'd0;
    end
  end
endmodule

module DatapathSingleCycle (
    input wire                clk,
    input wire                rst,
    output logic              halt,
    output logic [`REG_SIZE]  pc_to_imem,
    input wire [`INSN_SIZE]   insn_from_imem,
    // addr_to_dmem is used for both loads and stores
    output logic [`REG_SIZE]  addr_to_dmem,
    input logic [`REG_SIZE]   load_data_from_dmem,
    output logic [`REG_SIZE]  store_data_to_dmem,
    output logic [3:0]        store_we_to_dmem,

    // the PC of the insn executing in the current cycle
    output logic [`REG_SIZE]  trace_completed_pc,
    // the machine code of the insn executing in the current cycle
    output logic [`INSN_SIZE] trace_completed_insn,
    // the cycle status of the current cycle: should always be CYCLE_NO_STALL
    output cycle_status_e     trace_completed_cycle_status
);

  // components of the instruction
  wire [6:0] insn_funct7;
  wire [4:0] insn_rs2;
  wire [4:0] insn_rs1;
  wire [2:0] insn_funct3;
  wire [4:0] insn_rd;
  wire [`OPCODE_SIZE] insn_opcode;

  // split R-type instruction - see section 2.2 of RiscV spec
  assign {insn_funct7, insn_rs2, insn_rs1, insn_funct3, insn_rd, insn_opcode} = insn_from_imem;

  // setup for I, S, B & J type instructions
  // I - short immediates and loads
  wire [11:0] imm_i;
  assign imm_i = insn_from_imem[31:20];
  wire [ 4:0] imm_shamt = insn_from_imem[24:20];

  // S - stores
  wire [11:0] imm_s;
  assign imm_s[11:5] = insn_funct7;
  assign imm_s[4:0] = insn_rd;

  // B - conditionals
  wire [12:0] imm_b;
  assign {imm_b[12], imm_b[10:5]} = insn_funct7, {imm_b[4:1], imm_b[11]} = insn_rd, imm_b[0] = 1'b0;

  // J - unconditional jumps
  wire [20:0] imm_j;
  assign {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12], imm_j[0]} = {insn_from_imem[31:12], 1'b0};

  wire [`REG_SIZE] imm_i_sext = {{20{imm_i[11]}}, imm_i[11:0]};
  wire [`REG_SIZE] imm_s_sext = {{20{imm_s[11]}}, imm_s[11:0]};
  wire [`REG_SIZE] imm_b_sext = {{19{imm_b[12]}}, imm_b[12:0]};
  wire [`REG_SIZE] imm_j_sext = {{11{imm_j[20]}}, imm_j[20:0]};

  // opcodes - see section 19 of RiscV spec
  localparam bit [`OPCODE_SIZE] OpLoad = 7'b00_000_11;
  localparam bit [`OPCODE_SIZE] OpStore = 7'b01_000_11;
  localparam bit [`OPCODE_SIZE] OpBranch = 7'b11_000_11;
  localparam bit [`OPCODE_SIZE] OpJalr = 7'b11_001_11;
  localparam bit [`OPCODE_SIZE] OpMiscMem = 7'b00_011_11;
  localparam bit [`OPCODE_SIZE] OpJal = 7'b11_011_11;

  localparam bit [`OPCODE_SIZE] OpRegImm = 7'b00_100_11;
  localparam bit [`OPCODE_SIZE] OpRegReg = 7'b01_100_11;
  localparam bit [`OPCODE_SIZE] OpEnviron = 7'b11_100_11;

  localparam bit [`OPCODE_SIZE] OpAuipc = 7'b00_101_11;
  localparam bit [`OPCODE_SIZE] OpLui = 7'b01_101_11;

  wire insn_lui   = insn_opcode == OpLui;
  wire insn_auipc = insn_opcode == OpAuipc;
  wire insn_jal   = insn_opcode == OpJal;
  wire insn_jalr  = insn_opcode == OpJalr;

  wire insn_beq  = insn_opcode == OpBranch && insn_from_imem[14:12] == 3'b000;
  wire insn_bne  = insn_opcode == OpBranch && insn_from_imem[14:12] == 3'b001;
  wire insn_blt  = insn_opcode == OpBranch && insn_from_imem[14:12] == 3'b100;
  wire insn_bge  = insn_opcode == OpBranch && insn_from_imem[14:12] == 3'b101;
  wire insn_bltu = insn_opcode == OpBranch && insn_from_imem[14:12] == 3'b110;
  wire insn_bgeu = insn_opcode == OpBranch && insn_from_imem[14:12] == 3'b111;

  wire insn_lb  = insn_opcode == OpLoad && insn_from_imem[14:12] == 3'b000;
  wire insn_lh  = insn_opcode == OpLoad && insn_from_imem[14:12] == 3'b001;
  wire insn_lw  = insn_opcode == OpLoad && insn_from_imem[14:12] == 3'b010;
  wire insn_lbu = insn_opcode == OpLoad && insn_from_imem[14:12] == 3'b100;
  wire insn_lhu = insn_opcode == OpLoad && insn_from_imem[14:12] == 3'b101;

  wire insn_sb = insn_opcode == OpStore && insn_from_imem[14:12] == 3'b000;
  wire insn_sh = insn_opcode == OpStore && insn_from_imem[14:12] == 3'b001;
  wire insn_sw = insn_opcode == OpStore && insn_from_imem[14:12] == 3'b010;

  wire insn_addi  = insn_opcode == OpRegImm && insn_from_imem[14:12] == 3'b000;
  wire insn_slti  = insn_opcode == OpRegImm && insn_from_imem[14:12] == 3'b010;
  wire insn_sltiu = insn_opcode == OpRegImm && insn_from_imem[14:12] == 3'b011;
  wire insn_xori  = insn_opcode == OpRegImm && insn_from_imem[14:12] == 3'b100;
  wire insn_ori   = insn_opcode == OpRegImm && insn_from_imem[14:12] == 3'b110;
  wire insn_andi  = insn_opcode == OpRegImm && insn_from_imem[14:12] == 3'b111;

  wire insn_slli = insn_opcode == OpRegImm && insn_from_imem[14:12] == 3'b001 && insn_from_imem[31:25] == 7'd0;
  wire insn_srli = insn_opcode == OpRegImm && insn_from_imem[14:12] == 3'b101 && insn_from_imem[31:25] == 7'd0;
  wire insn_srai = insn_opcode == OpRegImm && insn_from_imem[14:12] == 3'b101 && insn_from_imem[31:25] == 7'b0100000;

  wire insn_add  = insn_opcode == OpRegReg && insn_from_imem[14:12] == 3'b000 && insn_from_imem[31:25] == 7'd0;
  wire insn_sub  = insn_opcode == OpRegReg && insn_from_imem[14:12] == 3'b000 && insn_from_imem[31:25] == 7'b0100000;
  wire insn_sll  = insn_opcode == OpRegReg && insn_from_imem[14:12] == 3'b001 && insn_from_imem[31:25] == 7'd0;
  wire insn_slt  = insn_opcode == OpRegReg && insn_from_imem[14:12] == 3'b010 && insn_from_imem[31:25] == 7'd0;
  wire insn_sltu = insn_opcode == OpRegReg && insn_from_imem[14:12] == 3'b011 && insn_from_imem[31:25] == 7'd0;
  wire insn_xor  = insn_opcode == OpRegReg && insn_from_imem[14:12] == 3'b100 && insn_from_imem[31:25] == 7'd0;
  wire insn_srl  = insn_opcode == OpRegReg && insn_from_imem[14:12] == 3'b101 && insn_from_imem[31:25] == 7'd0;
  wire insn_sra  = insn_opcode == OpRegReg && insn_from_imem[14:12] == 3'b101 && insn_from_imem[31:25] == 7'b0100000;
  wire insn_or   = insn_opcode == OpRegReg && insn_from_imem[14:12] == 3'b110 && insn_from_imem[31:25] == 7'd0;
  wire insn_and  = insn_opcode == OpRegReg && insn_from_imem[14:12] == 3'b111 && insn_from_imem[31:25] == 7'd0;

  wire insn_mul    = insn_opcode == OpRegReg && insn_from_imem[31:25] == 7'd1 && insn_from_imem[14:12] == 3'b000;
  wire insn_mulh   = insn_opcode == OpRegReg && insn_from_imem[31:25] == 7'd1 && insn_from_imem[14:12] == 3'b001;
  wire insn_mulhsu = insn_opcode == OpRegReg && insn_from_imem[31:25] == 7'd1 && insn_from_imem[14:12] == 3'b010;
  wire insn_mulhu  = insn_opcode == OpRegReg && insn_from_imem[31:25] == 7'd1 && insn_from_imem[14:12] == 3'b011;
  wire insn_div    = insn_opcode == OpRegReg && insn_from_imem[31:25] == 7'd1 && insn_from_imem[14:12] == 3'b100;
  wire insn_divu   = insn_opcode == OpRegReg && insn_from_imem[31:25] == 7'd1 && insn_from_imem[14:12] == 3'b101;
  wire insn_rem    = insn_opcode == OpRegReg && insn_from_imem[31:25] == 7'd1 && insn_from_imem[14:12] == 3'b110;
  wire insn_remu   = insn_opcode == OpRegReg && insn_from_imem[31:25] == 7'd1 && insn_from_imem[14:12] == 3'b111;

  wire insn_ecall = insn_opcode == OpEnviron && insn_from_imem[31:7] == 25'd0;
  wire insn_fence = insn_opcode == OpMiscMem;

  // this code is only for simulation, not synthesis
  `ifndef SYNTHESIS
  `include "RvDisassembler.sv"
  string disasm_string;
  always_comb begin
    disasm_string = rv_disasm(insn_from_imem);
  end
  // HACK: get disasm_string to appear in GtkWave, which can apparently show only wire/logic...
  wire [(8*32)-1:0] disasm_wire;
  genvar i;
  for (i = 0; i < 32; i = i + 1) begin : gen_disasm
    assign disasm_wire[(((i+1))*8)-1:((i)*8)] = disasm_string[31-i];
  end
  `endif

  // program counter
  logic [`REG_SIZE] pcNext, pcCurrent;
  always @(posedge clk) begin
    if (rst) begin
      pcCurrent <= 32'd0;
    end else begin
      pcCurrent <= pcNext;
    end
  end
  assign pc_to_imem = pcCurrent;

  // cycle/insn_from_imem counters
  logic [`REG_SIZE] cycles_current, num_insns_current;
  always @(posedge clk) begin
    if (rst) begin
      cycles_current <= 0;
      num_insns_current <= 0;
    end else begin
      cycles_current <= cycles_current + 1;
      if (!rst) begin
        num_insns_current <= num_insns_current + 1;
      end
    end
  end

  // NOTE: don't rename your RegFile instance as the tests expect it to be `rf`
  logic rf_we;
  logic [4:0] rf_rd;
  logic [`REG_SIZE] rf_wdata;

  wire [`REG_SIZE] rs1_data;
  wire [`REG_SIZE] rs2_data;
  RegFile rf (
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

  logic illegal_insn;

  // helpers
  wire [`REG_SIZE] lui_imm = {insn_from_imem[31:12], 12'b0};
  wire [4:0] shamt_reg = rs2_data[4:0];
  wire signed [`REG_SIZE] s_rs1 = $signed(rs1_data);
  wire signed [`REG_SIZE] s_rs2 = $signed(rs2_data);
  wire signed [`REG_SIZE] s_imm_i = $signed(imm_i_sext);

  // CLA inputs
  logic [31:0] alu_a, alu_b;
  logic        alu_cin;
  wire  [31:0] alu_sum;

  // Divider inputs (always unsigned core)
  logic [31:0] div_a, div_b;
  wire  [31:0] div_q, div_r;

  CarryLookaheadAdder u_cla (
    .a   (alu_a),
    .b   (alu_b),
    .cin (alu_cin),
    .sum (alu_sum)
  );

  DividerUnsigned u_divu (
    .i_dividend (div_a),
    .i_divisor  (div_b),
    .o_quotient (div_q),
    .o_remainder(div_r)
  );

  // address helpers for word-aligned
  logic [`REG_SIZE] eff_addr;
  logic [`REG_SIZE] aligned_addr;
  logic [1:0] addr_off;

  // load selection helpers
  logic [7:0]  load_byte;
  logic [15:0] load_half;
  logic [31:0] shifted;

  always_comb begin
    // defaults
    alu_a   = rs1_data;
    alu_b   = rs2_data;
    alu_cin = 1'b0;

    div_a = rs1_data;
    div_b = rs2_data;

    // ADDI
    if (insn_addi) begin
      alu_b = imm_i_sext;
    end

    // SUB
    if (insn_sub) begin
      alu_b   = ~rs2_data;
      alu_cin = 1'b1;
    end

    // signed div/rem: feed absolute values
    if (insn_div || insn_rem) begin
      div_a = rs1_data[31] ? (~rs1_data + 1) : rs1_data;
      div_b = rs2_data[31] ? (~rs2_data + 1) : rs2_data;
    end

    // unsigned div/rem
    if (insn_divu || insn_remu) begin
      div_a = rs1_data;
      div_b = rs2_data;
    end
  end

  always_comb begin
    illegal_insn = 1'b0;

    trace_completed_pc = pcCurrent;
    trace_completed_insn = insn_from_imem;
    trace_completed_cycle_status = CYCLE_NO_STALL;

    // defaults
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
      OpMiscMem: begin
        if (!insn_fence) illegal_insn = 1'b1;
      end

      OpEnviron: begin
        if (insn_ecall) begin
          halt = 1'b1;
        end else begin
          illegal_insn = 1'b1;
        end
      end

      // ----- U-TYPE -----

      OpLui: begin
        rf_we = 1'b1;
        rf_wdata = lui_imm;
      end

       OpAuipc: begin
        rf_we = 1'b1;
        rf_wdata = pcCurrent + lui_imm;
      end

      // ----- JUMPS -----

      OpJal: begin
        rf_we    = 1'b1;
        rf_wdata = pcCurrent + 32'd4;
        pcNext   = pcCurrent + imm_j_sext;
      end

      OpJalr: begin
        rf_we    = 1'b1;
        rf_wdata = pcCurrent + 32'd4;
        // target = (rs1 + imm_i) & ~1
        pcNext   = (rs1_data + imm_i_sext) & 32'hFFFF_FFFE;
      end

      // ----- I-TYPE -----

      OpRegImm: begin
        case (insn_funct3)
          3'b000: begin // addi
            rf_we    = 1'b1;
            rf_wdata = alu_sum;
          end
          3'b010: begin // slti
            rf_we    = 1'b1;
            rf_wdata = (s_rs1 < s_imm_i) ? 32'd1 : 32'd0;
          end
          3'b011: begin // sltiu
            rf_we    = 1'b1;
            rf_wdata = (rs1_data < imm_i_sext) ? 32'd1 : 32'd0;
          end
          3'b100: begin // xori
            rf_we    = 1'b1;
            rf_wdata = rs1_data ^ imm_i_sext;
          end
          3'b110: begin // ori
            rf_we    = 1'b1;
            rf_wdata = rs1_data | imm_i_sext;
          end
          3'b111: begin // andi
            rf_we    = 1'b1;
            rf_wdata = rs1_data & imm_i_sext;
          end
          3'b001: begin // slli
            if (insn_from_imem[31:25] == 7'd0) begin
              rf_we    = 1'b1;
              rf_wdata = rs1_data << imm_shamt;
            end else begin
              illegal_insn = 1'b1;
            end
          end
          3'b101: begin // srli/srai
            if (insn_from_imem[31:25] == 7'd0) begin
              rf_we    = 1'b1;
              rf_wdata = rs1_data >> imm_shamt; // srli
            end else if (insn_from_imem[31:25] == 7'b0100000) begin
              rf_we    = 1'b1;
              rf_wdata = $signed(rs1_data) >>> imm_shamt; // srai
            end else begin
              illegal_insn = 1'b1;
            end
          end
          default: illegal_insn = 1'b1;
        endcase
      end

      // ----- R-TYPE -----

      OpRegReg: begin
        if (insn_funct7 == 7'd0) begin
          case (insn_funct3)
            3'b000: begin // add
              rf_we    = 1'b1;
              rf_wdata = alu_sum;
            end
            3'b001: begin // sll
              rf_we    = 1'b1;
              rf_wdata = rs1_data << shamt_reg;
            end
            3'b010: begin // slt
              rf_we    = 1'b1;
              rf_wdata = (s_rs1 < s_rs2) ? 32'd1 : 32'd0;
            end
            3'b011: begin // sltu
              rf_we    = 1'b1;
              rf_wdata = (rs1_data < rs2_data) ? 32'd1 : 32'd0;
            end
            3'b100: begin // xor
              rf_we    = 1'b1;
              rf_wdata = rs1_data ^ rs2_data;
            end
            3'b101: begin // srl
              rf_we    = 1'b1;
              rf_wdata = rs1_data >> shamt_reg;
            end
            3'b110: begin // or
              rf_we    = 1'b1;
              rf_wdata = rs1_data | rs2_data;
            end
            3'b111: begin // and
              rf_we    = 1'b1;
              rf_wdata = rs1_data & rs2_data;
            end
            default: illegal_insn = 1'b1;
          endcase
        end else if (insn_funct7 == 7'b0100000) begin
          case (insn_funct3)
            3'b000: begin // sub
              rf_we    = 1'b1;
              rf_wdata = alu_sum;
            end
            3'b101: begin // sra
              rf_we    = 1'b1;
              rf_wdata = $signed(rs1_data) >>> shamt_reg;
            end
            default: illegal_insn = 1'b1;
          endcase
        end else if (insn_funct7 == 7'd1) begin
          logic [63:0] prod;
          logic signed [63:0] s_prod;
          logic signed [31:0] s_a32;
          logic signed [31:0] s_b32;
          logic [63:0] u_prod;

          // defaults
          prod   = 64'd0;
          s_prod = 64'd0;
          u_prod = 64'd0;
          s_a32  = $signed(rs1_data);
          s_b32  = $signed(rs2_data);

          rf_we = 1'b1;

          unique case (insn_funct3)
            3'b000: begin // mul
              u_prod   = $unsigned(rs1_data) * $unsigned(rs2_data);
              rf_wdata = u_prod[31:0];
            end
            3'b001: begin // mulh
              s_prod   = $signed(s_a32) * $signed(s_b32);
              rf_wdata = s_prod[63:32];
            end
            3'b010: begin // mulhsu
              s_prod   = $signed(s_a32) * $signed({1'b0, rs2_data});
              rf_wdata = s_prod[63:32];
            end
            3'b011: begin // mulhu
              u_prod   = $unsigned(rs1_data) * $unsigned(rs2_data);
              rf_wdata = u_prod[63:32];
            end

            3'b100, // div
            3'b101, // divu
            3'b110, // rem
            3'b111: begin // remu
              // division / remainder via DividerUnsigned (no / %)
              logic div_by_zero;
              logic signed_overflow;
              logic a_neg, b_neg;
              logic [`REG_SIZE] a_abs, b_abs;
              logic [`REG_SIZE] q_u, r_u;
              logic [`REG_SIZE] q_s, r_s;

              div_by_zero     = (rs2_data == 32'd0);
              signed_overflow = (rs1_data == 32'h8000_0000) && (rs2_data == 32'hFFFF_FFFF);

              a_neg = rs1_data[31];
              b_neg = rs2_data[31];

              // abs via two's complement (no '-')
              a_abs = a_neg ? (~rs1_data + 32'd1) : rs1_data;
              b_abs = b_neg ? (~rs2_data + 32'd1) : rs2_data;

              q_u = div_q;
              r_u = div_r;

              // sign adjust
              q_s = (a_neg ^ b_neg) ? (~q_u + 32'd1) : q_u;
              r_s = a_neg ? (~r_u + 32'd1) : r_u;

              unique case (insn_funct3)
                3'b100: begin // div
                  if (div_by_zero) begin
                    rf_wdata = 32'hFFFF_FFFF;
                  end else if (signed_overflow) begin
                    rf_wdata = 32'h8000_0000;
                  end else begin
                    rf_wdata = q_s;
                  end
                end
                3'b101: begin // divu
                  if (div_by_zero) begin
                    rf_wdata = 32'hFFFF_FFFF;
                  end else begin
                    rf_wdata = div_q;
                  end
                end
                3'b110: begin // rem
                  if (div_by_zero) begin
                    rf_wdata = rs1_data;
                  end else if (signed_overflow) begin
                    rf_wdata = 32'd0;
                  end else begin
                    rf_wdata = r_s;
                  end
                end
                3'b111: begin // remu
                  if (div_by_zero) begin
                    rf_wdata = rs1_data;
                  end else begin
                    rf_wdata = div_r;
                  end
                end
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
        end else begin
          illegal_insn = 1'b1;
        end
      end

      // ----- BRANCH -----

      OpBranch: begin
        logic take_branch;
        take_branch = 1'b0;
        unique case (insn_funct3)
          3'b000: take_branch = (rs1_data == rs2_data); // beq
          3'b001: take_branch = (rs1_data != rs2_data); // bne
          3'b100: take_branch = (s_rs1 <  s_rs2); // blt
          3'b101: take_branch = (s_rs1 >= s_rs2); // bge
          3'b110: take_branch = (rs1_data <  rs2_data); // bltu
          3'b111: take_branch = (rs1_data >= rs2_data); // bgeu
          default: illegal_insn = 1'b1;
        endcase

        if (!illegal_insn && take_branch) begin
          pcNext = pcCurrent + imm_b_sext;
        end
      end

      // ----- LOAD -----
      OpLoad: begin
        eff_addr     = rs1_data + imm_i_sext;
        aligned_addr = {eff_addr[31:2], 2'b00};
        addr_off     = eff_addr[1:0];

        addr_to_dmem = aligned_addr;

        shifted   = load_data_from_dmem >> (8 * addr_off);
        load_byte = shifted[7:0];

        shifted   = load_data_from_dmem >> (16 * addr_off[1]);
        load_half = shifted[15:0];

        rf_we = 1'b1;

        unique case (insn_funct3)
          3'b000: begin // lb
            rf_wdata = {{24{load_byte[7]}}, load_byte};
          end
          3'b001: begin // lh
            if (addr_off[0] != 1'b0) begin
              illegal_insn = 1'b1;
              rf_we = 1'b0;
            end else begin
              rf_wdata = {{16{load_half[15]}}, load_half};
            end
          end
          3'b010: begin // lw
            if (addr_off != 2'b00) begin
              illegal_insn = 1'b1;
              rf_we = 1'b0;
            end else begin
              rf_wdata = load_data_from_dmem;
            end
          end
          3'b100: begin // lbu
            rf_wdata = {24'd0, load_byte};
          end
          3'b101: begin // lhu
            if (addr_off[0] != 1'b0) begin
              illegal_insn = 1'b1;
              rf_we = 1'b0;
            end else begin
              rf_wdata = {16'd0, load_half};
            end
          end
          default: begin
            illegal_insn = 1'b1;
            rf_we = 1'b0;
          end
        endcase
      end

      // ----- STORE -----
      OpStore: begin
        eff_addr     = rs1_data + imm_s_sext;
        aligned_addr = {eff_addr[31:2], 2'b00};
        addr_off     = eff_addr[1:0];

        addr_to_dmem = aligned_addr;

        unique case (insn_funct3)
          3'b000: begin // sb
            store_we_to_dmem   = 4'b0001 << addr_off;
            store_data_to_dmem = {4{rs2_data[7:0]}};
          end
          3'b001: begin // sh
            if (addr_off[0] != 1'b0) begin
              illegal_insn = 1'b1;
            end else begin
              store_we_to_dmem   = 4'b0011 << addr_off;
              store_data_to_dmem = {2{rs2_data[15:0]}};
            end
          end
          3'b010: begin // sw
            if (addr_off != 2'b00) begin
              illegal_insn = 1'b1;
            end else begin
              store_we_to_dmem   = 4'b1111;
              store_data_to_dmem = rs2_data;
            end
          end
          default: illegal_insn = 1'b1;
        endcase
      end

      default: begin
        illegal_insn = 1'b1;
      end

    endcase
  end

endmodule

/* A memory module that supports 1-cycle reads and writes, with one read-only port
 * and one read+write port.
 */
module MemorySingleCycle #(
    parameter int NUM_WORDS = 512
) (
    // rst for both imem and dmem
    input wire rst,

    // clock for both imem and dmem. See RiscvProcessor for clock details.
    input wire clock_mem,

    // must always be aligned to a 4B boundary
    input wire [`REG_SIZE] pc_to_imem,

    // the value at memory location pc_to_imem
    output logic [`INSN_SIZE] insn_from_imem,

    // must always be aligned to a 4B boundary
    input wire [`REG_SIZE] addr_to_dmem,

    // the value at memory location addr_to_dmem
    output logic [`REG_SIZE] load_data_from_dmem,

    // the value to be written to addr_to_dmem, controlled by store_we_to_dmem
    input wire [`REG_SIZE] store_data_to_dmem,

    // Each bit determines whether to write the corresponding byte of store_data_to_dmem to memory location addr_to_dmem.
    // E.g., 4'b1111 will write 4 bytes. 4'b0001 will write only the least-significant byte.
    input wire [3:0] store_we_to_dmem
);

  // memory is arranged as an array of 4B words
  logic [`REG_SIZE] mem_array[NUM_WORDS];

`ifdef SYNTHESIS
  initial begin
    $readmemh("mem_initial_contents.hex", mem_array);
  end
`endif

  always_comb begin
    // memory addresses should always be 4B-aligned
    assert (pc_to_imem[1:0] == 2'b00);
    assert (addr_to_dmem[1:0] == 2'b00);
  end

  localparam int AddrMsb = $clog2(NUM_WORDS) + 1;
  localparam int AddrLsb = 2;

  always @(posedge clock_mem) begin
    if (rst) begin
    end else begin
      insn_from_imem <= mem_array[{pc_to_imem[AddrMsb:AddrLsb]}];
    end
  end

  always @(negedge clock_mem) begin
    if (rst) begin
    end else begin
      if (store_we_to_dmem[0]) begin
        mem_array[addr_to_dmem[AddrMsb:AddrLsb]][7:0] <= store_data_to_dmem[7:0];
      end
      if (store_we_to_dmem[1]) begin
        mem_array[addr_to_dmem[AddrMsb:AddrLsb]][15:8] <= store_data_to_dmem[15:8];
      end
      if (store_we_to_dmem[2]) begin
        mem_array[addr_to_dmem[AddrMsb:AddrLsb]][23:16] <= store_data_to_dmem[23:16];
      end
      if (store_we_to_dmem[3]) begin
        mem_array[addr_to_dmem[AddrMsb:AddrLsb]][31:24] <= store_data_to_dmem[31:24];
      end
      // dmem is "read-first": read returns value before the write
      load_data_from_dmem <= mem_array[{addr_to_dmem[AddrMsb:AddrLsb]}];
    end
  end
endmodule

/*
This shows the relationship between clock_proc and clock_mem. The clock_mem is
phase-shifted 90° from clock_proc. You could think of one proc cycle being
broken down into 3 parts. During part 1 (which starts @posedge clock_proc)
the current PC is sent to the imem. In part 2 (starting @posedge clock_mem) we
read from imem. In part 3 (starting @negedge clock_mem) we read/write memory and
prepare register/PC updates, which occur at @posedge clock_proc.

        ____
 proc: |    |______
           ____
 mem:  ___|    |___
*/
module Processor (
    input wire               clock_proc,
    input wire               clock_mem,
    input wire               rst,
    output wire [`REG_SIZE]  trace_completed_pc,
    output wire [`INSN_SIZE] trace_completed_insn,
    output cycle_status_e    trace_completed_cycle_status, 
    output logic             halt
);

  wire [`REG_SIZE] pc_to_imem, mem_data_addr, mem_data_loaded_value, mem_data_to_write;
  wire [`INSN_SIZE] insn_from_imem;
  wire [3:0] mem_data_we;

  // This wire is set by cocotb to the name of the currently-running test, to make it easier
  // to see what is going on in the waveforms.
  wire [(8*32)-1:0] test_case;

  MemorySingleCycle #(
      .NUM_WORDS(8192)
  ) memory (
      .rst      (rst),
      .clock_mem (clock_mem),
      // imem is read-only
      .pc_to_imem(pc_to_imem),
      .insn_from_imem(insn_from_imem),
      // dmem is read-write
      .addr_to_dmem(mem_data_addr),
      .load_data_from_dmem(mem_data_loaded_value),
      .store_data_to_dmem (mem_data_to_write),
      .store_we_to_dmem  (mem_data_we)
  );

  DatapathSingleCycle datapath (
      .clk(clock_proc),
      .rst(rst),
      .pc_to_imem(pc_to_imem),
      .insn_from_imem(insn_from_imem),
      .addr_to_dmem(mem_data_addr),
      .store_data_to_dmem(mem_data_to_write),
      .store_we_to_dmem(mem_data_we),
      .load_data_from_dmem(mem_data_loaded_value),
      .trace_completed_pc(trace_completed_pc),
      .trace_completed_insn(trace_completed_insn),
      .trace_completed_cycle_status(trace_completed_cycle_status),
      .halt(halt)
  );

endmodule

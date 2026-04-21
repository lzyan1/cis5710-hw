`timescale 1ns / 1ns

// registers are 32 bits in RV32
`define REG_SIZE 31:0

// insns are 32 bits in RV32IM
`define INSN_SIZE 31:0

// RV opcodes are 7 bits
`define OPCODE_SIZE 6:0

`define ADDR_WIDTH 32
`define DATA_WIDTH 32

`ifndef DIVIDER_STAGES
`define DIVIDER_STAGES 8
`endif

`ifndef SYNTHESIS
  `include "../hw3-singlecycle/RvDisassembler.sv"
`endif
`include "../hw2b-cla/CarryLookaheadAdder.sv"
`include "../hw3-singlecycle/cycle_status.sv"
`include "../hw4-multicycle/DividerUnsignedPipelined.sv"
`include "EasyAxilMemory.sv"

module Disasm #(
    PREFIX = "D"
) (
    input wire [31:0] insn,
    output wire [(8*32)-1:0] disasm
);
`ifndef RISCV_FORMAL
`ifndef SYNTHESIS
  // this code is only for simulation, not synthesis
  string disasm_string;
  always_comb begin
    disasm_string = rv_disasm(insn);
  end
  // HACK: get disasm_string to appear in GtkWave, which can apparently show only wire/logic. Also,
  // string needs to be reversed to render correctly.
  genvar i;
  for (i = 3; i < 32; i = i + 1) begin : gen_disasm
    assign disasm[((i+1-3)*8)-1-:8] = disasm_string[31-i];
  end
  assign disasm[255-:8] = PREFIX;
  assign disasm[247-:8] = ":";
  assign disasm[239-:8] = " ";
`endif
`endif
endmodule

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
    if (rs1 == 5'd0)
      rs1_data = 32'd0;
    else if (we && rd == rs1 && rd != 5'd0)
      rs1_data = rd_data;
    else
      rs1_data = regs[rs1];

    if (rs2 == 5'd0)
      rs2_data = 32'd0;
    else if (we && rd == rs2 && rd != 5'd0)
      rs2_data = rd_data;
    else
      rs2_data = regs[rs2];
  end

  integer j;
  always_ff @(posedge clk) begin
    if (rst) begin
      for (j = 0; j < NumRegs; j = j + 1)
        regs[j] <= 32'd0;
    end else begin
      if (we && rd != 5'd0)
        regs[rd] <= rd_data;
      regs[0] <= 32'd0;
    end
  end
endmodule

typedef struct packed {
  logic [`REG_SIZE] pc;
  cycle_status_e    cycle_status;
} stage_g_t;

typedef struct packed {
  logic [`REG_SIZE] pc;
  logic [`INSN_SIZE] insn;
  cycle_status_e cycle_status;
} stage_decode_t;

typedef struct packed {
  logic [`REG_SIZE]  pc;
  logic [`INSN_SIZE] insn;
  cycle_status_e     cycle_status;

  logic [4:0]        rs1;
  logic [4:0]        rs2;
  logic [4:0]        rd;

  logic [`REG_SIZE]  rs1_data;
  logic [`REG_SIZE]  rs2_data;

  logic [`REG_SIZE]  imm_i_sext;
  logic [`REG_SIZE]  imm_b_sext;
  logic [`REG_SIZE]  imm_j_sext;
  logic [`REG_SIZE]  imm_s_sext;
  logic [`REG_SIZE]  imm_u; // LUI

  logic              rf_we;
} stage_execute_t;

typedef struct packed {
  logic [`REG_SIZE]  pc;
  logic [`INSN_SIZE] insn;
  cycle_status_e     cycle_status;
  logic [4:0]        rd;
  logic [`REG_SIZE]  rd_data;
  logic              rf_we;
  logic              halt;

  logic              is_load;
  logic              is_store;
  logic [2:0]        mem_funct3;
  logic [`REG_SIZE]  mem_addr;
  logic [`REG_SIZE]  store_data;
} stage_memory_t;

// state before W
typedef struct packed {
  logic [`REG_SIZE]  pc;
  logic [`INSN_SIZE] insn;
  cycle_status_e     cycle_status;
  logic [4:0]        rd;
  logic [`REG_SIZE]  rd_data;
  logic              rf_we;
  logic              halt;
} stage_writeback_t;

typedef struct packed {
  logic              valid;
  logic [`REG_SIZE]  pc;
  logic [`INSN_SIZE] insn;
  cycle_status_e     cycle_status;
  logic [4:0]        rd;
  logic [2:0]        funct3;
  logic              rs1_neg;
  logic              rs2_neg;
  logic [`REG_SIZE]  rs1_val;
  logic [`REG_SIZE]  rs2_val;
} stage_divq_t;

module DatapathPipelinedAxil (
    input wire clk,
    input wire rst,

    axil_if.manager imem,
    axil_if.manager dmem,
    output logic halt,

    output logic [`REG_SIZE] trace_completed_pc,
    output logic [`INSN_SIZE] trace_completed_insn,
    output cycle_status_e trace_completed_cycle_status
);

  // opcodes
  localparam bit [`OPCODE_SIZE] OpcodeLoad    = 7'b00_000_11;
  localparam bit [`OPCODE_SIZE] OpcodeStore   = 7'b01_000_11;
  localparam bit [`OPCODE_SIZE] OpcodeBranch  = 7'b11_000_11;
  localparam bit [`OPCODE_SIZE] OpcodeJalr    = 7'b11_001_11;
  localparam bit [`OPCODE_SIZE] OpcodeMiscMem = 7'b00_011_11;
  localparam bit [`OPCODE_SIZE] OpcodeJal     = 7'b11_011_11;
  localparam bit [`OPCODE_SIZE] OpcodeRegImm  = 7'b00_100_11;
  localparam bit [`OPCODE_SIZE] OpcodeRegReg  = 7'b01_100_11;
  localparam bit [`OPCODE_SIZE] OpcodeEnviron = 7'b11_100_11;
  localparam bit [`OPCODE_SIZE] OpcodeAuipc   = 7'b00_101_11;
  localparam bit [`OPCODE_SIZE] OpcodeLui     = 7'b01_101_11;

  // cycle counter
  logic [`REG_SIZE] cycles_current;
  always_ff @(posedge clk) begin
    if (rst) begin
      cycles_current <= 0;
    end else begin
      cycles_current <= cycles_current + 1;
    end
  end

  logic             x_branch_taken;
  logic [`REG_SIZE] x_branch_target;

  wire d_load_use_stall;
  wire d_div_stall;

  wire pipeline_stall = d_load_use_stall || d_div_stall;

  // =====================================================
  // FETCH
  // =====================================================

  logic [`REG_SIZE] f_pc_current;
  cycle_status_e    f_cycle_status;

  assign imem.ARADDR  = f_pc_current;
  assign imem.ARVALID = !pipeline_stall && !x_branch_taken;
  assign imem.ARPROT  = 3'b000;

  assign imem.RREADY  = !pipeline_stall;

  assign imem.AWADDR  = 32'd0;
  assign imem.AWVALID = 1'b0;
  assign imem.AWPROT  = 3'b000;
  assign imem.WDATA   = 32'd0;
  assign imem.WSTRB   = 4'b0000;
  assign imem.WVALID  = 1'b0;
  assign imem.BREADY  = 1'b1;

  wire imem_ar_fire = imem.ARVALID && imem.ARREADY;
  wire imem_r_fire  = imem.RVALID  && imem.RREADY;

  always_ff @(posedge clk) begin
    if (rst) begin
      f_pc_current   <= 32'd0;
      f_cycle_status <= CYCLE_NO_STALL;
    end else begin
      f_cycle_status <= CYCLE_NO_STALL;

      if (x_branch_taken)
        f_pc_current <= x_branch_target;
      else if (pipeline_stall)
        f_pc_current <= f_pc_current;
      else if (imem_ar_fire)
        f_pc_current <= f_pc_current + 32'd4;
      else
        f_pc_current <= f_pc_current;
    end
  end

  // =====================================================
  // FG PIPELINE
  // =====================================================

  stage_g_t g_state;

  always_ff @(posedge clk) begin
    if (rst) begin
      g_state <= '{pc: 0, cycle_status: CYCLE_RESET};
    end else if (x_branch_taken) begin
      g_state <= '{pc: 0, cycle_status: CYCLE_TAKEN_BRANCH};
    end else if (pipeline_stall) begin
      g_state <= g_state;
    end else if (imem_ar_fire) begin
      g_state <= '{
        pc:           f_pc_current,
        cycle_status: f_cycle_status
      };
    end else begin
      g_state <= g_state;
    end
  end

  wire [255:0] g_disasm;
  Disasm #(.PREFIX("G")) disasm_0g (
      .insn  (imem.RDATA),
      .disasm(g_disasm)
  );

  // =====================================================
  // GD PIPELINE
  // =====================================================

  stage_decode_t decode_state;

  always_ff @(posedge clk) begin
    if (rst) begin
      decode_state <= '{pc: 0, insn: 0, cycle_status: CYCLE_RESET};
    end else if (x_branch_taken) begin
      decode_state <= '{pc: 0, insn: 0, cycle_status: CYCLE_TAKEN_BRANCH};
    end else if (pipeline_stall) begin
      decode_state <= decode_state;
    end else if (imem_r_fire) begin
      decode_state <= '{
        pc:           g_state.pc,
        insn:         imem.RDATA,
        cycle_status: g_state.cycle_status
      };
    end else begin
      decode_state <= decode_state;
    end
  end

  wire [255:0] d_disasm;
  Disasm #(.PREFIX("D")) disasm_1decode (
      .insn  (decode_state.insn),
      .disasm(d_disasm)
  );

  // =====================================================
  // DECODE
  // =====================================================

  wire [`OPCODE_SIZE] d_opcode = decode_state.insn[6:0];
  wire [4:0]          d_rd     = decode_state.insn[11:7];
  wire [2:0]          d_funct3 = decode_state.insn[14:12];
  wire [4:0]          d_rs1    = decode_state.insn[19:15];
  wire [4:0]          d_rs2    = decode_state.insn[24:20];
  wire [6:0]          d_funct7 = decode_state.insn[31:25];

  wire [11:0] d_imm_i = decode_state.insn[31:20];
  wire [11:0] d_imm_s;
  assign d_imm_s[11:5] = d_funct7;
  assign d_imm_s[4:0]  = d_rd;

  wire [12:0] d_imm_b;
  assign {d_imm_b[12], d_imm_b[10:5]} = d_funct7;
  assign {d_imm_b[4:1], d_imm_b[11]}  = d_rd;
  assign d_imm_b[0] = 1'b0;

  wire [20:0] d_imm_j;
  assign {d_imm_j[20], d_imm_j[10:1], d_imm_j[11], d_imm_j[19:12], d_imm_j[0]} =
         {decode_state.insn[31:12], 1'b0};

  wire [`REG_SIZE] d_imm_i_sext = {{20{d_imm_i[11]}},  d_imm_i};
  wire [`REG_SIZE] d_imm_b_sext = {{19{d_imm_b[12]}},  d_imm_b};
  wire [`REG_SIZE] d_imm_j_sext = {{11{d_imm_j[20]}},  d_imm_j};
  wire [`REG_SIZE] d_imm_u      = {decode_state.insn[31:12], 12'b0};
  wire [`REG_SIZE] d_imm_s_sext = {{20{d_imm_s[11]}}, d_imm_s};

  wire x_is_load_in_exec = (execute_state.insn[6:0] == OpcodeLoad);

  logic d_uses_rs1, d_uses_rs2;
  always_comb begin
    d_uses_rs1 = 1'b0;
    d_uses_rs2 = 1'b0;
    case (d_opcode)
      OpcodeLoad, OpcodeRegImm, OpcodeJalr: begin
        d_uses_rs1 = 1'b1;
      end
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

  assign d_load_use_stall =
    !x_branch_taken &&
    x_is_load_in_exec &&
    (execute_state.rd != 5'd0) &&
    ((d_uses_rs1 && execute_state.rd == d_rs1) ||
     (d_uses_rs2 && execute_state.rd == d_rs2));

  logic [`REG_SIZE] d_rs1_data, d_rs2_data;
  logic             w_rf_we;
  logic [4:0]       w_rd;
  logic [`REG_SIZE] w_rd_data;

  RegFile rf (
      .clk    (clk),
      .rst    (rst),
      .we     (w_rf_we),
      .rd     (w_rd),
      .rd_data(w_rd_data),
      .rs1    (d_rs1),
      .rs2    (d_rs2),
      .rs1_data(d_rs1_data),
      .rs2_data(d_rs2_data)
  );

  logic d_rf_we;
  always_comb begin
    case (d_opcode)
      OpcodeBranch, OpcodeStore, OpcodeMiscMem,
      OpcodeEnviron: d_rf_we = 1'b0;
      default:        d_rf_we = 1'b1;
    endcase
  end

  // =====================================================
  // DX PIPELINE
  // =====================================================

  stage_execute_t execute_state;

  always_ff @(posedge clk) begin
    if (rst) begin
      execute_state <= '{
        pc: 0, insn: 0, cycle_status: CYCLE_RESET,
        rs1: 0, rs2: 0, rd: 0,
        rs1_data: 0, rs2_data: 0,
        imm_i_sext: 0, imm_b_sext: 0, imm_j_sext: 0, imm_s_sext: 0, imm_u: 0,
        rf_we: 0
      };
    end else if (x_branch_taken) begin
      execute_state <= '{
        pc: 0, insn: 0, cycle_status: CYCLE_TAKEN_BRANCH,
        rs1: 0, rs2: 0, rd: 0,
        rs1_data: 0, rs2_data: 0,
        imm_i_sext: 0, imm_b_sext: 0, imm_j_sext: 0, imm_s_sext: 0, imm_u: 0,
        rf_we: 0
      };
    end else if (d_div_stall) begin
      execute_state <= '{
        pc: 0, insn: 0, cycle_status: CYCLE_DIV,
        rs1: 0, rs2: 0, rd: 0,
        rs1_data: 0, rs2_data: 0,
        imm_i_sext: 0, imm_b_sext: 0, imm_j_sext: 0, imm_s_sext: 0, imm_u: 0,
        rf_we: 0
      };
    end else if (d_load_use_stall) begin
      execute_state <= '{
        pc: 0, insn: 0, cycle_status: CYCLE_LOAD2USE,
        rs1: 0, rs2: 0, rd: 0,
        rs1_data: 0, rs2_data: 0,
        imm_i_sext: 0, imm_b_sext: 0, imm_j_sext: 0, imm_s_sext: 0, imm_u: 0,
        rf_we: 0
      };
    end else begin
      execute_state <= '{
        pc:           decode_state.pc,
        insn:         decode_state.insn,
        cycle_status: decode_state.cycle_status,
        rs1:          d_rs1,
        rs2:          d_rs2,
        rd:           d_rd,
        rs1_data:     d_rs1_data,
        rs2_data:     d_rs2_data,
        imm_i_sext:   d_imm_i_sext,
        imm_b_sext:   d_imm_b_sext,
        imm_j_sext:   d_imm_j_sext,
        imm_s_sext:   d_imm_s_sext,
        imm_u:        d_imm_u,
        rf_we:        d_rf_we
      };
    end
  end

  wire [255:0] x_disasm;
  Disasm #(.PREFIX("X")) disasm_2execute (
      .insn  (execute_state.insn),
      .disasm(x_disasm)
  );

  // =====================================================
  // EXECUTE
  // =====================================================

  wire [`OPCODE_SIZE] x_opcode    = execute_state.insn[6:0];
  wire [2:0]          x_funct3    = execute_state.insn[14:12];
  wire [6:0]          x_funct7    = execute_state.insn[31:25];
  wire [4:0]          x_imm_shamt = execute_state.insn[24:20];

  stage_memory_t    memory_state;
  stage_writeback_t writeback_state;

  logic [`REG_SIZE] x_rs1, x_rs2;
  logic [`REG_SIZE] m_rd_data;

  logic             x_is_load, x_is_store;
  logic [2:0]       x_mem_funct3;
  logic [`REG_SIZE] x_mem_addr, x_store_data;

  always_comb begin
    if (memory_state.rf_we && memory_state.rd != 5'd0 &&
        memory_state.rd == execute_state.rs1)
      x_rs1 = m_rd_data;
    else if (writeback_state.rf_we && writeback_state.rd != 5'd0 &&
             writeback_state.rd == execute_state.rs1)
      x_rs1 = writeback_state.rd_data;
    else
      x_rs1 = execute_state.rs1_data;

    if (memory_state.rf_we && memory_state.rd != 5'd0 &&
        memory_state.rd == execute_state.rs2)
      x_rs2 = m_rd_data;
    else if (writeback_state.rf_we && writeback_state.rd != 5'd0 &&
             writeback_state.rd == execute_state.rs2)
      x_rs2 = writeback_state.rd_data;
    else
      x_rs2 = execute_state.rs2_data;
  end

  logic [`REG_SIZE] x_alu_a, x_alu_b;
  logic             x_alu_cin;
  wire  [`REG_SIZE] x_alu_sum;

  CarryLookaheadAdder u_cla (
      .a  (x_alu_a),
      .b  (x_alu_b),
      .cin(x_alu_cin),
      .sum(x_alu_sum)
  );

  logic [`REG_SIZE] div_op_a, div_op_b;
  wire  [`REG_SIZE] x_div_quotient, x_div_remainder;

  always_comb begin
    if (x_funct3 == 3'b100 || x_funct3 == 3'b110) begin
      div_op_a = x_rs1[31] ? (~x_rs1 + 32'd1) : x_rs1;
      div_op_b = x_rs2[31] ? (~x_rs2 + 32'd1) : x_rs2;
    end else begin
      div_op_a = x_rs1;
      div_op_b = x_rs2;
    end
  end

  DividerUnsignedPipelined u_div (
      .clk        (clk),
      .rst        (rst),
      .stall      (1'b0),
      .i_dividend (div_op_a),
      .i_divisor  (div_op_b),
      .o_quotient (x_div_quotient),
      .o_remainder(x_div_remainder)
  );

  wire x_is_div_op = (x_opcode == OpcodeRegReg) && (x_funct7 == 7'd1) &&
                     (x_funct3 == 3'b100 || x_funct3 == 3'b101 ||
                      x_funct3 == 3'b110 || x_funct3 == 3'b111);

  stage_divq_t div_q[7];

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < 7; i++) div_q[i] <= '0;
    end else begin
      for (int i = 6; i > 0; i--) div_q[i] <= div_q[i-1];
      if (x_is_div_op) begin
        div_q[0] <= '{
          valid:        1'b1,
          pc:           execute_state.pc,
          insn:         execute_state.insn,
          cycle_status: execute_state.cycle_status,
          rd:           execute_state.rd,
          funct3:       x_funct3,
          rs1_neg:      x_rs1[31],
          rs2_neg:      x_rs2[31],
          rs1_val:      x_rs1,
          rs2_val:      x_rs2
        };
      end else begin
        div_q[0] <= '0;
      end
    end
  end

  wire d_is_div_op = (d_opcode == OpcodeRegReg) && (d_funct7 == 7'd1) &&
                     (d_funct3 == 3'b100 || d_funct3 == 3'b101 ||
                      d_funct3 == 3'b110 || d_funct3 == 3'b111);

  wire div_inflight = x_is_div_op    ||
                      div_q[0].valid || div_q[1].valid || div_q[2].valid ||
                      div_q[3].valid || div_q[4].valid || div_q[5].valid;

  wire d_div_dependent =
    (x_is_div_op    && execute_state.rd != 5'd0
                    && (execute_state.rd == d_rs1 || execute_state.rd == d_rs2)) ||
    (div_q[0].valid && div_q[0].rd != 5'd0
                    && (div_q[0].rd == d_rs1 || div_q[0].rd == d_rs2)) ||
    (div_q[1].valid && div_q[1].rd != 5'd0
                    && (div_q[1].rd == d_rs1 || div_q[1].rd == d_rs2)) ||
    (div_q[2].valid && div_q[2].rd != 5'd0
                    && (div_q[2].rd == d_rs1 || div_q[2].rd == d_rs2)) ||
    (div_q[3].valid && div_q[3].rd != 5'd0
                    && (div_q[3].rd == d_rs1 || div_q[3].rd == d_rs2)) ||
    (div_q[4].valid && div_q[4].rd != 5'd0
                    && (div_q[4].rd == d_rs1 || div_q[4].rd == d_rs2)) ||
    (div_q[5].valid && div_q[5].rd != 5'd0
                    && (div_q[5].rd == d_rs1 || div_q[5].rd == d_rs2));

  assign d_div_stall =
    !x_branch_taken &&
    div_inflight &&
    (d_is_div_op ? d_div_dependent : 1'b1);

  logic [`REG_SIZE] div_result;
  always_comb begin
    logic div_by_zero, signed_overflow;
    logic [`REG_SIZE] q_u, r_u, q_s, r_s;
    div_result      = 32'd0;
    div_by_zero     = 1'b0;
    signed_overflow = 1'b0;
    q_u = 32'd0; r_u = 32'd0; q_s = 32'd0; r_s = 32'd0;
    if (div_q[6].valid) begin
      div_by_zero     = (div_q[6].rs2_val == 32'd0);
      signed_overflow = (div_q[6].rs1_val == 32'h8000_0000) &&
                        (div_q[6].rs2_val == 32'hFFFF_FFFF);
      q_u = x_div_quotient;
      r_u = x_div_remainder;
      q_s = (div_q[6].rs1_neg ^ div_q[6].rs2_neg) ? (~q_u + 32'd1) : q_u;
      r_s = div_q[6].rs1_neg ? (~r_u + 32'd1) : r_u;
      case (div_q[6].funct3)
        3'b100: div_result = div_by_zero    ? 32'hFFFF_FFFF :
                             signed_overflow ? 32'h8000_0000 : q_s;
        3'b101: div_result = div_by_zero    ? 32'hFFFF_FFFF : x_div_quotient;
        3'b110: div_result = div_by_zero    ? div_q[6].rs1_val :
                             signed_overflow ? 32'd0          : r_s;
        3'b111: div_result = div_by_zero    ? div_q[6].rs1_val : x_div_remainder;
        default: div_result = 32'd0;
      endcase
    end
  end

  logic [`REG_SIZE] x_rd_data;
  logic             x_rf_we;
  logic             x_halt;

  wire signed [`REG_SIZE] x_s_rs1   = $signed(x_rs1);
  wire signed [`REG_SIZE] x_s_rs2   = $signed(x_rs2);
  wire signed [`REG_SIZE] x_s_imm_i = $signed(execute_state.imm_i_sext);

  always_comb begin
    x_alu_a   = x_rs1;
    x_alu_b   = x_rs2;
    x_alu_cin = 1'b0;

    x_rd_data       = 32'd0;
    x_rf_we         = execute_state.rf_we;
    x_halt          = 1'b0;
    x_branch_taken  = 1'b0;
    x_branch_target = 32'd0;

    x_is_load    = 1'b0;
    x_is_store   = 1'b0;
    x_mem_funct3 = 3'd0;
    x_mem_addr   = 32'd0;
    x_store_data = 32'd0;

    case (x_opcode)
      OpcodeLui: begin
        x_rd_data = execute_state.imm_u;
      end

      OpcodeAuipc: begin
        x_rd_data = execute_state.pc + execute_state.imm_u;
      end

      OpcodeJal: begin
        x_rd_data       = execute_state.pc + 32'd4;
        x_branch_taken  = 1'b1;
        x_branch_target = execute_state.pc + execute_state.imm_j_sext;
      end

      OpcodeJalr: begin
        x_alu_a         = x_rs1;
        x_alu_b         = execute_state.imm_i_sext;
        x_alu_cin       = 1'b0;
        x_rd_data       = execute_state.pc + 32'd4;
        x_branch_taken  = 1'b1;
        x_branch_target = {x_alu_sum[31:1], 1'b0};
      end

      OpcodeRegImm: begin
        case (x_funct3)
          3'b000: begin
            x_alu_a   = x_rs1;
            x_alu_b   = execute_state.imm_i_sext;
            x_alu_cin = 1'b0;
            x_rd_data = x_alu_sum;
          end
          3'b010: x_rd_data = (x_s_rs1 <  x_s_imm_i) ? 32'd1 : 32'd0;
          3'b011: x_rd_data = (x_rs1   <  execute_state.imm_i_sext) ? 32'd1 : 32'd0;
          3'b100: x_rd_data = x_rs1 ^ execute_state.imm_i_sext;
          3'b110: x_rd_data = x_rs1 | execute_state.imm_i_sext;
          3'b111: x_rd_data = x_rs1 & execute_state.imm_i_sext;
          3'b001: x_rd_data = x_rs1 << x_imm_shamt;
          3'b101: begin
            if (x_funct7 == 7'b0100000)
              x_rd_data = $signed(x_rs1) >>> x_imm_shamt;
            else
              x_rd_data = x_rs1 >> x_imm_shamt;
          end
          default: x_rf_we = 1'b0;
        endcase
      end

      OpcodeRegReg: begin
        if (x_funct7 == 7'd0) begin
          case (x_funct3)
            3'b000: begin
              x_alu_a   = x_rs1; x_alu_b = x_rs2; x_alu_cin = 1'b0;
              x_rd_data = x_alu_sum;
            end
            3'b001: x_rd_data = x_rs1 << x_rs2[4:0];
            3'b010: x_rd_data = (x_s_rs1 < x_s_rs2) ? 32'd1 : 32'd0;
            3'b011: x_rd_data = (x_rs1   < x_rs2)   ? 32'd1 : 32'd0;
            3'b100: x_rd_data = x_rs1 ^ x_rs2;
            3'b101: x_rd_data = x_rs1 >> x_rs2[4:0];
            3'b110: x_rd_data = x_rs1 | x_rs2;
            3'b111: x_rd_data = x_rs1 & x_rs2;
            default: x_rf_we = 1'b0;
          endcase
        end else if (x_funct7 == 7'b0100000) begin
          case (x_funct3)
            3'b000: begin
              x_alu_a = x_rs1; x_alu_b = ~x_rs2; x_alu_cin = 1'b1;
              x_rd_data = x_alu_sum;
            end
            3'b101: x_rd_data = $signed(x_rs1) >>> x_rs2[4:0];
            default: x_rf_we = 1'b0;
          endcase
        end else if (x_funct7 == 7'd1) begin
          logic [63:0] u_prod;
          logic signed [63:0] s_prod;
          u_prod = 64'd0; s_prod = 64'd0;
          case (x_funct3)
            3'b000: begin
              u_prod    = $unsigned(x_rs1) * $unsigned(x_rs2);
              x_rd_data = u_prod[31:0];
            end
            3'b001: begin
              s_prod    = $signed(x_rs1) * $signed(x_rs2);
              x_rd_data = s_prod[63:32];
            end
            3'b010: begin
              s_prod    = $signed(x_rs1) * $signed({1'b0, x_rs2});
              x_rd_data = s_prod[63:32];
            end
            3'b011: begin
              u_prod    = $unsigned(x_rs1) * $unsigned(x_rs2);
              x_rd_data = u_prod[63:32];
            end
            3'b100, 3'b101, 3'b110, 3'b111: begin
              x_rf_we = 1'b0;
            end
            default: x_rf_we = 1'b0;
          endcase
        end else begin
          x_rf_we = 1'b0;
        end
      end

      OpcodeBranch: begin
        x_rf_we = 1'b0;
        begin
          logic take;
          take = 1'b0;
          case (x_funct3)
            3'b000: take = (x_rs1 == x_rs2);
            3'b001: take = (x_rs1 != x_rs2);
            3'b100: take = (x_s_rs1 <  x_s_rs2);
            3'b101: take = (x_s_rs1 >= x_s_rs2);
            3'b110: take = (x_rs1   <  x_rs2);
            3'b111: take = (x_rs1   >= x_rs2);
            default: take = 1'b0;
          endcase
          if (take) begin
            x_branch_taken  = 1'b1;
            x_branch_target = execute_state.pc + execute_state.imm_b_sext;
          end
        end
      end

      OpcodeEnviron: begin
        if (execute_state.insn[31:7] == 25'd0)
          x_halt = 1'b1;
        x_rf_we = 1'b0;
      end

      OpcodeMiscMem: begin
        x_rf_we = 1'b0;
      end

      OpcodeLoad: begin
        x_alu_a      = x_rs1;
        x_alu_b      = execute_state.imm_i_sext;
        x_alu_cin    = 1'b0;
        x_mem_addr   = x_alu_sum;
        x_mem_funct3 = x_funct3;
        x_is_load    = 1'b1;
        x_rf_we      = 1'b1;
      end

      OpcodeStore: begin
        x_alu_a      = x_rs1;
        x_alu_b      = execute_state.imm_s_sext;
        x_alu_cin    = 1'b0;
        x_mem_addr   = x_alu_sum;
        x_mem_funct3 = x_funct3;
        x_is_store   = 1'b1;
        x_store_data = x_rs2;
        x_rf_we      = 1'b0;
      end

      default: begin
        x_rf_we = 1'b0;
      end
    endcase
  end

  // =====================================================
  // XM PIPELINE
  // =====================================================

  always_ff @(posedge clk) begin
    if (rst) begin
      memory_state <= '{
        pc: 0, insn: 0, cycle_status: CYCLE_RESET,
        rd: 0, rd_data: 0, rf_we: 0, halt: 0,
        is_load: 0, is_store: 0, mem_funct3: 0, mem_addr: 0, store_data: 0
      };
    end else if (div_q[6].valid) begin
      memory_state <= '{
        pc:           div_q[6].pc,
        insn:         div_q[6].insn,
        cycle_status: div_q[6].cycle_status,
        rd:           div_q[6].rd,
        rd_data:      div_result,
        rf_we:        (div_q[6].rd != 5'd0),
        halt:         1'b0,
        is_load: 0, is_store: 0, mem_funct3: 0, mem_addr: 0, store_data: 0
      };
    end else if (x_is_div_op) begin
      memory_state <= '{
        pc: 0, insn: 0, cycle_status: CYCLE_DIV,
        rd: 0, rd_data: 0, rf_we: 0, halt: 0,
        is_load: 0, is_store: 0, mem_funct3: 0, mem_addr: 0, store_data: 0
      };
    end else begin
      memory_state <= '{
        pc:           execute_state.pc,
        insn:         execute_state.insn,
        cycle_status: execute_state.cycle_status,
        rd:           execute_state.rd,
        rd_data:      x_rd_data,
        rf_we:        x_rf_we,
        halt:         x_halt,
        is_load:      x_is_load,
        is_store:     x_is_store,
        mem_funct3:   x_mem_funct3,
        mem_addr:     x_mem_addr,
        store_data:   x_store_data
      };
    end
  end

  wire [255:0] m_disasm;
  Disasm #(.PREFIX("M")) disasm_3memory (
      .insn  (memory_state.insn),
      .disasm(m_disasm)
  );

  // =====================================================
  // MEMORY
  // =====================================================

  logic [`REG_SIZE] x_dmem_addr_aligned;
  logic [`REG_SIZE] x_dmem_wdata;
  logic [3:0]       x_dmem_wstrb;

  wire  [`REG_SIZE] load_data_from_dmem = dmem.RDATA;

  logic [7:0]  m_load_byte;
  logic [15:0] m_load_half;

  always_comb begin
    x_dmem_addr_aligned = {x_mem_addr[31:2], 2'b00};
    x_dmem_wdata        = 32'd0;
    x_dmem_wstrb        = 4'b0000;

    if (x_is_store) begin
      case (x_mem_funct3)
        3'b000: begin
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
        end

        3'b001: begin
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
        end

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
  end

  always_comb begin
    m_rd_data   = memory_state.rd_data;
    m_load_byte = 8'd0;
    m_load_half = 16'd0;

    if (memory_state.is_load) begin
      case (memory_state.mem_addr[1:0])
        2'b00: m_load_byte = load_data_from_dmem[ 7: 0];
        2'b01: m_load_byte = load_data_from_dmem[15: 8];
        2'b10: m_load_byte = load_data_from_dmem[23:16];
        2'b11: m_load_byte = load_data_from_dmem[31:24];
      endcase

      case (memory_state.mem_addr[1])
        1'b0: m_load_half = load_data_from_dmem[15: 0];
        1'b1: m_load_half = load_data_from_dmem[31:16];
      endcase

      case (memory_state.mem_funct3)
        3'b000: m_rd_data = {{24{m_load_byte[7]}}, m_load_byte};
        3'b001: m_rd_data = {{16{m_load_half[15]}}, m_load_half};
        3'b010: m_rd_data = load_data_from_dmem;
        3'b100: m_rd_data = {24'd0, m_load_byte};
        3'b101: m_rd_data = {16'd0, m_load_half};
        default: m_rd_data = memory_state.rd_data;
      endcase
    end
  end

  assign dmem.ARADDR  = x_dmem_addr_aligned;
  assign dmem.ARVALID = x_is_load;
  assign dmem.ARPROT  = 3'b000;
  assign dmem.RREADY  = 1'b1;

  assign dmem.AWADDR  = x_dmem_addr_aligned;
  assign dmem.AWVALID = x_is_store;
  assign dmem.AWPROT  = 3'b000;

  assign dmem.WDATA   = x_dmem_wdata;
  assign dmem.WSTRB   = x_dmem_wstrb;
  assign dmem.WVALID  = x_is_store;

  assign dmem.BREADY  = 1'b1;

  // =====================================================
  // MW PIPELINE
  // =====================================================

  always_ff @(posedge clk) begin
    if (rst) begin
      writeback_state <= '{
        pc: 0, insn: 0, cycle_status: CYCLE_RESET,
        rd: 0, rd_data: 0, rf_we: 0, halt: 0
      };
    end else begin
      writeback_state <= '{
        pc:           memory_state.pc,
        insn:         memory_state.insn,
        cycle_status: memory_state.cycle_status,
        rd:           memory_state.rd,
        rd_data:      m_rd_data,
        rf_we:        memory_state.rf_we,
        halt:         memory_state.halt
      };
    end
  end

  wire [255:0] w_disasm;
  Disasm #(.PREFIX("W")) disasm_4writeback (
      .insn  (writeback_state.insn),
      .disasm(w_disasm)
  );

  // =====================================================
  // WRITEBACK
  // =====================================================

  assign w_rf_we   = writeback_state.rf_we;
  assign w_rd      = writeback_state.rd;
  assign w_rd_data = writeback_state.rd_data;
  assign halt      = writeback_state.halt;

  assign trace_completed_pc           = writeback_state.pc;
  assign trace_completed_insn         = writeback_state.insn;
  assign trace_completed_cycle_status = writeback_state.cycle_status;

endmodule // DatapathPipelinedAxil

/* This design has just one clock for both processor and memory. */
module Processor (
    input  wire  clk,
    input  wire  rst,
    output logic halt,
    output wire [`REG_SIZE] trace_completed_pc,
    output wire [`INSN_SIZE] trace_completed_insn,
    output cycle_status_e trace_completed_cycle_status
);

  wire [(8*32)-1:0] test_case;

  axil_if axil_mem_ro ();
  axil_if axil_mem_rw ();

  EasyAxilMemory #(
      .OPT_SKIDBUFFER(1),
      .OPT_LOWPOWER(0),
      .NUM_WORDS(8192)
  ) memory (
      .ACLK(clk),
      .ARESETn(~rst),
      .port_ro(axil_mem_ro.subord),
      .port_rw(axil_mem_rw.subord)
  );

  DatapathPipelinedAxil datapath (
      .clk(clk),
      .rst(rst),
      .imem(axil_mem_ro.manager),
      .dmem(axil_mem_rw.manager),
      .halt(halt),
      .trace_completed_pc(trace_completed_pc),
      .trace_completed_insn(trace_completed_insn),
      .trace_completed_cycle_status(trace_completed_cycle_status)
  );

endmodule

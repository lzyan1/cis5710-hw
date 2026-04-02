`timescale 1ns / 1ns

// registers are 32 bits in RV32
`define REG_SIZE 31:0

// insns are 32 bits in RV32IM
`define INSN_SIZE 31:0

// RV opcodes are 7 bits
`define OPCODE_SIZE 6:0

`ifndef DIVIDER_STAGES
`define DIVIDER_STAGES 8
`endif

`ifndef SYNTHESIS
`include "../hw3-singlecycle/RvDisassembler.sv"
`endif
`include "../hw2b-cla/CarryLookaheadAdder.sv"
`include "../hw4-multicycle/DividerUnsignedPipelined.sv"
`include "../hw3-singlecycle/cycle_status.sv"

module Disasm #(
    byte PREFIX = "D"
) (
    input wire [31:0] insn,
    output wire [(8*32)-1:0] disasm
);
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

  // WD bypass
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

/** state at the start of Decode stage */
typedef struct packed {
  logic [`REG_SIZE] pc;
  logic [`INSN_SIZE] insn;
  cycle_status_e cycle_status;
} stage_decode_t;

/** state at the start of X stage */
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
 
 /** state at the start of M stage */
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

 /** state at the start of W stage */
typedef struct packed {
  logic [`REG_SIZE]  pc;
  logic [`INSN_SIZE] insn;
  cycle_status_e     cycle_status;
  logic [4:0]        rd;
  logic [`REG_SIZE]  rd_data;
  logic              rf_we;
} stage_writeback_t;

module DatapathPipelined (
    input wire clk,
    input wire rst,
    output logic [`REG_SIZE] pc_to_imem,
    input wire [`INSN_SIZE] insn_from_imem,
    output logic [`REG_SIZE] addr_to_dmem,
    input wire [`REG_SIZE] load_data_from_dmem,
    output logic [`REG_SIZE] store_data_to_dmem,
    output logic [3:0] store_we_to_dmem,
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
    if (rst) cycles_current <= 0;
    else     cycles_current <= cycles_current + 1;
  end
 
  // =====================================================
  // FETCH
  // =====================================================
 
  logic [`REG_SIZE] f_pc_current;
  cycle_status_e    f_cycle_status;
 
  logic             x_branch_taken;
  logic [`REG_SIZE] x_branch_target;
 
  always_ff @(posedge clk) begin
    if (rst) begin
      f_pc_current   <= 32'd0;
      f_cycle_status <= CYCLE_NO_STALL;
    end else begin
      f_cycle_status <= CYCLE_NO_STALL;
      if (d_load_use_stall)
        f_pc_current <= f_pc_current;        // hold — re-fetch same insn next cycle
      else if (x_branch_taken)
        f_pc_current <= x_branch_target;
      else
        f_pc_current <= f_pc_current + 32'd4;
    end
  end

  assign pc_to_imem = f_pc_current;
 
  wire [`INSN_SIZE] f_insn = insn_from_imem;
 
  wire [255:0] f_disasm;
  Disasm #(.PREFIX("F")) disasm_0fetch (
      .insn  (f_insn),
      .disasm(f_disasm)
  );
 
  // =====================================================
  // DECODE STAGE
  // =====================================================
 
  stage_decode_t decode_state;
  wire flush_fd = x_branch_taken;
 
  always_ff @(posedge clk) begin
    if (rst) begin
      decode_state <= '{pc: 0, insn: 0, cycle_status: CYCLE_RESET};
    end else if (flush_fd) begin
      decode_state <= '{pc: 0, insn: 0, cycle_status: CYCLE_TAKEN_BRANCH};
    end else if (d_load_use_stall) begin
      decode_state <= decode_state;          // hold
    end else begin
      decode_state <= '{
        pc:           f_pc_current,
        insn:         f_insn,
        cycle_status: f_cycle_status
      };
    end
  end
 
  wire [255:0] d_disasm;
  Disasm #(.PREFIX("D")) disasm_1decode (
      .insn  (decode_state.insn),
      .disasm(d_disasm)
  );
 
  // ---- decode insn ----
  wire [`OPCODE_SIZE] d_opcode   = decode_state.insn[6:0];
  wire [4:0]          d_rd       = decode_state.insn[11:7];
  wire [2:0]          d_funct3   = decode_state.insn[14:12];
  wire [4:0]          d_rs1      = decode_state.insn[19:15];
  wire [4:0]          d_rs2      = decode_state.insn[24:20];
  wire [6:0]          d_funct7   = decode_state.insn[31:25];
 
  // immediates
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

  // load-use hazard: load in Execute, dependent insn in Decode
  wire x_is_load_in_exec = (execute_state.insn[6:0] == OpcodeLoad);
  wire d_load_use_stall  = x_is_load_in_exec
                        && (execute_state.rd != 5'd0)
                        && ((execute_state.rd == d_rs1)
                          || (execute_state.rd == d_rs2));
  
  // RegFile read (WD bypass inside RegFile)
  logic [`REG_SIZE] d_rs1_data, d_rs2_data;
 
  // RegFile wires from writeback
  logic        w_rf_we;
  logic [4:0]  w_rd;
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
 
  // rf_we
  logic d_rf_we;
  always_comb begin
    case (d_opcode)
      OpcodeBranch, OpcodeStore, OpcodeMiscMem: d_rf_we = 1'b0;
      OpcodeEnviron: d_rf_we = 1'b0;
      default: d_rf_we = 1'b1;
    endcase
  end
 
  // =====================================================
  // D/X PIPELINE REGISTER
  // =====================================================
 
  stage_execute_t execute_state;
 
  // flush the D/X register when branch taken
  wire flush_dx = x_branch_taken;
 
  always_ff @(posedge clk) begin
    if (rst) begin
      execute_state <= '{
        pc: 0, insn: 0, cycle_status: CYCLE_RESET,
        rs1: 0, rs2: 0, rd: 0,
        rs1_data: 0, rs2_data: 0,
        imm_i_sext: 0, imm_b_sext: 0, imm_j_sext: 0, imm_s_sext: 0, imm_u: 0,
        rf_we: 0
      };
    end else if (flush_dx) begin
      execute_state <= '{
        pc: 0, insn: 0, cycle_status: CYCLE_TAKEN_BRANCH,
        rs1: 0, rs2: 0, rd: 0,
        rs1_data: 0, rs2_data: 0,
        imm_i_sext: 0, imm_b_sext: 0, imm_j_sext: 0, imm_s_sext: 0, imm_u: 0,
        rf_we: 0
      };
    end else if (d_load_use_stall) begin
      // NOP bubble; the real insn stays in Decode one more cycle
      execute_state <= '{
        pc: 0, insn: 0, cycle_status: CYCLE_LOAD2USE,
        rs1: 0, rs2: 0, rd: 0,
        rs1_data: 0, rs2_data: 0,
        imm_i_sext: 0, imm_b_sext: 0, imm_j_sext: 0, imm_s_sext: 0, imm_u: 0,
        rf_we: 0
      };
    end else begin
      execute_state <= '{
        pc:         decode_state.pc,
        insn:       decode_state.insn,
        cycle_status: decode_state.cycle_status,
        rs1:        d_rs1,
        rs2:        d_rs2,
        rd:         d_rd,
        rs1_data:   d_rs1_data,
        rs2_data:   d_rs2_data,
        imm_i_sext: d_imm_i_sext,
        imm_b_sext: d_imm_b_sext,
        imm_j_sext: d_imm_j_sext,
        imm_s_sext: d_imm_s_sext,   // ← NEW
        imm_u:      d_imm_u,
        rf_we:      d_rf_we
      };
    end
  end
 
  wire [255:0] x_disasm;
  Disasm #(.PREFIX("X")) disasm_2execute (
      .insn  (execute_state.insn),
      .disasm(x_disasm)
  );
 
  // =====================================================
  // EXECUTE STAGE
  // =====================================================
 
  wire [`OPCODE_SIZE] x_opcode = execute_state.insn[6:0];
  wire [2:0]          x_funct3 = execute_state.insn[14:12];
  wire [6:0]          x_funct7 = execute_state.insn[31:25];
  wire [4:0]          x_imm_shamt = execute_state.insn[24:20];
 
  // X/M and M/W pipeline register values for bypass
  stage_memory_t    memory_state;
  stage_writeback_t writeback_state;
 
  // MX bypass: memory_state.rd_data
  // WX bypass: writeback_state.rd_data
  logic [`REG_SIZE] x_rs1, x_rs2;

  // forward-declared here so MX bypass and Execute comb can both see it
  logic [`REG_SIZE] m_rd_data;

  // new Execute-stage outputs for load/store
  logic              x_is_load, x_is_store;
  logic [2:0]        x_mem_funct3;
  logic [`REG_SIZE]  x_mem_addr, x_store_data;
 
  always_comb begin
    if (memory_state.rf_we && memory_state.rd != 5'd0 &&
        memory_state.rd == execute_state.rs1)
      x_rs1 = m_rd_data;                      // ← was memory_state.rd_data
    else if (writeback_state.rf_we && writeback_state.rd != 5'd0 &&
            writeback_state.rd == execute_state.rs1)
      x_rs1 = writeback_state.rd_data;
    else
      x_rs1 = execute_state.rs1_data;

    if (memory_state.rf_we && memory_state.rd != 5'd0 &&
        memory_state.rd == execute_state.rs2)
      x_rs2 = m_rd_data;                      // ← was memory_state.rd_data
    else if (writeback_state.rf_we && writeback_state.rd != 5'd0 &&
            writeback_state.rd == execute_state.rs2)
      x_rs2 = writeback_state.rd_data;
    else
      x_rs2 = execute_state.rs2_data;
  end
 
  // CLA adder
  logic [`REG_SIZE] x_alu_a, x_alu_b;
  logic             x_alu_cin;
  wire  [`REG_SIZE] x_alu_sum;
 
  CarryLookaheadAdder u_cla (
      .a  (x_alu_a),
      .b  (x_alu_b),
      .cin(x_alu_cin),
      .sum(x_alu_sum)
  );
 
  // ALU result and control
  logic [`REG_SIZE] x_rd_data;
  logic             x_rf_we;
  logic             x_halt;
 
  wire signed [`REG_SIZE] x_s_rs1 = $signed(x_rs1);
  wire signed [`REG_SIZE] x_s_rs2 = $signed(x_rs2);
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
 
      // ---- LUI ----
      OpcodeLui: begin
        x_rd_data = execute_state.imm_u;
      end
 
      // ---- AUIPC ----
      OpcodeAuipc: begin
        x_rd_data = execute_state.pc + execute_state.imm_u;
      end
 
      // ---- JAL ----
      OpcodeJal: begin
        x_rd_data      = execute_state.pc + 32'd4;
        x_branch_taken  = 1'b1;
        x_branch_target = execute_state.pc + execute_state.imm_j_sext;
      end
 
      // ---- JALR ----
      OpcodeJalr: begin
        x_alu_a         = x_rs1;
        x_alu_b         = execute_state.imm_i_sext;
        x_alu_cin       = 1'b0;
        x_rd_data       = execute_state.pc + 32'd4;
        x_branch_taken  = 1'b1;
        x_branch_target = {x_alu_sum[31:1], 1'b0};
      end
 
      // ---- I-TYPE ----
      OpcodeRegImm: begin
        case (x_funct3)
          3'b000: begin // addi
            x_alu_a   = x_rs1;
            x_alu_b   = execute_state.imm_i_sext;
            x_alu_cin = 1'b0;
            x_rd_data = x_alu_sum;
          end
          3'b010: begin // slti
            x_rd_data = (x_s_rs1 < x_s_imm_i) ? 32'd1 : 32'd0;
          end
          3'b011: begin // sltiu
            x_rd_data = (x_rs1 < execute_state.imm_i_sext) ? 32'd1 : 32'd0;
          end
          3'b100: begin // xori
            x_rd_data = x_rs1 ^ execute_state.imm_i_sext;
          end
          3'b110: begin // ori
            x_rd_data = x_rs1 | execute_state.imm_i_sext;
          end
          3'b111: begin // andi
            x_rd_data = x_rs1 & execute_state.imm_i_sext;
          end
          3'b001: begin // slli
            x_rd_data = x_rs1 << x_imm_shamt;
          end
          3'b101: begin // srli / srai
            if (x_funct7 == 7'b0100000)
              x_rd_data = $signed(x_rs1) >>> x_imm_shamt;
            else
              x_rd_data = x_rs1 >> x_imm_shamt;
          end
          default: x_rf_we = 1'b0;
        endcase
      end
 
      // ---- R-TYPE ----
      OpcodeRegReg: begin
        if (x_funct7 == 7'd0) begin
          case (x_funct3)
            3'b000: begin // add
              x_alu_a   = x_rs1;
              x_alu_b   = x_rs2;
              x_alu_cin = 1'b0;
              x_rd_data = x_alu_sum;
            end
            3'b001: x_rd_data = x_rs1 << x_rs2[4:0];          // sll
            3'b010: x_rd_data = (x_s_rs1 < x_s_rs2) ? 32'd1 : 32'd0; // slt
            3'b011: x_rd_data = (x_rs1 < x_rs2) ? 32'd1 : 32'd0;     // sltu
            3'b100: x_rd_data = x_rs1 ^ x_rs2;                 // xor
            3'b101: x_rd_data = x_rs1 >> x_rs2[4:0];           // srl
            3'b110: x_rd_data = x_rs1 | x_rs2;                 // or
            3'b111: x_rd_data = x_rs1 & x_rs2;                 // and
            default: x_rf_we = 1'b0;
          endcase
        end else if (x_funct7 == 7'b0100000) begin
          case (x_funct3)
            3'b000: begin // sub
              x_alu_a   = x_rs1;
              x_alu_b   = ~x_rs2;
              x_alu_cin = 1'b1;
              x_rd_data = x_alu_sum;
            end
            3'b101: x_rd_data = $signed(x_rs1) >>> x_rs2[4:0]; // sra
            default: x_rf_we = 1'b0;
          endcase
        end else if (x_funct7 == 7'd1) begin
          logic [63:0] u_prod;
          logic signed [63:0] s_prod;
          u_prod = 64'd0;
          s_prod = 64'd0;
          case (x_funct3)
            3'b000: begin // mul
              u_prod    = $unsigned(x_rs1) * $unsigned(x_rs2);
              x_rd_data = u_prod[31:0];
            end
            3'b001: begin // mulh
              s_prod    = $signed(x_rs1) * $signed(x_rs2);
              x_rd_data = s_prod[63:32];
            end
            3'b010: begin // mulhsu
              s_prod    = $signed(x_rs1) * $signed({1'b0, x_rs2});
              x_rd_data = s_prod[63:32];
            end
            3'b011: begin // mulhu
              u_prod    = $unsigned(x_rs1) * $unsigned(x_rs2);
              x_rd_data = u_prod[63:32];
            end
            default: x_rf_we = 1'b0;
          endcase
        end else begin
          x_rf_we = 1'b0;
        end
      end
 
      // ---- BRANCH ----
      OpcodeBranch: begin
        x_rf_we = 1'b0;
        begin
          logic take;
          take = 1'b0;
          case (x_funct3)
            3'b000: take = (x_rs1 == x_rs2);              // beq
            3'b001: take = (x_rs1 != x_rs2);              // bne
            3'b100: take = (x_s_rs1 <  x_s_rs2);          // blt
            3'b101: take = (x_s_rs1 >= x_s_rs2);          // bge
            3'b110: take = (x_rs1 <  x_rs2);              // bltu
            3'b111: take = (x_rs1 >= x_rs2);              // bgeu
            default: take = 1'b0;
          endcase
          if (take) begin
            x_branch_taken  = 1'b1;
            x_branch_target = execute_state.pc + execute_state.imm_b_sext;
          end
        end
      end
 
      // ---- ECALL / FENCE ----
      OpcodeEnviron: begin
        // ecall -> halt
        if (execute_state.insn[31:7] == 25'd0)
          x_halt = 1'b1;
        x_rf_we = 1'b0;
      end
 
      OpcodeMiscMem: begin
        x_rf_we = 1'b0; // fence: nop
      end

      // ---- LOAD ----
      OpcodeLoad: begin
        x_alu_a      = x_rs1;
        x_alu_b      = execute_state.imm_i_sext;
        x_alu_cin    = 1'b0;
        x_mem_addr   = x_alu_sum;
        x_mem_funct3 = x_funct3;
        x_is_load    = 1'b1;
        x_rf_we      = 1'b1;
        // rd_data set in Memory from dmem
      end

      // ---- STORE ----
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
  // X/M PIPELINE REGISTER
  // =====================================================
 
  always_ff @(posedge clk) begin
    if (rst) begin
      memory_state <= '{
        pc: 0, insn: 0, cycle_status: CYCLE_RESET,
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
  // MEMORY STAGE
  // (M1: no loads/stores, just pass through)
  // =====================================================
 
  // ─── Memory stage: load/store + compute m_rd_data ──────────────────────────
  logic [7:0]  m_load_byte;
  logic [15:0] m_load_half;

  assign halt = memory_state.halt;

  always_comb begin
    // defaults
    m_rd_data          = memory_state.rd_data;
    addr_to_dmem       = 32'd0;
    store_data_to_dmem = 32'd0;
    store_we_to_dmem   = 4'b0000;
    m_load_byte        = 8'd0;
    m_load_half        = 16'd0;

    if (memory_state.is_load) begin
      addr_to_dmem = {memory_state.mem_addr[31:2], 2'b00};

      // select byte / halfword based on byte offset
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
        3'b000: m_rd_data = {{24{m_load_byte[7]}}, m_load_byte};    // lb
        3'b001: m_rd_data = {{16{m_load_half[15]}}, m_load_half};   // lh
        3'b010: m_rd_data = load_data_from_dmem;                     // lw
        3'b100: m_rd_data = {24'd0, m_load_byte};                    // lbu
        3'b101: m_rd_data = {16'd0, m_load_half};                    // lhu
        default: m_rd_data = memory_state.rd_data;
      endcase

    end else if (memory_state.is_store) begin
      addr_to_dmem = {memory_state.mem_addr[31:2], 2'b00};

      case (memory_state.mem_funct3)
        3'b000: begin // sb — write one byte at byte offset
          case (memory_state.mem_addr[1:0])
            2'b00: begin store_we_to_dmem = 4'b0001;
                        store_data_to_dmem = {24'd0, memory_state.store_data[7:0]}; end
            2'b01: begin store_we_to_dmem = 4'b0010;
                        store_data_to_dmem = {16'd0, memory_state.store_data[7:0], 8'd0}; end
            2'b10: begin store_we_to_dmem = 4'b0100;
                        store_data_to_dmem = {8'd0, memory_state.store_data[7:0], 16'd0}; end
            2'b11: begin store_we_to_dmem = 4'b1000;
                        store_data_to_dmem = {memory_state.store_data[7:0], 24'd0}; end
          endcase
        end
        3'b001: begin // sh — write two bytes at halfword offset
          case (memory_state.mem_addr[1])
            1'b0: begin store_we_to_dmem = 4'b0011;
                        store_data_to_dmem = {16'd0, memory_state.store_data[15:0]}; end
            1'b1: begin store_we_to_dmem = 4'b1100;
                        store_data_to_dmem = {memory_state.store_data[15:0], 16'd0}; end
          endcase
        end
        3'b010: begin // sw
          store_we_to_dmem   = 4'b1111;
          store_data_to_dmem = memory_state.store_data;
        end
        default: begin
          store_we_to_dmem   = 4'b0000;
          store_data_to_dmem = 32'd0;
        end
      endcase
    end
  end
 
  // =====================================================
  // M/W PIPELINE REGISTER
  // =====================================================
 
  always_ff @(posedge clk) begin
    if (rst) begin
      writeback_state <= '{
        pc: 0, insn: 0, cycle_status: CYCLE_RESET,
        rd: 0, rd_data: 0, rf_we: 0
      };
    end else begin
      writeback_state <= '{
        pc:           memory_state.pc,
        insn:         memory_state.insn,
        cycle_status: memory_state.cycle_status,
        rd:           memory_state.rd,
        rd_data:      m_rd_data, 
        rf_we:        memory_state.rf_we
      };
    end
  end
 
  wire [255:0] w_disasm;
  Disasm #(.PREFIX("W")) disasm_4writeback (
      .insn  (writeback_state.insn),
      .disasm(w_disasm)
  );
 
  // =====================================================
  // WRITEBACK STAGE
  // =====================================================
 
  assign w_rf_we   = writeback_state.rf_we;
  assign w_rd      = writeback_state.rd;
  assign w_rd_data = writeback_state.rd_data;
 
  assign trace_completed_pc           = writeback_state.pc;
  assign trace_completed_insn         = writeback_state.insn;
  assign trace_completed_cycle_status = writeback_state.cycle_status;
 
 
endmodule

module MemorySingleCycle #(
    parameter int NUM_WORDS = 512
) (
    // rst for both imem and dmem
    input wire rst,

    // clock for both imem and dmem. The memory reads/writes on @(negedge clk)
    input wire clk,

    // must always be aligned to a 4B boundary
    input wire [`REG_SIZE] pc_to_imem,

    // the value at memory location pc_to_imem
    output logic [`REG_SIZE] insn_from_imem,

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

  always @(negedge clk) begin
    if (rst) begin
    end else begin
      insn_from_imem <= mem_array[{pc_to_imem[AddrMsb:AddrLsb]}];
    end
  end

  always @(negedge clk) begin
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

/* This design has just one clock for both processor and memory. */
module Processor (
    input  wire  clk,
    input  wire  rst,
    output logic halt,
    output wire [`REG_SIZE] trace_writeback_pc,
    output wire [`INSN_SIZE] trace_writeback_insn,
    output cycle_status_e trace_writeback_cycle_status
);

  wire [`INSN_SIZE] insn_from_imem;
  wire [`REG_SIZE] pc_to_imem, mem_data_addr, mem_data_loaded_value, mem_data_to_write;
  wire [3:0] mem_data_we;

  // This wire is set by cocotb to the name of the currently-running test, to make it easier
  // to see what is going on in the waveforms.
  wire [(8*32)-1:0] test_case;

  MemorySingleCycle #(
      .NUM_WORDS(8192)
  ) memory (
      .rst                (rst),
      .clk                (clk),
      // imem is read-only
      .pc_to_imem         (pc_to_imem),
      .insn_from_imem     (insn_from_imem),
      // dmem is read-write
      .addr_to_dmem       (mem_data_addr),
      .load_data_from_dmem(mem_data_loaded_value),
      .store_data_to_dmem (mem_data_to_write),
      .store_we_to_dmem   (mem_data_we)
  );

  DatapathPipelined datapath (
      .clk(clk),
      .rst(rst),
      .pc_to_imem(pc_to_imem),
      .insn_from_imem(insn_from_imem),
      .addr_to_dmem(mem_data_addr),
      .store_data_to_dmem(mem_data_to_write),
      .store_we_to_dmem(mem_data_we),
      .load_data_from_dmem(mem_data_loaded_value),
      .halt(halt),
      .trace_completed_pc(trace_writeback_pc),
      .trace_completed_insn(trace_writeback_insn),
      .trace_completed_cycle_status(trace_writeback_cycle_status)
  );

endmodule

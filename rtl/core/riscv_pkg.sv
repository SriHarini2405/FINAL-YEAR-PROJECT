// ============================================================================
// Package: riscv_pkg
// ============================================================================
package riscv_pkg;

    typedef enum logic [6:0] {
        OP_LUI      = 7'b0110111,
        OP_AUIPC    = 7'b0010111,
        OP_JAL      = 7'b1101111,
        OP_JALR     = 7'b1100111,
        OP_BRANCH   = 7'b1100011,
        OP_LOAD     = 7'b0000011,
        OP_STORE    = 7'b0100011,
        OP_OP_IMM   = 7'b0010011,
        OP_OP       = 7'b0110011,
        OP_SYSTEM   = 7'b1110011,
        OP_CUSTOM_0 = 7'b0001011     // imu_mac
    } opcode_e;

    typedef enum logic [3:0] {
        ALU_ADD    = 4'b0000,
        ALU_SUB    = 4'b0001,
        ALU_SLL    = 4'b0010,
        ALU_SLT    = 4'b0011,
        ALU_SLTU   = 4'b0100,
        ALU_XOR    = 4'b0101,
        ALU_SRL    = 4'b0110,
        ALU_SRA    = 4'b0111,
        ALU_OR     = 4'b1000,
        ALU_AND    = 4'b1001,
        ALU_PASS_B = 4'b1010
    } alu_op_e;

    typedef enum logic [2:0] {
        BR_EQ  = 3'b000,
        BR_NE  = 3'b001,
        BR_LT  = 3'b100,
        BR_GE  = 3'b101,
        BR_LTU = 3'b110,
        BR_GEU = 3'b111
    } branch_op_e;

    typedef enum logic [2:0] {
        MEM_B  = 3'b000,
        MEM_H  = 3'b001,
        MEM_W  = 3'b010,
        MEM_BU = 3'b100,
        MEM_HU = 3'b101
    } mem_format_e;

    typedef enum logic [2:0] {
        M_MUL    = 3'b000,
        M_MULH   = 3'b001,
        M_MULHSU = 3'b010,
        M_MULHU  = 3'b011,
        M_DIV    = 3'b100,
        M_DIVU   = 3'b101,
        M_REM    = 3'b110,
        M_REMU   = 3'b111
    } m_op_e;

    typedef enum logic [2:0] {
        WB_ALU,
        WB_MEM,
        WB_MD,
        WB_PC4,
        WB_CIM
    } wb_sel_e;

    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] instr;
        logic        valid;
    } if_id_reg_t;

    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] rs1_data;
        logic [31:0] rs2_data;
        logic [31:0] imm;
        logic [4:0]  rs1_addr;
        logic [4:0]  rs2_addr;
        logic [4:0]  rd_addr;
        logic        valid;
        alu_op_e     alu_op;
        logic        alu_src_a;
        logic        alu_src_b;
        logic        is_branch;
        branch_op_e  branch_type;
        logic        is_jal;
        logic        is_jalr;
        logic        mem_read;
        logic        mem_write;
        mem_format_e mem_format;
        logic        reg_write;
        wb_sel_e     wb_sel;
        logic        is_m_ext;
        m_op_e       m_op;
        logic        is_cim;
    } id_ex_reg_t;

    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] alu_result;
        logic [31:0] md_result;
        logic [31:0] cim_result;
        logic [31:0] rs2_data;
        logic [4:0]  rd_addr;
        logic        valid;
        logic        mem_read;
        logic        mem_write;
        mem_format_e mem_format;
        logic        reg_write;
        wb_sel_e     wb_sel;
        logic        is_cim;
    } ex_mem_reg_t;

    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] alu_result;
        logic [31:0] md_result;
        logic [31:0] cim_result;
        logic [31:0] mem_data;
        logic [4:0]  rd_addr;
        logic        valid;
        logic        reg_write;
        wb_sel_e     wb_sel;
    } mem_wb_reg_t;

endpackage
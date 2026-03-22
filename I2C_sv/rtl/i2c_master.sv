`timescale 1ps / 1ns

module i2c_master
    import i2c_pkg::*;
#(
    parameter int CLK_DIV = 16
) (
    // System
    input logic clk,
    input logic rst_n,
    // control
    input logic i_start,
    input i2c_rw_e i_rw,
    input logic [I2C_ADDR_W-1:0] i_slave_addr,
    input logic [I2C_DATA_W-1:0] i_tx_data,
    input logic [3:0] i_num_bytes,
    input logic i_rep_start,
    // status
    output logic o_busy,
    output logic o_done,
    output logic o_ack_error,
    output logic [I2C_DATA_W-1:0] o_rx_data,
    output logic o_rx_valid,
    output logic [3:0] o_bytes_received,
    // i2c bus
    output logic o_scl_oe,
    input logic i_scl,
    output logic o_sda_oe,
    input logic i_sda
);
    // ---- Local typedef ----
    // Transaction FSM states
    typedef enum logic [2:0] {
        MST_IDLE,
        MST_START,
        MST_ADDR,
        MST_DATA,
        MST_STOP
    } mst_state_e;

    // Phisical FSM states
    typedef enum logic [2:0] {
        PHY_IDLE,
        PHY_START,
        PHT_WRITE_BIT,
        PHT_READ_BIT,
        PHY_ACK,
        PHY_STOP
    } phy_state_e;

    // Command enum
    typedef enum logic {
        CMD_START,
        CMD_SEND_BYTE,
        CMD_READ_BYTE,
        CMD_STOP
    } i2c_cmd_e;


    typedef struct packed {
        logic [I2C_ADDR_W-1:0] slave_addr;
        i2c_rw_e rw;
    } i2c_addr_t;

    // ---- Local parameters ----
    localparam int BIT_MAX = 7;

    // ---- Internal signals ----
    mst_state_e mst_state;
    phy_state_e phy_state;
    logic scl_internal;
    logic [BIT_MAX:0] shift_reg;
    logic [2:0] bit_cnt;

    // ---- Submodules ----
    i2c_clk_div #(
        .DIV(CLK_DIV)
    ) u_clk_div (
        .clk  (clk),
        .rst_n(rst_n),
        .i_en (o_busy),
        .o_scl(scl_internal)
    );

    // ---- FSMs ----

endmodule

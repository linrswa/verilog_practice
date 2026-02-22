`timescale 1ns / 1ps

module i2c_master (
    input  wire       clk,         // 系統時鐘（遠快於 SCL，例如 50MHz）
    input  wire       rst_n,       // 非同步 reset（active low）
    input  wire       start,       // 外部觸發：開始一筆 transaction
    input  wire [6:0] slave_addr,  // 7-bit slave address
    input  wire [7:0] data_in,     // 要寫入的 8-bit data
    output reg        busy,        // transaction 進行中
    output reg        done,        // transaction 完成（one-cycle pulse）
    output reg        ack_error,   // slave 回 NACK（address 或 data phase）
    output wire       scl,         // I2C clock（open-drain）
    inout  wire       sda          // I2C data（open-drain, bidirectional）
);

    // parameter / 內部 reg、wire 宣告
    parameter integer CLK_DIV = 100;
    reg [$clog2(CLK_DIV)-1:0] clk_div_cnt;  // clock divider counter
    reg sda_oe;
    reg scl_oe;

    reg [2:0] state;
    reg [7:0] addr_buf;
    reg [7:0] data_buf;
    reg [2:0] bit_cnt;

    // open-drain assign
    assign sda = sda_oe ? 1'b0 : 1'bz;  // sda_oe = 1 時拉低，否則高阻
    assign scl = scl_oe ? 1'b0 : 1'bz;  //
    // clock divider counter 的 always block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div_cnt <= 0;
        end else if (clk_div_cnt == CLK_DIV - 1) begin
            clk_div_cnt <= 0;
        end else begin
            clk_div_cnt <= clk_div_cnt + 1;
        end
    end
    // FSM state transition 的 always block
    localparam integer CntPhase0 = 0;  // SCL 下降沿的 half cycle
    localparam integer CntPhase1 = CLK_DIV / 4;  // SCL low middle point
    localparam integer CntPhase2 = CLK_DIV / 2;  // SCL 上升沿的 half cycle
    localparam integer CntPhase3 = 3 * CLK_DIV / 4;  // SCL high middle point

    localparam integer IDLE       = 3'b000,
                       START      = 3'b001,
                       ADDR       = 3'b010,
                       ADDR_ACK   = 3'b011,
                       DATA       = 3'b100,
                       DATA_ACK   = 3'b101,
                       STOP       = 3'b110;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_oe <= 0;
            scl_oe <= 0;
            busy <= 0;
            done <= 0;
            ack_error <= 0;
            bit_cnt <= 0;
            state <= IDLE;
        end else begin
            done <= 0;
            case (state)
                IDLE: begin
                    sda_oe <= 0;
                    scl_oe <= 0;
                    busy   <= 0;
                    done   <= 0;
                    if (start) begin
                        state <= START;
                        ack_error <= 0;
                        busy <= 1;
                    end
                end
                START: begin
                    if (clk_div_cnt == CntPhase3) begin
                        sda_oe <= 1;  // 拉低 SDA 產生 start condition
                        addr_buf <= {slave_addr, 1'b0};  // 7-bit address + write bit (0)
                        state  <= ADDR;
                    end
                end
                ADDR: begin
                    case (clk_div_cnt)
                        CntPhase0: scl_oe <= 1;  // SCL low
                        CntPhase1: sda_oe <= ~addr_buf[7-bit_cnt];  // MSB first
                        CntPhase2: scl_oe <= 0;  // SCL high
                        CntPhase3: begin
                            if (bit_cnt == 7) begin
                                state  <= ADDR_ACK;  // 發送完 address 後進入 ACK phase
                                sda_oe <= 0;  // 釋放 SDA 等待 slave 回 ACK
                            end
                            bit_cnt <= bit_cnt + 1;
                        end
                        default: begin
                            scl_oe <= scl_oe;
                            sda_oe <= sda_oe;
                        end
                    endcase
                end
                ADDR_ACK: begin
                    case (clk_div_cnt)
                        CntPhase0: scl_oe <= 1;  // SCL low
                        CntPhase2: scl_oe <= 0;  // SCL high
                        CntPhase3: begin
                            if (sda) begin
                                ack_error <= 1;  // NACK
                                state <= STOP;  // 發生 NACK 就結束 transaction
                            end else begin
                                bit_cnt <= 0;  // ACK 正確，準備發送 data
                                data_buf <= data_in;
                                state   <= DATA;
                            end
                        end
                        default: begin
                            scl_oe <= scl_oe;
                            sda_oe <= sda_oe;
                        end
                    endcase
                end
                DATA: begin
                    case (clk_div_cnt)
                        CntPhase0: scl_oe <= 1;  // SCL low
                        CntPhase1: sda_oe <= ~data_buf[7-bit_cnt];  // MSB first
                        CntPhase2: scl_oe <= 0;  // SCL high
                        CntPhase3: begin
                            if (bit_cnt == 7) begin
                                state  <= DATA_ACK;  // 發送完 data 後進入 ACK phase
                                sda_oe <= 0;  // 釋放 SDA 等待 slave 回 ACK
                            end
                            bit_cnt <= bit_cnt + 1;
                        end
                        default: begin
                            scl_oe <= scl_oe;
                            sda_oe <= sda_oe;
                        end
                    endcase
                end
                DATA_ACK: begin
                    case (clk_div_cnt)
                        CntPhase0: scl_oe <= 1;  // SCL low
                        CntPhase2: scl_oe <= 0;  // SCL high
                        CntPhase3: begin
                            if (sda) begin
                                ack_error <= 1;  // NACK
                            end
                            state <= STOP;  // 不論 ACK/NACK 都結束 transaction
                        end
                        default: begin
                            scl_oe <= scl_oe;
                            sda_oe <= sda_oe;
                        end
                    endcase
                end
                STOP: begin
                    case (clk_div_cnt)
                        CntPhase0: scl_oe <= 1;  // SCL low
                        CntPhase1: sda_oe <= 1;  // 拉低 SDA
                        CntPhase2: scl_oe <= 0;  // SCL high
                        CntPhase3: begin
                            sda_oe <= 0;  // 釋放 SDA 產生 stop condition
                            done <= 1;
                            state  <= IDLE;
                        end
                        default: begin
                            scl_oe <= scl_oe;
                            sda_oe <= sda_oe;
                        end
                    endcase
                end
                default: state <= state;
            endcase
        end
    end
endmodule

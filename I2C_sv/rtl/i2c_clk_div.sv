`timescale 1ns / 1ps

module i2c_clk_div
#(
    parameter int DIV = 16
    )(
    input  logic clk,
    input  logic rst_n,
    input  logic i_en,
    output logic o_scl
);

  typedef enum logic [1:0] {
    FALLING,
    LOW_MID,
    RISING,
    HIGH_MID
  } scl_state_e;

  localparam int CNT_W = (DIV <= 1) ? 1 : $clog2(DIV);
  localparam int QUARTER = DIV / 4;
  logic [(CNT_W-1):0] counter;
  scl_state_e phase;

  always_comb begin
    if (counter < CNT_W'(QUARTER)) begin
      phase = FALLING;
    end else if (counter < CNT_W'(2 * QUARTER)) begin
      phase = LOW_MID;
    end else if (counter < CNT_W'(3 * QUARTER)) begin
      phase = RISING;
    end else begin
      phase = HIGH_MID;
    end
  end

  always_comb begin
    o_scl = 1'b0;
    case (phase)
      FALLING:  o_scl = 1'b0;
      LOW_MID:  o_scl = 1'b0;
      RISING:   o_scl = 1'b1;
      HIGH_MID: o_scl = 1'b1;
      default:  o_scl = 1'b0;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= 0;
    end else if (!i_en) begin
      counter <= 0;
    end else begin
      if (counter >= CNT_W'(DIV - 1)) begin
        counter <= 0;
      end else begin
        counter <= counter + 1;
      end
    end
  end

endmodule

`timescale 1ns / 1ps

module open_drain_output (
    input  wire data_out,   // 想要送出的資料（1 或 0）
    input  wire output_en,  // 輸出致能：1 = 驅動, 0 = 釋放（高阻抗）
    output wire pad         // 連接到外部 bus 的 pad（open-drain）
);

    assign pad = (output_en && !data_out) ? 1'b0 : 1'bz;

endmodule

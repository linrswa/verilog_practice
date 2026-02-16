module vending_fsm(
    input  clk,
    input  rst_n,        // async reset
    input  coin5,        // 投入 5 元 (pulse)
    input  coin10,       // 投入 10 元 (pulse)
    output reg vend,     // 出貨
    output reg change    // 找 5 元
);

    localparam S_0 = 3'b000, S_5 = 3'b001, S_10 = 3'b010, S_VEND = 3'b011, S_VEND_CHANGE = 3'b100;

    reg [2:0] state, next_state;

    // State
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            state <= S_0;
        else 
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        vend = 1'b0;
        change = 1'b0;
        case (state)
            S_0: begin
                if (coin5) next_state = S_5;
                else if (coin10) next_state = S_10;
            end
            S_5: begin
                if (coin5) next_state = S_10;
                else if (coin10) next_state = S_VEND;
            end
            S_10: begin
                if (coin5) next_state = S_VEND;
                else if (coin10) next_state = S_VEND_CHANGE;
            end
            S_VEND: begin
                vend = 1'b1;
                next_state = S_0; // 出貨後回到初始狀態
            end
            S_VEND_CHANGE: begin
                vend = 1'b1;
                change = 1'b1;
                next_state = S_0; // 出貨後回到初始狀態
            end
            default: next_state = S_0; // 異常恢復
        endcase
    end
endmodule

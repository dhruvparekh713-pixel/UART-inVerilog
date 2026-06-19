module buadRateGen #(
    parameter  CLK_FREQ = 50_000_000, // 50 MHz
    parameter BAUD_RATE = 9600
    )(
        input wire clk,
        input wire rst_n, // Active-low Asynchronus Reset
        output reg tick
);
    localparam DIVISIOR = CLK_FREQ/(BAUD_RATE*16); // Over-Samples to prevent error accumulation
    // 50MHz/(9600*16Hz) = 325.5 -> Divisor = 325, Error ~0.15% (not to much)

    //counter register to allow for DIVISOR to me accumulated and then wrapped around when counting
    reg [$clog2(DIVISIOR)-1:0] counter;

    always @(posedge clk or negedge rst_n) begin

        //reset branch
        if(!rst_n) begin 
            counter <= 0;
            tick <= 1'b0;
        end else if (counter == DIVISIOR - 1) begin // reseting counter
            counter <= 0;
            tick <= 1'b1; // makes tick 1 to show that 1/16 of baud cycle is complete, which the TX and RX keep tack of
        end else begin 
            counter <= counter + 1;
            tick <= 1'b0;
            // increments count and keeps tick = 0, so the TX and RX don't increment thier count, and instead
            // the counter increments to show that the cycle is moving forwards towards DIVISOR 
        end
        
    end
endmodule
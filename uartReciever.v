module uartReciever #(
    parameter databits = 8
)
(
    input wire clk, 
    input wire tick, //16x oversampled enable from baudRateGen 
    input wire rst_n, 
    input wire  rxIn, // serial line
    output reg [databits - 1:0] dataOut, //recvied byte 
    output reg dataReady, // tells us if a byte is ready 
    output reg framingError // a validity check, 1 if stop bit was not high
);
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    localparam MID = 7; // mid-bit sample bit for 16x oversampled tick
    localparam LAST = 15; // last tick of a bit-period

    // similar set up to Transmitter
    reg[1:0] state,nextState;
    reg[3:0] tickCounter;
    reg[2:0] dataCounter;
    reg [databits-1:0] shiftreg;

    //state change similar to UART Transmitter
    always@(*) begin
        nextState = state;
        case(state)
            IDLE : if(!rxIn) nextState = START;

            START: begin 
                if(tick && tickCounter == MID && rxIn) nextState = IDLE;
                else if(tick && tickCounter == LAST) nextState = DATA;
            end

            DATA: begin
                if(tick && tickCounter == LAST && dataCounter == databits - 1) nextState = STOP;
            end

            STOP: if(tick && tickCounter == LAST) nextState = IDLE;

            default: nextState = IDLE; // safety
        endcase
    end

    // What each state will actually do 
    always@(posedge clk or negedge rst_n) begin 
        if(!rst_n) begin 
            state <= IDLE;
            tickCounter <= 0;
            dataCounter <= 0;
            shiftreg <= 0;
            dataOut <= 0;
            dataReady <= 1'b0;
            framingError <= 1'b0;
        end else begin 
            state <= nextState;
            dataReady <= 1'b0; //default low; pulses high for a cycle

            case(nextState)
                IDLE:tickCounter <= 0;
            
                START: begin 
                    if(state == IDLE) begin
                        tickCounter <= 0;
                        dataCounter <= 0;
                    end else if (tick) begin
                        if(tickCounter == LAST) tickCounter <= 0;
                        else tickCounter <= tickCounter+1;
                    end
                end

                DATA: begin 
                    if (state == START) begin 
                        tickCounter <= 0;
                        dataCounter <= 0;
                    end else if (tick)begin
                        if(tickCounter == MID) begin 
                            shiftreg <= {rxIn,shiftreg[databits-1:1]}; // sample at the middle of the bit cycle
                            tickCounter <= tickCounter + 1;
                        end else if (tickCounter == LAST) begin 
                            tickCounter <= 0;
                            dataCounter <= dataCounter +1;
                        end else begin
                            tickCounter <= tickCounter +1;
                        end   
                    end
                end

                STOP:begin 
                    if(state == DATA) begin 
                        tickCounter <= 0;
                    end else if(tick) begin 
                        if (tickCounter == MID) begin
                            framingError <= ~rxIn; // stop bit has to be high flag otherwise
                            dataOut <= shiftreg; // shift reg holds the 8 recieved bits
                            dataReady <= 1'b1;
                        end
                        if(tickCounter == LAST) tickCounter <= 0;
                        else tickCounter <= tickCounter + 1;
                    end
                end
            endcase
        end
    end
endmodule
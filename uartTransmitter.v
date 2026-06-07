module uartTransmitter(
    input wire clk,
    input wire tick,
    input wire rst_n,
    input wire startTrigger,
    input wire [7:0] dataBits,
    output reg txOut,
    output reg busy
);
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    reg[1:0] state, nextState;
    reg[3:0] tickCounter;
    reg[2:0] dataCounter;
    reg[7:0] shiftReg; 

  
    always @(*)begin 
        nextState = state;
        case(state)
            IDLE: if(startTrigger)begin 
                nextState = START;
            end
            START: if(tick && tickCounter == 15) begin 
                nextState = DATA;
            end
            DATA: if(tick && tickCounter == 15 && dataCounter == 7) begin 
                nextState = STOP;
            end
            STOP: if(tick && tickCounter == 15)begin 
                nextState = IDLE;
            end
            default: nextState = IDLE; 
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            state <= IDLE;
            tickCounter <= 0;
            dataCounter <= 0;
            shiftReg <= 0;
            txOut <= 1'b1; // IDLE HIGH
            busy <= 1'b0; // Not Busy
        end else begin
            state <= nextState;
            case(nextState)
                IDLE: begin 
                    txOut <= 1'b1;
                    busy <= 1'b0;
                    if(startTrigger) begin 
                        shiftReg <= dataBits;
                        busy <= 1'b1;
                        tickCounter <= 0;
                    end
                end

                START:begin 
                    txOut <= 1'b0;
                    if (tick) begin 
                        if(tickCounter == 15) begin 
                            tickCounter <= 0;
                            dataCounter <= 0;
                        end else begin
                            tickCounter <= tickCounter +1;
                        end
                    end
                end

                DATA:begin 
                    txOut <= shiftReg[0]; // put LSB onto the line
                    if(tick) begin 
                        if(tickCounter == 15) begin 
                            tickCounter <= 0;
                            shiftReg <= shiftReg >> 1;
                            dataCounter <= dataCounter +1;
                        end else begin 
                            tickCounter <= tickCounter + 1;
                        end
                    end
                end

                STOP:begin 
                    txOut <= 1'b1;
                    if(tick) begin 
                        if(tickCounter == 15) begin 
                            tickCounter <= 0;
                            busy <= 1'b0;
                        end else begin 
                            tickCounter <= tickCounter +1;
                        end
                    end
                    
                end
            endcase
        end
    end

endmodule
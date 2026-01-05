`timescale 1ns / 1ps



module uart_tx(

    input logic clk,
    input logic reset,
    input logic tx_start,
    input logic[7:0] data_in,
    output logic tx_out,
    output logic tx_busy

    );
    
    localparam clk_freq = 32'd12_000_000;
    localparam baudrate = 32'd9600;
    localparam baud_cycles = clk_freq / baudrate;
    logic[31:0] baud_counter;
    logic baud_tick;
    
    typedef enum logic[1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } tx_states;
    
    tx_states state, next_state;
        
    logic[7:0] buffer;
    logic data_done;
    logic[3:0] data_counter;
    
    // baud tick generator
    always_ff @(posedge clk) begin
        if(reset | (state == IDLE) | (baud_counter == baud_cycles - 1)) 
            baud_counter <= 0;
        else
            baud_counter <= baud_counter + 1;
    end
    assign baud_tick = (baud_counter == baud_cycles - 1);    
    
    // state machine conditions
    always_comb begin
        case (state)
            IDLE: next_state = tx_start ? START : IDLE;
            START: next_state = baud_tick ? DATA : START;
            DATA: next_state = data_done ? STOP : DATA;
            STOP: next_state = baud_tick ? IDLE : STOP;
            default: next_state = IDLE;
        endcase
    end
    
    // buffer data input
    always_ff @(posedge clk) begin
        if(reset)
            buffer <= 0;
        else if((state == IDLE) && (next_state == START))
            buffer <= data_in;
    end
    
    // Main SFM register
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            data_counter <= 0;
        end
        else begin
            if (state == DATA) begin // data bit counter
                if (baud_tick) begin
                    if (data_counter == 4'd7) 
                        data_counter <= 0;
                    else 
                    data_counter <= data_counter + 1;
                end
            end
            state <= next_state;    
        end
    end
    assign data_done = ((data_counter == 4'd7) && baud_tick);
    
    // outputs
    always_comb begin
        case(state) 
            IDLE: begin 
                tx_out = 1;
                tx_busy = 0;
                end
            START: begin
                tx_out = 0;
                tx_busy = 1;
                end
            DATA: begin
                tx_out = buffer[data_counter];
                tx_busy = 1;
                end
            STOP: begin
                tx_out = 1;
                tx_busy = 1;
                end
             default: begin
                tx_out = 1;
                tx_busy = 0;
                end
        endcase
    end
    
    
endmodule

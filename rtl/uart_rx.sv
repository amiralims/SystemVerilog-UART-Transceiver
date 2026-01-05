`timescale 1ns / 1ps


module uart_rx(
    
    input logic clk,
    input logic reset,
    input logic rx_in,
    output logic[7:0] data_received,
    output logic data_ready,
    output logic framing_error
    );
    // clock and internal timer registers/wires
    localparam clk_freq = 32'd12_000_000;
    localparam baudrate = 32'd9600;
    localparam cycles_per_tick = clk_freq / (baudrate * 16); //Internal timer fs = 16*baudrate
    logic[15:0] timer_counter;
    logic timer_tick;
    logic[7:0] tick_counter;
    logic bit_done; // 16 timer tick done
    // 2ff synchronizer registers
    logic rx_in_metas; // ff1 output (metastabled) 
    logic rx_in_sync; // ff2 output (synchronized)
    //states
    typedef enum logic[1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } rx_states;
    
    rx_states state, next_state;
    // data registers and flags
    logic[7:0] buffer;
    logic data_done;
    logic[3:0] data_counter;
    logic start_check; // for checking if start bit is correct (0)
    logic stop_check; // for checkin if stop bit is correct (1)
    
    // timer tick generator
    always_ff @(posedge clk) begin
        if(reset | (state == IDLE) | (timer_counter == cycles_per_tick - 1)) 
            timer_counter <= 0;
        else
            timer_counter <= timer_counter + 1;
    end
    assign timer_tick = (timer_counter == cycles_per_tick - 1); 
    
    // 2 flip-flop synchronizer 
    always_ff @(posedge clk) begin
        if(reset) begin
            rx_in_metas <= 0;
            rx_in_sync <= 0;
        end
        else begin
            rx_in_metas <= rx_in;
            rx_in_sync <= rx_in_metas;
        end
    end
    
    // state machine conditions
    always_comb begin
        case (state)
            IDLE: next_state = rx_in_sync ? IDLE : START;
            START: next_state = bit_done ? (start_check ? DATA : IDLE) : START;
            DATA: next_state = data_done ? STOP : DATA;
            STOP: next_state = bit_done ? IDLE : STOP;
            default: next_state = IDLE;
        endcase
    end   
    
    // counters and data reading
    always_ff @(posedge clk) begin
        if(reset) begin
            state <= IDLE;
            tick_counter <= 0;
            data_counter <= 0;
            buffer <= 0;
            start_check <= 0;
            stop_check <= 0;
            data_received <= 0;
        end
        else begin
            state <= next_state;
            if ((state == STOP) && (next_state == IDLE))
                data_received <= buffer;
            if(timer_tick) begin 
                if(tick_counter == 8'd15) begin //end of the bit
                    tick_counter <= 0;
                    if(state == DATA) begin
                        if(data_counter == 3'd7)
                            data_counter <= 0;
                        else
                            data_counter <= data_counter + 1;
                        stop_check <= 0;
                        start_check <= 0;
                    end
                end
                else if(tick_counter == 8'd7) begin  //reading data at the middle of the bit
                    tick_counter <= tick_counter + 1;
                    if(state == START)
                        start_check <= ~rx_in_sync;
                    else if(state == STOP)
                        stop_check <= rx_in_sync;
                    else if(state == DATA)
                        buffer[data_counter] <= rx_in_sync;
                end
                else
                    tick_counter <= tick_counter + 1;
                
            end
        end
    end
    
    // assigning flags
    assign bit_done = (tick_counter == 8'd15) && timer_tick;
    assign data_done = (data_counter == 3'd7) && bit_done;
    
    // outputs
    assign data_ready = (state == STOP) && (next_state == IDLE) && stop_check;
    assign framing_error = (state == STOP) && (next_state == IDLE) && ~stop_check;
    
endmodule

`timescale 1ns / 1ps


module uart_echo(

    input logic clk,
    input logic reset,
    input logic uart_rx_in,
    output logic uart_tx_out,
    
    //debuggin pins
    output logic debug_rx,
    output logic debug_tx,
    output logic debug_data_ready

    );
    
    logic[7:0] data_from_rx;
    logic[7:0] data_to_tx;
    
    logic data_ready; // flag for receiving data
    logic start_transmit; // pulse for sending data
    logic echo_start; // flag to start the echo process
    logic framing_error;
    logic tx_busy;
    
    uart_rx receiver(
        .clk            (clk),
        .reset          (reset),
        .rx_in          (uart_rx_in),
        .data_received  (data_from_rx),
        .data_ready     (data_ready),
        .framing_error  (framing_error)
        );
    
    uart_tx transmitter(
        .clk            (clk),
        .reset          (reset),
        .tx_start       (start_transmit),
        .data_in        (data_to_tx),
        .tx_out         (uart_tx_out),
        .tx_busy        (tx_busy)
        );
     
     always_ff @(posedge clk) begin
        if(reset) begin
            start_transmit <= 0;
            data_to_tx <= 8'b0;
        end
        else begin
            if(data_ready)
                echo_start <= 1'b1;
            else
                echo_start <= 1'b0;
            
            if(echo_start) begin
                start_transmit <= 1'b1;
                data_to_tx <= data_from_rx;
            end
            else 
                start_transmit <= 1'b0;
        end
     end
     
     // debugging pins (to be used with logic analyzer) 
     assign debug_rx = uart_rx_in;
     assign debug_tx = uart_tx_out;
     assign debug_data_ready = data_ready;

   
    
endmodule

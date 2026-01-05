`timescale 1ns / 1ps


module tb_uart_rx;

    logic clk;
    logic reset;
    logic rx_in;
    logic[7:0] data_received;
    logic data_ready;
    logic framing_error;
    integer errors;
    
    localparam clk_freq = 32'd12_000_000;
    localparam baudrate = 32'd9600;
    localparam baud_cycles = clk_freq / baudrate;

    uart_rx dut(.*);
    
    // clock
    localparam CLK_PERIOD = 84; // 12MHz 
    always #((CLK_PERIOD)/2) clk = ~clk;
    
    // transmitter sim
    task send_uart_byte (logic[7:0] data_sent, logic correct_framing=1'b1);
        // need for re-asserting rx_in after a delay (50 cycles)
        // becasuse of a strange glitch in simulation that drove back the rx_in to 1
        // after 20 clk cycles only in second sent charachter
        rx_in = 1'b0;
        repeat(50) @(posedge clk);
        rx_in = 1'b0;
        repeat(baud_cycles - 50) @(posedge clk);
        for(int i=0; i<8; i++) begin
            rx_in = data_sent[i];
            repeat(baud_cycles) @(posedge clk);
        end
        if(correct_framing)
            rx_in = 1'b1;
        else
            rx_in = 1'b0;
        repeat(baud_cycles) @(posedge clk);
        rx_in = 1'b1;
    endtask
    
    
    initial begin
    
        $display("[%d] UART RX Verification....", $time);
        clk = 1'b0;
        reset = 1'b1;
        rx_in = 1'b1;
        errors = 0;
        
        $display("\n[%d] Asserting Reset....", $time);
        repeat(5) @(posedge clk);
        reset = 1'b0;
        $display("\n[%d] Wait for module to be ready.....", $time);
        wait (dut.data_ready == 1'b0);
        
        $display("\n[%d] Start sending charachter C.....", $time);
        repeat(30) @(posedge clk);
        fork
            send_uart_byte(8'h43, 1);
        join_none;
        wait(dut.data_ready == 1'b1);
        @(posedge clk);
        #1;
        $display("\n[%d] Recieved byte is %c.....", $time, dut.data_received);
        if(dut.data_received !== 8'h43)
            errors = errors + 1;
        
        $display("\n[%d] Start sending charachter p.....", $time);
        repeat(30) @(posedge clk);
        fork
            send_uart_byte(8'h70, 1);
        join_none;
        wait(dut.data_ready == 1'b1);
        @(posedge clk);
        #1;
        $display("\n[%d] Recieved byte is %c.....", $time, dut.data_received);
        if(dut.data_received !== 8'h70)
            errors = errors + 1;
            
        $display("\n[%d] Start sending charachter 9 (with framing error).....", $time);
        repeat(30) @(posedge clk);
        fork
            send_uart_byte(8'h39, 0);
        join_none;
        wait(dut.framing_error == 1'b1);
        @(posedge clk);
        #1;
        $display("\n[%d] Recieved byte is %c.....", $time, dut.data_received);
        if(dut.data_received !== 8'h39)
            errors = errors + 1;
            
        if(errors == 0)
            $display("\n[%d] Simulation finished successfully....", $time);
        else
            $display("\n[%d] Simulation failed with %d errors....", $time, errors);
            
        $finish;
    
    end
    
endmodule

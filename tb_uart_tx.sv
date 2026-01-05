`timescale 1ns / 1ps


module tb_uart_tx;
    
    logic clk;
    logic reset;
    logic tx_start;
    logic[7:0] data_in;
    logic tx_out;
    logic tx_busy;
    logic expected_tx_out;
    logic[31:0] error_counter;
    localparam baud_cycles = 32'd12_000_000 / 32'd9600;
    
    uart_tx dut (.*);
    
    localparam CLK_PERIOD = 84; // 12MHz 
    always #((CLK_PERIOD)/2) clk = ~clk;
    
    
    //Generating expected signal
     task generate_signal(logic[7:0] data);
        expected_tx_out = 1'b0;
        repeat(baud_cycles) @(posedge clk);
        for(int i=0; i<8; i++) begin
            expected_tx_out = data[i];
            repeat(baud_cycles) @(posedge clk);
        end
        expected_tx_out = 1'b1;
        repeat(baud_cycles) @(posedge clk);
     endtask
    
    initial begin
    
        $display("UART TX Verification......");
        clk = 1'b0;
        tx_start = 1'b0;
        reset = 1'b1;
        expected_tx_out = 1'b1;
        $display("\nAsserting Reset.....");
        repeat(5) @(posedge clk);
        reset = 1'b0;
        $display("\nWait for module to be ready.....");
        wait (dut.tx_busy == 0);
        
        $display("\nSet data_in to be 'A'.....");
        data_in = 8'h41;
        $display("\nAssert tx_start....");
        tx_start = 1'b1;
        @(posedge clk);
        #1;
        tx_start = 1'b0;
        fork
            generate_signal(data_in);
        join_none
        $display("\nWait for transmition to be finished....");
        wait (dut.tx_busy == 0);
        
        $display("\nSet data_in to be 'b'.....");
        data_in = 8'h62;
        $display("\nAssert tx_start....");
        tx_start = 1'b1;
        @(posedge clk);
        #1;
        tx_start = 1'b0;
        fork
            generate_signal(data_in);
        join_none
        $display("\nWait for transmition to be finished....");
        wait (dut.tx_busy == 0);
        
        $display("\nSet data_in to be '4'.....");
        data_in = 8'h34;
        $display("\nAssert tx_start....");
        tx_start = 1'b1;
        @(posedge clk);
        #1;
        tx_start = 1'b0;
        fork
            generate_signal(data_in);
        join_none
        $display("\nWait for transmition to be finished....");
        wait (dut.tx_busy == 0);
        $display("\nAll charachters were sent....");
        if(error_counter == 0)
            $display("\nSimulation passed successfully....");
        else
            $display("\nSimulation failed with %b errors....", error_counter);
        $finish;
        
     end
     
     always_ff @(negedge clk) begin
        if(reset)
            error_counter <= 0;
        else if(dut.tx_out !== expected_tx_out) begin
            $error("Mismatch! DUT output is %b, expected %b", dut.tx_out, expected_tx_out);
            error_counter <= error_counter + 1;
        end
     end 
    
endmodule

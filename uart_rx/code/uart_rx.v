// EcoMender Bot : Task 2A - UART Receiver
/*
Instructions
-------------------
Students are not allowed to make any changes in the Module declaration.

This file is used to receive UART Rx data packet from receiver line and then update the rx_msg and rx_complete data lines.

Recommended Quartus Version : 20.1
The submitted project file must be 20.1 compatible as the evaluation will be done on Quartus Prime Lite 20.1.

Warning: The error due to compatibility will not be entertained.
-------------------
*/

/*
Module UART Receiver

Baudrate: 230400 

Input:  clk_3125 - 3125 KHz clock
        rx      - UART Receiver

Output: rx_msg - received input message of 8-bit width
        rx_parity - received parity bit
        rx_complete - successful uart packet processed signal
*/

// module declaration
module uart_rx(
    input clk_3125,
    input rx,
    output reg [7:0] rx_msg,
    output reg rx_parity,
    output reg rx_complete
    );

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE//////////////////

// States
localparam IDLE       = 3'd0;
localparam START_BIT  = 3'd1;
localparam DATA_BITS  = 3'd2;
localparam PARITY_BIT = 3'd3;
localparam STOP_BIT   = 3'd4;

reg [2:0] state = IDLE;
reg [3:0] bit_index = 0;
reg [12:0] clk_counter = -1;
reg [7:0] data_buffer = 0;
reg parity_bit_received = 0;
reg rx_parity_1=0;

// Double buffer for rx signal
reg rx_buffer_1 = 1;
reg rx_buffer_2 = 1;

// Sampling Interval for 230400 baud rate at 3.125 MHz
localparam BIT_PERIOD = 13;

initial begin
    rx_msg = 0;
	  rx_parity = 0;
    rx_complete = 0;
end

// Double buffer the rx signal to remove metastability issues
always @(posedge clk_3125) begin
    rx_buffer_1 <= rx;       // First flip-flop
    rx_buffer_2 <= rx_buffer_1; // Second flip-flop
end

always @(posedge clk_3125) begin
    case (state)
        IDLE: begin
            if (rx == 0) begin // Start bit detected (falling edge)
                state <= START_BIT;
                
                rx_complete <= 0;
            end
        end

        START_BIT: begin
            if (clk_counter == (BIT_PERIOD / 2)) begin // Middle of start bit
                if (rx_buffer_2 == 0) begin
                    state <= DATA_BITS;
                    clk_counter <= 0;
                    bit_index <= 0;
                end else begin
                    state <= IDLE; // False start, return to idle
                end
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end

        DATA_BITS: begin
            if (clk_counter == BIT_PERIOD) begin
                data_buffer[7 - bit_index] <= rx_buffer_2; // Store in reverse order
                clk_counter <= 0;
                bit_index <= bit_index + 1;

                if (bit_index == 7) begin
                    state <= PARITY_BIT;
                end
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end

        PARITY_BIT: begin
            if (clk_counter == BIT_PERIOD ) begin
                rx_parity_1 <= rx_buffer_2; // Store received parity bit
                parity_bit_received <= rx_buffer_2;
                clk_counter <= 0;
                state <= STOP_BIT;
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end

        STOP_BIT: begin
            if (clk_counter == BIT_PERIOD + BIT_PERIOD / 2 ) begin // Half-bit delay
                if (rx == 1) begin // Stop bit should be high
                    // Check parity
						  rx_parity <= rx_parity_1;
                    if (^data_buffer == parity_bit_received) begin
                        rx_msg <= data_buffer; // No parity error
                    end else begin
                        rx_msg <= 8'h3F; // Parity error, output '?'
                    end
                    rx_complete <= 1;
                end
					 clk_counter <= 0;
                state <= IDLE; // Go back to idle
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end

    endcase
end

// Add your code here....

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE//////////////////


endmodule
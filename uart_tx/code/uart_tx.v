// EcoMender Bot : Task 2A - UART Transmitter
/*
Instructions
-------------------
Students are not allowed to make any changes in the Module declaration.

This file is used to generate UART Tx data packet to transmit the messages based on the input data.

Recommended Quartus Version : 20.1
The submitted project file must be 20.1 compatible as the evaluation will be done on Quartus Prime Lite 20.1.

Warning: The error due to compatibility will not be entertained.
-------------------
*/

/*
Module UART Transmitter

Input:  clk_3125 - 3125 KHz clock
        parity_type - even(0)/odd(1) parity type
        tx_start - signal to start the communication.
        data    - 8-bit data line to transmit

Output: tx      - UART Transmission Line
        tx_done - message transmitted flag
*/

// module declaration
module uart_tx(
    input clk_3125,
    input parity_type,tx_start,
    input [7:0] data,
    output reg tx, tx_done
);

///////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE//////////////////

// State encoding
localparam IDLE = 0, START_BIT = 1, DATA_BITS = 2, PARITY_BIT = 3, STOP_BIT = 4, DONE = 5;

// State variables
reg [2:0] state = IDLE;
reg [3:0] bit_index;  // Track the bit position
reg [3:0] clk_count;  // Counter for bit timing
reg parity_bit;

// Initial block for RTL simulation
initial begin
    tx = 1;
    tx_done = 0;
    state = IDLE;
    clk_count = 0;
    bit_index = 0;
end

// Calculate parity
always @(*) begin
    if (parity_type == 1)  // Odd parity
        parity_bit = ~(^data);
    else                   // Even parity
        parity_bit = ^data;
end

// Main state machine
always @(posedge clk_3125) begin
    case (state)
        IDLE: begin
            tx <= 1;           // Idle state, tx remains high
            tx_done <= 0;
            clk_count <= 0;
            bit_index <= 0;
            if (tx_start) begin
                state <= START_BIT;  // Move to START_BIT when tx_start is asserted
					 tx <= 0;           // Transmit start bit (0)
            end
        end
        
        START_BIT: begin
            
            if (clk_count < 12) clk_count <= clk_count + 1; // 14 cycles for bit duration
            else begin
                clk_count <= 0;
                state <= DATA_BITS;  // Move to DATA_BITS after duration
            end
        end

        DATA_BITS: begin
				tx <= data[7 - bit_index];  // Transmit each bit from MSB to LSB
				 if (clk_count < 13) 
					  clk_count <= clk_count + 1;
				 else begin
					  clk_count <= 0;
					  if (bit_index < 7) 
							bit_index <= bit_index + 1;  // Move to the next bit (decrement bit position)
					  else begin
							bit_index <= 0;
							state <= PARITY_BIT;  // All data bits sent, move to PARITY_BIT
					  end
				 end
			end

        PARITY_BIT: begin
            tx <= parity_bit;  // Transmit the parity bit
            if (clk_count < 13) clk_count <= clk_count + 1;
            else begin
                clk_count <= 0;
                state <= STOP_BIT;  // Move to STOP_BIT after duration
            end
        end

        STOP_BIT: begin
            tx <= 1;           // Transmit stop bit (1)
            if (clk_count < 13) clk_count <= clk_count + 1;
            else begin
                clk_count <= 0;
                
					 tx_done <= 1;      // Signal transmission complete
					 state <= IDLE;     // Return to IDLE state
            end
        end
    endcase
end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE//////////////////
endmodule
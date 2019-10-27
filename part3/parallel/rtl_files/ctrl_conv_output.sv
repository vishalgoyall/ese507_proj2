//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ESE 507 : Project 2 (Convolution)
// Authors : Prateek Jain and Vishal Goyal
// Purpose :
// Control Module to 
// 1. generate signal to provide select line for MUX on X_mem output for conv
// 2. generate signals to control MAC operations
// 3. generate valid signal for AXI interface
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

module ctrl_conv_output #(parameter F_MEM_SIZE = 4, parameter X_MEM_SIZE = 8, parameter X_MEM_ADDR_WIDTH = 3, parameter F_MEM_ADDR_WIDTH = 2) (
        input                                 clk,            
        input                                 reset,           
        input                                 conv_start,     
        input                                 m_ready_y,       
        output logic                          conv_done,       
	output logic [X_MEM_ADDR_WIDTH-1:0]   load_xaddr_val,
        output logic                          m_valid_y       
);

logic	next_conv;
logic	conv_start_pulse, conv_start_reg;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Generating pulse on the rise edge of conv start to kick-start the conv

always @ (posedge clk) begin
	if (reset == 1)
		conv_start_reg <= 0;
	else
		conv_start_reg <= conv_start;
end
assign conv_start_pulse = conv_start && !conv_start_reg;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Logic to assert next_conv request; asserted once previous calculation has
// been accepted

always_comb begin
	next_conv = 0;
	if (conv_start) begin
		if (m_valid_y == 1 && m_ready_y == 1) begin
			next_conv = 1;
		end else if (m_valid_y == 1 && m_ready_y == 0) begin
			next_conv = 0;
		end
	end
end

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Logic to assert valid_y and incrementing the start address of x

always @ (posedge clk) begin
	if (reset == 1) begin
		load_xaddr_val	<= 'b0;
		m_valid_y	<= 'b0;
	end else begin
		if (conv_done == 1) begin
			load_xaddr_val <= 'b0;
			m_valid_y <= 0;
		end else if (next_conv == 1 || conv_start_pulse == 1) begin
			load_xaddr_val <= load_xaddr_val + 1;
			m_valid_y <= 1;
		end
	end
end

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Setting convolution done flag once last entry has been processed and system
// is ready to accept the last entry

assign conv_done = (load_xaddr_val == X_MEM_SIZE-F_MEM_SIZE+1) && next_conv;


endmodule

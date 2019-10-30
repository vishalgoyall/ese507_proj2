module control_unit #(
	parameter F_MEM_SIZE = 4, parameter X_MEM_SIZE = 8, parameter X_MEM_ADDR_WIDTH = 3, parameter F_MEM_ADDR_WIDTH = 2
) (
        input                             clk,            
        input                             reset,           
        input                             conv_start,     
        input                             m_ready_y,       
	input                             s_valid_x,

	output logic			  mem_wr_en,
        output logic                      conv_done,       
        output logic                      m_valid_y,
	output logic                      s_ready_x,
	output logic [X_MEM_ADDR_WIDTH:0]   x_count
);

logic			      next_conv;
logic				conv_start_pulse, conv_start_reg;
logic [X_MEM_ADDR_WIDTH-1:0]	load_xaddr_val;

localparam S0 = 1'd0;
localparam S1 = 1'd1;

logic  next_state, curr_state;
logic  mem_wr_en_int;

assign mem_wr_en_int = s_valid_x & s_ready_x; //wr_en is combo logic of ready and valid

always_comb begin
	next_state = conv_start ? S1 : S0;
	mem_wr_en = mem_wr_en_int;
	/*if (curr_state == S0) begin
		mem_wr_en = mem_wr_en_int;
		s_ready_x = 1;
	end else begin
		mem_wr_en = mem_wr_en_int & m_ready_y;
		if (next_conv == 0)
			s_ready_x = 0;
		else
			s_ready_x = 1;
	end*/
end

always @ (posedge clk) begin
	if (reset == 1) begin
		s_ready_x <= 'b0;
	end else begin
		if (curr_state == S0)
			s_ready_x <= 'b1;
		else
			s_ready_x <= m_valid_y & m_ready_y;
	end
end

always @ (posedge clk)
begin
	if (reset == 1)
		curr_state <= S0;
	else
		curr_state <= next_state;
end

//Block to generate s_ready_x signal and mem_addr 
always_ff @(posedge clk) begin
	if (reset == 1'b1 || conv_done == 1) begin  //with reset, restart the memory writing from address 0
		x_count <= 0;
	end
	else begin
		if (curr_state == S0) begin
			if (mem_wr_en == 1'b1)  //else if wr_en is asserted, keep on incrementing the count of writes done
				x_count <= x_count + 1;
		end
	end
end

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
		end else if (m_valid_y==1 && m_ready_y == 0) begin
			next_conv = 0;
		end
	end
end

logic mem_wr_en_reg;
logic mem_wr_en_reg_reg;
always @ (posedge clk) begin
	if (reset == 1) begin
		mem_wr_en_reg <= 0;
		mem_wr_en_reg_reg <= 0;
	end else begin
		mem_wr_en_reg <= mem_wr_en;
		mem_wr_en_reg_reg <= mem_wr_en_reg;
	end
end
//
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
		end else begin
			if (curr_state == S1) begin
				if (m_valid_y == 1) begin
					if (m_ready_y == 1) begin
						m_valid_y <= mem_wr_en;
						load_xaddr_val <= load_xaddr_val + 1;
					end
				end else if (conv_start_pulse == 1) begin
					m_valid_y <= 1;
				//end else if (mem_wr_en == 1) begin
				//	m_valid_y <= 1;
				//	if (m_ready_y == 1)
				//		load_xaddr_val <= load_xaddr_val + 1;
				//end else if (mem_wr_en == 0) begin
				//	m_valid_y <= 0;
				end else if (s_valid_x == 1) begin
					m_valid_y <= s_valid_x;
				end
			end
		end
	end
end

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Setting convolution done flag once last entry has been processed and system
// is ready to accept the last entry

assign conv_done = (load_xaddr_val == X_MEM_SIZE-F_MEM_SIZE) && next_conv;


endmodule

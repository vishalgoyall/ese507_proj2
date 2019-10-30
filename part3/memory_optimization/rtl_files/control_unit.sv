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
	output logic [X_MEM_ADDR_WIDTH:0] x_count,
	output logic			  y_accepted
);

logic			      next_conv;
logic				conv_start_pulse, conv_start_reg;
logic [X_MEM_ADDR_WIDTH-1:0]	load_xaddr_val;

logic  next_state, curr_state;
logic  mem_wr_en_int;
logic y_out_en_reg;

typedef enum {FILL_X, S0, S1, S2, DONE} fsm;
fsm state;

logic dummy;
//assign dummy = (state == S0) ? m_ready_y : 1;
assign mem_wr_en   = s_valid_x & s_ready_x; //wr_en is combo logic of ready and valid
assign y_accepted  = (m_valid_y & m_ready_y) | (conv_start_pulse);
assign conv_done   = (x_count == X_MEM_SIZE-1);

logic conv_done_reg, conv_done_reg_reg;

always @ (posedge clk) begin
	if (reset == 1) begin
		conv_done_reg <=  0;
		conv_done_reg_reg <=  0;
	end else begin
		conv_done_reg <= conv_done;
		conv_done_reg_reg <= conv_done_reg;
	end
end

always_ff @ (posedge clk) begin
	if (reset == 1) begin
		state <= FILL_X;
		m_valid_y <= 'b0;
		s_ready_x <= 'b0;
		x_count <= 'b0;
	end else begin
		case (state)
			FILL_X: begin
				s_ready_x <= 'b1;
				if (mem_wr_en == 1)
					x_count   <= x_count + 1;
				if (conv_start_pulse == 1) begin
					m_valid_y <= 1;
					//s_ready_x <= 1;
					state <= S0;
				end
			end

			S0: begin	// state where last data has been accepted by slave, and new data is available at x
				m_valid_y <= 1;
				if (conv_done_reg_reg == 1) begin
					state     <= DONE;
				end else if (mem_wr_en == 1 && y_accepted == 1) begin // data accepted at slave, and new writes
					m_valid_y <= 1;
					s_ready_x <= 1;
					x_count   <= x_count + 1;
					state     <= S0;
				end else if (mem_wr_en == 0 && y_accepted == 1) begin // data has been accepted as slave, but no new writes
					m_valid_y <= 0;
					state     <= S1;
				end else if (mem_wr_en == 1 && y_accepted == 0) begin // new writes, but data not accepted
					s_ready_x <= 0;
					state     <= S2;
				end
			end

			S1: begin // state where last data has been accepted, but no new write is avaialble; asserting valid ones write is available
				if (mem_wr_en == 1) begin
					m_valid_y <= 1;
					x_count   <= x_count + 1;
					state     <= S0;
				end
			end

			S2: begin
				if (y_accepted == 1) begin
					s_ready_x <= 1;
					x_count   <= x_count + 1;
					state     <= S0;
				end
			end

			DONE: begin
				m_valid_y <= 0;
				s_ready_x <= 1;
				x_count   <= 0;
				state     <= FILL_X;
			end
		endcase
	end
end

//Block to generate s_ready_x signal and mem_addr 
/*
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
*/

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

/*
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
*/
//

/*
logic next_valid, next_valid_reg;
always_comb begin
	next_valid = 0;
	if (m_valid_y == 1 && mem_wr_en == 1) begin
		next_valid = 1;
	end
end
logic conv_start_pulse_reg;
always @ (posedge clk) begin
	if (reset == 1) begin
		next_valid_reg <= 0;
		conv_start_pulse_reg <= 0;
	end else begin
		next_valid_reg <= next_valid;
		conv_start_pulse_reg <= conv_start_pulse;
	end
end
*/

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Logic to assert valid_y and incrementing the start address of x
/*
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
					if (y_accepted == 1) begin
						load_xaddr_val <= load_xaddr_val + 1;
						if (mem_wr_en == 0)
							m_valid_y <= 0;
					end
				end else if (conv_start_pulse_reg == 1) begin
					load_xaddr_val <= load_xaddr_val + 1;
					m_valid_y <= 1;
				end else if (mem_wr_en == 1) begin
					m_valid_y <= 1;
				end

				//if (m_valid_y == 1) begin
				//	if (m_ready_y == 1) begin
				//		m_valid_y <= next_valid;
				//		load_xaddr_val <= load_xaddr_val + 1;
				//	end
				//end else if (conv_start_pulse == 1) begin
				//	m_valid_y <= 1;
				//end else if (mem_wr_en == 1) begin
				//	m_valid_y <= 1;
				//	if (m_ready_y == 1)
				//		load_xaddr_val <= load_xaddr_val + 1;
				//end else if (mem_wr_en == 0) begin
				//	m_valid_y <= 0;
				//end else if (s_valid_x == 1) begin
				//	m_valid_y <= s_valid_x;
				end
			end
		end
	end
end
*/

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Setting convolution done flag once last entry has been processed and system
// is ready to accept the last entry

endmodule

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ESE 507 : Project 1 
// Authors : Prateek Jain and Vishal Goyal
// Purpose : 
// 1. Generate control signals to load memory with input data from Master
// 2. Follow AXI protocol and generate READY signal
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
module ctrl_x_mem_write #(parameter MEM_ADDR_WIDTH = 3, parameter MEM_SIZE = 8) (
        input                             clk,  
        input                             reset,
        input                             s_valid,
	input                             en_ext_ctrl,
	input				  next_write,
	input				  ready_y,
        output logic                      s_ready,
        output logic                      mem_wr_en,
	output logic [MEM_ADDR_WIDTH:0]   x_count
);

localparam S0 = 1'd0;
localparam S1 = 1'd1;

logic  next_state, curr_state;
logic  mem_wr_en_int;

assign mem_wr_en_int = s_valid & s_ready; //wr_en is combo logic of ready and valid

always_comb begin
	next_state = curr_state;
	s_ready = 1;
	next_state = en_ext_ctrl ? S1 : S0;
	if (curr_state == S0) begin
		mem_wr_en = mem_wr_en_int;
		s_ready = 1;
	end else begin
		mem_wr_en = mem_wr_en_int & ready_y;
		if (next_write == 0)
			s_ready = 0;
		else
			s_ready = 1;
	end

	/*case (curr_state)
		S0: begin
			s_ready = 1;
			if (x_count < F_MEM_SIZE)
				next_state <= S0;
			else
				next_state <= S1;
		end
		S1: begin
			if (next_write == 0)
				s_ready = 0;
			if (en_ext_ctrl == 1)
				next_state <= S1;
			else
				next_state <= S0;
		end
	endcase
	*/
end

always @ (posedge clk)
begin
	if (reset == 1)
		curr_state <= S0;
	else
		curr_state <= next_state;
end

//Block to generate s_ready signal and mem_addr 
always_ff @(posedge clk) begin
	if (reset == 1'b1) begin  //with reset, restart the memory writing from address 0
		x_count <= 0;
	end
	else begin
		if (curr_state == S0) begin
			if (mem_wr_en == 1'b1)  //else if wr_en is asserted, keep on incrementing the count of writes done
				x_count <= x_count + 1;
		end
	end
end

endmodule




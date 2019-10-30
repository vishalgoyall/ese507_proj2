//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ESE 507 : Project 2 (Convolution)
// Authors : Prateek Jain and Vishal Goyal
// Purpose :
// Control Module to 
// 1. generate signal to provide select line for MUX on X_mem output for conv
// 2. generate signals to control MAC operations
// 3. generate valid signal for AXI interface
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

module ctrl_conv_output 
#(
	parameter F_MEM_SIZE = 4, 
	parameter X_MEM_SIZE = 8, 
	parameter X_MEM_ADDR_WIDTH = 3,
        parameter PLINE_STAGES = 5,	
	parameter F_MEM_ADDR_WIDTH = 2
)(
        input                                 clk,            
        input                                 reset,           
        input                                 conv_start,     
        input                                 m_ready_y,       
        output logic                          conv_done,       
	output logic [X_MEM_ADDR_WIDTH-1:0]   load_xaddr_val,
	output logic                          en_pline_stages,
        output logic                          m_valid_y       
);

logic en_pline_fsm;
logic [$clog2(PLINE_STAGES)-1:0] init_cntr;

typedef enum {IDLE, FLUSH_IN, NEXT_COMPUTE, FLUSH_OUT} fsm;
fsm state;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// FSM to control pipelined convolution process after complete X and F memories are full
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

always_ff @(posedge clk) begin
	if (reset == 1'b1) begin
        	m_valid_y      <= 1'b0;
        	en_pline_fsm   <= 1'b1;
        	init_cntr      <= 0;
        	load_xaddr_val <= 0;
		conv_done      <= 1'b0;
        	state          <= IDLE;
	end
	else begin
		case (state) 
			IDLE : begin
				if (conv_start == 1'b1 && conv_done == 1'b0) begin  //once conv starts jump to next state
					m_valid_y      <= 1'b0;
					en_pline_fsm   <= 1'b1;
					init_cntr      <= 1;
					load_xaddr_val <= load_xaddr_val + 'b1;
					state          <= FLUSH_IN;
				end
				conv_done <= 1'b0;
			end

			FLUSH_IN: begin
				if (init_cntr != unsigned'(PLINE_STAGES-1)) begin  //allow pipeline to fill the very first time
					init_cntr <= init_cntr + 'b1;
				end 
				else begin
					m_valid_y    <= 1'b1;
					en_pline_fsm <= 1'b0;
					state        <= NEXT_COMPUTE;
				end
				load_xaddr_val <= load_xaddr_val + 'b1;
			end
			
			NEXT_COMPUTE: begin
				if (en_pline_stages == 1'b1 && load_xaddr_val != unsigned'(X_MEM_SIZE - F_MEM_SIZE))
					load_xaddr_val <= load_xaddr_val + 'b1;
				else if (en_pline_stages == 1'b1)
					state <= FLUSH_OUT;
			end


			FLUSH_OUT: begin
				if (en_pline_stages == 1'b1 && init_cntr != 0) begin  //need to wait before for pipeline to flush out
					init_cntr <= init_cntr - 'b1;
				end
				else if (en_pline_stages == 1'b1 && init_cntr == 0) begin  //all stages flushed out i.e. last elem is picked by master
					conv_done      <= 1'b1;
					init_cntr      <= 0;
					load_xaddr_val <= 0;
					state          <= IDLE;
					m_valid_y      <= 0;
					en_pline_fsm   <= 1;
				end
			end
		endcase
	end
end

assign en_pline_stages = en_pline_fsm || (m_valid_y && m_ready_y);

endmodule

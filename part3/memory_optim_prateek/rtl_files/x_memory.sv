//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ESE 507 : Project 2 (Convolution)
// Authors : Prateek Jain and Vishal Goyal
// Description: 
// COnverted to shift registers with serial write and parallel read paths
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

module x_memory(clk, data_in, data_out, wr_en);
   
    parameter                   	WIDTH=16, SIZE=64, LOGSIZE=6;
    input [WIDTH-1:0]           	data_in;
    output logic signed [WIDTH-1:0]	data_out[SIZE-1:0];
    input                       	clk, wr_en;
    
    // Signal to output all the memory registers
    logic signed [WIDTH-1:0] mem[SIZE-1:0];
    integer i;
    
    assign data_out = mem;
    always_ff @(posedge clk) begin
	if (wr_en) begin
        	mem[SIZE-1] <= data_in;
    		for (i=SIZE-1; i>0; i--) begin
			mem[i-1] <= mem[i];
    		end
	end
    end
endmodule

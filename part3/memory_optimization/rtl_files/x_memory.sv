//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ESE 507 : Project 1 (Convolution)
// Authors : Prateek Jain and Vishal Goyal
// Description: This is the memory module being used to store X and F vectors
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

module x_memory(clk, data_in, data_out, wr_en);
   
    parameter                   	WIDTH=16, SIZE=64, LOGSIZE=6;
    input [WIDTH-1:0]           	data_in;
    output logic signed [WIDTH-1:0]	data_out[SIZE:0];
    input                       	clk, wr_en;
    
    // Signal to output all the memory registers
    logic signed [WIDTH-1:0] mem[SIZE:0];
    integer i;
    
    assign data_out = mem;
    always_ff @(posedge clk) begin
	if (wr_en) begin
        	mem[SIZE] <= data_in;
    		for (i=SIZE; i>0; i--) begin
			mem[i-1] <= mem[i];
    		end
	end
    end
endmodule

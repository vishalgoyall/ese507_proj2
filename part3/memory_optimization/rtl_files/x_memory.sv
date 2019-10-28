//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ESE 507 : Project 1 (Convolution)
// Authors : Prateek Jain and Vishal Goyal
// Description: This is the memory module being used to store X and F vectors
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

module memory(clk, data_in, data_out, wr_en);
   
    parameter                   	WIDTH=16, SIZE=64, LOGSIZE=6;
    input [WIDTH-1:0]           	data_in;
    output logic signed [WIDTH-1:0]	data_out[SIZE-1:0];
    input                       	clk, wr_en;
    
    // Signal to output all the memory registers
    logic signed [WIDTH-1:0] mem[SIZE-1:0];
    integer i;
    
    always_ff @(posedge clk) begin
        data_out <= mem;
        if (wr_en)
        	mem[0] <= data_in;
    	for (i=0; i<SIZE-1; i++) begin
		mem[i+1] <= mem[i];
    	end
    end
endmodule

module ALU_tb;

'define WIDTH = 8;

	task driver_random(output reg[WIDTH -1:0] OPA,OPB);
		OPA = $urandom();
		OPB = $urandom();
	endtask
	
	task driver_specific(input [WIDTH-1:0] start,stop,output reg[WIDTH -1:0] OPA,OPB);
		OPA = $urandom_range(start,stop);
		OPB = $urandom_range(start,stop);
	endtask



endmodule

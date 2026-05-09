`define WIDTH = 8;
module ALU_tb;

initial
	CLK =1'b0;

always
	#5 CLK = ~CLK; // time period 10


// DRIVERS A and B
	task driver_random_AB;
	begin
		OPA = $urandom;
		OPB = $urandom;
	end
	endtask
	
	task driver_specific_AB(input [WIDTH-1:0] start,stop);
	begin
		OPA = $urandom_range(start,stop);
		OPB = $urandom_range(start,stop);
	end
	endtask

// DRIVERS RESET
	task driver_RST_high;
              	RST = 1'b1;
        endtask

        task driver_RST_low;
		RST = 1'b0;
        endtask
	
// DRIVER CE	
	 task driver_CE_high;
                CE = 1'b1;
        endtask

        task driver_CE_low;
                CE = 1'b0;
        endtask


// DRIVER CIN	
	 task driver_CIN_high;
                CIN = 1'b1;
        endtask

        task driver_CIN_low;
                CIN = 1'b0;
        endtask

// DRIVER INP_VALID
	task drive_INP_VALID(input [1:0] i);
		INP_VALID = i;
	endtask



endmodule

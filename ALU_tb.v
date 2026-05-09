module ALU_tb;

localparam WIDTH = 8;

reg CLK,RST,CE,CIN;
reg [1:0] INP_VALID;
reg [WIDTH-1:0] OPA,OPB;

wire [(2*WIDTH)-1:0]RES_ref;
wire G_ref,L_ref,E_ref,ERR_ref,OFLOW_ref,COUT_ref,


wire [(2*WIDTH)-1:0]RES_dut;
wire G_dut,L_dut,E_dut,ERR_dut,OFLOW_dut,COUT_dut;

integer passed,failed;
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

//ALU_REFERENCE CALL
//ALU_DUT CALL

	task monitor_scb;
		begin
			if(ERR_res == 1 && ERR_dut == 1)
			begin
				passed = passed + 1;
				$display(""); // fill later
			end
			else
			begin
				if( (RES_ref == RES_dut) && (OFLOW_res ==OFLOW_dut) && (COUT_res == COUT_dut) && (G_ref == G_dut) && (L_ref == L_dut) && (E_ref == E_dut))
				      	passed = passed + 1;
					$display("") // fill later		      
			end
	task driver_CE_high;
                CE = 1'b1;
        endtask

        task driver_CE_low;
                CE = 1'b0;
        endtask
			end
		end
	endtask;
endmodule

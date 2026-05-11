module ALU_tb;

localparam WIDTH = 8;

reg CLK,RST,CE,CIN;
reg [1:0] INP_VALID;
reg [WIDTH-1:0] OPA,OPB;
reg MODE;
reg [3:0] CMD;


wire [(2*WIDTH)-1:0]RES_ref;
wire G_ref,L_ref,E_ref,ERR_ref,OFLOW_ref,COUT_ref;


wire [(2*WIDTH)-1:0]RES_dut;
wire G_dut,L_dut,E_dut,ERR_dut,OFLOW_dut,COUT_dut;

integer passed=0,failed=0;
integer total=0;
integer i=0,j=0,k=0,l=0;
integer temp=1;

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
	
// DRIVERS RESET
	task driver_RST_high;
              	RST = 1'b1;
        endtask

        task driver_RST_low;
		RST = 1'b0;
        endtask
	

//ALU_REFERENCE CALL
ALU_ref #(.WIDTH(WIDTH)) ref 
(
    .OPA(OPA),
    .OPB(OPB),
    .CIN(CIN),
    .CLK(CLK),
    .RST(RST),
    .CE(CE),
    .MODE(MODE),
    .INP_VALID(INP_VALID),
    .CMD(CMD),
    .RES(RES_ref),
    .OFLOW(OFLOW_ref),
    .COUT(COUT_ref),
    .G(G_ref),
    .L(L_ref),
    .E(E_ref),
    .ERR(ERR_ref)
);

//ALU_DUT CALL
ALU_rtl_design #(.N(WIDTH))dut
(
    .OPA(OPA),
    .OPB(OPB),
    .CIN(CIN),
    .CLK(CLK),
    .RST(RST),
    .CMD(CMD),
    .CE(CE),
    .MODE(MODE),
    .INP_VALID(INP_VALID),
    .COUT(COUT_dut),
    .OFLOW(OFLOW_dut),
    .RES(RES_dut),
    .G(G_dut),
    .E(E_dut),
    .L(L_dut),
    .ERR(ERR_dut)
);


	task monitor_scb;
		begin
			total = total + 1;
			if( (ERR_ref == 1) && (ERR_dut == 1) )
			begin
				passed = passed + 1;
				$display("[PASS] TIME=%0t | MODE=%b CMD=%b | OPA=%0d OPB=%0d CIN=%b | DUT -> RES=%0d COUT=%b OFLOW=%b G=%b L=%b E=%b ERR=%b",$time,MODE,CMD,OPA,OPB,CIN,RES_dut,COUT_dut,OFLOW_dut,G_dut,L_dut,E_dut,ERR_dut);
			end
			else if( (MODE == 1) && (CMD == 8))
			begin
				if((G_ref == G_dut) && (L_ref == L_dut) && (E_ref == E_dut))
				begin
					 passed = passed + 1;                                                                                                                                $display("[PASS] TIME=%0t | MODE=%b CMD=%b | OPA=%0d OPB=%0d CIN=%b | DUT -> RES=%0d COUT=%b OFLOW=%b G=%b L=%b E=%b ERR=%b",$time,MODE,CMD,OPA,OPB,CIN,RES_dut,COUT_dut,OFLOW_dut,G_dut,L_dut,E_dut,ERR_dut);
				end
				else
				begin
					 failed = failed + 1;

                                        $display("[FAIL] TIME=%0t | MODE=%b CMD=%b | OPA=%0d OPB=%0d CIN=%b",$time,MODE,CMD,OPA,OPB,CIN);

                                        $display(" DUT -> RES=%0d COUT=%b OFLOW=%b G=%b L=%b E=%b ERR=%b",RES_dut,COUT_dut,OFLOW_dut,G_dut,L_dut,E_dut,ERR_dut);

                                        $display(" REF -> RES=%0d COUT=%b OFLOW=%b G=%b L=%b E=%b ERR=%b",RES_ref,COUT_ref,OFLOW_ref,G_ref,L_ref,E_ref,ERR_ref);
				end
			end
			else
			begin
				if( (RES_ref == RES_dut) && (OFLOW_ref ==OFLOW_dut) && (COUT_ref == COUT_dut) && (G_ref == G_dut) && (L_ref == L_dut) && (E_ref == E_dut))
				begin
					passed = passed + 1;
					$display("[PASS] TIME=%0t | MODE=%b CMD=%b | OPA=%0d OPB=%0d CIN=%b | DUT -> RES=%0d COUT=%b OFLOW=%b G=%b L=%b E=%b ERR=%b",$time,MODE,CMD,OPA,OPB,CIN,RES_dut,COUT_dut,OFLOW_dut,G_dut,L_dut,E_dut,ERR_dut);
				end
				else
				begin
					failed = failed + 1;

					$display("[FAIL] TIME=%0t | MODE=%b CMD=%b | OPA=%0d OPB=%0d CIN=%b",$time,MODE,CMD,OPA,OPB,CIN);

					$display(" DUT -> RES=%0d COUT=%b OFLOW=%b G=%b L=%b E=%b ERR=%b",RES_dut,COUT_dut,OFLOW_dut,G_dut,L_dut,E_dut,ERR_dut);

					$display(" REF -> RES=%0d COUT=%b OFLOW=%b G=%b L=%b E=%b ERR=%b",RES_ref,COUT_ref,OFLOW_ref,G_ref,L_ref,E_ref,ERR_ref);
				end
			end
		end
	endtask

//drive inputs

	task run_vec;
   		input mode_in;
    		input [3:0] cmd_in;
    		input [1:0] inv;
    		input [WIDTH-1:0] a, b;
    		input cin_in;
    		input integer cycles; // 1 or 3
    		begin
        	@(negedge CLK);
        	MODE = mode_in;
        	CMD = cmd_in;
        	INP_VALID = inv;
        	OPA = a;
        	OPB = b;
        	CIN = cin_in;
        	repeat(cycles) @(posedge CLK);
       	 	#1;
        	monitor_scb();
    	end
	endtask


initial
begin

    OPA = 0;
    OPB = 0;
    CIN = 0;
    CE = 0;
    RST = 1;
    INP_VALID = 2'b00;

    repeat(2) @(posedge CLK);

    driver_RST_low();

    CE=1;
    // MAIN RANDOM TEST LOOP
    // cycle through all modes at negedge

     for(l=0;l<2;l=l+1) // all modes
     begin
   	 for(i = 0; i < 16; i = i + 1) //all cmds
    	begin
		temp = ( (i == 9) || (i == 10))? 3:1;
		for(j=0;j<4;j= j+ 1) // all input valids
		begin
			for(k=0;k<2;k=k+1) // all cin
			begin
				//RANDOM
				driver_random_AB(); run_vec(l,i,j,OPA,OPB,k,temp);
				driver_random_AB(); run_vec(l,i,j,OPA,OPA,k,temp); //same value
				//SPECIFIC
				run_vec(l,i,j,8'hFF,8'hFF,k,temp);
				run_vec(l,i,j,8'h00,8'h00,k,temp);
				run_vec(l,i,j,8'hFF,8'h00,k,temp);
				run_vec(l,i,j,8'h00,8'hFF,k,temp);
		
				run_vec(l,i,j,8'hFE,8'hFF,k,temp);
                        	run_vec(l,i,j,8'hFE,8'h00,k,temp);

                        	run_vec(l,i,j,8'h00,8'hFE,k,temp);
                	       	run_vec(l,i,j,8'hFF,8'hFE,k,temp);
		
        	                run_vec(l,i,j,8'hFE,8'hFE,k,temp);

				run_vec(l,i,j,8'h80,8'h02,k,temp);
				run_vec(l,i,j,8'h01,8'h02,k,temp);

				run_vec(l,i,j,8'h7F,8'h7F,k,temp);
				run_vec(l,i,j,8'hF0,8'h04,k,temp);
			end

		end
    	end
    end

    run_vec(0,0,2'b11,8'h10,8'h20,0,1); 
    run_vec(1,0,2'b11,8'hF0,8'h0F,0,1);

   run_vec(1,0,2'b11,8'h10,8'h20,0,1);
   run_vec(0,0,2'b11,8'hF0,8'h0F,0,1);

   @(negedge CLK);
   CE        = 0;
   @(posedge CLK);
   #1 monitor_scb();
   CE = 1;
    @(posedge CLK);
    #1 monitor_scb();
    $display("------------------------------------------------");


    $display("=======================================");
    $display("TOTAL  = %0d", total);
    $display("PASSED = %0d", passed);
    $display("FAILED = %0d", failed);
    $display("=======================================");

    $finish;
end

endmodule

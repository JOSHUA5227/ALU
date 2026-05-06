module ALU #(parameter WIDTH = 8)(OPA,OPB,CIN,CLK,RST,CE,MODE,INP_VALID,CMD,RES,OFLOW,COUT,G,L,E,ERR);

input wire CLK,RST;

input wire [WIDTH-1:0] OPA,OPB;

input wire CIN;
input wire CE;

input wire MODE;
input wire [3:0] CMD;

input wire [1:0] INP_VALID;

output reg [2*WIDTH -1:0]RES;
output reg OFLOW,COUT,G,L,E,ERR;

reg [1:0] count; // 3 bit counter
reg [4:0] current_operation; // for resetting counter
reg [WIDTH-1:0] OPA_reg,OPB_reg; // temp registers for multiplication
reg [1:0] valid_reg; //temp register for multiplication
reg count_EN; 

wire clk1;

assign clk1 = CLK & CE;

reg [(2*WIDTH)- 1 : 0] next_res;
reg next_oflow,next_cout,next_g,next_l,next_e,next_err;

parameter MAX_COUNT = 2;
reg flag; // pipelining

always@(posedge clk1 or posedge RST)
begin
        if(RST)
        begin
                RES <= 'b0;
                OFLOW <= 1'b0;
                COUT <= 1'b0;
                {G,L,E} <= 3'b0;
                ERR <= 1'b0;
		count_EN <=1'b0;
		OPA_reg <=1'b0;
		OPB_reg <=1'b0;
		valid_reg <= 1'b0;
		flag <= 1'b0;
        end
        else
	begin
		RES <= next_res;
                OFLOW <= next_oflow;
                COUT <= next_cout;
                {G,L,E} <= {next_g,next_l,next_e};
                ERR <= next_err;
	end

end
always@(*)
begin
	{next_res,next_oflow,next_cout,next_g,next_l,next_e,next_err} = 'b0;
		case({MODE,CMD})
		5'b1_0000: 	// 0:ADD
		begin
			if(INP_VALID == 2'b11)
			begin
				{next_cout,next_res[WIDTH-1:0]} = OPA + OPB;
				next_res = OPA + OPB;
				next_err = 1'b0;
			end
			else
				next_err =1'b1;

		end

		5'b1_0001:	// 1:SUB	
		begin
			if(INP_VALID == 2'b11)
                        begin
                                {next_oflow,next_res[WIDTH-1:0]} = OPA - OPB;
                                next_res = OPA - OPB;
                                next_err = 1'b0;
                        end 
                        else
                                next_err = 1'b1;
		end

		5'b1_0010:	// 2:ADD_CIN
		begin
                        if(INP_VALID == 2'b11)
                        begin
                                {next_cout,next_res[WIDTH-1:0]} = OPA + OPB + CIN;
                                next_res = OPA + OPB + CIN;
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end

		5'b1_0011:	// 3:SUB_CIN	
		begin
                        if(INP_VALID == 2'b11)
                        begin
                                {next_oflow,next_res[WIDTH-1:0]} = OPA - OPB - CIN;
                                next_res = OPA - OPB - CIN;
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end

		5'b1_0100:	// 4:INC_A	
		begin
			if(INP_VALID[0] == 1'b1)
			begin
				next_res = OPA + 1;
			end
			else
				next_err = 1'b1;
		end

		5'b1_0101:	// 5:DEC_A	
		begin
                        if(INP_VALID[0] == 1'b1)
                        begin
                               	next_res = OPA - 1;
                        end
                        else
                                next_err = 1'b1;
                end

		5'b1_0110:	// 6:INC_B
		begin
                        if(INP_VALID[1] == 1'b1)
                        begin
                                next_res = OPB + 1;
                        end
                        else
                                next_err = 1'b1;
                end

		5'b1_0111:	// 7:DEC_B	
		begin
                        if(INP_VALID[1] == 1'b1)
                        begin
                                next_res = OPB - 1;
                        end
                        else
                                next_err = 1'b1;
                end

		5'b1_1000:	// 8:CMP
		begin
			if(INP_VALID == 2'b11)
			begin
				{next_g,next_l,next_e} = (OPA == OPB) ? 3'b001: (OPA > OPB) ? 3'b100:3'b010;
				next_err = 1'b0;
			end
			else
				next_err <= 1'b1;
		end

		5'b1_1001:	// 9: OP 9
		begin
			count_EN = 1'b1;
			if(count == 0)
			begin
				OPA_reg = OPA;
				OPB_reg = OPB;
				valid_reg = INP_VALID;
			end
			else
			begin
				if(count == MAX_COUNT - flag)
				begin
					if(valid_reg == 2'b11)
					begin
						next_res = (OPA_reg+1) * (OPB_reg+1);
						next_err = 1'b0;
						flag = 1'b1;
						OPA_reg = OPA;
                                                OPB_reg = OPB;
                                                valid_reg = INP_VALID;
					end
					else
						next_err = 1'b1;
				end
				//else do nothing	
			end
		end
		5'b1_1010:	// 10:OP 10	
		 begin
                        count_EN = 1'b1;
                        if(count == 0)
                        begin
                                OPA_reg = OPA;
                                OPB_reg = OPB;
                                valid_reg = INP_VALID;
                        end
                        else
                        begin
                                if(count == MAX_COUNT - flag)
                                begin
                                        if(valid_reg == 2'b11)
                                        begin
                                                next_res = (OPA_reg << 1) * OPB_reg;
                                                next_err = 1'b0;
						flag =1'b1;
						OPA_reg = OPA;
                                		OPB_reg = OPB;
                                		valid_reg = INP_VALID;
                                        end
                                        else
                                                next_err = 1'b1;
                                end
                                //else do nothing
                        end
                end

		5'b1_1011:	// 11:OP 11	
		begin
			if(INP_VALID == 2'b11)
			begin
				{next_g,next_l,next_e} = ($signed(OPA) == $signed(OPB)) ? 3'b001: ($signed(OPA) > $signed(OPB)) ? 3'b100:3'b010;
                                next_err = 1'b0;	
				next_res = OPA + OPB;

				next_oflow = ( (OPA[WIDTH-1] == OPB[WIDTH -1]) != next_res[WIDTH-1]) ? 1:0;
			end
			else
				next_err = 1'b1;
		end
		5'b1_1100:	// 12:OP 12	
		begin
		if(INP_VALID == 2'b11)
                        begin
                                {next_g,next_l,next_e} = ($signed(OPA) == $signed(OPB)) ? 3'b001: ($signed(OPA) > $signed(OPB)) ? 3'b100:3'b010;
                                next_err = 1'b0;
                                next_res = OPA - OPB;

				next_oflow = ( (OPA[WIDTH-1] == OPB[WIDTH -1]) != next_res[WIDTH-1]) ? 1:0;
                        end
                        else
                                next_err = 1'b1;
		end

		//LOGICAL OPERATIONS

		5'b0_0000: 	// 0:AND
		begin
			if(INP_VALID == 2'b11)
			begin
				next_res[WIDTH - 1] = OPA  & OPB;
				next_err = 1'b0;
			end
			else
				next_err = 1'b1;
		end
		5'b0_0001:	// 1:NAND
		 begin
                        if(INP_VALID == 2'b11)
                        begin
                                next_res[WIDTH - 1] = ~(OPA  & OPB);
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_0010:	// 2:OR
		 begin
                        if(INP_VALID == 2'b11)
                        begin
                                next_res[WIDTH - 1]  = OPA | OPB;
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_0011:	// 3:NOR
		begin
                        if(INP_VALID == 2'b11)
                        begin
                                next_res[WIDTH - 1]  = ~(OPA  | OPB);
                                next_err= 1'b0;
                        end
                        else
                                next_err= 1'b1;
                end	
		5'b0_0100:	// 4:XOR
		begin
                        if(INP_VALID == 2'b11)
                        begin
                                next_res[WIDTH - 1]  = (OPA  ^ OPB);
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_0101:	// 5:XNOR	
		begin
                        if(INP_VALID == 2'b11)
                        begin
                                next_res[WIDTH - 1] = ~(OPA  ^ OPB);
                                next_err = 1'b0;
                        end
                        else		
                                next_err = 1'b1;
                end
		5'b0_0110:	// 6:NOT_A
		begin
                        if(INP_VALID[0] == 1'b1)
                        begin
                                next_res[WIDTH - 1] = ~(OPA);
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_0111:	// 7:NOT_B	
		begin
                        if(INP_VALID[1] == 1'b1)
                        begin
                                next_res[WIDTH - 1] = ~(OPB);
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_1000:	// 8:SHR1_A	
		begin
                        if(INP_VALID[0] == 1'b1)
                        begin
                                next_res[WIDTH - 1] = OPA >> 1;
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_1001:	// 9:SHL1_A	
		begin
                        if(INP_VALID[0] == 1'b1)
                        begin
                                next_res[WIDTH - 1] = OPA << 1;
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_1010:	// 10:SHR1_B	
		 begin
                        if(INP_VALID[1] == 1'b1)
                        begin
                                next_res[WIDTH - 1] = OPB >> 1;
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_1011:	// 11:SHL1_B	
		begin
                        if(INP_VALID[1] == 1'b1)
                        begin
                                next_res[WIDTH - 1] = OPB << 1;
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_1100:	// 12:ROL_A_B	
		begin
			if(INP_VALID == 2'b11)
			begin
				if(|OPB[WIDTH-1: ($clog2(WIDTH)+1) ])
					next_err =1'b1;
				else
				begin
					next_err =1'b0;
				end	
				next_res[WIDTH - 1] = { OPA << OPB[ ($clog2(WIDTH)-1):0],OPA >> OPB[ ($clog2(WIDTH)-1):0] };
			end
			else
				next_err <= 1'b1;
		end
		5'b0_1101:	// 13:ROR_A_B	
		 begin
                        if(INP_VALID == 2'b11)
                        begin
                                if(|OPB[WIDTH-1: ($clog2(WIDTH)+1) ])
                                        next_err =1'b1;
                                else
                                begin
                                        next_err =1'b0;
                                end
				next_res[WIDTH - 1] = { OPA >> OPB[($clog2(WIDTH)-1):0] ,OPA << OPB[ ($clog2(WIDTH) -1 ):0] };
                        end
                        else
                                next_err = 1'b1;
                end
		endcase		
end

// storing previous operation
always@(posedge clk1 or posedge RST)
begin
	if(RST)
	begin
		current_operation <= 5'b0;
	end
	else
		current_operation <= {CMD,MODE};
end

// counter logic
always@(posedge clk1 or posedge RST)
begin
	if(RST)
	begin
		count <=1'b0;
	end
	else if	(count_EN)
	begin
		if(current_operation == {CMD,MODE})
		begin
			if(count >= (MAX_COUNT - flag))
				count <=1'b0;
			else
				count <= count + 1;
		end
		else
			count <= 1'b0;
	end
	else
			count <= 1'b0;
end
endmodule

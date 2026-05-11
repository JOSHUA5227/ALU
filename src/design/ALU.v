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
reg flag;
reg combinational_on; // flag to ensure the combinational block runs after sequential mainitaining the clock delay
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
		combinational_on <=1'b0;
        end
        else
	begin
		RES <= next_res;
                OFLOW <= next_oflow;
                COUT <= next_cout;
                {G,L,E} <= {next_g,next_l,next_e};
                ERR <= next_err;
		combinational_on <= ~combinational_on;

		if(count == 0 && ({MODE,CMD} == 5'b1_1001 || {MODE,CMD} == 5'b1_1010))
		begin
			OPA_reg <= OPA;
			OPB_reg <= OPB;
			valid_reg <= INP_VALID;
		end
		else if (count == 2)
		begin
			OPA_reg <= OPA;
			OPB_reg <= OPB;
			valid_reg <= INP_VALID;
			flag <=1'b1;
		end
		else
		begin
			OPA_reg <= OPA_reg;
			OPB_reg <= OPB_reg;
			valid_reg <= valid_reg;
		end
	end

end
always@(combinational_on)
begin
	{next_oflow,next_cout,next_g,next_l,next_e,next_err,count_EN} = 'b0;
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
				next_res[WIDTH-1:0] = OPA + 1;
			end
			else
				next_err = 1'b1;
		end

		5'b1_0101:	// 5:DEC_A	
		begin
                        if(INP_VALID[0] == 1'b1)
                        begin
                               	next_res[WIDTH-1:0]  = OPA - 1;
                        end
                        else
                                next_err = 1'b1;
                end

		5'b1_0110:	// 6:INC_B
		begin
                        if(INP_VALID[1] == 1'b1)
                        begin
                                next_res[WIDTH-1:0]  = OPB + 1;
                        end
                        else
                                next_err = 1'b1;
                end

		5'b1_0111:	// 7:DEC_B	
		begin
                        if(INP_VALID[1] == 1'b1)
                        begin
                                next_res[WIDTH-1:0]  = OPB - 1;
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
				next_err = 1'b1;
		end

		5'b1_1001:	// 9: INCREMENT AND MUL
		begin
			count_EN = 1'b1;
				if(count == MAX_COUNT-1)
				begin
					if(valid_reg == 2'b11)
					begin
						next_res = (OPA_reg+ 1) * (OPB_reg+ 1);
						next_err = 1'b0;
					end
					else
						next_err = 1'b1;
				end
				//else do nothing	
		end
		5'b1_1010:	// 10: MUL WITH LEFT SHIFT
		 begin
                        count_EN = 1'b1;
                        begin
                                if(count == MAX_COUNT - 1)
                                begin
                                        if(valid_reg == 2'b11)
                                        begin
						next_res = (OPA_reg << 1) *(OPB_reg);
                                                next_err = 1'b0;
                                        end
                                        else
                                                next_err = 1'b1;
                                end
                                //else do nothing
                        end
		end
		5'b1_1011:	// 11: SIGNED ADDITION WITH SIGNED GLE	
		begin
			if(INP_VALID == 2'b11)
			begin
				{next_g,next_l,next_e} = ($signed(OPA) == $signed(OPB)) ? 3'b001: ($signed(OPA) > $signed(OPB)) ? 3'b100:3'b010;
                                next_err = 1'b0;	
				next_res = $signed(OPA) + $signed(OPB);

				next_oflow = ( (OPA[WIDTH-1] == OPB[WIDTH -1]) && (next_res[WIDTH-1] != OPA[WIDTH-1] ) )? 1:0;
			end
			else
				next_err = 1'b1;
		end
		5'b1_1100:	// 12:OP SIGNED SUBTRACTION WITH SIGNED GLE
		begin
		if(INP_VALID == 2'b11)
                        begin
                                {next_g,next_l,next_e} = ($signed(OPA) == $signed(OPB)) ? 3'b001: ($signed(OPA) > $signed(OPB)) ? 3'b100:3'b010;
                                next_err = 1'b0;
                                next_res = $signed(OPA) - $signed(OPB);

				next_oflow = ( (OPA[WIDTH-1] != OPB[WIDTH -1]) && (next_res[WIDTH-1] != OPA[WIDTH-1] ) )? 1:0;
                        end
                        else
                                next_err = 1'b1;
		end

		//LOGICAL OPERATIONS

		5'b0_0000: 	// 0:AND
		begin
			if(INP_VALID == 2'b11)
			begin
				next_res = 0;
				next_res[WIDTH - 1:0] = OPA  & OPB;
				next_err = 1'b0;
			end
			else
				next_err = 1'b1;
		end
		5'b0_0001:	// 1:NAND
		 begin
                        if(INP_VALID == 2'b11)
                        begin
				next_res = 0;
                                next_res[WIDTH - 1:0] = ~(OPA  & OPB);
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_0010:	// 2:OR
		 begin
                        if(INP_VALID == 2'b11)
                        begin
				next_res = 0;
                                next_res[WIDTH - 1:0]  = OPA | OPB;
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_0011:	// 3:NOR
		begin
                        if(INP_VALID == 2'b11)
                        begin
				next_res = 0;
                                next_res[WIDTH - 1:0]  = ~(OPA  | OPB);
                                next_err= 1'b0;
                        end
                        else
                                next_err= 1'b1;
                end	
		5'b0_0100:	// 4:XOR
		begin
                        if(INP_VALID == 2'b11)
                        begin
				next_res = 0;
                                next_res[WIDTH - 1:0]  = (OPA  ^ OPB);
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_0101:	// 5:XNOR	
		begin
                        if(INP_VALID == 2'b11)
                        begin
				next_res = 0;
                                next_res[WIDTH - 1:0] = ~(OPA  ^ OPB);
                                next_err = 1'b0;
                        end
                        else		
                                next_err = 1'b1;
                end
		5'b0_0110:	// 6:NOT_A
		begin
                        if(INP_VALID[0] == 1'b1)
                        begin
				next_res = 0;
                                next_res[WIDTH - 1:0] = ~(OPA);
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_0111:	// 7:NOT_B	
		begin
                        if(INP_VALID[1] == 1'b1)
                        begin
				next_res = 0;
                                next_res[WIDTH - 1:0] = ~(OPB);
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_1000:	// 8:SHR1_A	
		begin
                        if(INP_VALID[0] == 1'b1)
                        begin
				next_res = 0;
                                next_res[WIDTH - 1:0] = OPA >> 1;
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_1001:	// 9:SHL1_A	
		begin
                        if(INP_VALID[0] == 1'b1)
                        begin
				next_res = 0;
                                next_res[WIDTH - 1:0] = OPA << 1;
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_1010:	// 10:SHR1_B	
		 begin
                        if(INP_VALID[1] == 1'b1)
                        begin
				next_res = 0;
                                next_res[WIDTH - 1:0] = OPB >> 1;
                                next_err = 1'b0;
                        end
                        else
                                next_err = 1'b1;
                end
		5'b0_1011:	// 11:SHL1_B	
		begin
                        if(INP_VALID[1] == 1'b1)
                        begin
				next_res = 0;
                                next_res[WIDTH - 1:0] = OPB << 1;
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
				next_res = 0;
				if(OPB == 0)
					next_res = OPA;
				else
					next_res[WIDTH - 1:0] = (OPA << OPB[ ($clog2(WIDTH)-1):0]) | (OPA >> (WIDTH - 1 - OPB[ ($clog2(WIDTH)-1):0] ));
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
				next_res = 0;
				if(OPB == 0)
					next_res = OPA;
				else
					next_res[WIDTH - 1:0] = (OPA >> OPB[($clog2(WIDTH)-1):0]) | (WIDTH - 1 - (OPA << OPB[ ($clog2(WIDTH) -1 ):0] ));
                        end
                        else
                                next_err = 1'b1;
                end
		default: next_res <= 0;
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
		current_operation <= {MODE,CMD};
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
		if(current_operation == {MODE,CMD})
		begin
			if(count >= (MAX_COUNT - 1))
				count <=1'b0 + flag;
			else
				count <= count + 1;
		end
		else
			count <= 1'b0 + flag;
	end
	else
			count <= 1'b0 + flag;
end
endmodule

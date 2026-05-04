module ALU(# parameter WIDTH = 7)(OPA,OPB,CIN,CLK,RST,CE,MODE,INP_VALID,CMD,RES,OFLOW,COUT,G,L,E,ERR);

input wire clk,rst;

input wire [WIDTH:0] OPA,OPB;

input wire CIN;
input wire CE;

input wire MODE;
input wire [3:0] CMD;

input wire [1:0] INP_VALID;

output reg [2*WIDTH -1:0]RES;
output reg OFLOW,COUT,G,L,E,ERR;

reg [1:0] count; // 3 bit counter

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		RES <= 'b0;
		OFLOW <= 1'b0;
		COUT <= 1'b0;
		{G,L,E} <= 3'b0;
		ERR <= 1'b0;
	end
	else if(CE)
	begin
		
	end
	else
	begin
		RES <= RES;
                OFLOW <= OFLOW;
                COUT <= COUT;
                {G,L,E} <= {G,L,E};
                ERR <= ERR;
	end
end
endmodule

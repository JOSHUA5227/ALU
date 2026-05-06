
`timescale 1ns/1ps

module ALU_tb;

// ============================================================
// Parameters
// ============================================================
parameter WIDTH = 8;
parameter CLK_PERIOD = 10;

// ============================================================
// DUT Signals
// ============================================================
reg                  CLK, RST, CIN, CE, MODE;
reg  [3:0]           CMD;
reg  [WIDTH-1:0]     OPA, OPB;
reg  [1:0]           INP_VALID;

wire [2*WIDTH-1:0]   RES;
wire                 OFLOW, COUT, G, L, E, ERR;

// ============================================================
// Test tracking
// ============================================================
integer pass_count;
integer fail_count;
integer test_num;

// ============================================================
// DUT Instantiation
// ============================================================
ALU #(.WIDTH(WIDTH)) dut (
    .OPA(OPA), .OPB(OPB), .CIN(CIN),
    .CLK(CLK), .RST(RST), .CE(CE),
    .MODE(MODE), .INP_VALID(INP_VALID),
    .CMD(CMD),
    .RES(RES), .OFLOW(OFLOW), .COUT(COUT),
    .G(G), .L(L), .E(E), .ERR(ERR)
);

// ============================================================
// Clock Generation
// ============================================================
initial CLK = 0;
always #(CLK_PERIOD/2) CLK = ~CLK;

// ============================================================
// Task: Apply inputs and clock
// ============================================================
task apply_inputs;
    input [WIDTH-1:0]   opa_in, opb_in;
    input               cin_in;
    input               mode_in;
    input [3:0]         cmd_in;
    input [1:0]         valid_in;
    begin
        @(negedge CLK);
        OPA       = opa_in;
        OPB       = opb_in;
        CIN       = cin_in;
        MODE      = mode_in;
        CMD       = cmd_in;
        INP_VALID = valid_in;
        @(posedge CLK);
        #1; // small settle after clock edge
    end
endtask

// ============================================================
// Task: Check result
// ============================================================
task check_result;
    input [127:0]        test_name; // up to 16 chars packed — just use $sformat
    input [2*WIDTH-1:0]  exp_res;
    input                exp_oflow;
    input                exp_cout;
    input                exp_g, exp_l, exp_e;
    input                exp_err;
    begin
        test_num = test_num + 1;
        if ( RES    === exp_res    &&
             OFLOW  === exp_oflow  &&
             COUT   === exp_cout   &&
             G      === exp_g      &&
             L      === exp_l      &&
             E      === exp_e      &&
             ERR    === exp_err )
        begin
            $display("[PASS] Test %0d | OPA=%0d OPB=%0d CIN=%0b MODE=%0b CMD=%0d VALID=%0b | RES=%0d OFLOW=%0b COUT=%0b G=%0b L=%0b E=%0b ERR=%0b",
                      test_num, OPA, OPB, CIN, MODE, CMD, INP_VALID,
                      RES, OFLOW, COUT, G, L, E, ERR);
            pass_count = pass_count + 1;
        end
        else
        begin
            $display("[FAIL] Test %0d | OPA=%0d OPB=%0d CIN=%0b MODE=%0b CMD=%0d VALID=%0b",
                      test_num, OPA, OPB, CIN, MODE, CMD, INP_VALID);
            $display("        Expected  -> RES=%0d OFLOW=%0b COUT=%0b G=%0b L=%0b E=%0b ERR=%0b",
                      exp_res, exp_oflow, exp_cout, exp_g, exp_l, exp_e, exp_err);
            $display("        Got       -> RES=%0d OFLOW=%0b COUT=%0b G=%0b L=%0b E=%0b ERR=%0b",
                      RES, OFLOW, COUT, G, L, E, ERR);
            fail_count = fail_count + 1;
        end
    end
endtask

// ============================================================
// Reset task
// ============================================================
task do_reset;
    begin
        RST = 1;
        repeat(3) @(posedge CLK);
        RST = 0;
        #1;
    end
endtask

// ============================================================
// MAIN TEST SEQUENCE
// ============================================================
initial begin
    // Init
    pass_count = 0;
    fail_count = 0;
    test_num   = 0;
    CE  = 1;
    RST = 0;
    OPA = 0; OPB = 0; CIN = 0; MODE = 0; CMD = 0; INP_VALID = 0;

    do_reset;

    // --------------------------------------------------------
    // ---- ARITHMETIC MODE (MODE=1) --------------------------
    // --------------------------------------------------------

    // --- CMD 0: ADD ---
    // General
    apply_inputs(8'd10,  8'd20,  0, 1, 4'd0, 2'b11);
    check_result("ADD_general",    16'd30,  0,0, 0,0,0, 0);

    apply_inputs(8'd100, 8'd55,  0, 1, 4'd0, 2'b11);
    check_result("ADD_general2",   16'd155, 0,0, 0,0,0, 0);

    // Overflow / carry
    apply_inputs(8'd255, 8'd1,   0, 1, 4'd0, 2'b11);
    check_result("ADD_carry",      16'd256, 0,1, 0,0,0, 0);

    apply_inputs(8'd255, 8'd255, 0, 1, 4'd0, 2'b11);
    check_result("ADD_max",        16'd510, 0,1, 0,0,0, 0);

    // Corner: add zeros
    apply_inputs(8'd0,   8'd0,   0, 1, 4'd0, 2'b11);
    check_result("ADD_zero",       16'd0,   0,0, 0,0,0, 0);

    // ERR: invalid inputs
    apply_inputs(8'd10,  8'd20,  0, 1, 4'd0, 2'b01);
    check_result("ADD_err",        16'd0,   0,0, 0,0,0, 1);

    // --- CMD 1: SUB ---
    apply_inputs(8'd50,  8'd20,  0, 1, 4'd1, 2'b11);
    check_result("SUB_general",    16'd30,  0,0, 0,0,0, 0);

    // Underflow (borrow)
    apply_inputs(8'd10,  8'd20,  0, 1, 4'd1, 2'b11);
    check_result("SUB_underflow",  16'hFFF6,1,0, 0,0,0, 0); // 10-20 = -10, 16-bit two's comp = 0xFFF6

    // Corner: subtract self
    apply_inputs(8'd100, 8'd100, 0, 1, 4'd1, 2'b11);
    check_result("SUB_self",       16'd0,   0,0, 0,0,0, 0);

    // Corner: subtract from 0
    apply_inputs(8'd0,   8'd1,   0, 1, 4'd1, 2'b11);
    check_result("SUB_zero_neg",   16'hFFFF,1,0, 0,0,0, 0);

    apply_inputs(8'd10,  8'd20,  0, 1, 4'd1, 2'b00);
    check_result("SUB_err",        16'd0,   0,0, 0,0,0, 1);

    // --- CMD 2: ADD_CIN ---
    apply_inputs(8'd10,  8'd20,  1, 1, 4'd2, 2'b11);
    check_result("ADDCIN_general", 16'd31,  0,0, 0,0,0, 0);

    apply_inputs(8'd255, 8'd0,   1, 1, 4'd2, 2'b11);
    check_result("ADDCIN_carry",   16'd256, 0,1, 0,0,0, 0);

    apply_inputs(8'd255, 8'd255, 1, 1, 4'd2, 2'b11);
    check_result("ADDCIN_maxcarry",16'd511, 0,1, 0,0,0, 0);

    apply_inputs(8'd0,   8'd0,   0, 1, 4'd2, 2'b11);
    check_result("ADDCIN_zero",    16'd0,   0,0, 0,0,0, 0);

    apply_inputs(8'd10,  8'd20,  1, 1, 4'd2, 2'b10);
    check_result("ADDCIN_err",     16'd0,   0,0, 0,0,0, 1);

    // --- CMD 3: SUB_CIN ---
    apply_inputs(8'd50,  8'd20,  1, 1, 4'd3, 2'b11);
    check_result("SUBCIN_general", 16'd29,  0,0, 0,0,0, 0);

    apply_inputs(8'd0,   8'd0,   1, 1, 4'd3, 2'b11);
    check_result("SUBCIN_zero",    16'hFFFF,1,0, 0,0,0, 0);

    apply_inputs(8'd10,  8'd20,  1, 1, 4'd3, 2'b00);
    check_result("SUBCIN_err",     16'd0,   0,0, 0,0,0, 1);

    // --- CMD 4: INC_A ---
    apply_inputs(8'd10,  8'd0,   0, 1, 4'd4, 2'b01);
    check_result("INC_A_general",  16'd11,  0,0, 0,0,0, 0);

    apply_inputs(8'd255, 8'd0,   0, 1, 4'd4, 2'b01);
    check_result("INC_A_wrap",     16'd256, 0,0, 0,0,0, 0);

    apply_inputs(8'd0,   8'd0,   0, 1, 4'd4, 2'b01);
    check_result("INC_A_zero",     16'd1,   0,0, 0,0,0, 0);

    apply_inputs(8'd10,  8'd0,   0, 1, 4'd4, 2'b00);
    check_result("INC_A_err",      16'd0,   0,0, 0,0,0, 1);

    // --- CMD 5: DEC_A ---
    apply_inputs(8'd10,  8'd0,   0, 1, 4'd5, 2'b01);
    check_result("DEC_A_general",  16'd9,   0,0, 0,0,0, 0);

    apply_inputs(8'd0,   8'd0,   0, 1, 4'd5, 2'b01);
    check_result("DEC_A_wrap",     16'hFFFF,0,0, 0,0,0, 0);

    apply_inputs(8'd1,   8'd0,   0, 1, 4'd5, 2'b01);
    check_result("DEC_A_to_zero",  16'd0,   0,0, 0,0,0, 0);

    apply_inputs(8'd10,  8'd0,   0, 1, 4'd5, 2'b10);
    check_result("DEC_A_err",      16'd0,   0,0, 0,0,0, 1);

    // --- CMD 6: INC_B ---
    apply_inputs(8'd0,   8'd10,  0, 1, 4'd6, 2'b10);
    check_result("INC_B_general",  16'd11,  0,0, 0,0,0, 0);

    apply_inputs(8'd0,   8'd255, 0, 1, 4'd6, 2'b10);
    check_result("INC_B_wrap",     16'd256, 0,0, 0,0,0, 0);

    apply_inputs(8'd0,   8'd10,  0, 1, 4'd6, 2'b01);
    check_result("INC_B_err",      16'd0,   0,0, 0,0,0, 1);

    // --- CMD 7: DEC_B ---
    apply_inputs(8'd0,   8'd10,  0, 1, 4'd7, 2'b10);
    check_result("DEC_B_general",  16'd9,   0,0, 0,0,0, 0);

    apply_inputs(8'd0,   8'd0,   0, 1, 4'd7, 2'b10);
    check_result("DEC_B_wrap",     16'hFFFF,0,0, 0,0,0, 0);

    apply_inputs(8'd0,   8'd10,  0, 1, 4'd7, 2'b01);
    check_result("DEC_B_err",      16'd0,   0,0, 0,0,0, 1);

    // --- CMD 8: CMP ---
    apply_inputs(8'd50,  8'd30,  0, 1, 4'd8, 2'b11);
    check_result("CMP_greater",    16'd0,   0,0, 1,0,0, 0);

    apply_inputs(8'd20,  8'd40,  0, 1, 4'd8, 2'b11);
    check_result("CMP_less",       16'd0,   0,0, 0,1,0, 0);

    apply_inputs(8'd77,  8'd77,  0, 1, 4'd8, 2'b11);
    check_result("CMP_equal",      16'd0,   0,0, 0,0,1, 0);

    apply_inputs(8'd0,   8'd0,   0, 1, 4'd8, 2'b11);
    check_result("CMP_zero_equal", 16'd0,   0,0, 0,0,1, 0);

    apply_inputs(8'd255, 8'd0,   0, 1, 4'd8, 2'b11);
    check_result("CMP_max_greater",16'd0,   0,0, 1,0,0, 0);

    apply_inputs(8'd10,  8'd20,  0, 1, 4'd8, 2'b10);
    check_result("CMP_err",        16'd0,   0,0, 0,0,0, 1);

    // --- CMD 11: SIGNED ADD with overflow + signed GLE ---
    // RES = OPA + OPB, stored as 8-bit result zero-extended to 16 bits.
    // OFLOW set when both operands same sign but result sign differs.
    // GLE uses $signed(OPA) vs $signed(OPB) 8-bit comparison.

    // 127 + 1 = 128 = 8'h80, zero-extended = 16'h0080
    // Signs: OPA[7]=0, OPB[7]=0, RES[7]=1 => OFLOW=1
    // Signed: +127 > +1 => G=1
    apply_inputs(8'd127, 8'd1,   0, 1, 4'd11, 2'b11);
    check_result("SADD_pos_oflow", 16'h0080, 1,0, 1,0,0, 0);

    // 0xFF(-1) + 0x80(-128) = 0x17F, 8-bit result = 0x7F, zero-ext = 16'h007F
    // Signs: OPA[7]=1, OPB[7]=1, RES[7]=0 => OFLOW=1
    // Signed: -1 > -128 => G=1
    apply_inputs(8'hFF, 8'h80,   0, 1, 4'd11, 2'b11);
    check_result("SADD_neg_oflow", 16'h007F, 1,0, 1,0,0, 0);

    // 0xFE(-2) + 0x01(+1) = 0xFF(-1), zero-ext = 16'h00FF
    // Signs: OPA[7]=1, OPB[7]=0 => different signs, OFLOW=0
    // Signed: -2 < +1 => L=1
    apply_inputs(8'hFE, 8'h01,   0, 1, 4'd11, 2'b11);
    check_result("SADD_normal",    16'h00FF, 0,0, 0,1,0, 0);

    // 5 + 5 = 10 = 16'h000A, no overflow
    // Signed: +5 == +5 => E=1
    apply_inputs(8'd5,  8'd5,    0, 1, 4'd11, 2'b11);
    check_result("SADD_equal",     16'h000A, 0,0, 0,0,1, 0);

    apply_inputs(8'd10, 8'd5,    0, 1, 4'd11, 2'b00);
    check_result("SADD_err",       16'd0,    0,0, 0,0,0, 1);

    // --- CMD 12: SIGNED SUB with overflow + signed GLE ---
    // RES = OPA - OPB, 8-bit result zero-extended to 16 bits.
    // OFLOW set when OPA and OPB have different signs and result sign != OPA sign.
    // GLE uses $signed(OPA) vs $signed(OPB) 8-bit comparison.

    // 0x80(-128) - 0x01(+1) = 0x7F(+127), zero-ext = 16'h007F
    // Signs differ (OPA[7]=1, OPB[7]=0), result sign(0) != OPA sign(1) => OFLOW=1
    // Signed: -128 < +1 => L=1
    apply_inputs(8'h80, 8'd1,    0, 1, 4'd12, 2'b11);
    check_result("SSUB_neg_oflow", 16'h007F, 1,0, 0,1,0, 0);

    // 0x7F(+127) - 0xFF(-1) = 0x80(-128), zero-ext = 16'h0080
    // Signs differ (OPA[7]=0, OPB[7]=1), result sign(1) != OPA sign(0) => OFLOW=1
    // Signed: +127 > -1 => G=1
    apply_inputs(8'h7F, 8'hFF,   0, 1, 4'd12, 2'b11);
    check_result("SSUB_pos_oflow", 16'h0080, 1,0, 1,0,0, 0);

    // 10 - 5 = 5, zero-ext = 16'h0005, no overflow
    // Signed: +10 > +5 => G=1
    apply_inputs(8'd10,  8'd5,   0, 1, 4'd12, 2'b11);
    check_result("SSUB_normal",    16'h0005, 0,0, 1,0,0, 0);

    // 5 - 5 = 0, zero-ext = 16'h0000, no overflow
    // Signed: equal => E=1
    apply_inputs(8'd5,   8'd5,   0, 1, 4'd12, 2'b11);
    check_result("SSUB_equal",     16'h0000, 0,0, 0,0,1, 0);

    apply_inputs(8'd10,  8'd5,   0, 1, 4'd12, 2'b01);
    check_result("SSUB_err",       16'd0,    0,0, 0,0,0, 1);

    // --------------------------------------------------------
    // ---- LOGICAL MODE (MODE=0) -----------------------------
    // --------------------------------------------------------

    // --- CMD 0: AND ---
    apply_inputs(8'hF0, 8'hFF, 0, 0, 4'd0, 2'b11);
    check_result("AND_general",   {8'd0,8'hF0}, 0,0, 0,0,0, 0);

    apply_inputs(8'hAA, 8'h55, 0, 0, 4'd0, 2'b11);
    check_result("AND_nooverlap", {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'hFF, 8'hFF, 0, 0, 4'd0, 2'b11);
    check_result("AND_all_ones",  {8'd0,8'hFF}, 0,0, 0,0,0, 0);

    apply_inputs(8'h00, 8'hFF, 0, 0, 4'd0, 2'b11);
    check_result("AND_zero",      {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'hF0, 8'hFF, 0, 0, 4'd0, 2'b01);
    check_result("AND_err",       16'd0,        0,0, 0,0,0, 1);

    // --- CMD 1: NAND ---
    apply_inputs(8'hF0, 8'hFF, 0, 0, 4'd1, 2'b11);
    check_result("NAND_general",  {8'd0,8'h0F}, 0,0, 0,0,0, 0);

    apply_inputs(8'hFF, 8'hFF, 0, 0, 4'd1, 2'b11);
    check_result("NAND_allones",  {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'h00, 8'h00, 0, 0, 4'd1, 2'b11);
    check_result("NAND_zero",     {8'd0,8'hFF}, 0,0, 0,0,0, 0);

    apply_inputs(8'hF0, 8'hFF, 0, 0, 4'd1, 2'b10);
    check_result("NAND_err",      16'd0,        0,0, 0,0,0, 1);

    // --- CMD 2: OR ---
    apply_inputs(8'hF0, 8'h0F, 0, 0, 4'd2, 2'b11);
    check_result("OR_general",    {8'd0,8'hFF}, 0,0, 0,0,0, 0);

    apply_inputs(8'h00, 8'h00, 0, 0, 4'd2, 2'b11);
    check_result("OR_zero",       {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'hAA, 8'h55, 0, 0, 4'd2, 2'b11);
    check_result("OR_complement", {8'd0,8'hFF}, 0,0, 0,0,0, 0);

    apply_inputs(8'hF0, 8'h0F, 0, 0, 4'd2, 2'b00);
    check_result("OR_err",        16'd0,        0,0, 0,0,0, 1);

    // --- CMD 3: NOR ---
    apply_inputs(8'hF0, 8'h0F, 0, 0, 4'd3, 2'b11);
    check_result("NOR_general",   {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'h00, 8'h00, 0, 0, 4'd3, 2'b11);
    check_result("NOR_zero",      {8'd0,8'hFF}, 0,0, 0,0,0, 0);

    apply_inputs(8'hF0, 8'h0F, 0, 0, 4'd3, 2'b01);
    check_result("NOR_err",       16'd0,        0,0, 0,0,0, 1);

    // --- CMD 4: XOR ---
    apply_inputs(8'hF0, 8'hFF, 0, 0, 4'd4, 2'b11);
    check_result("XOR_general",   {8'd0,8'h0F}, 0,0, 0,0,0, 0);

    apply_inputs(8'hAA, 8'hAA, 0, 0, 4'd4, 2'b11);
    check_result("XOR_self",      {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'hAA, 8'h55, 0, 0, 4'd4, 2'b11);
    check_result("XOR_comp",      {8'd0,8'hFF}, 0,0, 0,0,0, 0);

    apply_inputs(8'hAA, 8'hFF, 0, 0, 4'd4, 2'b00);
    check_result("XOR_err",       16'd0,        0,0, 0,0,0, 1);

    // --- CMD 5: XNOR ---
    apply_inputs(8'hF0, 8'hFF, 0, 0, 4'd5, 2'b11);
    check_result("XNOR_general",  {8'd0,8'hF0}, 0,0, 0,0,0, 0);

    apply_inputs(8'hAA, 8'hAA, 0, 0, 4'd5, 2'b11);
    check_result("XNOR_self",     {8'd0,8'hFF}, 0,0, 0,0,0, 0);

    apply_inputs(8'hAA, 8'h55, 0, 0, 4'd5, 2'b11);
    check_result("XNOR_comp",     {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'hAA, 8'hFF, 0, 0, 4'd5, 2'b10);
    check_result("XNOR_err",      16'd0,        0,0, 0,0,0, 1);

    // --- CMD 6: NOT_A ---
    apply_inputs(8'hF0, 8'd0,  0, 0, 4'd6, 2'b01);
    check_result("NOTA_general",  {8'd0,8'h0F}, 0,0, 0,0,0, 0);

    apply_inputs(8'h00, 8'd0,  0, 0, 4'd6, 2'b01);
    check_result("NOTA_zero",     {8'd0,8'hFF}, 0,0, 0,0,0, 0);

    apply_inputs(8'hFF, 8'd0,  0, 0, 4'd6, 2'b01);
    check_result("NOTA_ones",     {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'hF0, 8'd0,  0, 0, 4'd6, 2'b00);
    check_result("NOTA_err",      16'd0,        0,0, 0,0,0, 1);

    // --- CMD 7: NOT_B ---
    apply_inputs(8'd0, 8'hF0,  0, 0, 4'd7, 2'b10);
    check_result("NOTB_general",  {8'd0,8'h0F}, 0,0, 0,0,0, 0);

    apply_inputs(8'd0, 8'h00,  0, 0, 4'd7, 2'b10);
    check_result("NOTB_zero",     {8'd0,8'hFF}, 0,0, 0,0,0, 0);

    apply_inputs(8'd0, 8'hFF,  0, 0, 4'd7, 2'b10);
    check_result("NOTB_ones",     {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'd0, 8'hF0,  0, 0, 4'd7, 2'b00);
    check_result("NOTB_err",      16'd0,        0,0, 0,0,0, 1);

    // --- CMD 8: SHR1_A (right shift A by 1) ---
    apply_inputs(8'hF0, 8'd0,  0, 0, 4'd8, 2'b01);
    check_result("SHR1A_general", {8'd0,8'h78}, 0,0, 0,0,0, 0);

    apply_inputs(8'h01, 8'd0,  0, 0, 4'd8, 2'b01);
    check_result("SHR1A_one",     {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'h00, 8'd0,  0, 0, 4'd8, 2'b01);
    check_result("SHR1A_zero",    {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'hF0, 8'd0,  0, 0, 4'd8, 2'b10);
    check_result("SHR1A_err",     16'd0,        0,0, 0,0,0, 1);

    // --- CMD 9: SHL1_A (left shift A by 1) ---
    apply_inputs(8'h0F, 8'd0,  0, 0, 4'd9, 2'b01);
    check_result("SHL1A_general", {8'd0,8'h1E}, 0,0, 0,0,0, 0);

    apply_inputs(8'h80, 8'd0,  0, 0, 4'd9, 2'b01);
    check_result("SHL1A_msb",     {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'h00, 8'd0,  0, 0, 4'd9, 2'b01);
    check_result("SHL1A_zero",    {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'h0F, 8'd0,  0, 0, 4'd9, 2'b10);
    check_result("SHL1A_err",     16'd0,        0,0, 0,0,0, 1);

    // --- CMD 10: SHR1_B ---
    apply_inputs(8'd0,  8'hF0, 0, 0, 4'd10, 2'b10);
    check_result("SHR1B_general", {8'd0,8'h78}, 0,0, 0,0,0, 0);

    apply_inputs(8'd0,  8'h01, 0, 0, 4'd10, 2'b10);
    check_result("SHR1B_one",     {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'd0,  8'hF0, 0, 0, 4'd10, 2'b01);
    check_result("SHR1B_err",     16'd0,        0,0, 0,0,0, 1);

    // --- CMD 11: SHL1_B ---
    apply_inputs(8'd0,  8'h0F, 0, 0, 4'd11, 2'b10);
    check_result("SHL1B_general", {8'd0,8'h1E}, 0,0, 0,0,0, 0);

    apply_inputs(8'd0,  8'h80, 0, 0, 4'd11, 2'b10);
    check_result("SHL1B_msb",     {8'd0,8'h00}, 0,0, 0,0,0, 0);

    apply_inputs(8'd0,  8'h0F, 0, 0, 4'd11, 2'b01);
    check_result("SHL1B_err",     16'd0,        0,0, 0,0,0, 1);

    // --- CMD 12: ROL_A_B (rotate A left by OPB bits) ---
    apply_inputs(8'hF0, 8'd2,  0, 0, 4'd12, 2'b11);
    check_result("ROLA_general",  {8'd0, (8'hF0 << 2)|(8'hF0 >> 6)}, 0,0, 0,0,0, 0);

    apply_inputs(8'hAA, 8'd0,  0, 0, 4'd12, 2'b11);
    check_result("ROLA_byZero",   {8'd0, (8'hAA << 0)|(8'hAA >> 0)}, 0,0, 0,0,0, 0);

    apply_inputs(8'hF0, 8'h10, 0, 0, 4'd12, 2'b11);
    check_result("ROLA_oob_err",  {8'd0, (8'hF0 << 0)|(8'hF0 >> 0)}, 0,0, 0,0,0, 1);

    apply_inputs(8'hF0, 8'd2,  0, 0, 4'd12, 2'b01);
    check_result("ROLA_inv_err",  16'd0,        0,0, 0,0,0, 1);

    // --- CMD 13: ROR_A_B (rotate A right by OPB bits) ---
    apply_inputs(8'h0F, 8'd2,  0, 0, 4'd13, 2'b11);
    check_result("RORA_general",  {8'd0, (8'h0F >> 2)|(8'h0F << 6)}, 0,0, 0,0,0, 0);

    apply_inputs(8'hAA, 8'd0,  0, 0, 4'd13, 2'b11);
    check_result("RORA_byZero",   {8'd0, (8'hAA >> 0)|(8'hAA << 0)}, 0,0, 0,0,0, 0);

    apply_inputs(8'h0F, 8'h10, 0, 0, 4'd13, 2'b11);
    check_result("RORA_oob_err",  {8'd0, (8'h0F >> 0)|(8'h0F << 0)}, 0,0, 0,0,0, 1);

    apply_inputs(8'h0F, 8'd2,  0, 0, 4'd13, 2'b10);
    check_result("RORA_inv_err",  16'd0,        0,0, 0,0,0, 1);

    // --------------------------------------------------------
    // ---- PIPELINED MULTIPLY OPS (CMD 9/10 MODE=1) ----------
    // These need 3 clock cycles (count 0,1,2=MAX_COUNT)
    // --------------------------------------------------------

    // Reset before multiply tests to clear counter state
    do_reset;

    // CMD 9 (ARITH): INCREMENT AND MUL  => (OPA+1)*(OPB+1)
    // Cycle 0: latch
    apply_inputs(8'd3,  8'd4,  0, 1, 4'd9, 2'b11);
    // Cycle 1: pipeline
    apply_inputs(8'd3,  8'd4,  0, 1, 4'd9, 2'b11);
    // Cycle 2 (MAX_COUNT): result
    apply_inputs(8'd3,  8'd4,  0, 1, 4'd9, 2'b11);
    check_result("MUL_inc_general", 16'd20, 0,0, 0,0,0, 0); // (3+1)*(4+1)=20

    do_reset;
    // Corner: MUL zero
    apply_inputs(8'd0,  8'd0,  0, 1, 4'd9, 2'b11);
    apply_inputs(8'd0,  8'd0,  0, 1, 4'd9, 2'b11);
    apply_inputs(8'd0,  8'd0,  0, 1, 4'd9, 2'b11);
    check_result("MUL_inc_zero",    16'd1,  0,0, 0,0,0, 0); // (0+1)*(0+1)=1

    do_reset;
    // Corner: MUL max
    apply_inputs(8'd255, 8'd255, 0, 1, 4'd9, 2'b11);
    apply_inputs(8'd255, 8'd255, 0, 1, 4'd9, 2'b11);
    apply_inputs(8'd255, 8'd255, 0, 1, 4'd9, 2'b11);
    check_result("MUL_inc_max",    16'h0000,  0,0, 0,0,0, 0); // (255+1)^2=65536 overflows 16-bit => 0

    do_reset;
    // ERR: invalid inputs on pipeline entry
    apply_inputs(8'd3,   8'd4,  0, 1, 4'd9, 2'b01);
    apply_inputs(8'd3,   8'd4,  0, 1, 4'd9, 2'b01);
    apply_inputs(8'd3,   8'd4,  0, 1, 4'd9, 2'b01);
    check_result("MUL_inc_err",    16'd0,  0,0, 0,0,0, 1);

    do_reset;
    // CMD 10 (ARITH): MUL WITH LEFT SHIFT => (OPA<<1)*OPB
    apply_inputs(8'd3,  8'd4,  0, 1, 4'd10, 2'b11);
    apply_inputs(8'd3,  8'd4,  0, 1, 4'd10, 2'b11);
    apply_inputs(8'd3,  8'd4,  0, 1, 4'd10, 2'b11);
    check_result("MUL_lsh_general", 16'd24, 0,0, 0,0,0, 0); // (3<<1)*4=6*4=24

    do_reset;
    apply_inputs(8'd0,  8'd5,  0, 1, 4'd10, 2'b11);
    apply_inputs(8'd0,  8'd5,  0, 1, 4'd10, 2'b11);
    apply_inputs(8'd0,  8'd5,  0, 1, 4'd10, 2'b11);
    check_result("MUL_lsh_zeroA",  16'd0,  0,0, 0,0,0, 0); // (0<<1)*5=0

    do_reset;
    apply_inputs(8'd5,  8'd0,  0, 1, 4'd10, 2'b11);
    apply_inputs(8'd5,  8'd0,  0, 1, 4'd10, 2'b11);
    apply_inputs(8'd5,  8'd0,  0, 1, 4'd10, 2'b11);
    check_result("MUL_lsh_zeroB",  16'd0,  0,0, 0,0,0, 0); // (5<<1)*0=0

    do_reset;
    apply_inputs(8'd3,  8'd4,  0, 1, 4'd10, 2'b10);
    apply_inputs(8'd3,  8'd4,  0, 1, 4'd10, 2'b10);
    apply_inputs(8'd3,  8'd4,  0, 1, 4'd10, 2'b10);
    check_result("MUL_lsh_err",    16'd0,  0,0, 0,0,0, 1);

    // --------------------------------------------------------
    // ---- RST BEHAVIOR CHECK --------------------------------
    // --------------------------------------------------------
    @(negedge CLK);
    OPA = 8'hFF; OPB = 8'hFF; MODE = 1; CMD = 4'd0; INP_VALID = 2'b11;
    @(posedge CLK); #1;
    RST = 1;
    @(posedge CLK); #1;
    RST = 0;
    test_num = test_num + 1;
    if (RES === 16'd0 && ERR === 1'b0 && OFLOW === 1'b0 && COUT === 1'b0 &&
        G === 1'b0 && L === 1'b0 && E === 1'b0)
    begin
        $display("[PASS] Test %0d | RST clears all outputs", test_num);
        pass_count = pass_count + 1;
    end
    else
    begin
        $display("[FAIL] Test %0d | RST did not clear outputs correctly", test_num);
        $display("        Got RES=%0d OFLOW=%0b COUT=%0b G=%0b L=%0b E=%0b ERR=%0b",
                  RES, OFLOW, COUT, G, L, E, ERR);
        fail_count = fail_count + 1;
    end

    // CE=0: no change
    do_reset;
    apply_inputs(8'd10, 8'd20, 0, 1, 4'd0, 2'b11);
    check_result("CE1_ADD_works",  16'd30, 0,0, 0,0,0, 0);

    CE = 0;
    @(negedge CLK); OPA = 8'd99; OPB = 8'd99; @(posedge CLK); #1;
    test_num = test_num + 1;
    if (RES === 16'd30)
    begin
        $display("[PASS] Test %0d | CE=0 holds output stable", test_num);
        pass_count = pass_count + 1;
    end
    else
    begin
        $display("[FAIL] Test %0d | CE=0 did not hold output. RES=%0d", test_num, RES);
        fail_count = fail_count + 1;
    end
    CE = 1;

    // --------------------------------------------------------
    // ---- SUMMARY -------------------------------------------
    // --------------------------------------------------------
    $display("");
    $display("======================================================");
    $display("  TEST SUMMARY");
    $display("  Total  : %0d", test_num);
    $display("  Passed : %0d", pass_count);
    $display("  Failed : %0d", fail_count);
    $display("======================================================");
    if (fail_count == 0)
        $display("  ALL TESTS PASSED");
    else
        $display("  *** %0d TEST(S) FAILED — see [FAIL] lines above ***", fail_count);
    $display("======================================================");

    $finish;
end

endmodule

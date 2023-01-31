`timescale 10 ns / 10 ns

module tb_M68kDramController_Verilog();

	reg Clock;								// used to drive the state machine- stat changes occur on positive edge
	reg Reset_L;     						// active low reset 
	reg [31:0] Address;		// address bus from 68000
	reg [15:0] DataIn;			// data bus in from 68000
	reg UDS_L;								// active low signal driven by 68000 when 68000 transferring data over data bit 15-8
	reg LDS_L; 								// active low signal driven by 68000 when 68000 transferring data over data bit 7-0
	reg DramSelect_L;     				// active low signal indicating dram is being addressed by 68000
	reg WE_L;  								// active low write signal, otherwise assumed to be read
	reg AS_L;

	wire [15:0] DataOut; 				// data bus out to 68000
	wire SDram_CKE_H;								// active high clock enable for dram chip
	wire SDram_CS_L;								// active low chip select for dram chip
	wire SDram_RAS_L;								// active low RAS select for dram chip
	wire SDram_CAS_L;								// active low CAS select for dram chip		
	wire SDram_WE_L;								// active low Write enable for dram chip
	wire [12:0] SDram_Addr;			// 13 bit address bus dram chip	
	wire [1:0] SDram_BA;				// 2 bit bank address
	wire [15:0] SDram_DQ;			// 16 bit bi-directional data lines to dram chip
			
	wire Dtack_L;									// Dtack back to CPU at end of bus cycle
	wire ResetOut_L;								// reset out to the CPU
	
			// Use only if you want to simulate dram controller state (e.g. for debugging)
	wire [4:0] DramState;	

	M68kDramController_Verilog dut(
			.Clock(Clock),								// used to drive the state machine- stat changes occur on positive edge
			.Reset_L(Reset_L),     						// active low reset 
			.Address(Address),		// address bus from 68000
			.DataIn(DataIn),			// data bus in from 68000
			.UDS_L(UDS_L),								// active low signal driven by 68000 when 68000 transferring data over data bit 15-8
			.LDS_L(LDS_L), 								// active low signal driven by 68000 when 68000 transferring data over data bit 7-0
			.DramSelect_L(DramSelect_L),     				// active low signal indicating dram is being addressed by 68000
			.WE_L(WE_L),  								// active low write signal, otherwise assumed to be read
			.AS_L(AS_L),									// Address Strobe
			
			.DataOut(DataOut), 				// data bus out to 68000
			.SDram_CKE_H(SDram_CKE_H),								// active high clock enable for dram chip
			.SDram_CS_L(SDram_CS_L),								// active low chip select for dram chip
			.SDram_RAS_L(SDram_RAS_L),								// active low RAS select for dram chip
			.SDram_CAS_L(SDram_CAS_L),								// active low CAS select for dram chip		
			.SDram_WE_L(SDram_WE_L),								// active low Write enable for dram chip
			.SDram_Addr(SDram_Addr),			// 13 bit address bus dram chip	
			.SDram_BA(SDram_BA),				// 2 bit bank address
			.SDram_DQ(SDram_DQ),			// 16 bit bi-directional data lines to dram chip
			
			.Dtack_L(Dtack_L),									// Dtack back to CPU at end of bus cycle
			.ResetOut_L(ResetOut_L),								// reset out to the CPU
	
			// Use only if you want to simulate dram controller state (e.g. for debugging)
			.DramState(DramState)
		); 

	initial begin
		Clock = 0; #1;

		forever begin
			Clock = 1; #1;
			Clock = 0; #1;
		end

	end

	initial begin
		#1;
		Reset_L = 0;
		#1;
		Reset_L = 1;
		#120;
		
		$stop;

	end


endmodule

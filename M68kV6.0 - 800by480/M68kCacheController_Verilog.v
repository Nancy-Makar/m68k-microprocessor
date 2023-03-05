///////////////////////////////////////////////////////////////////////////////////////
// Simple Cache controller
//
// designed to work with TG68 (68000 based) cpu with 16 bit data bus and 32 bit address bus
// separate upper and lowe data stobes for individual byte and also 16 bit word access
//
// Copyright PJ Davies August 2017
///////////////////////////////////////////////////////////////////////////////////////

module M68kCacheController_Verilog (
		input Clock,											// used to drive the state machine - state changes occur on positive edge
		input Reset_L,     									// active low reset 
		input CacheHit_H,										// high when cache contains matching address during read
		input ValidBitIn_H,									// indicates if the cache line is valid

		// signals to 68k
		
		input DramSelect68k_H,     						// active high signal indicating Dram is being addressed by 68000
		input unsigned [31:0] AddressBusInFrom68k,  	// address bus from 68000
		input unsigned [15:0] DataBusInFrom68k, 		// data bus in from 68000
		output reg unsigned [15:0] DataBusOutTo68k, 	// data bus out from Cache controller back to 68000 (during read)
		input UDS_L,											// active low signal driven by 68000 when 68000 transferring data over data bit 15-8
		input LDS_L, 											// active low signal driven by 68000 when 68000 transferring data over data bit 7-0
		input WE_L,  											// active low write signal, otherwise assumed to be read
		input AS_L,
		input DtackFromDram_L,								// dtack back from Dram
		input CAS_Dram_L,										// cas to Dram so we can count 2 clock delays before 1st data
		input RAS_Dram_L,										// so we can detect diference between a read and a refresh command

		input unsigned [15:0] DataBusInFromDram, 							// data bus in from Dram
		output reg unsigned [15:0] DataBusOutToDramController, 		// data bus out to Dram (during write)
		input unsigned [15:0] DataBusInFromCache, 						// data bus in from Cache
		output reg UDS_DramController_L, 									// active low signal driven by 68000 when 68000 transferring data over data bit 7-0
		output reg LDS_DramController_L,										// active low signal driven by 68000 when 68000 transferring data over data bit 15-8
		output reg DramSelectFromCache_L,
		output reg WE_DramController_L,  									// active low Dram controller write signal
		output reg AS_DramController_L,
		output reg DtackTo68k_L, 												// Dtack back to 68k at end of operation
		
		// Cache memory write signals
		output reg TagCache_WE_L,												// to store an address in Cache
		output reg DataCache_WE_L,												// to store data in Cache
		output reg ValidBit_WE_L,												// to store a valid bit
		
		output reg unsigned [31:0] AddressBusOutToDramController,  	// address bus from Cache to Dram controller
		output reg unsigned [22:0] TagDataOut,  							// tag data to store in the tag Cache
		output reg unsigned [2:0] WordAddress,								// upto 8 bytes in a Cache line
		output reg ValidBitOut_H,												// indicates the cache line is valid
		output reg unsigned [8:4] Index,										// 5 bit index in this example cache

		output unsigned [4:0] CacheState										// for debugging
	);


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Initialisation States
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	parameter	Reset	= 5'b00000;
	parameter	InvalidateCache = 5'b00001 ;
	parameter 	Idleaaa = 5'b00010;	
	parameter	CheckForCacheHit = 5'b00011;	
	parameter	ReadDataFromDramIntoCache = 5'b00100 ;
	parameter	CASDelay1 = 5'b00101;
	parameter	CASDelay2 = 5'b00110;
	parameter	BurstFill = 5'b00111;
	parameter	EndBurstFill = 5'b01000 ;
	parameter	WriteDataToDram = 5'b01001 ;
	parameter	WaitForEndOfCacheRead = 5'b01010 ;
	
	
	// 5 bit variables to hold current and next state of the state machine
	reg unsigned [4:0]  CurrentState;						// holds the current state of the Cache controller
	reg unsigned [4:0]  NextState;							// holds the next state of the Cache controller
	
	// counter for the read burst fill
	reg unsigned [15:0] BurstCounter;						// counts for at least 8 during a burst Dram read also counts lines when flusing the cache
	reg BurstCounterReset_L;									// reset for the above counter

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// concurrent process state registers
// this process RECORDS the current state of the system.
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	assign CacheState = CurrentState;						// for debugging purposes only

   always@(posedge Clock, negedge Reset_L)
	begin
		if(Reset_L == 0) 
			CurrentState <= Reset ;
		else
			CurrentState <= NextState;	
	end
	
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Burst read counter: Used to provide a 3 bit address to the data Cache during burst reads from Dram and upto 2^12 cache lines
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	always@(posedge Clock)
	begin
		if(BurstCounterReset_L == 0) 						// synchronous reset
			BurstCounter <= 0;
		else
			BurstCounter <= BurstCounter + 1;
	end
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// next state and output logic
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
	always@(*) begin
		// start with default inactive values for everything and override as necessary, so we do not infer storage for signals inside this process
	
		NextState 						<= Idleaaa ;
		DataBusOutTo68k 				<= DataBusInFromCache;
		DataBusOutToDramController <= DataBusInFrom68k;

		// default is to give the Dram the 68k's signals directly (unless we want to change something)	
		
		AddressBusOutToDramController[31:4]	<= AddressBusInFrom68k[31:4];
		AddressBusOutToDramController[3:1]  <= 0;								// all reads to Dram have lower 3 address lines set to 0 for a Cache line regardless of 68k address
		AddressBusOutToDramController[0] 	<= 0;								// to avoid inferring a latch for this bit
		
		TagDataOut						<= AddressBusInFrom68k[31:9];
		Index								<= AddressBusInFrom68k[8:4];			// cache index is 68ks address bits [8:4]
		
		UDS_DramController_L			<= UDS_L;
		LDS_DramController_L	   	<= LDS_L;
		WE_DramController_L 			<= WE_L;
		AS_DramController_L			<= AS_L;
		
		DtackTo68k_L					<= 1;									// don't supply until we are ready
		TagCache_WE_L 					<= 1;									// don't write Cache address
		DataCache_WE_L 				<= 1;									// don't write Cache data
		ValidBit_WE_L					<= 1;									// don't write valid data
		ValidBitOut_H					<= 0;									// line invalid
		DramSelectFromCache_L 		<= 1;									// don't give the Dram controller a select signal since we might not always want to cycle the Dram if we have a hit during a read
		WordAddress						<= 0;									// default is byte 0 in 8 byte Cache line	
		
		BurstCounterReset_L 			<= 1;									// default is that burst counter can run (and wrap around if needed), we'll control when to reset it		
		NextState 						<= Idleaaa ;							// default is to go to this state
			
//////////////////////////////////////////////////////////////////
// Initial State following a reset
//////////////////////////////////////////////////////////////////
		
		if(CurrentState == Reset) begin	  								// if we are in the Reset state				
			BurstCounterReset_L 				<= 0;							// reset the burst counter (synchronously)
			NextState							<= InvalidateCache;				// go flush the cache
		end

/////////////////////////////////////////////////////////////////
// This state will flush the cache before entering idle state
/////////////////////////////////////////////////////////////////	
		else if(CurrentState == InvalidateCache) begin	  						
			
			// burst counter should now be 0 when we first enter this state, as it was reset in state above
			
			if(BurstCounter == 32) 											// if we have done all cache lines
				NextState 						<= Idleaaa;
			else begin
				NextState						<= InvalidateCache;				// assume we stay here
				Index	 							<= BurstCounter[4:0];	// 5 bit address for Index for 32 lines of cache
				
				// clear the validity bit for each cache line
				ValidBitOut_H 					<=	0;		
				ValidBit_WE_L					<= 0;
			end
		end

///////////////////////////////////////////////
// Main IDLE state: 
///////////////////////////////////////////////
		else if(CurrentState == Idleaaa) begin
			if(DramSelect68k_H == 1 && AS_L == 0) begin
				if(WE_L == 1) begin
					UDS_DramController_L <= 0;
					LDS_DramController_L <= 0;
					NextState <= CheckForCacheHit;
				end
				else begin
					if(ValidBitIn_H == 1) begin
						ValidBitOut_H <= 0;
						ValidBit_WE_L <= 0;
				
					end
				
					DramSelectFromCache_L <= 0;
					NextState <= WriteDataToDram;
			
				end
			
			end
			

		end

////////////////////////////////////////////////////////////////////////////////////////////////////
// Check if we have a Cache HIT. If so give data to 68k or if not, go generate a burst fill 
////////////////////////////////////////////////////////////////////////////////////////////////////

		else if(CurrentState == CheckForCacheHit) begin	  			// if we are looking for Cache hit			
			UDS_DramController_L <= 0;
			LDS_DramController_L <= 0;
			
			if(CacheHit_H == 1 && ValidBitIn_H == 1) begin
				WordAddress <= AddressBusInFrom68k [3:1];
				DtackTo68k_L <= 0;
				NextState <= WaitForEndOfCacheRead;
			end
			else begin
				DramSelectFromCache_L <= 0;
				NextState <= ReadDataFromDramIntoCache;
			end
		
		end	

///////////////////////////////////////////////////////////////////////////////////////////////
// Got a Cache hit, so give the 68k the Cache data now, then wait for the 68k to end bus cycle 
///////////////////////////////////////////////////////////////////////////////////////////////

		else if(CurrentState == WaitForEndOfCacheRead) begin
			UDS_DramController_L <= 0;
			LDS_DramController_L <= 0;
			WordAddress <= AddressBusInFrom68k[3:1];
			DtackTo68k_L <= 0;
			
			if(AS_L == 0)
				NextState <= WaitForEndOfCacheRead;

		end
			
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Start of operation to Read from Dram State : Remember that CAS latency is 2 clocks before 1st item of burst data appears
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		else if(CurrentState == ReadDataFromDramIntoCache) begin
			NextState <= ReadDataFromDramIntoCache;
			
			if(CAS_Dram_L == 0 && RAS_Dram_L == 1)
				NextState <= CASDelay1;
				
			DramSelectFromCache_L <= 0;
			DtackTo68k_L  <= 1;
			
			TagCache_WE_L <= 0;
			
			ValidBitOut_H <= 1;
			
			ValidBit_WE_L <= 0;
			
			UDS_DramController_L <= 0;
			LDS_DramController_L <= 0;
			

		end
						
///////////////////////////////////////////////////////////////////////////////////////
// Wait for 1st CAS clock (latency)
///////////////////////////////////////////////////////////////////////////////////////
			
		else if(CurrentState == CASDelay1) begin						// wait for Dram case signal to go low
			UDS_DramController_L <= 0;
			LDS_DramController_L <= 0;
			DramSelectFromCache_L <= 0;
			DtackTo68k_L <= 1;
			
			NextState <= CASDelay2;
		
		end
				
///////////////////////////////////////////////////////////////////////////////////////
// Wait for 2nd CAS Clock Latency
///////////////////////////////////////////////////////////////////////////////////////
			
		else if(CurrentState == CASDelay2) begin						// wait for Dram case signal to go low
			UDS_DramController_L <= 0;
			LDS_DramController_L <= 0;
			DramSelectFromCache_L <= 0;
			DtackTo68k_L <= 1;
			
			BurstCounterReset_L <= 0;
			NextState <= BurstFill;
			
		end

/////////////////////////////////////////////////////////////////////////////////////////////
// Start of burst fill from Dram into Cache (data should be available at Dram in this  state)
/////////////////////////////////////////////////////////////////////////////////////////////
		
		else if(CurrentState == BurstFill) begin						// wait for Dram case signal to go low
			UDS_DramController_L <= 0;
			LDS_DramController_L <= 0;
			DramSelectFromCache_L <= 0;
			DtackTo68k_L <= 1;
			
			if(BurstCounter == 8) begin 
				NextState <= EndBurstFill;
			end
			else begin
				WordAddress <= BurstCounter[2:0];
				DataCache_WE_L <= 0;
				NextState <= BurstFill;
			end
			
		end
			
///////////////////////////////////////////////////////////////////////////////////////
// End Burst fill
///////////////////////////////////////////////////////////////////////////////////////
		else if(CurrentState == EndBurstFill) begin							// wait for Dram case signal to go low
			DramSelectFromCache_L <= 1;
			DtackTo68k_L <= 0;
			UDS_DramController_L <= 0;
			LDS_DramController_L <= 0;
			
			WordAddress <= AddressBusInFrom68k[3:1];
			DataBusOutTo68k <= DataBusInFromCache;
			
			if(AS_L == 1 || DramSelect68k_H == 0) begin
				NextState <= Idleaaa ;
			
			end
			else begin
				NextState <= EndBurstFill;
			end
			
		end

///////////////////////////////////////////////
// Write Data to Dram State (no Burst)
///////////////////////////////////////////////
		else if(CurrentState == WriteDataToDram) begin	  					// if we are writing data to Dram
			AddressBusOutToDramController <= AddressBusInFrom68k;
			DramSelectFromCache_L <= 0;
			DtackTo68k_L <=  DtackFromDram_L;
			
			if(AS_L == 1 || DramSelect68k_H == 0) begin
				NextState <= Idleaaa ;
			
			end
			else begin
				NextState <= WriteDataToDram;
			end
		
		end
	end
endmodule
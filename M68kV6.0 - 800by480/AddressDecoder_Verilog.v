module AddressDecoder_Verilog (
		input unsigned [31:0] Address,
		
		output reg OnChipRomSelect_H,
		output reg OnChipRamSelect_H,
		output reg DramSelect_H,
		output reg IOSelect_H,
		output reg DMASelect_L,
		output reg GraphicsCS_L,
		output reg OffBoardMemory_H,
		output reg CanBusSelect_H
);

	always@(*) begin

		// defaults output are inactive override as required later
		
		OnChipRomSelect_H <= 0 ;
		OnChipRamSelect_H <= 0 ;
		DramSelect_H <= 0 ;
		IOSelect_H <= 0 ;
		DMASelect_L <= 1 ;
		GraphicsCS_L <= 1 ;
		OffBoardMemory_H <= 0;
		CanBusSelect_H <= 0;
		
		// overriddent value
	
		if(Address[31:15] == 17'b0000_0000_0000_0000_0) 	// ON CHIP ROM address hex 0000 0000 - 0000 7FFF 32k full decoding
			OnChipRomSelect_H <= 1 ;								// DO NOT CHANGE - debugger expects rom at this address
		
		if(Address[31:18] == 14'b0000_1000_0000_00) 			// address hex 0800 0000 - 0803 FFFF Partial decoding - 256kbytes
			DramSelect_H <= 1 ;										// DO NOT CHANGE - debugger expects memory at this address
			
		if(Address[31:16] == 16'b0000_0000_0100_0000)  		// address hex 0040 0000 - 0040 FFFF Partial decoding
			IOSelect_H <= 1 ;											// DO NOT CHANGE - debugger expects IO at this address
		
		//
		// add other decoder signals here as we work through assignments and labs
		//
		
		if(Address[31:26] == 6'b1111_00)							// address hex F000 0000 - F3FF FFFF Partial decoding
			OnChipRamSelect_H <= 1 ;								// memory range allocated for static ram (previously SDRAM)
			
		
		
		
		
		end
endmodule

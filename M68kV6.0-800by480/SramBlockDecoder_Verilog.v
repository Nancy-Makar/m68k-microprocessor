module SramBlockDecoder_Verilog( 
		input unsigned [16:0] Address, // lower 17 lines of address bus from 68k
		input SRamSelect_H,				 // from main (top level) address decoder indicating 68k is talking to Sram
		
		// 4 separate block select signals that parition 256kbytes (128k words) into 4 blocks of 64k (32 k words)
		output reg Block0_H, 
		output reg Block1_H, 
		output reg Block2_H, 
		output reg Block3_H 
);	

	always@(*)	begin
	
		// default block selects are inactive - override as appropriate later
		if(SRamSelect_H == 1'b1 && Address[16:15] == 2'b00) begin
			Block0_H <= 1;
			Block1_H <= 0;
			Block2_H <= 0; 
			Block3_H <= 0;		
		end
		else if(SRamSelect_H == 1'b1 && Address[16:15] == 2'b01) begin
			Block0_H <= 0; 
			Block1_H <= 1;
			Block2_H <= 0; 
			Block3_H <= 0;
		end
		else if(SRamSelect_H == 1'b1 && Address[16:15] == 2'b10) begin
			Block0_H <= 0; 
			Block1_H <= 0;
			Block2_H <= 1;
			Block3_H <= 0;
		end
		else if(SRamSelect_H == 1'b1 && Address[16:15] == 2'b11) begin
			Block0_H <= 0; 
			Block1_H <= 0;
			Block2_H <= 0; 
			Block3_H <= 1; 	
		end
		else begin
			Block0_H <= 0; 
			Block1_H <= 0;
			Block2_H <= 0; 
			Block3_H <= 0;
		end
		
		
	
		// decode the top two address lines plus SRamSelect to provide 4 block select signals
		// for 4 blocks of 64k bytes (32k words) to give 256k bytes in total
	
		// TODO
		
	end
endmodule

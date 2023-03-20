module IIC_SPI_BUS_Decoder (
input unsigned [31:0] Address,
input IOSelect_H,
input AS_L,
output reg IIC0_Enable_H
);

	always@(*) begin
	
	IIC0_Enable_H <= 0 ;
	
	if(AS_L == 0 && IOSelect_H == 1)							
		begin
			// addresses in the range hex [0040 0000 - 0040 FFFF]
			if(Address[15:4] == 12'b1000_0000_0010)
				IIC0_Enable_H <= 1 ;

		end

	end
endmodule
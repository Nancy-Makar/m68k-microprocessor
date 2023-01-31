-- Copyright (C) 2018  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details.

-- *****************************************************************************
-- This file contains a Vhdl test bench with test vectors .The test vectors     
-- are exported from a vector file in the Quartus Waveform Editor and apply to  
-- the top level entity of the current Quartus project .The user can use this   
-- testbench to simulate his design using a third-party simulation tool .       
-- *****************************************************************************
-- Generated on "01/20/2023 12:25:46"
                                                             
-- Vhdl Test Bench(with test vectors) for design  :          MC68K
-- 
-- Simulation tool : 3rd Party
-- 

LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                

ENTITY MC68K_vhd_vec_tst IS
END MC68K_vhd_vec_tst;
ARCHITECTURE MC68K_arch OF MC68K_vhd_vec_tst IS
-- constants                                                 
-- signals                                                   
SIGNAL AddressBus : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL AS_L : STD_LOGIC;
SIGNAL BG_L : STD_LOGIC;
SIGNAL Can0_RX : STD_LOGIC;
SIGNAL Can0_TX : STD_LOGIC;
SIGNAL Can1_RX : STD_LOGIC;
SIGNAL Can1_TX : STD_LOGIC;
SIGNAL CanBusSelect_H : STD_LOGIC;
SIGNAL CLOCK_50 : STD_LOGIC;
SIGNAL CPUClock : STD_LOGIC;
SIGNAL DataBusIn : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL DataBusOut : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL DRAM_ADDR : STD_LOGIC_VECTOR(12 DOWNTO 0);
SIGNAL DRAM_BA : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL DRAM_CAS_N : STD_LOGIC;
SIGNAL DRAM_CKE : STD_LOGIC;
SIGNAL DRAM_CLK : STD_LOGIC;
SIGNAL DRAM_CS_N : STD_LOGIC;
SIGNAL DRAM_DQ : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL DRAM_LDQM : STD_LOGIC;
SIGNAL DRAM_RAS_N : STD_LOGIC;
SIGNAL DRAM_UDQM : STD_LOGIC;
SIGNAL DRAM_WE_N : STD_LOGIC;
SIGNAL DramDtack_L : STD_LOGIC;
SIGNAL DramRamSelect_H : STD_LOGIC;
SIGNAL Dtack_L : STD_LOGIC;
SIGNAL GraphicsSelect_L : STD_LOGIC;
SIGNAL HEX0 : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL HEX1 : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL HEX2 : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL HEX3 : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL HEX4 : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL HEX5 : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL IOSelect_H : STD_LOGIC;
SIGNAL IRQ2_L : STD_LOGIC;
SIGNAL IRQ4_L : STD_LOGIC;
SIGNAL LCD_Contrast_DE1 : STD_LOGIC;
SIGNAL LCD_Data : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL LCD_E : STD_LOGIC;
SIGNAL LCD_RS : STD_LOGIC;
SIGNAL LCD_RW : STD_LOGIC;
SIGNAL LDS_L : STD_LOGIC;
SIGNAL LEDR : STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL miso_i : STD_LOGIC;
SIGNAL mosi_o : STD_LOGIC;
SIGNAL RamSelect_H : STD_LOGIC;
SIGNAL Reset_L : STD_LOGIC;
SIGNAL ResetOut : STD_LOGIC;
SIGNAL RomSelect_H : STD_LOGIC;
SIGNAL RS232_RxData : STD_LOGIC;
SIGNAL RS232_TxData : STD_LOGIC;
SIGNAL RW : STD_LOGIC;
SIGNAL sck_o : STD_LOGIC;
SIGNAL SCL : STD_LOGIC;
SIGNAL SDA : STD_LOGIC;
SIGNAL SSN_O : STD_LOGIC_VECTOR(0 DOWNTO 0);
SIGNAL SW : STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL TraceRequest_L : STD_LOGIC;
SIGNAL UDS_L : STD_LOGIC;
SIGNAL VGA_B : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL VGA_BLANK_N : STD_LOGIC;
SIGNAL VGA_CLK : STD_LOGIC;
SIGNAL VGA_G : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL VGA_HS : STD_LOGIC;
SIGNAL VGA_R : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL VGA_SYNC_N : STD_LOGIC;
SIGNAL VGA_VS : STD_LOGIC;
COMPONENT MC68K
	PORT (
	AddressBus : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	AS_L : OUT STD_LOGIC;
	BG_L : OUT STD_LOGIC;
	Can0_RX : IN STD_LOGIC;
	Can0_TX : OUT STD_LOGIC;
	Can1_RX : IN STD_LOGIC;
	Can1_TX : OUT STD_LOGIC;
	CanBusSelect_H : OUT STD_LOGIC;
	CLOCK_50 : IN STD_LOGIC;
	CPUClock : OUT STD_LOGIC;
	DataBusIn : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
	DataBusOut : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
	DRAM_ADDR : OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
	DRAM_BA : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
	DRAM_CAS_N : OUT STD_LOGIC;
	DRAM_CKE : OUT STD_LOGIC;
	DRAM_CLK : OUT STD_LOGIC;
	DRAM_CS_N : OUT STD_LOGIC;
	DRAM_DQ : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
	DRAM_LDQM : OUT STD_LOGIC;
	DRAM_RAS_N : OUT STD_LOGIC;
	DRAM_UDQM : OUT STD_LOGIC;
	DRAM_WE_N : OUT STD_LOGIC;
	DramDtack_L : OUT STD_LOGIC;
	DramRamSelect_H : OUT STD_LOGIC;
	Dtack_L : OUT STD_LOGIC;
	GraphicsSelect_L : OUT STD_LOGIC;
	HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	IOSelect_H : OUT STD_LOGIC;
	IRQ2_L : IN STD_LOGIC;
	IRQ4_L : IN STD_LOGIC;
	LCD_Contrast_DE1 : OUT STD_LOGIC;
	LCD_Data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	LCD_E : OUT STD_LOGIC;
	LCD_RS : OUT STD_LOGIC;
	LCD_RW : OUT STD_LOGIC;
	LDS_L : OUT STD_LOGIC;
	LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
	miso_i : IN STD_LOGIC;
	mosi_o : OUT STD_LOGIC;
	RamSelect_H : OUT STD_LOGIC;
	Reset_L : IN STD_LOGIC;
	ResetOut : OUT STD_LOGIC;
	RomSelect_H : OUT STD_LOGIC;
	RS232_RxData : IN STD_LOGIC;
	RS232_TxData : OUT STD_LOGIC;
	RW : OUT STD_LOGIC;
	sck_o : OUT STD_LOGIC;
	SCL : INOUT STD_LOGIC;
	SDA : INOUT STD_LOGIC;
	SSN_O : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
	SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
	TraceRequest_L : IN STD_LOGIC;
	UDS_L : OUT STD_LOGIC;
	VGA_B : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	VGA_BLANK_N : OUT STD_LOGIC;
	VGA_CLK : OUT STD_LOGIC;
	VGA_G : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	VGA_HS : OUT STD_LOGIC;
	VGA_R : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	VGA_SYNC_N : OUT STD_LOGIC;
	VGA_VS : OUT STD_LOGIC
	);
END COMPONENT;
BEGIN
	i1 : MC68K
	PORT MAP (
-- list connections between master ports and signals
	AddressBus => AddressBus,
	AS_L => AS_L,
	BG_L => BG_L,
	Can0_RX => Can0_RX,
	Can0_TX => Can0_TX,
	Can1_RX => Can1_RX,
	Can1_TX => Can1_TX,
	CanBusSelect_H => CanBusSelect_H,
	CLOCK_50 => CLOCK_50,
	CPUClock => CPUClock,
	DataBusIn => DataBusIn,
	DataBusOut => DataBusOut,
	DRAM_ADDR => DRAM_ADDR,
	DRAM_BA => DRAM_BA,
	DRAM_CAS_N => DRAM_CAS_N,
	DRAM_CKE => DRAM_CKE,
	DRAM_CLK => DRAM_CLK,
	DRAM_CS_N => DRAM_CS_N,
	DRAM_DQ => DRAM_DQ,
	DRAM_LDQM => DRAM_LDQM,
	DRAM_RAS_N => DRAM_RAS_N,
	DRAM_UDQM => DRAM_UDQM,
	DRAM_WE_N => DRAM_WE_N,
	DramDtack_L => DramDtack_L,
	DramRamSelect_H => DramRamSelect_H,
	Dtack_L => Dtack_L,
	GraphicsSelect_L => GraphicsSelect_L,
	HEX0 => HEX0,
	HEX1 => HEX1,
	HEX2 => HEX2,
	HEX3 => HEX3,
	HEX4 => HEX4,
	HEX5 => HEX5,
	IOSelect_H => IOSelect_H,
	IRQ2_L => IRQ2_L,
	IRQ4_L => IRQ4_L,
	LCD_Contrast_DE1 => LCD_Contrast_DE1,
	LCD_Data => LCD_Data,
	LCD_E => LCD_E,
	LCD_RS => LCD_RS,
	LCD_RW => LCD_RW,
	LDS_L => LDS_L,
	LEDR => LEDR,
	miso_i => miso_i,
	mosi_o => mosi_o,
	RamSelect_H => RamSelect_H,
	Reset_L => Reset_L,
	ResetOut => ResetOut,
	RomSelect_H => RomSelect_H,
	RS232_RxData => RS232_RxData,
	RS232_TxData => RS232_TxData,
	RW => RW,
	sck_o => sck_o,
	SCL => SCL,
	SDA => SDA,
	SSN_O => SSN_O,
	SW => SW,
	TraceRequest_L => TraceRequest_L,
	UDS_L => UDS_L,
	VGA_B => VGA_B,
	VGA_BLANK_N => VGA_BLANK_N,
	VGA_CLK => VGA_CLK,
	VGA_G => VGA_G,
	VGA_HS => VGA_HS,
	VGA_R => VGA_R,
	VGA_SYNC_N => VGA_SYNC_N,
	VGA_VS => VGA_VS
	);

-- Reset_L
t_prcs_Reset_L: PROCESS
BEGIN
	Reset_L <= '0';
	WAIT FOR 90000 ps;
	Reset_L <= '1';
WAIT;
END PROCESS t_prcs_Reset_L;

-- SW[8]
t_prcs_SW_8: PROCESS
BEGIN
	SW(8) <= '0';
WAIT;
END PROCESS t_prcs_SW_8;

-- IRQ4_L
t_prcs_IRQ4_L: PROCESS
BEGIN
	IRQ4_L <= '1';
WAIT;
END PROCESS t_prcs_IRQ4_L;

-- IRQ2_L
t_prcs_IRQ2_L: PROCESS
BEGIN
	IRQ2_L <= '1';
WAIT;
END PROCESS t_prcs_IRQ2_L;

-- TraceRequest_L
t_prcs_TraceRequest_L: PROCESS
BEGIN
	TraceRequest_L <= '1';
WAIT;
END PROCESS t_prcs_TraceRequest_L;

-- CLOCK_50
t_prcs_CLOCK_50: PROCESS
BEGIN
LOOP
	CLOCK_50 <= '0';
	WAIT FOR 10000 ps;
	CLOCK_50 <= '1';
	WAIT FOR 10000 ps;
	IF (NOW >= 25000000 ps) THEN WAIT; END IF;
END LOOP;
END PROCESS t_prcs_CLOCK_50;
END MC68K_arch;

//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.12 (64-bit)
//Part Number: GW5AT-LV60PG484AC1/I0
//Device: GW5AT-60
//Device Version: B
//Created Time: Sun Nov 23 14:50:15 2025

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	Integer_Division your_instance_name(
		.clk(clk), //input clk
		.rstn(rstn), //input rstn
		.dividend(dividend), //input [31:0] dividend
		.divisor(divisor), //input [31:0] divisor
		.quotient(quotient) //output [31:0] quotient
	);

//--------Copy end-------------------

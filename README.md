# mdif_parser
General MDIF parser for both simulated and measured data. 
First use `parsemdf.m` to create a general structure that includes all fields of the MDIF file. 
The script `formatstruct.m` then creates a non-scalar structure for use with other scripts, depending on the specified input/output voltages/currents.

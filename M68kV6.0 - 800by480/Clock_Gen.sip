set_global_assignment -entity "Clock_Gen" -library "lib_Clock_Gen" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "Clock_Gen" -library "lib_Clock_Gen" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "Clock_Gen" -library "lib_Clock_Gen" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_Clock_Gen" -name SPD_FILE [file join $::quartus(sip_path) "Clock_Gen.spd"]

set_global_assignment -library "lib_Clock_Gen" -name MISC_FILE [file join $::quartus(sip_path) "Clock_Gen_sim/Clock_Gen.vo"]

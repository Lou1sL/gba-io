
# source create_ila.tcl

# create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_buffer
# create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_cart
# create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_mux
# create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_usb

set_property -dict [list \
    CONFIG.C_NUM_OF_PROBES {22} \
    CONFIG.C_DATA_DEPTH {131072} \
    CONFIG.C_PROBE0_WIDTH {4} \
    CONFIG.C_PROBE1_WIDTH {26} \
    CONFIG.C_PROBE2_WIDTH {26} \
    CONFIG.C_PROBE3_WIDTH {19} \
    CONFIG.C_PROBE4_WIDTH {19} \
    CONFIG.C_PROBE5_WIDTH {2} \
    CONFIG.C_PROBE6_WIDTH {2} \
    CONFIG.C_PROBE7_WIDTH {2} \
    CONFIG.C_PROBE8_WIDTH {2} \
    CONFIG.C_PROBE9_WIDTH {2} \
    CONFIG.C_PROBE10_WIDTH {2} \
    CONFIG.C_PROBE11_WIDTH {2} \
    CONFIG.C_PROBE12_WIDTH {2} \
    CONFIG.C_PROBE13_WIDTH {2} \
    CONFIG.C_PROBE14_WIDTH {2} \
    CONFIG.C_PROBE15_WIDTH {2} \
    CONFIG.C_PROBE16_WIDTH {2} \
    CONFIG.C_PROBE17_WIDTH {2} \
    CONFIG.C_PROBE18_WIDTH {26} \
    CONFIG.C_PROBE19_WIDTH {19} \
    CONFIG.C_PROBE20_WIDTH {1} \
    CONFIG.C_PROBE21_WIDTH {1} \
] [get_ips ila_buffer]

set_property -dict [list \
    CONFIG.C_NUM_OF_PROBES {42} \
    CONFIG.C_DATA_DEPTH {131072} \
    CONFIG.C_PROBE0_WIDTH {1} \
    CONFIG.C_PROBE1_WIDTH {1} \
    CONFIG.C_PROBE2_WIDTH {1} \
    CONFIG.C_PROBE3_WIDTH {1} \
    CONFIG.C_PROBE4_WIDTH {1} \
    CONFIG.C_PROBE5_WIDTH {1} \
    CONFIG.C_PROBE6_WIDTH {1} \
    CONFIG.C_PROBE7_WIDTH {1} \
    CONFIG.C_PROBE8_WIDTH {1} \
    CONFIG.C_PROBE9_WIDTH {1} \
    CONFIG.C_PROBE10_WIDTH {1} \
    CONFIG.C_PROBE11_WIDTH {1} \
    CONFIG.C_PROBE12_WIDTH {25} \
    CONFIG.C_PROBE13_WIDTH {16} \
    CONFIG.C_PROBE14_WIDTH {1} \
    CONFIG.C_PROBE15_WIDTH {1} \
    CONFIG.C_PROBE16_WIDTH {1} \
    CONFIG.C_PROBE17_WIDTH {1} \
    CONFIG.C_PROBE18_WIDTH {1} \
    CONFIG.C_PROBE19_WIDTH {1} \
    CONFIG.C_PROBE20_WIDTH {26} \
    CONFIG.C_PROBE21_WIDTH {16} \
    CONFIG.C_PROBE22_WIDTH {16} \
    CONFIG.C_PROBE23_WIDTH {1} \
    CONFIG.C_PROBE24_WIDTH {1} \
    CONFIG.C_PROBE25_WIDTH {1} \
    CONFIG.C_PROBE26_WIDTH {1} \
    CONFIG.C_PROBE27_WIDTH {1} \
    CONFIG.C_PROBE28_WIDTH {16} \
    CONFIG.C_PROBE29_WIDTH {8} \
    CONFIG.C_PROBE30_WIDTH {1} \
    CONFIG.C_PROBE31_WIDTH {1} \
    CONFIG.C_PROBE32_WIDTH {1} \
    CONFIG.C_PROBE33_WIDTH {1} \
    CONFIG.C_PROBE34_WIDTH {1} \
    CONFIG.C_PROBE35_WIDTH {1} \
    CONFIG.C_PROBE36_WIDTH {1} \
    CONFIG.C_PROBE37_WIDTH {1} \
    CONFIG.C_PROBE38_WIDTH {1} \
    CONFIG.C_PROBE39_WIDTH {1} \
    CONFIG.C_PROBE40_WIDTH {1} \
    CONFIG.C_PROBE41_WIDTH {1} \
] [get_ips ila_cart]

set_property -dict [list \
    CONFIG.C_NUM_OF_PROBES {8} \
    CONFIG.C_DATA_DEPTH {131072} \
    CONFIG.C_PROBE0_WIDTH {4} \
    CONFIG.C_PROBE1_WIDTH {1} \
    CONFIG.C_PROBE2_WIDTH {1} \
    CONFIG.C_PROBE3_WIDTH {1} \
    CONFIG.C_PROBE4_WIDTH {1} \
    CONFIG.C_PROBE5_WIDTH {26} \
    CONFIG.C_PROBE6_WIDTH {32} \
    CONFIG.C_PROBE7_WIDTH {32} \
] [get_ips ila_mux]

set_property -dict [list \
    CONFIG.C_NUM_OF_PROBES {23} \
    CONFIG.C_DATA_DEPTH {131072} \
    CONFIG.C_PROBE0_WIDTH {8} \
    CONFIG.C_PROBE1_WIDTH {32} \
    CONFIG.C_PROBE2_WIDTH {32} \
    CONFIG.C_PROBE3_WIDTH {32} \
    CONFIG.C_PROBE4_WIDTH {1} \
    CONFIG.C_PROBE5_WIDTH {8} \
    CONFIG.C_PROBE6_WIDTH {72} \
    CONFIG.C_PROBE7_WIDTH {1} \
    CONFIG.C_PROBE8_WIDTH {1} \
    CONFIG.C_PROBE9_WIDTH {1} \
    CONFIG.C_PROBE10_WIDTH {32} \
    CONFIG.C_PROBE11_WIDTH {1} \
    CONFIG.C_PROBE12_WIDTH {1} \
    CONFIG.C_PROBE13_WIDTH {1} \
    CONFIG.C_PROBE14_WIDTH {32} \
    CONFIG.C_PROBE15_WIDTH {1} \
    CONFIG.C_PROBE16_WIDTH {1} \
    CONFIG.C_PROBE17_WIDTH {1} \
    CONFIG.C_PROBE18_WIDTH {32} \
    CONFIG.C_PROBE19_WIDTH {1} \
    CONFIG.C_PROBE20_WIDTH {1} \
    CONFIG.C_PROBE21_WIDTH {1} \
    CONFIG.C_PROBE22_WIDTH {32} \
] [get_ips ila_usb]

# generate_target all [get_ips ila_buffer]
# generate_target all [get_ips ila_cart]
# generate_target all [get_ips ila_mux]
# generate_target all [get_ips ila_usb]

set_param synth.elaboration.rodinMoreOptions {rt::set_parameter dissolveMemorySizeLimit 3212288}

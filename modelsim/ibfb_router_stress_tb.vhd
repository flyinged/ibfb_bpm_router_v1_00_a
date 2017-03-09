library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Needed for FIFO36
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use work.ibfb_comm_package.all;

entity ibfb_router_stress_tb is
end entity ibfb_router_stress_tb;

architecture test of ibfb_router_stress_tb is

component throughput_meter is
generic(
    CLK_FREQ_HZ     : real;
    DATA_WIDTH_BITS : real
);
port(
    i_clk, i_rst : in std_logic;
    i_data_valid : in std_logic;
    o_bps        : out real
);
end component throughput_meter;

constant K_SOP : std_logic_vector(7 downto 0) := X"FB";
constant K_EOP : std_logic_vector(7 downto 0) := X"FD";
constant N_BUCKETS : natural := 2700;

signal core_clk, rst, rst_n : std_logic;
--router
signal rout_in_next     : std_logic_vector(0 to 3-1);
signal rout_in_valid    : std_logic_vector(0 to 3-1);
signal rout_in_charisk  : array4(0 to 3-1);
signal rout_in_data     : array32(0 to 3-1);
signal rout_out_next    : std_logic_vector(0 to 2-1);
signal rout_out_valid   : std_logic_vector(0 to 2-1);
signal rout_out_err     : std_logic_vector(0 to 2-1);
signal rout_out_charisk : array4(0 to 2-1);
signal rout_out_data    : array32(0 to 2-1);

type uarray2  is array (natural range <>) of unsigned(1 downto 0);
type uarray16 is array (natural range <>) of unsigned(15 downto 0);
signal s    : uarray2(0 to 2);
signal dcnt : uarray16(0 to 2);

type rarray is array (natural range <>) of real;
signal rout_in_speed  : rarray(0 to 2);
signal rout_out_speed : rarray(0 to 1);

for all: ibfb_packet_router use entity work.ibfb_packet_router(no_pkt_buf);

begin

core_clk <= '0' after 6.4 ns   when core_clk = '1' else
            '1' after 6.4 ns;
rst_n    <= '0', '1' after 500 ns;
rst      <= not rst_n;

GEN_TXDATA : for i in 0 to 2 generate
    --generate continuous input data
    DGEN : process(core_clk)
    begin
        if rising_edge(core_clk) then
            if rst_n = '0' then
                dcnt(i) <= (others => '0');
                s(i)    <= "00";
            else
                if rout_in_next(i) = '1' then
                    if s(i) = "11" then
                        dcnt(i) <= dcnt(i)+1;
                    end if;
                    s(i) <= s(i)+1;
                end if;
            end if;
        end if;
    end process;
    rout_in_valid(i) <= rst_n; --data always valid
    rout_in_charisk(i) <= X"4" when s(i) = "00" else
                          X"1" when s(i) = "11" else
                          X"0";
    rout_in_data(i)    <= (X"00" & K_SOP & std_logic_vector(dcnt(i))) when s(i) = "00" else
                          (std_logic_vector(dcnt(i)) & X"00" & K_EOP) when s(i) = "11" else 
                          (std_logic_vector(dcnt(i)) & std_logic_vector(dcnt(i)));

    ROUT_IN_METER_i : throughput_meter
    generic map(
        CLK_FREQ_HZ     => 78.125,
        DATA_WIDTH_BITS => 32.0
    )
    port map(
        i_clk => core_clk, 
        i_rst => rst,
        i_data_valid => rout_in_next(i),
        o_bps        => rout_in_speed(i)
    );
end generate;

ROUTER : ibfb_packet_router 
generic map(
        K_SOP => K_SOP,
        K_EOP => K_EOP,
        N_INPUT_PORTS  => 3, --in0: local BPM, in1: xFPGA, in2: backplane
        N_OUTPUT_PORTS => 2, --out0: xFPGA, out1: backplane
        ROUTING_TABLE => (X"00000003", --IN0: local BPM => to both outputs
                          X"00000002", --IN1: xFPGA     => to backplane 
                          X"00000002", --IN2: Backplane => to backplane
                          X"FFFFFFFF", 
                          X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF",                              
                          X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF",                              
                          X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF",                              
                          X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF",                              
                          X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF",                              
                          X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF",                              
                          X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF")                              
)
port map(
    i_clk     => core_clk,
    i_rst     => rst,
    i_err_rst => '0',
    --input (FIFO, FWFT)
    o_next    => rout_in_next,
    i_valid   => rout_in_valid,
    i_charisk => rout_in_charisk,
    i_data    => rout_in_data,
    --output (STREAMING. i_next is used only to detect errors, but does not control data flow)
    i_next    => rout_out_next,
    o_valid   => rout_out_valid,
    o_err     => rout_out_err,
    o_charisk => rout_out_charisk,
    o_data    => rout_out_data
);

GEN_DATA_READ : for i in 0 to 1 generate
    --read continuously output data
    rout_out_next(i) <= rout_out_valid(i);
     
    ROUT_OUT_METER_i : throughput_meter
    generic map(
        CLK_FREQ_HZ     => 78.125,
        DATA_WIDTH_BITS => 32.0
    )
    port map(
        i_clk => core_clk, 
        i_rst => rst,
        i_data_valid => rout_out_valid(i),
        o_bps        => rout_out_speed(i)
    );
end generate;

end architecture test;

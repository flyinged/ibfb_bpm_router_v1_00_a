library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--textio
use STD.textio.all;
use work.txt_util.all;

--Needed for FIFO36
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use work.ibfb_comm_package.all;

entity ibfb_packet_router_tb is
end entity ibfb_packet_router_tb;

architecture test of ibfb_packet_router_tb is

----------------------------------------------------------------
--  Components declaration  ------------------------------------
----------------------------------------------------------------
component ibfb_bpm_emulator is
generic(
    BUNCH_TRIG_OFFSET  : time := 10 us;  --start delay of bunch trigger
    BUNCH_TRIG_DUR    : time := 500 ns; --bunch trigger high time
    PAUSE_AFTER_BUNCH  : time := 100 us; --time between last bucket and next bunch trigger
    FIRST_BUCKET_DELAY : time := 1 us;   --bunch trigger to 1st bucket delay
    BKT_TRIG_DUR      : time := 50 ns;  --bucket trigger high time
    BKT_TRIG_PERIOD   : time := 222 ns; --time between bucket triggers
    N_BUCKETS         : natural := 2700; --number of buckets
    K_SOP             : std_logic_vector(7 downto 0) := X"FB";
    K_EOP             : std_logic_vector(7 downto 0) := X"FD"
);
port(
    i_adc_clk      : in  std_logic;
    i_core_clk     : in  std_logic;
    i_core_rst_n   : in  std_logic;
    i_enable       : in  std_logic;
    i_bpm_id       : in  std_logic_vector(7 downto 0);
    o_bunch_trig    : out std_logic;
    o_bkt_trig      : out std_logic;
    o_pkt_fifo_werr : out std_logic;
    o_pkt_fifo_rerr : out std_logic;
    --Cross FPGA link
    --RX FIFO
    o_xf_rxf_rerr  : out std_logic;
    o_xf_rxf_werr  : out std_logic;
    o_xf_rxf_full  : out std_logic;
    i_xf_rxf_wr    : in  std_logic;
    i_xf_rxf_isk   : in  std_logic_vector(3 downto 0);
    i_xf_rxf_data  : in  std_logic_vector(31 downto 0);
    --TX FIFO
    o_xf_txf_rerr  : out std_logic;
    o_xf_txf_werr  : out std_logic;
    o_xf_txf_empty : out std_logic;
    i_xf_txf_next  : in  std_logic;
    o_xf_txf_isk   : out std_logic_vector(3 downto 0);
    o_xf_txf_data  : out std_logic_vector(31 downto 0);
    --Backplane link
    --RX FIFO
    o_bp_rxf_rerr  : out std_logic;
    o_bp_rxf_werr  : out std_logic;
    o_bp_rxf_full  : out std_logic;
    i_bp_rxf_wr    : in  std_logic;
    i_bp_rxf_isk   : in  std_logic_vector(3 downto 0);
    i_bp_rxf_data  : in  std_logic_vector(31 downto 0);
    --TX FIFO
    o_bp_txf_rerr  : out std_logic;
    o_bp_txf_werr  : out std_logic;
    o_bp_txf_empty : out std_logic;
    i_bp_txf_next  : in  std_logic;
    o_bp_txf_isk   : out std_logic_vector(3 downto 0);
    o_bp_txf_data  : out std_logic_vector(31 downto 0)
);
end component ibfb_bpm_emulator;

component xfpga_link_emulator is
generic(
    LINK_DELAY : time := 200 ns 
);
port(
    o_rxf_overflow : out std_logic;
    --Connect to TX FIFO
    i_txf_empty : in  std_logic;
    o_txf_next  : out std_logic;
    i_txf_isk   : in  std_logic_vector(3 downto 0);
    i_txf_data  : in  std_logic_vector(31 downto 0);
    --Connect to RX FIFO
    i_rxf_full  : in  std_logic;
    o_rxf_wr    : out std_logic;
    o_rxf_isk   : out std_logic_vector(3 downto 0);
    o_rxf_data  : out std_logic_vector(31 downto 0)
);
end component xfpga_link_emulator;

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
----------------------------------------------------------------
--  Signals declaration  ---------------------------------------
----------------------------------------------------------------
signal clk166, core_clk, rx_clk : std_logic;
signal rst, rst_n, fifo_rst : std_logic;
signal sr : std_logic_vector(3 downto 0);
signal bpm_enable : std_logic_vector(0 to 3);

--Cross-FPGA RX FIFOs
signal xf_rxf_overflow : std_logic_vector(0 to 3);
signal xf_rxf_full : std_logic_vector(0 to 3);
signal xf_rxf_wr   : std_logic_vector(0 to 3);
signal xf_rxf_isk  : array4(0 to 3);
signal xf_rxf_data : array32(0 to 3);
--Cross-FPGA TX FIFOs
signal xf_txf_empty : std_logic_vector(0 to 3);
signal xf_txf_next  : std_logic_vector(0 to 3);
signal xf_txf_isk   : array4(0 to 3);
signal xf_txf_data  : array32(0 to 3);
--Backplane RX FIFOs
signal bp_rxf_full : std_logic_vector(0 to 3);
signal bp_rxf_wr   : std_logic_vector(0 to 3);
signal bp_rxf_isk  : array4(0 to 3);
signal bp_rxf_data : array32(0 to 3);
--Backplane TX FIFOs
signal bp_txf_valid : std_logic_vector(0 to 3);
signal bp_txf_empty : std_logic_vector(0 to 3);
signal bp_txf_next  : std_logic_vector(0 to 3);
signal bp_txf_isk   : array4(0 to 3);
signal bp_txf_data  : array32(0 to 3);

--Terminal receivers' signals
signal us_rxf_full, us_rxf_wr, us_rxf_empty, us_rxf_next, us_rxf_valid : std_logic;
signal us_rxf_wisk,  us_rxf_risk  : std_logic_vector(3 downto 0);
signal us_rxf_wdata, us_rxf_rdata : std_logic_vector(31 downto 0);
signal upstream_bad, upstream_eop, upstream_crcgood : std_logic;
signal upstream_data : ibfb_comm_packet;

signal ds_rxf_full, ds_rxf_wr, ds_rxf_empty, ds_rxf_next, ds_rxf_valid : std_logic;
signal ds_rxf_wisk,  ds_rxf_risk  : std_logic_vector(3 downto 0);
signal ds_rxf_wdata, ds_rxf_rdata : std_logic_vector(31 downto 0);
signal dnstream_bad, dnstream_eop, dnstream_crcgood : std_logic;
signal dnstream_data : ibfb_comm_packet;

--fifo errors
signal bunch_trig, bkt_trig : std_logic_vector(0 to 3);
signal pkt_rxf_werr, pkt_rxf_rerr : std_logic_vector(0 to 3);
signal us_rxf_werr, us_rxf_rerr : std_logic;
signal ds_rxf_werr, ds_rxf_rerr : std_logic;
signal xf_rxf_werr : std_logic_vector(0 to 3);
signal xf_rxf_rerr : std_logic_vector(0 to 3);
signal xf_txf_werr : std_logic_vector(0 to 3);
signal xf_txf_rerr : std_logic_vector(0 to 3);
signal bp_rxf_werr : std_logic_vector(0 to 3);
signal bp_rxf_rerr : std_logic_vector(0 to 3);
signal bp_txf_werr : std_logic_vector(0 to 3);
signal bp_txf_rerr : std_logic_vector(0 to 3);
--debug counters
signal ds_cnt_0, ds_cnt_1, ds_cnt_2, ds_cnt_3, ds_cnt_err : natural;
signal us_cnt_0, us_cnt_1, us_cnt_2, us_cnt_3, us_cnt_err : natural;
--speed meters
type rarray is array (natural range <>) of real;
signal xf_txf_speed, xf_rxf_speed, bp_txf_speed, bp_rxf_speed : rarray(0 to 3);
signal ds_rxf_speed_w, ds_rxf_speed_r : real;
signal us_rxf_speed_w, us_rxf_speed_r : real;

--CONSTANTS
constant K_SOP : std_logic_vector(7 downto 0) := X"FB";
constant K_EOP : std_logic_vector(7 downto 0) := X"FD";
constant N_BUCKETS : natural := 2700;
constant MGT_LATENCY : time := 130 ns;

--FILE IO
signal timer : natural;
file us_file : TEXT open write_mode is "upstream.csv";
file ds_file : TEXT open write_mode is "downstream.csv";

begin

--ASSERTION
assert (pkt_rxf_werr = X"0") report "PKT FIFO OVERFLOW" severity error;
assert (pkt_rxf_rerr = X"0") report "PKT FIFO UNDERFLOW" severity error;
assert (us_rxf_werr = '0')  report "UPSTREAM RX FIFO OVERFLOW" severity error;
assert (us_rxf_rerr = '0')  report "UPSTREAM RX FIFO UNDERFLOW" severity error;
assert (ds_rxf_werr = '0')  report "DOWNSTREAM RX FIFO OVERFLOW" severity error;
assert (ds_rxf_rerr = '0')  report "DOWNSTREAM RX FIFO UNDERFLOW" severity error;
assert (xf_rxf_werr = X"0") report "XFPGA RX FIFO OVERFLOW" severity error;
assert (xf_rxf_rerr = X"0") report "XFPGA RX FIFO UNDERFLOW" severity error;
assert (xf_txf_werr = X"0") report "XFPGA TX FIFO OVERFLOW" severity error;
assert (xf_txf_rerr = X"0") report "XFPGA TX FIFO UNDERFLOW" severity error;
assert (bp_rxf_werr = X"0") report "BACKPLANE RX FIFO OVERFLOW" severity error;
assert (bp_rxf_rerr = X"0") report "BACKPLANE RX FIFO UNDERFLOW" severity error;
assert (bp_txf_werr = X"0") report "BACKPLANE TX FIFO OVERFLOW" severity error;
assert (bp_txf_rerr = X"0") report "BACKPLANE TX FIFO UNDERFLOW" severity error;

--Data synthesis section
clk166   <= '0' after 3 ns when clk166   = '1' else
            '1' after 3 ns;
core_clk <= '0' after 6.4 ns   when core_clk = '1' else
            '1' after 6.4 ns;
rx_clk   <= '0' after 5.5 ns   when rx_clk   = '1' else
            '1' after 5.5 ns;
rst_n    <= '0', '1' after 500 ns;
rst      <= not rst_n;

FIFO_RST_P : process(core_clk)
begin
    if rising_edge(core_clk) then
        sr <= sr(sr'left-1 downto 0) & rst;
    end if;
end process;
fifo_rst <= rst or sr(0) or sr(1);

bpm_enable(0) <= '1';
bpm_enable(1) <= '1';
bpm_enable(2) <= '1';
bpm_enable(3) <= '1';

---------------------------------------------------------
--  BPM EMULATORS  --------------------------------------
---------------------------------------------------------
--FIRST BPM IN DOWNSTREAM CHAIN, LAST IN UPSTREAM CHAIN
BPM0_EMU : ibfb_bpm_emulator
generic map(
    BUNCH_TRIG_OFFSET  => 1000 ns,  --start delay of bunch trigger
    BUNCH_TRIG_DUR    => 500 ns, --bunch trigger high time
    PAUSE_AFTER_BUNCH  => 100 us,
    FIRST_BUCKET_DELAY => 10 us,   --bunch trigger to 1st bucket delay
    BKT_TRIG_DUR      => 50 ns,  --bucket trigger high time
    BKT_TRIG_PERIOD   => 222 ns, --time between bucket triggers
    N_BUCKETS         => N_BUCKETS, --number of buckets
    K_SOP             => K_SOP,
    K_EOP             => K_EOP
)
port map(
    i_adc_clk      => clk166,
    i_core_clk     => core_clk,
    i_core_rst_n   => rst_n,
    i_enable       => bpm_enable(0),
    i_bpm_id       => X"AA",
    o_bunch_trig   => bunch_trig(0),
    o_bkt_trig     => bkt_trig(0),
    o_pkt_fifo_werr => pkt_rxf_werr(0),
    o_pkt_fifo_rerr => pkt_rxf_rerr(0),
    --Cross FPGA link
    o_xf_rxf_werr  => xf_rxf_werr(0),
    o_xf_rxf_rerr  => xf_rxf_rerr(0),
    o_xf_txf_werr  => xf_txf_werr(0),
    o_xf_txf_rerr  => xf_txf_rerr(0),
    o_bp_rxf_werr  => bp_rxf_werr(0),
    o_bp_rxf_rerr  => bp_rxf_rerr(0),
    o_bp_txf_werr  => bp_txf_werr(0),
    o_bp_txf_rerr  => bp_txf_rerr(0),
    --RX FIFO
    o_xf_rxf_full  => xf_rxf_full(0),
    i_xf_rxf_wr    => xf_rxf_wr(0),
    i_xf_rxf_isk   => xf_rxf_isk(0),
    i_xf_rxf_data  => xf_rxf_data(0),
    --TX FIFO
    o_xf_txf_empty => xf_txf_empty(0),
    i_xf_txf_next  => xf_txf_next(0),
    o_xf_txf_isk   => xf_txf_isk(0),
    o_xf_txf_data  => xf_txf_data(0),
    --Backplane link
    --RX FIFO
    o_bp_rxf_full  => bp_rxf_full(0),
    i_bp_rxf_wr    => bp_rxf_wr(0),
    i_bp_rxf_isk   => bp_rxf_isk(0),
    i_bp_rxf_data  => bp_rxf_data(0),
    --TX FIFO
    o_bp_txf_empty => bp_txf_empty(0),
    i_bp_txf_next  => bp_txf_next(0),
    o_bp_txf_isk   => bp_txf_isk(0),
    o_bp_txf_data  => bp_txf_data(0)
);



--SECOND BPM IN DOWNSTREAM CHAIN, THIRS IN UPSTREAM CHAIN
BPM1_EMU : ibfb_bpm_emulator
generic map(
    BUNCH_TRIG_OFFSET  => 1085 ns,  --start delay of bunch trigger
    BUNCH_TRIG_DUR    => 500 ns, --bunch trigger high time
    PAUSE_AFTER_BUNCH  => 100 us,
    FIRST_BUCKET_DELAY => 10 us,   --bunch trigger to 1st bucket delay
    BKT_TRIG_DUR      => 50 ns,  --bucket trigger high time
    BKT_TRIG_PERIOD   => 222 ns, --time between bucket triggers
    N_BUCKETS         => N_BUCKETS, --number of buckets
    K_SOP             => K_SOP,
    K_EOP             => K_EOP
)
port map(
    i_adc_clk      => clk166,
    i_core_clk     => core_clk,
    i_core_rst_n   => rst_n,
    i_enable       => bpm_enable(1),
    i_bpm_id       => X"BB",
    o_bunch_trig   => bunch_trig(1),
    o_bkt_trig     => bkt_trig(2),
    o_pkt_fifo_werr => pkt_rxf_werr(1),
    o_pkt_fifo_rerr => pkt_rxf_rerr(1),
    --Cross FPGA link
    o_xf_rxf_werr  => xf_rxf_werr(1),
    o_xf_rxf_rerr  => xf_rxf_rerr(1),
    o_xf_txf_werr  => xf_txf_werr(1),
    o_xf_txf_rerr  => xf_txf_rerr(1),
    o_bp_rxf_werr  => bp_rxf_werr(1),
    o_bp_rxf_rerr  => bp_rxf_rerr(1),
    o_bp_txf_werr  => bp_txf_werr(1),
    o_bp_txf_rerr  => bp_txf_rerr(1),
    --RX FIFO
    o_xf_rxf_full  => xf_rxf_full(1),
    i_xf_rxf_wr    => xf_rxf_wr(1),
    i_xf_rxf_isk   => xf_rxf_isk(1),
    i_xf_rxf_data  => xf_rxf_data(1),
    --TX FIFO
    o_xf_txf_empty => xf_txf_empty(1),
    i_xf_txf_next  => xf_txf_next(1),
    o_xf_txf_isk   => xf_txf_isk(1),
    o_xf_txf_data  => xf_txf_data(1),
    --Backplane link
    --RX FIFO
    o_bp_rxf_full  => bp_rxf_full(1),
    i_bp_rxf_wr    => bp_rxf_wr(1),
    i_bp_rxf_isk   => bp_rxf_isk(1),
    i_bp_rxf_data  => bp_rxf_data(1),
    --TX FIFO
    o_bp_txf_empty => bp_txf_empty(1),
    i_bp_txf_next  => bp_txf_next(1),
    o_bp_txf_isk   => bp_txf_isk(1),
    o_bp_txf_data  => bp_txf_data(1)
);

--THIRD BPM IN DOWNSTREAM CHAIN, SECOND IN UPSTREAM CHAIN
BPM2_EMU : ibfb_bpm_emulator
generic map(
    BUNCH_TRIG_OFFSET  => 1205 ns,  --start delay of bunch trigger
    BUNCH_TRIG_DUR    => 500 ns, --bunch trigger high time
    PAUSE_AFTER_BUNCH  => 100 us,
    FIRST_BUCKET_DELAY => 10 us,   --bunch trigger to 1st bucket delay
    BKT_TRIG_DUR      => 50 ns,  --bucket trigger high time
    BKT_TRIG_PERIOD   => 222 ns, --time between bucket triggers
    N_BUCKETS         => N_BUCKETS, --number of buckets
    K_SOP             => K_SOP,
    K_EOP             => K_EOP
)
port map(
    i_adc_clk      => clk166,
    i_core_clk     => core_clk,
    i_core_rst_n   => rst_n,
    i_enable       => bpm_enable(2),
    i_bpm_id       => X"CC",
    o_bunch_trig   => bunch_trig(2),
    o_bkt_trig     => bkt_trig(2),
    o_pkt_fifo_werr => pkt_rxf_werr(2),
    o_pkt_fifo_rerr => pkt_rxf_rerr(2),
    --Cross FPGA link
    o_xf_rxf_werr  => xf_rxf_werr(2),
    o_xf_rxf_rerr  => xf_rxf_rerr(2),
    o_xf_txf_werr  => xf_txf_werr(2),
    o_xf_txf_rerr  => xf_txf_rerr(2),
    o_bp_rxf_werr  => bp_rxf_werr(2),
    o_bp_rxf_rerr  => bp_rxf_rerr(2),
    o_bp_txf_werr  => bp_txf_werr(2),
    o_bp_txf_rerr  => bp_txf_rerr(2),
    --RX FIFO
    o_xf_rxf_full  => xf_rxf_full(2),
    i_xf_rxf_wr    => xf_rxf_wr(2),
    i_xf_rxf_isk   => xf_rxf_isk(2),
    i_xf_rxf_data  => xf_rxf_data(2),
    --TX FIFO
    o_xf_txf_empty => xf_txf_empty(2),
    i_xf_txf_next  => xf_txf_next(2),
    o_xf_txf_isk   => xf_txf_isk(2),
    o_xf_txf_data  => xf_txf_data(2),
    --Backplane link
    --RX FIFO
    o_bp_rxf_full  => bp_rxf_full(2),
    i_bp_rxf_wr    => bp_rxf_wr(2),
    i_bp_rxf_isk   => bp_rxf_isk(2),
    i_bp_rxf_data  => bp_rxf_data(2),
    --TX FIFO
    o_bp_txf_empty => bp_txf_empty(2),
    i_bp_txf_next  => bp_txf_next(2),
    o_bp_txf_isk   => bp_txf_isk(2),
    o_bp_txf_data  => bp_txf_data(2)
);

--LAST BPM IN DOWNSTREAM CHAIN, FIRST IN UPSTREAM CHAIN
BPM3_EMU : ibfb_bpm_emulator
generic map(
    BUNCH_TRIG_OFFSET  => 1252 ns,  --start delay of bunch trigger
    BUNCH_TRIG_DUR    => 500 ns, --bunch trigger high time
    PAUSE_AFTER_BUNCH  => 100 us,
    FIRST_BUCKET_DELAY => 10 us,   --bunch trigger to 1st bucket delay
    BKT_TRIG_DUR      => 50 ns,  --bucket trigger high time
    BKT_TRIG_PERIOD   => 222 ns, --time between bucket triggers
    N_BUCKETS         => N_BUCKETS, --number of buckets
    K_SOP             => K_SOP,
    K_EOP             => K_EOP
)
port map(
    i_adc_clk      => clk166,
    i_core_clk     => core_clk,
    i_core_rst_n   => rst_n,
    i_enable       => bpm_enable(3),
    i_bpm_id       => X"DD",
    o_bunch_trig   => bunch_trig(3),
    o_bkt_trig     => bkt_trig(3),
    o_pkt_fifo_werr => pkt_rxf_werr(3),
    o_pkt_fifo_rerr => pkt_rxf_rerr(3),
    --Cross FPGA link
    o_xf_rxf_werr  => xf_rxf_werr(3),
    o_xf_rxf_rerr  => xf_rxf_rerr(3),
    o_xf_txf_werr  => xf_txf_werr(3),
    o_xf_txf_rerr  => xf_txf_rerr(3),
    o_bp_rxf_werr  => bp_rxf_werr(3),
    o_bp_rxf_rerr  => bp_rxf_rerr(3),
    o_bp_txf_werr  => bp_txf_werr(3),
    o_bp_txf_rerr  => bp_txf_rerr(3),
    --RX FIFO
    o_xf_rxf_full  => xf_rxf_full(3),
    i_xf_rxf_wr    => xf_rxf_wr(3),
    i_xf_rxf_isk   => xf_rxf_isk(3),
    i_xf_rxf_data  => xf_rxf_data(3),
    --TX FIFO
    o_xf_txf_empty => xf_txf_empty(3),
    i_xf_txf_next  => xf_txf_next(3),
    o_xf_txf_isk   => xf_txf_isk(3),
    o_xf_txf_data  => xf_txf_data(3),
    --Backplane link
    --RX FIFO
    o_bp_rxf_full  => bp_rxf_full(3),
    i_bp_rxf_wr    => bp_rxf_wr(3),
    i_bp_rxf_isk   => bp_rxf_isk(3),
    i_bp_rxf_data  => bp_rxf_data(3),
    --TX FIFO
    o_bp_txf_empty => bp_txf_empty(3),
    i_bp_txf_next  => bp_txf_next(3),
    o_bp_txf_isk   => bp_txf_isk(3),
    o_bp_txf_data  => bp_txf_data(3)
);

--DEBUG: speed meters
METER_GEN : for i in 0 to 3 generate

    XF_RXF_METER_i : throughput_meter
    generic map(
        CLK_FREQ_HZ     => 78.125,
        DATA_WIDTH_BITS => 32.0
    )
    port map(
        i_clk => core_clk, 
        i_rst => rst,
        i_data_valid => xf_rxf_wr(i),
        o_bps        => xf_rxf_speed(i)
    );
    XF_TXF_METER_i : throughput_meter
    generic map(
        CLK_FREQ_HZ     => 78.125,
        DATA_WIDTH_BITS => 32.0
    )
    port map(
        i_clk => core_clk, 
        i_rst => rst,
        i_data_valid => xf_txf_next(i),
        o_bps        => xf_txf_speed(i)
    );
    BP_RXF_METER_i : throughput_meter
    generic map(
        CLK_FREQ_HZ     => 78.125,
        DATA_WIDTH_BITS => 32.0
    )
    port map(
        i_clk => core_clk, 
        i_rst => rst,
        i_data_valid => bp_rxf_wr(i),
        o_bps        => bp_rxf_speed(i)
    );
    BP_TXF_METER_i : throughput_meter
    generic map(
        CLK_FREQ_HZ     => 78.125,
        DATA_WIDTH_BITS => 32.0
    )
    port map(
        i_clk => core_clk, 
        i_rst => rst,
        i_data_valid => bp_txf_next(i),
        o_bps        => bp_txf_speed(i)
    );
end generate;

---------------------------------------------------------
--  CROSS-FPGA INTERCONNECTIONS  ------------------------
---------------------------------------------------------
--BPM0 => BPM1
XFPGA_01 : xfpga_link_emulator
generic map(
    LINK_DELAY => MGT_LATENCY
)
port map(
    o_rxf_overflow => xf_rxf_overflow(1),
    --connect to TX FIFO
    i_txf_empty => xf_txf_empty(0),
    o_txf_next  => xf_txf_next(0),
    i_txf_isk   => xf_txf_isk(0),
    i_txf_data  => xf_txf_data(0),
    --connect to RX FIFO
    i_rxf_full  => xf_rxf_full(1),
    o_rxf_wr    => xf_rxf_wr(1),
    o_rxf_isk   => xf_rxf_isk(1),
    o_rxf_data  => xf_rxf_data(1)
);

--BPM1 => BPM0
XFPGA_10 : xfpga_link_emulator
generic map(
    LINK_DELAY => 200 ns 
)
port map(
    o_rxf_overflow => xf_rxf_overflow(0),
    --connect to TX FIFO
    i_txf_empty => xf_txf_empty(1),
    o_txf_next  => xf_txf_next(1),
    i_txf_isk   => xf_txf_isk(1),
    i_txf_data  => xf_txf_data(1),
    --connect to RX FIFO
    i_rxf_full  => xf_rxf_full(0),
    o_rxf_wr    => xf_rxf_wr(0),
    o_rxf_isk   => xf_rxf_isk(0),
    o_rxf_data  => xf_rxf_data(0)
);

--BPM2 => BPM3
XFPGA_23 : xfpga_link_emulator
generic map(
    LINK_DELAY => MGT_LATENCY
)
port map(
    o_rxf_overflow => xf_rxf_overflow(3),
    --connect to TX FIFO
    i_txf_empty => xf_txf_empty(2),
    o_txf_next  => xf_txf_next(2),
    i_txf_isk   => xf_txf_isk(2),
    i_txf_data  => xf_txf_data(2),
    --connect to RX FIFO
    i_rxf_full  => xf_rxf_full(3),
    o_rxf_wr    => xf_rxf_wr(3),
    o_rxf_isk   => xf_rxf_isk(3),
    o_rxf_data  => xf_rxf_data(3)
);

--BPM3 => BPM2
XFPGA_32 : xfpga_link_emulator
generic map(
    LINK_DELAY => MGT_LATENCY
)
port map(
    o_rxf_overflow => xf_rxf_overflow(2),
    --connect to TX FIFO
    i_txf_empty => xf_txf_empty(3),
    o_txf_next  => xf_txf_next(3),
    i_txf_isk   => xf_txf_isk(3),
    i_txf_data  => xf_txf_data(3),
    --connect to RX FIFO
    i_rxf_full  => xf_rxf_full(2),
    o_rxf_wr    => xf_rxf_wr(2),
    o_rxf_isk   => xf_rxf_isk(2),
    o_rxf_data  => xf_rxf_data(2)
);

---------------------------------------------------------
--  BACKPLANE INTERCONNECTIONS  -------------------------
---------------------------------------------------------
--BP0 => UPSTREAM RECEIVER
BP0_USRX : xfpga_link_emulator
generic map(
    LINK_DELAY => MGT_LATENCY
)
port map(
    o_rxf_overflow => open,
    --connect to TX FIFO
    i_txf_empty => bp_txf_empty(0),
    o_txf_next  => bp_txf_next(0),
    i_txf_isk   => bp_txf_isk(0),
    i_txf_data  => bp_txf_data(0),
    --connect to RX FIFO
    i_rxf_full  => us_rxf_full,
    o_rxf_wr    => us_rxf_wr,
    o_rxf_isk   => us_rxf_wisk,
    o_rxf_data  => us_rxf_wdata
);

--BP1 => BP3 (DOWNSTREAM)
BP13 : xfpga_link_emulator
generic map(
    LINK_DELAY => MGT_LATENCY
)
port map(
    o_rxf_overflow => open,
    --connect to TX FIFO
    i_txf_empty => bp_txf_empty(1),
    o_txf_next  => bp_txf_next(1),
    i_txf_isk   => bp_txf_isk(1),
    i_txf_data  => bp_txf_data(1),
    --connect to RX FIFO
    i_rxf_full  => bp_rxf_full(3),
    o_rxf_wr    => bp_rxf_wr(3),
    o_rxf_isk   => bp_rxf_isk(3),
    o_rxf_data  => bp_rxf_data(3)
);

--BP2 => BP0 (UPSTREAM)
BP20 : xfpga_link_emulator
generic map(
    LINK_DELAY => MGT_LATENCY
)
port map(
    o_rxf_overflow => open,
    --connect to TX FIFO
    i_txf_empty => bp_txf_empty(2),
    o_txf_next  => bp_txf_next(2),
    i_txf_isk   => bp_txf_isk(2),
    i_txf_data  => bp_txf_data(2),
    --connect to RX FIFO
    i_rxf_full  => bp_rxf_full(0),
    o_rxf_wr    => bp_rxf_wr(0),
    o_rxf_isk   => bp_rxf_isk(0),
    o_rxf_data  => bp_rxf_data(0)
);

--BP3 => DOWNSTREAM RECEIVER
BP3_DSRX : xfpga_link_emulator
generic map(
    LINK_DELAY => MGT_LATENCY
)
port map(
    o_rxf_overflow => open,
    --connect to TX FIFO
    i_txf_empty => bp_txf_empty(3),
    o_txf_next  => bp_txf_next(3),
    i_txf_isk   => bp_txf_isk(3),
    i_txf_data  => bp_txf_data(3),
    --connect to RX FIFO
    i_rxf_full  => ds_rxf_full,
    o_rxf_wr    => ds_rxf_wr,
    o_rxf_isk   => ds_rxf_wisk,
    o_rxf_data  => ds_rxf_wdata
);


---------------------------------------------------------
--  UPSTREAM RECEIVER & FIFO  ---------------------------
---------------------------------------------------------



--Emulated MGT RXFIFO
UPSTREAM_RXFIFO : FIFO36
generic map(
    DATA_WIDTH              => 36,
    ALMOST_FULL_OFFSET      => X"0010", --ALMOST_FULL when EMPTY LOCATIONS are less than this value
    ALMOST_EMPTY_OFFSET     => X"0010", --ALMOST_EMPTY when FULL LOCATIONS are less than this value
    DO_REG                  => 1, --pipeline register. Must be enable for asynchronous operation
    EN_SYN                  => FALSE, --synchronous/asynchronous mode
    FIRST_WORD_FALL_THROUGH => TRUE
)
port map(
    RST         => fifo_rst, --must be asserted for at least 3 clock cycles
    --
    WRCLK       => core_clk,
    FULL        => us_rxf_full,
    ALMOSTFULL  => open,
    WREN        => us_rxf_wr,
    WRCOUNT     => open,
    WRERR       => us_rxf_werr,
    DIP         => us_rxf_wisk,
    DI          => us_rxf_wdata,
    --
    RDCLK       => rx_clk, --need more bandwidth for CRC calculation
    EMPTY       => us_rxf_empty,
    ALMOSTEMPTY => open,
    RDEN        => us_rxf_next,
    RDCOUNT     => open,
    RDERR       => us_rxf_rerr,
    DOP         => us_rxf_risk,
    DO          => us_rxf_rdata
);

us_rxf_valid <= not us_rxf_empty;

--Upstream receiver
UPSTREAM_RX : ibfb_packet_rx
generic map(
    K_SOP => K_SOP,
    K_EOP => K_EOP
)
port map(
    i_rst => rst,
    i_clk => rx_clk, --faster
    --MGT FIFO interface
    o_next      => us_rxf_next,
    i_valid     => us_rxf_valid,
    i_charisk   => us_rxf_risk,
    i_data      => us_rxf_rdata,
    --user interface
    o_bad_data => upstream_bad,
    o_eop      => upstream_eop,
    o_crc_good => upstream_crcgood,
    o_rx_data  => upstream_data,
    --debug
    o_csp_clk   => open,
    o_csp_data  => open
);

---------------------------------------------------------
--  DOWNSTREAM RECEIVER & FIFO  -------------------------
---------------------------------------------------------
--Emulated MGT RXFIFO
DOWNSTREAM_RXFIFO : FIFO36
generic map(
    DATA_WIDTH              => 36,
    ALMOST_FULL_OFFSET      => X"0010", --ALMOST_FULL when EMPTY LOCATIONS are less than this value
    ALMOST_EMPTY_OFFSET     => X"0010", --ALMOST_EMPTY when FULL LOCATIONS are less than this value
    DO_REG                  => 1, --pipeline register. Must be enable for asynchronous operation
    EN_SYN                  => FALSE, --synchronous/asynchronous mode
    FIRST_WORD_FALL_THROUGH => TRUE
)
port map(
    RST         => fifo_rst, --must be asserted for at least 3 clock cycles
    --
    WRCLK       => core_clk,
    FULL        => ds_rxf_full,
    ALMOSTFULL  => open,
    WREN        => ds_rxf_wr,
    WRCOUNT     => open,
    WRERR       => ds_rxf_werr,
    DIP         => ds_rxf_wisk,
    DI          => ds_rxf_wdata,
    --
    RDCLK       => rx_clk, --need more bandwidth for crc calculation
    EMPTY       => ds_rxf_empty,
    ALMOSTEMPTY => open,
    RDEN        => ds_rxf_next,
    RDCOUNT     => open,
    RDERR       => ds_rxf_rerr,
    DOP         => ds_rxf_risk,
    DO          => ds_rxf_rdata
);

ds_rxf_valid <= not ds_rxf_empty;


DOWNSTREAM_RX : ibfb_packet_rx
generic map(
    K_SOP => K_SOP,
    K_EOP => K_EOP
)
port map(
    i_rst => rst,
    i_clk => rx_clk, --faster
    --MGT FIFO interface
    o_next      => ds_rxf_next,
    i_valid     => ds_rxf_valid,
    i_charisk   => ds_rxf_risk,
    i_data      => ds_rxf_rdata,
    --user interface
    o_bad_data => dnstream_bad,
    o_eop      => dnstream_eop,
    o_crc_good => dnstream_crcgood,
    o_rx_data  => dnstream_data,
    --debug
    o_csp_clk   => open,
    o_csp_data  => open
);

--METERS
US_RXF_W_METER : throughput_meter
generic map(
    CLK_FREQ_HZ     => 78.125,
    DATA_WIDTH_BITS => 32.0
)
port map(
    i_clk => core_clk, 
    i_rst => rst,
    i_data_valid => us_rxf_wr,
    o_bps        => us_rxf_speed_w
);
US_RXF_R_METER : throughput_meter
generic map(
    CLK_FREQ_HZ     => 78.125,
    DATA_WIDTH_BITS => 32.0
)
port map(
    i_clk => core_clk, 
    i_rst => rst,
    i_data_valid => us_rxf_next,
    o_bps        => us_rxf_speed_r
);
DS_RXF_W_METER : throughput_meter
generic map(
    CLK_FREQ_HZ     => 78.125,
    DATA_WIDTH_BITS => 32.0
)
port map(
    i_clk => core_clk, 
    i_rst => rst,
    i_data_valid => ds_rxf_wr,
    o_bps        => ds_rxf_speed_w
);
DS_RXF_R_METER : throughput_meter
generic map(
    CLK_FREQ_HZ     => 78.125,
    DATA_WIDTH_BITS => 32.0
)
port map(
    i_clk => core_clk, 
    i_rst => rst,
    i_data_valid => ds_rxf_next,
    o_bps        => ds_rxf_speed_r
);

--COUNT packets with same BPM_ID
DS_RXCNT : process(rx_clk)
begin
    if rising_edge(rx_clk) then
        if rst = '1' then
            ds_cnt_0   <= 0;
            ds_cnt_1   <= 0;
            ds_cnt_2   <= 0;
            ds_cnt_3   <= 0;
            ds_cnt_err <= 0;
        elsif dnstream_eop = '1' then
            if dnstream_data.bpm = X"AA" then 
                ds_cnt_0 <= ds_cnt_0+1;
            end if;
            if dnstream_data.bpm = X"BB" then 
                ds_cnt_1 <= ds_cnt_1+1;
            end if;
            if dnstream_data.bpm = X"CC" then 
                ds_cnt_2 <= ds_cnt_2+1;
            end if;
            if dnstream_data.bpm = X"DD" then 
                ds_cnt_3 <= ds_cnt_3+1;
            end if;
            if dnstream_crcgood = '0' then 
                ds_cnt_err <= ds_cnt_err+1;
            end if;
        end if;
    end if;
end process;

US_RXCNT : process(rx_clk)
begin
    if rising_edge(rx_clk) then
        if rst = '1' then
            us_cnt_0   <= 0;
            us_cnt_1   <= 0;
            us_cnt_2   <= 0;
            us_cnt_3   <= 0;
            us_cnt_err <= 0;
        elsif upstream_eop = '1' then
            if upstream_data.bpm = X"AA" then 
                us_cnt_0 <= us_cnt_0+1;
            end if;
            if upstream_data.bpm = X"BB" then 
                us_cnt_1 <= us_cnt_1+1;
            end if;
            if upstream_data.bpm = X"CC" then 
                us_cnt_2 <= us_cnt_2+1;
            end if;
            if upstream_data.bpm = X"DD" then 
                us_cnt_3 <= us_cnt_3+1;
            end if;
            if upstream_crcgood = '0' then 
                us_cnt_err <= us_cnt_err+1;
            end if;
        end if;
    end if;
end process;

--FILE OUTPUT
TIMER_P : process(clk166)
begin
    if rising_edge(clk166) then
        if rst = '1' then
            timer <= 0;
        else
            if timer = 0 then --timer off 
                if bkt_trig(0) = '1' then --start on 1st bucket of BPM0
                    timer <= 1;
                end if;
            else --timer started 
                timer <= timer +1;
            end if;
        end if;
    end if;
end process;

DS_FILE_OUT : process(dnstream_eop)
    variable my_line : LINE;
begin
    if rising_edge(dnstream_eop) then
        write(my_line, str(timer) & ", " & hstr(dnstream_data.bpm) & ", " & str(TO_INTEGER(unsigned(dnstream_data.bucket))));
        writeline(ds_file, my_line);
    end if;
end process;

US_FILE_OUT : process(upstream_eop)
    variable my_line : LINE;
begin
    if rising_edge(upstream_eop) then
        write(my_line, str(timer) & ", " & hstr(upstream_data.bpm) & ", " & str(TO_INTEGER(UNSIGNED(upstream_data.bucket))));
        writeline(us_file, my_line);
    end if;
end process;

end architecture test;

---------------------------------------------------------
---------------------------------------------------------
--  ADC data generator  ---------------------------------
---------------------------------------------------------
---------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.ibfb_comm_package.all;

entity adc_data_gen is
generic(
    BUNCH_TRIG_OFFSET  : time := 10 us;  --start delay of bunch trigger
    BUNCH_TRIG_DUR     : time := 500 ns; --bunch trigger high time
    PAUSE_AFTER_BUNCH  : time := 100 us; --time between last bucket and next bunch trigger
    FIRST_BUCKET_DELAY : time := 1 us;   --bunch trigger to 1st bucket delay
    BKT_TRIG_DUR       : time := 50 ns;  --bucket trigger high time
    BKT_TRIG_PERIOD    : time := 222 ns; --time between bucket triggers
    N_BUCKETS          : natural := 2700 --number of buckets
);
port(
    i_adc_clk              : in  std_logic;
    i_enable               : in  std_logic;
    o_adc_bunch_train_trig : out std_logic;
    o_adc_x_new            : out std_logic;
    o_adc_x_valid          : out std_logic;
    o_adc_x                : out std_logic_vector(31 downto 0);
    o_adc_y_new            : out std_logic;
    o_adc_y_valid          : out std_logic;
    o_adc_y                : out std_logic_vector(31 downto 0)
);
end entity adc_data_gen;

architecture behav of adc_data_gen is

signal adc_x_new, adc_y_new : std_logic;
signal bunch_trig, bunch_trig_r, bunch_trig_re : std_logic;
signal bkt_trig,   bkt_trig_r,   bkt_trig_re   : std_logic;
signal xcnt, ycnt : unsigned(31 downto 0);

begin

--generate bunch trigger (leave room for start delay and N_BUCKETS)
BUNCH_TRIG_GEN_P : process
begin
    bunch_trig <= '0'; --reset trigger
    wait for BUNCH_TRIG_OFFSET; --start offset (ony at startup)
    while(true) loop
        bunch_trig <= '1'; --assert trigger
        wait for (BUNCH_TRIG_DUR); --wait for trigger high duration
        bunch_trig <= '0'; --reset trigger
        wait for (FIRST_BUCKET_DELAY+(N_BUCKETS*BKT_TRIG_PERIOD)-BUNCH_TRIG_DUR+PAUSE_AFTER_BUNCH);
    end loop;
end process; 

--generate train of N_BUCKETS bucket trigger pulses
BKT_TRIG_GEN_P : process
begin
    bkt_trig <= '0';
    wait until rising_edge(bunch_trig);
    wait for FIRST_BUCKET_DELAY;
    for i in 0 to (N_BUCKETS-1) loop
        bkt_trig <= '1';
        wait for (BKT_TRIG_DUR);
        bkt_trig <= '0';
        wait for (BKT_TRIG_PERIOD-BKT_TRIG_DUR);
    end loop;
end process;

--Data generation process
POS_GEN_P : process(i_adc_clk)
begin
    if rising_edge(i_adc_clk) then
        bunch_trig_r <= bunch_trig;
        bkt_trig_r   <= bkt_trig;

        o_adc_bunch_train_trig <= bunch_trig_re;

        if bunch_trig_re = '1' or i_enable = '0' then
            adc_x_new <= '0';
            adc_y_new <= '0';
            xcnt <= (others => '0');
            ycnt <= (others => '0');
        elsif bkt_trig_re = '1' then
            adc_x_new <= '1';
            adc_y_new <= '1';
            xcnt <= xcnt + 1;
            ycnt <= ycnt + 1;
        else
            adc_x_new <= '0';
            adc_y_new <= '0';
        end if;
    end if;
end process;

--synchronize triggers in clk166 domain
bunch_trig_re <= bunch_trig and not bunch_trig_r;
bkt_trig_re   <= bkt_trig   and not bkt_trig_r;

--bpm_cav_exfel interface
o_adc_x_new   <= adc_x_new; --all values valid
o_adc_y_new   <= adc_y_new; --all values valid
o_adc_x_valid <= adc_x_new; --all values valid
o_adc_y_valid <= adc_y_new; --all values valid
o_adc_x <= std_logic_vector(xcnt);
o_adc_y <= std_logic_vector(ycnt);
    
end architecture behav;


---------------------------------------------------------
---------------------------------------------------------
--  XFPGA_LINK_EMULATOR  --------------------------------
---------------------------------------------------------
---------------------------------------------------------
--Emulate a MGT link.
--Connects two FIFO pairs (left to right and right to left)
--Data is read from the TX fifos as soon as it is available.
--Data is written to the RX fifo ignoring the full flag (that's done on purpose)
--A transport delay is simulated and can be changed via generic.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.ibfb_comm_package.all;

entity xfpga_link_emulator is
generic(
    LINK_DELAY : time := 200 ns 
);
port(
    o_rxf_overflow : out std_logic;
    --Connect to TX FIFO
    i_txf_empty : in  std_logic;
    o_txf_next  : out std_logic;
    i_txf_isk   : in  std_logic_vector(3 downto 0);
    i_txf_data  : in  std_logic_vector(31 downto 0);
    --Connect to RX FIFO
    i_rxf_full  : in  std_logic;
    o_rxf_wr    : out std_logic;
    o_rxf_isk   : out std_logic_vector(3 downto 0);
    o_rxf_data  : out std_logic_vector(31 downto 0)
);
end entity xfpga_link_emulator;

architecture test of xfpga_link_emulator is
    
signal txf_next, rxf_wr : std_logic;

begin

--Read TX FIFO
txf_next   <= not i_txf_empty; --whenever data is available

o_txf_next <= txf_next;

--Write to RX FIFO
rxf_wr <= transport txf_next after LINK_DELAY;

o_rxf_wr   <= rxf_wr;
o_rxf_isk  <= transport i_txf_isk  after LINK_DELAY;
o_rxf_data <= transport i_txf_data after LINK_DELAY;

o_rxf_overflow <= rxf_wr and i_rxf_full;

end architecture test;

---------------------------------------------------------
---------------------------------------------------------
--  IBFB_BPM_EMULATOR  ---------------------------------
---------------------------------------------------------
---------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Needed for FIFO36
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use work.ibfb_comm_package.all;

entity ibfb_bpm_emulator is
generic(
    BUNCH_TRIG_OFFSET  : time := 10 us;  --start delay of bunch trigger
    BUNCH_TRIG_DUR    : time := 500 ns; --bunch trigger high time
    PAUSE_AFTER_BUNCH  : time := 100 us; --time between last bucket and next bunch trigger
    FIRST_BUCKET_DELAY : time := 1 us;   --bunch trigger to 1st bucket delay
    BKT_TRIG_DUR      : time := 50 ns;  --bucket trigger high time
    BKT_TRIG_PERIOD   : time := 222 ns; --time between bucket triggers
    N_BUCKETS         : natural := 2700; --number of buckets
    K_SOP             : std_logic_vector(7 downto 0) := X"FB";
    K_EOP             : std_logic_vector(7 downto 0) := X"FD"
);
port(
    i_adc_clk      : in  std_logic;
    i_core_clk     : in  std_logic;
    i_core_rst_n   : in  std_logic;
    i_enable       : in  std_logic;
    i_bpm_id       : in  std_logic_vector(7 downto 0);
    o_bunch_trig    : out std_logic;
    o_bkt_trig      : out std_logic;
    o_pkt_fifo_werr : out std_logic;
    o_pkt_fifo_rerr : out std_logic;
    --Cross FPGA link
    --RX FIFO
    o_xf_rxf_rerr  : out std_logic;
    o_xf_rxf_werr  : out std_logic;
    o_xf_rxf_full  : out std_logic;
    i_xf_rxf_wr    : in  std_logic;
    i_xf_rxf_isk   : in  std_logic_vector(3 downto 0);
    i_xf_rxf_data  : in  std_logic_vector(31 downto 0);
    --TX FIFO
    o_xf_txf_rerr  : out std_logic;
    o_xf_txf_werr  : out std_logic;
    o_xf_txf_empty : out std_logic;
    i_xf_txf_next  : in  std_logic;
    o_xf_txf_isk   : out std_logic_vector(3 downto 0);
    o_xf_txf_data  : out std_logic_vector(31 downto 0);
    --Backplane link
    --RX FIFO
    o_bp_rxf_rerr  : out std_logic;
    o_bp_rxf_werr  : out std_logic;
    o_bp_rxf_full  : out std_logic;
    i_bp_rxf_wr    : in  std_logic;
    i_bp_rxf_isk   : in  std_logic_vector(3 downto 0);
    i_bp_rxf_data  : in  std_logic_vector(31 downto 0);
    --TX FIFO
    o_bp_txf_rerr  : out std_logic;
    o_bp_txf_werr  : out std_logic;
    o_bp_txf_empty : out std_logic;
    i_bp_txf_next  : in  std_logic;
    o_bp_txf_isk   : out std_logic_vector(3 downto 0);
    o_bp_txf_data  : out std_logic_vector(31 downto 0)
);
end entity ibfb_bpm_emulator;

architecture test of ibfb_bpm_emulator is

----------------------------------------------------------------
--  Components declaration  ------------------------------------
----------------------------------------------------------------
component adc_data_gen is
generic(
    BUNCH_TRIG_OFFSET  : time := 10 us;
    BUNCH_TRIG_DUR    : time := 500 ns;
    PAUSE_AFTER_BUNCH  : time := 100 us; --time between last bucket and next bunch trigger
    FIRST_BUCKET_DELAY : time := 1 us;
    BKT_TRIG_DUR      : time    := 50 ns;
    BKT_TRIG_PERIOD   : time    := 222 ns;
    N_BUCKETS         : natural := 2700
);
port(
    i_adc_clk              : in  std_logic;
    i_enable               : in  std_logic;
    o_adc_bunch_train_trig : out std_logic;
    o_adc_x_new            : out std_logic;
    o_adc_x_valid          : out std_logic;
    o_adc_x                : out std_logic_vector(31 downto 0);
    o_adc_y_new            : out std_logic;
    o_adc_y_valid          : out std_logic;
    o_adc_y                : out std_logic_vector(31 downto 0)
);
end component adc_data_gen;

component ibfb_bpm_pkt_gen is
generic(
    K_SOP : std_logic_vector(7 downto 0) := X"FB";
    K_EOP : std_logic_vector(7 downto 0) := X"FD"
);
port(
    --cav_bpm_exfel interface
    i_adc_clk              : in  std_logic;
    i_adc_bunch_train_trig : in  std_logic;
    i_adc_x_new            : in  std_logic;
    i_adc_x_valid          : in  std_logic;
    i_adc_x                : in  std_logic_vector(31 downto 0);
    i_adc_y_new            : in  std_logic;
    i_adc_y_valid          : in  std_logic;
    i_adc_y                : in  std_logic_vector(31 downto 0);
    --output FIFO interface
    i_core_rst_n           : in  std_logic;
    i_core_clk             : in  std_logic;
    i_bpm_id               : in  std_logic_vector(7 downto 0);
    o_pkt_fifo_werr        : out std_logic;
    o_pkt_fifo_rerr        : out std_logic;
    o_pkt_fifo_empty       : out std_logic;
    i_pkt_fifo_next        : in  std_logic;
    o_pkt_fifo_isk         : out std_logic_vector(3 downto 0);
    o_pkt_fifo_data        : out std_logic_vector(31 downto 0)
);
end component ibfb_bpm_pkt_gen;

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

signal rst, fifo_rst : std_logic;
signal sr  : std_logic_vector(3 downto 0);

signal adc_bunch_trig : std_logic;
signal adc_x_new, adc_x_valid : std_logic;
signal adc_x : std_logic_vector(31 downto 0);
signal adc_y_new, adc_y_valid : std_logic;
signal adc_y : std_logic_vector(31 downto 0);

--packet fifo
signal pkt_fifo_empty, pkt_fifo_next : std_logic;
signal pkt_fifo_isk  : std_logic_vector(3 downto 0);
signal pkt_fifo_data : std_logic_vector(31 downto 0);
--xFPGA RX fifo
signal xf_rxf_empty, xf_rxf_next : std_logic;
signal xf_rxf_isk  : std_logic_vector(3 downto 0);
signal xf_rxf_data : std_logic_vector(31 downto 0);
--xFPGA TX fifo
signal xf_txf_full, xf_txf_wr : std_logic;
signal xf_txf_isk  : std_logic_vector(3 downto 0);
signal xf_txf_data : std_logic_vector(31 downto 0);
--Backplane RX fifo
signal bp_rxf_empty, bp_rxf_next : std_logic;
signal bp_rxf_isk  : std_logic_vector(3 downto 0);
signal bp_rxf_data : std_logic_vector(31 downto 0);
--Backplane TX fifo
signal bp_txf_full, bp_txf_wr : std_logic;
signal bp_txf_isk  : std_logic_vector(3 downto 0);
signal bp_txf_data : std_logic_vector(31 downto 0);

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

--debug
type rarray is array (natural range <>) of real;
signal adc_speed, pkt_fifo_read_speed : real;
signal rout_in_speed  : rarray(0 to 2);
signal rout_out_speed : rarray(0 to 1);

for all: ibfb_packet_router use entity work.ibfb_packet_router(no_pkt_buf);

begin

rst <= not i_core_rst_n;

SR_P : process(i_core_clk)
begin
    if rising_edge(i_core_clk) then
        sr <= sr(sr'left-1 downto 0) & rst;
    end if;
end process;
fifo_rst <= rst or sr(0) or sr(1);

-----------------------------------------------------------
--ADC data generator
-----------------------------------------------------------
ADC_GEN_I : adc_data_gen
generic map(
    BUNCH_TRIG_OFFSET  => BUNCH_TRIG_OFFSET,
    BUNCH_TRIG_DUR     => BUNCH_TRIG_DUR,
    PAUSE_AFTER_BUNCH  => PAUSE_AFTER_BUNCH,
    FIRST_BUCKET_DELAY => FIRST_BUCKET_DELAY,
    BKT_TRIG_DUR       => BKT_TRIG_DUR,
    BKT_TRIG_PERIOD    => BKT_TRIG_PERIOD,
    N_BUCKETS          => N_BUCKETS
)
port map(
    i_adc_clk              => i_adc_clk,
    i_enable               => i_enable,
    o_adc_bunch_train_trig => adc_bunch_trig,
    o_adc_x_new            => adc_x_new,
    o_adc_x_valid          => adc_x_valid,
    o_adc_x                => adc_x,
    o_adc_y_new            => adc_y_new,
    o_adc_y_valid          => adc_y_valid,
    o_adc_y                => adc_y
);

o_bunch_trig <= adc_bunch_trig;
o_bkt_trig   <= adc_x_valid;

ADC_METER : throughput_meter
generic map(
    CLK_FREQ_HZ     => 160.0,
    DATA_WIDTH_BITS => 64.0
)
port map(
    i_clk => i_adc_clk, 
    i_rst => rst,
    i_data_valid => adc_x_new,
    o_bps        => adc_speed
);
-----------------------------------------------------------
--BPM packet generator
-----------------------------------------------------------
PKT_GEN : ibfb_bpm_pkt_gen
generic map(
    K_SOP => K_SOP,
    K_EOP => K_EOP 
)
port map(
    --cav_bpm_exfel interface
    i_adc_clk              => i_adc_clk,
    i_adc_bunch_train_trig => adc_bunch_trig,
    i_adc_x_new            => adc_x_new,
    i_adc_x_valid          => adc_x_valid,
    i_adc_x                => adc_x,
    i_adc_y_new            => adc_y_new,
    i_adc_y_valid          => adc_y_valid,
    i_adc_y                => adc_y,
    --output FIFO interface
    i_core_rst_n           => i_core_rst_n,
    i_core_clk             => i_core_clk,
    i_bpm_id               => i_bpm_id,
    o_pkt_fifo_werr        => o_pkt_fifo_werr,
    o_pkt_fifo_rerr        => o_pkt_fifo_rerr,
    o_pkt_fifo_empty       => pkt_fifo_empty,
    i_pkt_fifo_next        => pkt_fifo_next,
    o_pkt_fifo_isk         => pkt_fifo_isk,
    o_pkt_fifo_data        => pkt_fifo_data
);

PKT_FIFO_R_METER : throughput_meter
generic map(
    CLK_FREQ_HZ     => 78.125,
    DATA_WIDTH_BITS => 32.0
)
port map(
    i_clk => i_core_clk, 
    i_rst => rst,
    i_data_valid => pkt_fifo_next,
    o_bps        => pkt_fifo_read_speed
);
-----------------------------------------------------------
--XFPGA RX FIFO
-----------------------------------------------------------
XFPGA_RXFIFO : FIFO36
generic map(
    DATA_WIDTH              => 36,
    ALMOST_FULL_OFFSET      => X"0010", --ALMOST_FULL when EMPTY LOCATIONS are less than this value
    ALMOST_EMPTY_OFFSET     => X"0010", --ALMOST_EMPTY when FULL LOCATIONS are less than this value
    DO_REG                  => 1, --pipeline register. Must be enable for asynchronous operation
    EN_SYN                  => FALSE, --synchronous/asynchronous mode
    FIRST_WORD_FALL_THROUGH => TRUE
)
port map(
    RST         => fifo_rst, --must be asserted for at least 3 clock cycles
    --
    WRCLK       => i_core_clk,
    FULL        => o_xf_rxf_full,
    ALMOSTFULL  => open,
    WREN        => i_xf_rxf_wr,
    WRCOUNT     => open,
    WRERR       => o_xf_rxf_werr,
    DIP         => i_xf_rxf_isk,
    DI          => i_xf_rxf_data,
    --
    RDCLK       => i_core_clk,
    EMPTY       => xf_rxf_empty,
    ALMOSTEMPTY => open,
    RDEN        => xf_rxf_next,
    RDCOUNT     => open,
    RDERR       => o_xf_rxf_rerr,
    DOP         => xf_rxf_isk,
    DO          => xf_rxf_data
);

-----------------------------------------------------------
--XFPGA TX FIFO
-----------------------------------------------------------
XFPGA_TXFIFO : FIFO36
generic map(
    DATA_WIDTH              => 36,
    ALMOST_FULL_OFFSET      => X"0010", --ALMOST_FULL when EMPTY LOCATIONS are less than this value
    ALMOST_EMPTY_OFFSET     => X"0010", --ALMOST_EMPTY when FULL LOCATIONS are less than this value
    DO_REG                  => 1, --pipeline register. Must be enable for asynchronous operation
    EN_SYN                  => FALSE, --synchronous/asynchronous mode
    FIRST_WORD_FALL_THROUGH => TRUE
)
port map(
    RST         => fifo_rst, --must be asserted for at least 3 clock cycles
    --
    WRCLK       => i_core_clk,
    FULL        => xf_txf_full,
    ALMOSTFULL  => open,
    WREN        => xf_txf_wr,
    WRCOUNT     => open,
    WRERR       => o_xf_txf_werr,
    DIP         => xf_txf_isk,
    DI          => xf_txf_data,
    --
    RDCLK       => i_core_clk,
    EMPTY       => o_xf_txf_empty,
    ALMOSTEMPTY => open,
    RDEN        => i_xf_txf_next,
    RDCOUNT     => open,
    RDERR       => o_xf_txf_rerr,
    DOP         => o_xf_txf_isk,
    DO          => o_xf_txf_data
);

-----------------------------------------------------------
--BACKPLANE RX FIFO
-----------------------------------------------------------
BKPLANE_RXFIFO : FIFO36
generic map(
    DATA_WIDTH              => 36,
    ALMOST_FULL_OFFSET      => X"0010", --ALMOST_FULL when EMPTY LOCATIONS are less than this value
    ALMOST_EMPTY_OFFSET     => X"0010", --ALMOST_EMPTY when FULL LOCATIONS are less than this value
    DO_REG                  => 1, --pipeline register. Must be enable for asynchronous operation
    EN_SYN                  => FALSE, --synchronous/asynchronous mode
    FIRST_WORD_FALL_THROUGH => TRUE
)
port map(
    RST         => fifo_rst, --must be asserted for at least 3 clock cycles
    --
    WRCLK       => i_core_clk,
    FULL        => o_bp_rxf_full,
    ALMOSTFULL  => open,
    WREN        => i_bp_rxf_wr,
    WRCOUNT     => open,
    WRERR       => o_bp_rxf_werr,
    DIP         => i_bp_rxf_isk,
    DI          => i_bp_rxf_data,
    --
    RDCLK       => i_core_clk,
    EMPTY       => bp_rxf_empty,
    ALMOSTEMPTY => open,
    RDEN        => bp_rxf_next,
    RDCOUNT     => open,
    RDERR       => o_bp_rxf_rerr,
    DOP         => bp_rxf_isk,
    DO          => bp_rxf_data
);

-----------------------------------------------------------
--BACKPLANE TX FIFO
-----------------------------------------------------------
BKPLANE_TXFIFO : FIFO36
generic map(
    DATA_WIDTH              => 36,
    ALMOST_FULL_OFFSET      => X"0010", --ALMOST_FULL when EMPTY LOCATIONS are less than this value
    ALMOST_EMPTY_OFFSET     => X"0010", --ALMOST_EMPTY when FULL LOCATIONS are less than this value
    DO_REG                  => 1, --pipeline register. Must be enable for asynchronous operation
    EN_SYN                  => FALSE, --synchronous/asynchronous mode
    FIRST_WORD_FALL_THROUGH => TRUE
)
port map(
    RST         => fifo_rst, --must be asserted for at least 3 clock cycles
    --
    WRCLK       => i_core_clk,
    FULL        => bp_txf_full,
    ALMOSTFULL  => open,
    WREN        => bp_txf_wr,
    WRCOUNT     => open,
    WRERR       => o_bp_txf_werr,
    DIP         => bp_txf_isk,
    DI          => bp_txf_data,
    --
    RDCLK       => i_core_clk,
    EMPTY       => o_bp_txf_empty,
    ALMOSTEMPTY => open,
    RDEN        => i_bp_txf_next,
    RDCOUNT     => open,
    RDERR       => o_bp_txf_rerr,
    DOP         => o_bp_txf_isk,
    DO          => o_bp_txf_data
);

-----------------------------------------------------------
--Packet router input connections
-----------------------------------------------------------
--Input 0 = local BPM FIFO
--Input 1 = cross-FPGA RX FIFO
--Input 2 = backplame RX FIFO
pkt_fifo_next<= rout_in_next(0);
xf_rxf_next  <= rout_in_next(1);
bp_rxf_next  <= rout_in_next(2);

rout_in_valid(0)   <= not pkt_fifo_empty;
rout_in_valid(1)   <= not xf_rxf_empty;
rout_in_valid(2)   <= not bp_rxf_empty;

rout_in_charisk(0) <= pkt_fifo_isk;
rout_in_charisk(1) <= xf_rxf_isk;
rout_in_charisk(2) <= bp_rxf_isk;

rout_in_data(0)    <= pkt_fifo_data;
rout_in_data(1)    <= xf_rxf_data;
rout_in_data(2)    <= bp_rxf_data;

GEN_RIN_METERS : for i in 0 to 2 generate
    ROUT_IN_METER_i : throughput_meter
    generic map(
        CLK_FREQ_HZ     => 78.125,
        DATA_WIDTH_BITS => 32.0
    )
    port map(
        i_clk => i_core_clk, 
        i_rst => rst,
        i_data_valid => rout_in_next(i),
        o_bps        => rout_in_speed(i)
    );
end generate;
-----------------------------------------------------------
--Packet router instance
-----------------------------------------------------------
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
    i_clk     => i_core_clk,
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

-----------------------------------------------------------
--Packet router output connections
-----------------------------------------------------------
--Output 0 = cross-FPGA TX FIFO
--Output 1 = backplane  TX FIFO
rout_out_next(0) <= not xf_txf_full;
rout_out_next(1) <= not bp_txf_full;

xf_txf_wr <= rout_out_valid(0);
bp_txf_wr <= rout_out_valid(1);

xf_txf_isk <= rout_out_charisk(0);
bp_txf_isk <= rout_out_charisk(1);

xf_txf_data <= rout_out_data(0);
bp_txf_data <= rout_out_data(1);

GEN_ROUT_METERS : for i in 0 to 1 generate
    ROUT_OUT_METER_i : throughput_meter
    generic map(
        CLK_FREQ_HZ     => 78.125,
        DATA_WIDTH_BITS => 32.0
    )
    port map(
        i_clk => i_core_clk, 
        i_rst => rst,
        i_data_valid => rout_out_valid(i),
        o_bps        => rout_out_speed(i)
    );
end generate;

end architecture test;

---------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity throughput_meter is
generic(
    CLK_FREQ_HZ     : real;
    DATA_WIDTH_BITS : real
);
port(
    i_clk, i_rst : in std_logic;
    i_data_valid : in std_logic;
    o_bps        : out real
);
end entity throughput_meter;

architecture behav of throughput_meter is

signal time_cnt, data_cnt : real;

begin

MAIN : process(i_clk)
begin
    if rising_edge(i_clk) then
        if i_rst = '1' then
            time_cnt <= 0.0;
            data_cnt <= 0.0;
        else
            time_cnt <= time_cnt + 1.0;
            if i_data_valid = '1' then
                data_cnt <= data_cnt + 1.0;
            end if;
        end if;
    end if;
end process;

o_bps <= (CLK_FREQ_HZ*DATA_WIDTH_BITS*data_cnt)/time_cnt when time_cnt > 0.0 else
         0.0;

end architecture behav;

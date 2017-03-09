library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Needed for FIFO36
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

--needed for ibfb_comm_packet type
library ibfb_common_v1_00_a;
use ibfb_common_v1_00_a.ibfb_comm_package.all;

entity ibfb_bpm_pkt_gen is
generic(
    K_SOP : std_logic_vector(7 downto 0) := X"FB";
    K_EOP : std_logic_vector(7 downto 0) := X"FD"
);
port(
    --DEBUG
    o_dbg_btt  : out std_logic;
    o_dbg_xnew : out std_logic;
    o_dbg_ynew : out std_logic;
    o_dbg_fifo_next : out std_logic;
    o_dbg_fifo_fout : out std_logic_vector(3 downto 0);
    o_dbg_fifo_bkt : out std_logic_vector(15 downto 0);
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
    o_bkt_rst              : out std_logic;
    o_pkt_fifo_rerr        : out std_logic;
    o_pkt_fifo_werr        : out std_logic;
    o_pkt_fifo_empty       : out std_logic;
    i_pkt_fifo_next        : in  std_logic;
    o_pkt_fifo_isk         : out std_logic_vector(3 downto 0);
    o_pkt_fifo_data        : out std_logic_vector(31 downto 0)
);
end entity ibfb_bpm_pkt_gen;

architecture struct of ibfb_bpm_pkt_gen is

----------------------------------------------------------------
--  Components declaration  ------------------------------------
----------------------------------------------------------------
component cav_bpm_interface is
port(
    --DEBUG
    o_dbg_btt  : out std_logic;
    o_dbg_xnew : out std_logic;
    o_dbg_ynew : out std_logic;
    o_dbg_fifo_next : out std_logic;
    o_dbg_fifo_fout : out std_logic_vector(3 downto 0);
    --cav_bpm_exfel interface
    i_adc_clk              : in  std_logic;
    i_adc_bunch_train_trig : in  std_logic;
    i_adc_x_new            : in  std_logic;
    i_adc_x_valid          : in  std_logic;
    i_adc_x                : in  std_logic_vector(31 downto 0);
    i_adc_y_new            : in  std_logic;
    i_adc_y_valid          : in  std_logic;
    i_adc_y                : in  std_logic_vector(31 downto 0);
    --FIFO write errors (adc_clk domain)
    o_xfifo_wr_err         : out std_logic;
    o_yfifo_wr_err         : out std_logic;
    --Core interface
    i_core_rst_n           : in  std_logic;
    i_core_clk             : in  std_logic;
    i_bpm_id               : in  std_logic_vector(7 downto 0);
    i_pkt_tx_busy          : in  std_logic;
    o_bkt_rst              : out std_logic;   
    o_pkt_tx_valid         : out std_logic;
    o_pkt_tx_data          : out ibfb_comm_packet --tx data (packet fields)
);
end component cav_bpm_interface;

----------------------------------------------------------------
--  Signals declaration  ---------------------------------------
----------------------------------------------------------------
signal rst : std_logic;

signal pkt_tx_valid, pkt_tx_busy : std_logic;
signal pkt_tx_data : ibfb_comm_packet;

signal rst_sr : std_logic_vector(3 downto 0);
signal pkt_fifo_rst, pkt_fifo_full, pkt_fifo_wr : std_logic;
signal pkt_fifo_isk  : std_logic_vector(3 downto 0);
signal pkt_fifo_data : std_logic_vector(31 downto 0);

begin

rst <= not i_core_rst_n;

----------------------------------------------------------------
--  Cross-clock-domain interface  ------------------------------
----------------------------------------------------------------
CDC_IF_0 : cav_bpm_interface
port map(
    --DEBUG
    o_dbg_btt  => o_dbg_btt,
    o_dbg_xnew => o_dbg_xnew,
    o_dbg_ynew => o_dbg_ynew,
    o_dbg_fifo_next => o_dbg_fifo_next,
    o_dbg_fifo_fout => o_dbg_fifo_fout,
    --cav_bpm_exfel interface
    i_adc_clk              => i_adc_clk,
    i_adc_bunch_train_trig => i_adc_bunch_train_trig,
    i_adc_x_new            => i_adc_x_new,
    i_adc_x_valid          => i_adc_x_valid,
    i_adc_x                => i_adc_x,
    i_adc_y_new            => i_adc_y_new,
    i_adc_y_valid          => i_adc_y_valid,
    i_adc_y                => i_adc_y,
    --FIFO write errors (adc_clk domain)
    o_xfifo_wr_err         => open,
    o_yfifo_wr_err         => open,
    --Core interface
    i_core_rst_n           => i_core_rst_n,
    i_core_clk             => i_core_clk,
    i_bpm_id               => i_bpm_id,
    o_bkt_rst              => o_bkt_rst,
    i_pkt_tx_busy          => pkt_tx_busy,
    o_pkt_tx_valid         => pkt_tx_valid,
    o_pkt_tx_data          => pkt_tx_data
);

--DEBUG
o_dbg_fifo_bkt <= pkt_tx_data.bucket;

----------------------------------------------------------------
--  Packet generator  ------------------------------------------
----------------------------------------------------------------
PKT_TX : ibfb_packet_tx
generic map(
    K_SOP => K_SOP,
    K_EOP => K_EOP,
    EXTERNAL_CRC => '0'
)
port map(
    i_rst       => rst,
    i_clk       => i_core_clk,
    --user interface
    o_sample    => open,
    o_busy      => pkt_tx_busy,
    i_tx_valid  => pkt_tx_valid,
    i_tx_data   => pkt_tx_data,
    --MGT FIFO interface
    i_fifo_full => pkt_fifo_full,
    o_valid     => pkt_fifo_wr, 
    o_charisk   => pkt_fifo_isk,
    o_data      => pkt_fifo_data
);

-----------------------------------------------------------
--FIFO reset 
-----------------------------------------------------------
--shift register to make reset pulse 3 clock cycles long
FIFO_RST_GEN_P : process(i_core_clk) --MUST BE THE SLOWEST FIFO CLOCK
begin
    if rising_edge(i_core_clk) then
        rst_sr <= rst_sr(rst_sr'left-1 downto 0) & (not i_core_rst_n); --feed reset into shift register
    end if;
end process;

--fifo reset: 3 i_core_clk cycles (slowest clock)
pkt_fifo_rst <= rst_sr(0) or rst_sr(1) or rst_sr(2);

--TODO: Xilinx FIFO supports FWFT only in Asynchronous mode.
--This mode has 5 clock cycles write to read latency.
--Better to use a custom RAM-based FIFO (can make it in 2 clock cycles)
PACKET_FIFO : FIFO36
generic map(
    DATA_WIDTH              => 36,
    ALMOST_FULL_OFFSET      => X"0010", --ALMOST_FULL when EMPTY LOCATIONS are less than this value
    ALMOST_EMPTY_OFFSET     => X"0010", --ALMOST_EMPTY when FULL LOCATIONS are less than this value
    DO_REG                  => 1, --pipeline register. Must be enable for asynchronous operation
    EN_SYN                  => FALSE, --synchronous/asynchronous mode
    FIRST_WORD_FALL_THROUGH => TRUE --works only in ASYNCHRONOUS mode
)
port map(
    RST         => pkt_fifo_rst, --must be asserted for at least 3 clock cycles
    --
    WRCLK       => i_core_clk,
    FULL        => pkt_fifo_full,
    ALMOSTFULL  => open,
    WREN        => pkt_fifo_wr,
    WRCOUNT     => open,
    WRERR       => o_pkt_fifo_werr,
    DIP         => pkt_fifo_isk,
    DI          => pkt_fifo_data,
    --
    RDCLK       => i_core_clk,
    EMPTY       => o_pkt_fifo_empty,
    ALMOSTEMPTY => open,
    RDEN        => i_pkt_fifo_next,
    RDCOUNT     => open,
    RDERR       => o_pkt_fifo_rerr,
    DOP         => o_pkt_fifo_isk,
    DO          => o_pkt_fifo_data
);

end architecture struct;


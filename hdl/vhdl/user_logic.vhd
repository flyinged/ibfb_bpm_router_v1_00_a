------------------------------------------------------------------------------
--                       Paul Scherrer Institute (PSI)
------------------------------------------------------------------------------
-- Unit    : user_logic.vhd
-- Author  : Alessandro Malatesta, Section Diagnostic
-- Version : $Revision: 1.6 $
------------------------------------------------------------------------------
-- Copyright © PSI, Section Diagnostic
------------------------------------------------------------------------------
-- Comment : Packet router for IBFB Cavity BPM
--           1.02: new router
--           1.03: removed BPM23 tile to avoid using MGT_CLK_18
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library ibfb_common_v1_00_a;
use ibfb_common_v1_00_a.virtex5_gtx_package.all;
use ibfb_common_v1_00_a.ibfb_comm_package.all;
--use ibfb_common_v1_00_a.pkg_ibfb_timing.all;

library ibfb_bpm_router_v1_00_a;
use ibfb_bpm_router_v1_00_a.all;

entity user_logic is
generic (
    --Packet protocol 
    K_SOP            : std_logic_vector(7 downto 0) := X"FB"; 
    K_EOP            : std_logic_vector(7 downto 0) := X"FD";
    --Transceivers
    C_GTX_REFCLK_SEL    : std_logic_vector(2 downto 0); --BPM23, BPM01, P0
    --
    C_P0_REFCLK_FREQ    : integer := 125; --MHz
    C_BPM_REFCLK_FREQ   : integer := 125; --MHz
    --
    C_P0_BAUD_RATE      : integer := 3125000; --Kbps
    C_BPM_BAUD_RATE     : integer := 3125000; --Kbps
    --PLB 
    C_SLV_AWIDTH        : integer     := 32; --added
    C_NUM_MEM           : integer     := 1;  --added
    C_SLV_DWIDTH        : integer := 32;
    C_NUM_REG           : integer := 32
);
port (
    ------------------------------------------------------------------------
    -- CHIPSCOPE
    ------------------------------------------------------------------------
    O_CSP_CLK                   : out std_logic;
    O_CSP_DATA                  : out std_logic_vector(127 downto 0); 
    ------------------------------------------------------------------------
    -- GTX INTERFACE
    ------------------------------------------------------------------------
    I_GTX_REFCLK1_IN            : in  std_logic;
    I_GTX_REFCLK2_IN            : in  std_logic;
    O_GTX_REFCLK_OUT            : out std_logic;
    I_GTX_RX_N                  : in  std_logic_vector(2*2-1 downto 0);
    I_GTX_RX_P                  : in  std_logic_vector(2*2-1 downto 0);
    O_GTX_TX_N                  : out std_logic_vector(2*2-1 downto 0);
    O_GTX_TX_P                  : out std_logic_vector(2*2-1 downto 0);
    ------------------------------------------------------------------------
    -- CAV_BPM_EXFEL interface
    ------------------------------------------------------------------------
    i_adc_clk                  : in  std_logic; 
    i_adc_bunch_train_trig     : in  std_logic;
    i_adc_x_new                : in  std_logic;
    i_adc_x_valid              : in  std_logic;
    i_adc_x                    : in  std_logic_vector(31 downto 0);
    i_adc_y_new                : in  std_logic;
    i_adc_y_valid              : in  std_logic;
    i_adc_y                    : in  std_logic_vector(31 downto 0);
    ------------------------------------------------------------------------
    -- Bus ports
    ------------------------------------------------------------------------
    --Bus2IP_Clk                  : in    std_logic;
    --Bus2IP_Reset                : in    std_logic;
    --Bus2IP_Data                 : in    std_logic_vector(0 to C_SLV_DWIDTH - 1);
    --Bus2IP_BE                   : in    std_logic_vector(0 to C_SLV_DWIDTH / 8 - 1);
    --Bus2IP_RdCE                 : in    std_logic_vector(0 to C_NUM_REG - 1);
    --Bus2IP_WrCE                 : in    std_logic_vector(0 to C_NUM_REG - 1);
    --IP2Bus_Data                 : out   std_logic_vector(0 to C_SLV_DWIDTH - 1);
    --IP2Bus_RdAck                : out   std_logic;
    --IP2Bus_WrAck                : out   std_logic;
    --IP2Bus_Error                : out   std_logic
    Bus2IP_Clk         : in  std_logic;
    Bus2IP_Reset       : in  std_logic;
    Bus2IP_Addr        : in  std_logic_vector(0 to C_SLV_AWIDTH-1);
    Bus2IP_CS          : in  std_logic_vector(0 to C_NUM_MEM-1);
    Bus2IP_RNW         : in  std_logic;
    Bus2IP_Data        : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
    Bus2IP_BE          : in  std_logic_vector(0 to C_SLV_DWIDTH/8-1);
    Bus2IP_RdCE        : in  std_logic_vector(0 to C_NUM_REG-1);
    Bus2IP_WrCE        : in  std_logic_vector(0 to C_NUM_REG-1);
    Bus2IP_Burst       : in  std_logic;
    Bus2IP_BurstLength : in  std_logic_vector(0 to 8);
    Bus2IP_RdReq       : in  std_logic;
    Bus2IP_WrReq       : in  std_logic;
    IP2Bus_AddrAck     : out std_logic;
    IP2Bus_Data        : out std_logic_vector(0 to C_SLV_DWIDTH-1);
    IP2Bus_RdAck       : out std_logic;
    IP2Bus_WrAck       : out std_logic;
    IP2Bus_Error       : out std_logic
);
end entity user_logic;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------
architecture behavioral of user_logic is
    
  component ibfb_bpm_pkt_gen is
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
  end component ibfb_bpm_pkt_gen; 

  component ibfb_packet_rx is
    generic(
        K_SOP : std_logic_vector(7 downto 0);
        K_EOP : std_logic_vector(7 downto 0)
    );
    port(
        i_rst : in std_logic;
        i_clk : in std_logic;
        --MGT FIFO interface
        o_next      : out std_logic;
        i_valid     : in  std_logic;
        i_charisk   : in  std_logic_vector(3 downto 0);
        i_data      : in  std_logic_vector(31 downto 0);
        --user interface
        o_bad_data : out std_logic; 
        o_eop      : out std_logic;
        o_crc_good : out std_logic;
        o_rx_data  : out ibfb_comm_packet; --tx data (packet fields)
        --debug
        o_csp_clk   : out std_logic;
        o_csp_data  : out std_logic_vector(63 downto 0)        
     );
  end component;

  ---------------------------------------------------------------------------
  -- Bus protocol signals
  ---------------------------------------------------------------------------
  -- Types ------------------------------------------------------------------
  type     slv_reg_type is array (0 to C_NUM_REG-1) of std_logic_vector(C_SLV_DWIDTH - 1 downto 0);
  -- Constants --------------------------------------------------------------
  constant LOW_REG                  : std_logic_vector(0 to C_NUM_REG - 1) := (others => '0');
  constant K_BAD : std_logic_vector(7 downto 0) := X"5C";
  -- Signals ----------------------------------------------------------------
  signal   slv_reg_rd      : slv_reg_type;
  signal   slv_reg_wr      : slv_reg_type;
  signal   slv_reg_rd_ack  : std_logic := '0';
  signal   slv_reg_wr_ack  : std_logic := '0';
  signal   slv_ip2bus_data : std_logic_vector( 0 to C_SLV_DWIDTH-1);
  -- Memory access               
  signal   mem_address            : std_logic_vector(31 downto  0) := (others => '0');
  signal   mem_rd_addr_ack        : std_logic := '0';
  signal   mem_rd_req             : std_logic_vector( 4 downto  0) := (others => '0');
  signal   mem_rd_ack             : std_logic := '0';
  signal   mem_rd_data            : std_logic_vector(31 downto  0) := (others => '0');
  signal   mem_wr_ack             : std_logic := '0';
  signal   mem_wr_data            : std_logic_vector(31 downto  0) := (others => '0');

  signal user_clk, rst_n, sync_bunch_trig : std_logic; --common clock for the core logic (from one of the transceivers)

  ---------------------------------------------------------------------------
  -- MGTs (numbering 5:0 <=> bpm(3:0) & p0(1:0)
  ---------------------------------------------------------------------------
  --Per-GTX-Tile signals
  signal p0_mgt_o     : mgt_out_type;
  signal bpm01_mgt_o  : mgt_out_type;
  signal bpm23_mgt_o  : mgt_out_type;
  signal rxrecclk    : std_logic_vector(5 downto 0);
  signal txoutclk    : std_logic_vector(5 downto 0);

  --Per-GTX-channel signals
  --P0
  signal p0_fifo_rst_c  : std_logic_vector(0 to 1);
  signal p0_rx_sync     : std_logic_vector(0 to 1);
  signal p0_loopback    : array3(0 to 1);
  signal p0_fifo_rst    : std_logic_vector(0 to 1);
  --P0 RX
  signal p0_rxf_vld     : std_logic_vector(0 to 1);
  signal p0_rxf_next    : std_logic_vector(0 to 1);
  signal p0_rxf_empty   : std_logic_vector(0 to 1);
  signal p0_rxf_charisk : array4(0 to 1);
  signal p0_rxf_data    : array32(0 to 1);
  --P0 TX
  signal p0_txf_vld     : std_logic_vector(0 to 1);
  signal p0_txf_full    : std_logic_vector(0 to 1);
  signal p0_txf_write   : std_logic_vector(0 to 1);
  signal p0_txf_charisk : array4(0 to 1);
  signal p0_txf_data    : array32(0 to 1);

  --BPM
  signal bpm_fifo_rst_c  : std_logic_vector(0 to 3);
  signal bpm_rx_sync     : std_logic_vector(0 to 3);
  signal bpm_loopback    : array3(0 to 3);
  signal bpm_fifo_rst    : std_logic_vector(0 to 3);
  --BPM RX
  signal bpm_rxf_vld     : std_logic_vector(0 to 3);
  signal bpm_rxf_next    : std_logic_vector(0 to 3);
  signal bpm_rxf_empty   : std_logic_vector(0 to 3);
  signal bpm_rxf_charisk : array4(0 to 3);
  signal bpm_rxf_data    : array32(0 to 3);
  --BPM TX
  signal bpm_txf_vld     : std_logic_vector(0 to 3);
  signal bpm_txf_full    : std_logic_vector(0 to 3);
  signal bpm_txf_write   : std_logic_vector(0 to 3);
  signal bpm_txf_charisk : array4(0 to 3);
  signal bpm_txf_data    : array32(0 to 3);

  --ibfb packet generator
  signal pkt_fifo_werr, pkt_fifo_rerr, pkt_fifo_empty, pkt_fifo_next, bpm_enable : std_logic;
  signal pkt_fifo_isk  : std_logic_vector(3 downto 0);
  signal pkt_fifo_data : std_logic_vector(31 downto 0);
  signal bpm_id : std_logic_vector(7 downto 0);
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
  signal routing_table    : array32(0 to 2); 
  signal route_bpm2back,  route_bpm2side  : std_logic;
  signal route_side2back, route_side2side : std_logic;
  signal route_back2back, route_back2side : std_logic;

  --error counters
  signal pkt_fifo_werr_rst, pkt_fifo_rerr_rst : std_logic;
  signal pkt_fifo_werr_cnt, pkt_fifo_rerr_cnt : unsigned(15 downto 0);
  
  signal router_err_rst0, router_err_rst1 : std_logic;
  signal router_err_cnt0, router_err_cnt1 : unsigned(15 downto 0);


  --LOS counters
  type   uarray16 is array(natural range <>) of unsigned(15 downto 0);
  signal los_cnt : uarray16(5 downto 0);
  signal los, los_r, los_cnt_rst : std_logic_vector(5 downto 0);

  --DEBUG
  constant CSP_SET : natural := 2;
  signal bad_k : std_logic_vector(3 downto 0);
  signal timer : unsigned(31 downto 0) := X"00000000";
  signal dbg_out_valid, dbg_out_good, dbg_out_baddata : std_logic;
  signal dbg_bpm_valid, dbg_bpm_good, dbg_bpm_baddata : std_logic;

  --type ibfb_comm_packet is record
  --    ctrl   : std_logic_vector( 7 downto 0);
  --    bpm    : std_logic_vector( 7 downto 0);
  --    bucket : std_logic_vector(15 downto 0);
  --    xpos   : std_logic_vector(31 downto 0);
  --    ypos   : std_logic_vector(31 downto 0);
  --    crc    : std_logic_vector( 7 downto 0);
  --end record ibfb_comm_packet;
  signal dbg_out_pkt : ibfb_comm_packet;
  signal dbg_bpm_pkt : ibfb_comm_packet;
  signal dbg_btt, dbg_xnew, dbg_ynew, dbg_fifo_next : std_logic;
  signal dbg_fifo_fout : std_logic_vector(3 downto 0);
  signal dbg_fifo_bkt  : std_logic_vector(15 downto 0);

  --CONFIG
  for all: ibfb_packet_router use entity ibfb_common_v1_00_a.ibfb_packet_router(pkt_buf);

  constant FW_VERSION : std_logic_vector(31 downto 0) := X"00000006";

begin

---------------------------------------------------------------------------
-- Clocks and resets
---------------------------------------------------------------------------
rxrecclk(0) <= p0_mgt_o.rx(0).RXRECCLK;
rxrecclk(1) <= p0_mgt_o.rx(1).RXRECCLK;
rxrecclk(2) <= bpm01_mgt_o.rx(0).RXRECCLK;
rxrecclk(3) <= bpm01_mgt_o.rx(1).RXRECCLK;
--rxrecclk(4) <= '0'; --bpm23_mgt_o.rx(0).RXRECCLK;

txoutclk(0) <= p0_mgt_o.tx(0).TXOUTCLK;
txoutclk(1) <= p0_mgt_o.tx(1).TXOUTCLK;
txoutclk(2) <= bpm01_mgt_o.tx(0).TXOUTCLK;
txoutclk(3) <= bpm01_mgt_o.tx(1).TXOUTCLK;
--txoutclk(4) <= '0'; --bpm23_mgt_o.tx(0).TXOUTCLK;
--txoutclk(5) <= '0'; --bpm23_mgt_o.tx(1).TXOUTCLK;

--use one of the TXOUTCLK as core clock
user_clk <= txoutclk(2); 

rst_n <= not Bus2IP_Reset;

---------------------------------------------------------------------------
-- Status
---------------------------------------------------------------------------
IP2Bus_AddrAck <= slv_reg_rd_ack or mem_rd_addr_ack or --all ACK signals OR-ed
                  slv_reg_wr_ack or mem_wr_ack;
IP2Bus_WrAck <= '1' when (Bus2IP_WrCE /= LOW_REG) else '0';
IP2Bus_RdAck <= '1' when (Bus2IP_RdCE /= LOW_REG) else '0';
IP2Bus_Error <= '0';

---------------------------------------------------------------------------
-- IP to Bus data
---------------------------------------------------------------------------
IP2Bus_Data    <= slv_ip2bus_data when (slv_reg_rd_ack = '1') else
                  mem_rd_data     when (mem_rd_ack     = '1') else
                  (others => '0');

---------------------------------------------------------------------------
-- Register Read
---------------------------------------------------------------------------
slv_reg_rd_proc: process(Bus2IP_RdCE, slv_reg_rd) is
begin
   slv_ip2bus_data             <= (others => '0');
   for register_index in 0 to C_NUM_REG - 1 loop
     if (Bus2IP_RdCE(register_index) = '1') then
       slv_ip2bus_data       <= slv_reg_rd(register_index);
     end if;
   end loop;
end process slv_reg_rd_proc;

slv_reg_rd_ack                 <= '1' when (Bus2IP_RdCE /= LOW_REG) else '0';

---------------------------------------------------------------------------
-- Register Write
---------------------------------------------------------------------------
slv_reg_wr_proc: process(Bus2IP_Clk) is
begin
    if rising_edge(Bus2IP_Clk) then
        slv_reg_wr_gen: for register_index in 0 to C_NUM_REG - 1 loop
        if Bus2IP_Reset = '1' then
            slv_reg_wr(register_index) <= (others => '0');
        else
            if (Bus2IP_WrCE(register_index) = '1') then
                --for byte_index in 0 to (C_SLV_DWIDTH / 8) - 1 loop
                    if (Bus2IP_BE(0) = '1') then
                        slv_reg_wr(register_index)(31 downto 24) <= Bus2IP_Data( 0 to  7);
                    end if;
                    if (Bus2IP_BE(1) = '1') then
                        slv_reg_wr(register_index)(23 downto 16) <= Bus2IP_Data( 8 to 15);
                    end if;
                    if (Bus2IP_BE(2) = '1') then
                        slv_reg_wr(register_index)(15 downto  8) <= Bus2IP_Data(16 to 23);
                    end if;
                    if (Bus2IP_BE(3) = '1') then
                        slv_reg_wr(register_index)( 7 downto  0) <= Bus2IP_Data(24 to 31);
                    end if;
                --end loop;             
            end if;
        end if;
        end loop;
    end if;
end process slv_reg_wr_proc;

slv_reg_wr_ack                 <= '1' when (Bus2IP_WrCE /= LOW_REG) else '0';

---------------------------------------------------------------------------
-- Memory Read
---------------------------------------------------------------------------
mem_rd_req_proc: process(Bus2IP_Clk) is
begin
    if rising_edge(Bus2IP_Clk) then
        if (Bus2IP_Reset = '1') then
            mem_rd_req <= (others => '0');
        else
            if (Bus2IP_CS( 0) = '1') then
                --delay memory read request with a shift-register
                mem_rd_req <= mem_rd_req(3 downto 0) & Bus2IP_RdReq;
            else
                mem_rd_req <= (others => '0');
            end if;
        end if;
    end if;
end process mem_rd_req_proc;

mem_rd_addr_ack <= '1' when ((Bus2IP_CS( 0) = '1') and (Bus2IP_RdReq = '1')) else '0';
mem_rd_ack      <= '1' when (mem_rd_req( 4) = '1') else '0';

---------------------------------------------------------------------------
-- Memory write
---------------------------------------------------------------------------
mem_wr_ack                     <= '1' when ((Bus2IP_CS( 0) = '1') and (Bus2IP_WrReq = '1')) else '0';

---------------------------------------------------------------------------
-- Memory Interface
---------------------------------------------------------------------------
mem_address                    <= Bus2IP_Addr;
mem_rd_data                    <= X"00000000";
mem_wr_data                    <= Bus2IP_Data(0 to 31);

---------------------------------------------------------------------------
-- CHIPSCOPE connections
---------------------------------------------------------------------------

--csp_set1.cpj
DBG_TX_PKT_P0 : ibfb_packet_rx
generic map(
    K_SOP => K_SOP,
    K_EOP => K_EOP
)
port map(
    i_rst => Bus2IP_Reset,
    i_clk => user_clk,
    --MGT FIFO interface
    o_next      => open,
    i_valid     => p0_txf_write(1),
    i_charisk   => p0_txf_charisk(1),
    i_data      => p0_txf_data(1),
    --user interface
    o_bad_data => dbg_out_baddata,
    o_eop      => dbg_out_valid,
    o_crc_good => dbg_out_good,
    o_rx_data  => dbg_out_pkt,
    --debug
    o_csp_clk   => open,
    o_csp_data  => open
);

DBG_TX_PKT_BPM0 : ibfb_packet_rx
generic map(
    K_SOP => K_SOP,
    K_EOP => K_EOP
)
port map(
    i_rst => Bus2IP_Reset,
    i_clk => user_clk,
    --MGT FIFO interface
    o_next      => open,
    i_valid     => bpm_txf_write(0),
    i_charisk   => bpm_txf_charisk(0),
    i_data      => bpm_txf_data(0),
    --user interface
    o_bad_data => dbg_bpm_baddata,
    o_eop      => dbg_bpm_valid,
    o_crc_good => dbg_bpm_good,
    o_rx_data  => dbg_bpm_pkt,
    --debug
    o_csp_clk   => open,
    o_csp_data  => open
);


O_CSP_CLK   <= user_clk; --Bus2IP_Clk;

--csp_set0.cpj
CSP0_GEN : if CSP_SET = 0 generate
    bad_k(0) <= '1' when p0_txf_write(1) = '1' and 
                         p0_txf_charisk(1)(0) = '1' and 
                         p0_txf_data(1)(07 downto 00) /= K_SOP and 
                         p0_txf_data(1)(07 downto 00) /= K_EOP 
                    else '0';
    bad_k(1) <= '1' when p0_txf_write(1) = '1' and 
                         p0_txf_charisk(1)(1) = '1' and 
                         p0_txf_data(1)(15 downto 08) /= K_SOP and 
                         p0_txf_data(1)(15 downto 08) /= K_EOP 
                    else '0';
    bad_k(2) <= '1' when p0_txf_write(1) = '1' and 
                         p0_txf_charisk(1)(2) = '1' and 
                         p0_txf_data(1)(23 downto 16) /= K_SOP and 
                         p0_txf_data(1)(23 downto 16) /= K_EOP 
                    else '0';
    bad_k(3) <= '1' when p0_txf_write(1) = '1' and 
                         p0_txf_charisk(1)(3) = '1' and 
                         p0_txf_data(1)(31 downto 24) /= K_SOP and 
                         p0_txf_data(1)(31 downto 24) /= K_EOP 
                    else '0';

    O_CSP_REG_P : process(user_clk) 
    begin
        if rising_edge(user_clk) then
            O_CSP_DATA(         127) <= sync_bunch_trig;

            --
            O_CSP_DATA(115 downto 112) <= bad_k;
            O_CSP_DATA(           111) <= rout_out_err(1);
            O_CSP_DATA(           110) <= rout_out_err(0);
            O_CSP_DATA(           109) <= rout_out_next(1);
            O_CSP_DATA(           108) <= rout_out_next(0);
            O_CSP_DATA(           107) <= rout_in_next(2);
            O_CSP_DATA(           106) <= rout_in_next(1);
            O_CSP_DATA(           105) <= rout_in_next(0);
            O_CSP_DATA(           104) <= rout_out_valid(1);
            O_CSP_DATA(           103) <= rout_out_valid(0);
            O_CSP_DATA(           102) <= rout_in_valid(2);
            O_CSP_DATA(           101) <= rout_in_valid(1);
            O_CSP_DATA(           100) <= rout_in_valid(0);
            O_CSP_DATA( 99 downto  96) <= rout_out_charisk(1);          
            O_CSP_DATA( 95 downto  92) <= rout_out_charisk(0);          
            O_CSP_DATA( 91 downto  88) <= rout_in_charisk(2);          
            O_CSP_DATA( 87 downto  84) <= rout_in_charisk(1);          
            O_CSP_DATA( 83 downto  80) <= rout_in_charisk(0);          
            O_CSP_DATA( 79 downto  64) <= rout_out_data(1)(15 downto 0);
            O_CSP_DATA( 63 downto  48) <= rout_out_data(0)(15 downto 0);
            O_CSP_DATA( 47 downto  32) <= rout_in_data(2)(15 downto 0);
            O_CSP_DATA( 31 downto  16) <= rout_in_data(1)(15 downto 0);
            O_CSP_DATA( 15 downto  00) <= rout_in_data(0)(15 downto 0);
        end if;
    end process;
end generate; --CSP0_GEN


CSP1_GEN : if CSP_SET = 1 generate
    O_CSP_REG_P : process(user_clk) 
    begin
        if rising_edge(user_clk) then
            timer <= timer+1; --free running time reference

            O_CSP_DATA(           127) <= sync_bunch_trig;
            O_CSP_DATA(           126) <= pkt_fifo_next;
            O_CSP_DATA(125 downto 118) <= bpm_id;
                
            O_CSP_DATA(            93) <= dbg_ynew;
            O_CSP_DATA(            92) <= dbg_xnew;
            O_CSP_DATA(            91) <= dbg_xnew or dbg_ynew;
            O_CSP_DATA(            90) <= dbg_btt;
            O_CSP_DATA(            89) <= dbg_bpm_baddata;
            O_CSP_DATA(            88) <= dbg_bpm_good;
            O_CSP_DATA(            87) <= dbg_bpm_valid;
            O_CSP_DATA(            86) <= dbg_out_baddata;
            O_CSP_DATA(            85) <= dbg_out_good;
            O_CSP_DATA(            84) <= dbg_out_valid;
            O_CSP_DATA( 83 downto  82) <= dbg_bpm_pkt.ctrl(1 downto 0);
            O_CSP_DATA( 81 downto  80) <= dbg_out_pkt.ctrl(1 downto 0);
            O_CSP_DATA( 79 downto  72) <= dbg_bpm_pkt.bpm;
            O_CSP_DATA( 71 downto  64) <= dbg_out_pkt.bpm;
            O_CSP_DATA( 63 downto  48) <= dbg_bpm_pkt.bucket;
            O_CSP_DATA( 47 downto  32) <= dbg_out_pkt.bucket;
            O_CSP_DATA( 31 downto  00) <= std_logic_vector(timer);
        end if;
    end process;
end generate; --CSP1_GEN


CSP2_GEN : if CSP_SET = 2 generate
    O_CSP_REG_P : process(user_clk) 
    begin
        if rising_edge(user_clk) then
            timer <= timer+1; --free running time reference

            O_CSP_DATA(           127) <= sync_bunch_trig;
            O_CSP_DATA(           126) <= pkt_fifo_next;
            O_CSP_DATA(125 downto 118) <= bpm_id;
                
            O_CSP_DATA(            91) <= pkt_fifo_werr;
            O_CSP_DATA(            90) <= pkt_fifo_rerr;
            O_CSP_DATA(            89) <= dbg_bpm_baddata;
            O_CSP_DATA(            88) <= dbg_bpm_good;
            O_CSP_DATA(            87) <= dbg_bpm_valid;
            O_CSP_DATA(            86) <= dbg_out_baddata;
            O_CSP_DATA(            85) <= dbg_out_good;
            O_CSP_DATA(            84) <= dbg_out_valid;
            O_CSP_DATA( 83 downto  82) <= dbg_bpm_pkt.ctrl(1 downto 0);
            O_CSP_DATA( 81 downto  80) <= dbg_out_pkt.ctrl(1 downto 0);
            O_CSP_DATA( 79 downto  72) <= dbg_bpm_pkt.bpm;
            O_CSP_DATA( 71 downto  64) <= dbg_out_pkt.bpm;
            O_CSP_DATA( 63 downto  48) <= dbg_bpm_pkt.bucket;
            O_CSP_DATA( 47 downto  32) <= dbg_out_pkt.bucket;
            O_CSP_DATA( 31 downto  16) <= dbg_fifo_bkt;      
            O_CSP_DATA( 15 downto  08) <= X"00";             
            O_CSP_DATA( 07 downto  04) <= dbg_fifo_fout;     
            O_CSP_DATA(            03) <= dbg_fifo_next;
            O_CSP_DATA(            02) <= dbg_xnew;
            O_CSP_DATA(            01) <= dbg_xnew or dbg_ynew;
            O_CSP_DATA(            00) <= dbg_btt;
        end if;
    end process;
end generate; --CSP2_GEN

---------------------------------------------------------------------------
-- PLB registers connections (local clock domain)
---------------------------------------------------------------------------

PLB_REG_CORE_CLOCK_P : process(Bus2IP_Clk)
begin
    if rising_edge(Bus2IP_Clk) then
        p0_fifo_rst_c     <= slv_reg_wr(0)(01 downto 00); 
        bpm_fifo_rst_c    <= slv_reg_wr(0)(05 downto 02); 
        pkt_fifo_werr_rst <= slv_reg_wr(0)(06);
        pkt_fifo_rerr_rst <= slv_reg_wr(0)(07);
        router_err_rst0   <= slv_reg_wr(0)(08);
        router_err_rst1   <= slv_reg_wr(0)(09);
        --
        p0_loopback(0)    <= slv_reg_wr(1)(02 downto 00); 
        p0_loopback(1)    <= slv_reg_wr(1)(06 downto 04); 
        --
        bpm_loopback(0)   <= slv_reg_wr(1)(10 downto 08); 
        bpm_loopback(1)   <= slv_reg_wr(1)(14 downto 12); 
        bpm_loopback(2)   <= slv_reg_wr(1)(18 downto 16); 
        bpm_loopback(3)   <= slv_reg_wr(1)(22 downto 20); 
        bpm_id            <= slv_reg_wr(1)(31 downto 24);
        bpm_enable        <= slv_reg_wr(9)(          00);
        route_bpm2side    <= slv_reg_wr(9)(          08);
        route_bpm2back    <= slv_reg_wr(9)(          09);
        route_side2side   <= slv_reg_wr(9)(          10);
        route_side2back   <= slv_reg_wr(9)(          11);
        route_back2side   <= slv_reg_wr(9)(          12);
        route_back2back   <= slv_reg_wr(9)(          13);

    
        -- STATUS -----------------------------------------------------------------
        slv_reg_rd( 0)               <= slv_reg_wr(0);          
        slv_reg_rd( 1)               <= slv_reg_wr(1);          
        --
        slv_reg_rd( 2)( 0)           <= p0_mgt_o.ctrl.PLLLKDET;
        slv_reg_rd( 2)( 1)           <= p0_mgt_o.ctrl.RESETDONE0;
        slv_reg_rd( 2)( 2)           <= p0_mgt_o.ctrl.RESETDONE1;
        slv_reg_rd( 2)( 3)           <= '0';
        slv_reg_rd( 2)( 5 downto  4) <= p0_mgt_o.rx(0).RXLOSSOFSYNC;
        slv_reg_rd( 2)( 7 downto  6) <= p0_mgt_o.rx(1).RXLOSSOFSYNC;
        --
        slv_reg_rd( 2)( 8)           <= bpm01_mgt_o.ctrl.PLLLKDET;
        slv_reg_rd( 2)( 9)           <= bpm01_mgt_o.ctrl.RESETDONE0;
        slv_reg_rd( 2)(10)           <= bpm01_mgt_o.ctrl.RESETDONE1;
        slv_reg_rd( 2)(11)           <= '0';
        slv_reg_rd( 2)(13 downto 13) <= bpm01_mgt_o.rx(0).RXLOSSOFSYNC;
        slv_reg_rd( 2)(15 downto 14) <= bpm01_mgt_o.rx(1).RXLOSSOFSYNC;
        --
        slv_reg_rd( 2)(16)           <= '0'; --bpm23_mgt_o.ctrl.PLLLKDET;
        slv_reg_rd( 2)(17)           <= '0'; --bpm23_mgt_o.ctrl.RESETDONE0;
        slv_reg_rd( 2)(18)           <= '0'; --bpm23_mgt_o.ctrl.RESETDONE1;
        slv_reg_rd( 2)(19)           <= '0';
        slv_reg_rd( 2)(21 downto 20) <= "00"; --bpm23_mgt_o.rx(0).RXLOSSOFSYNC;
        slv_reg_rd( 2)(23 downto 22) <= "00"; --bpm23_mgt_o.rx(1).RXLOSSOFSYNC;
        --
        slv_reg_rd( 2)(29 downto 24) <= bpm_rx_sync & p0_rx_sync;
        --
        slv_reg_rd( 3)               <= std_logic_vector(los_cnt(1)) & std_logic_vector(los_cnt(0));
        slv_reg_rd( 4)               <= std_logic_vector(los_cnt(3)) & std_logic_vector(los_cnt(2));
        slv_reg_rd( 5)               <= std_logic_vector(los_cnt(5)) & std_logic_vector(los_cnt(4));
        --
        slv_reg_rd( 6)(15 downto  0) <= K_SOP & K_EOP;
        --
        slv_reg_rd( 7)               <= std_logic_vector(pkt_fifo_rerr_cnt) & std_logic_vector(pkt_fifo_werr_cnt);
        slv_reg_rd( 8)               <= std_logic_vector(router_err_cnt1) & std_logic_vector(router_err_cnt1);
        --
        slv_reg_rd( 9)               <= slv_reg_wr(9);          
        --
        slv_reg_rd(31)               <= FW_VERSION;
    end if;
end process;



---------------------------------------------------------------------------
-- Loss of sync counters
---------------------------------------------------------------------------
--Loss-of-sync detection (rising edge)
LOS_RE_P0_0 : process(rxrecclk(0))
begin
    if rising_edge(rxrecclk(0)) then
        --first registration of LOS signals
        los(0) <= p0_mgt_o.rx(0).RXLOSSOFSYNC(1);
        los_r(0) <= los(0);
    end if;
end process;

LOS_RE_P0_1 : process(rxrecclk(1))
begin
    if rising_edge(rxrecclk(1)) then
        los(1) <= p0_mgt_o.rx(1).RXLOSSOFSYNC(1);
        los_r(1) <= los(1);
    end if;
end process;

LOS_RE_BPM_0 : process(rxrecclk(2))
begin
    if rising_edge(rxrecclk(2)) then
        los(2) <= bpm01_mgt_o.rx(0).RXLOSSOFSYNC(1);
        los_r(2) <= los(2);
    end if;
end process;

LOS_RE_BPM_1 : process(rxrecclk(3))
begin
    if rising_edge(rxrecclk(3)) then
        los(3) <= bpm01_mgt_o.rx(1).RXLOSSOFSYNC(1);
        los_r(3) <= los(3);
    end if;
end process;

--LOS_RE_BPM_2 : process(rxrecclk(4))
--begin
--    if rising_edge(rxrecclk(4)) then
--        los(4) <= '0'; --bpm23_mgt_o.rx(0).RXLOSSOFSYNC(1);
--        los_r(4) <= los(4);
--    end if;
--end process;

--LOS_RE_BPM_3 : process(rxrecclk(5))
--begin
--    if rising_edge(rxrecclk(5)) then
--        los(5) <= '0'; --bpm23_mgt_o.rx(1).RXLOSSOFSYNC(1);
--    end if;
--end process;

--Increment counters on rising edge of LOSSOFSYNC(1)
LOS_CNT_GEN : for i in 0 to 3 generate
    LOS_CNT_P : process(rxrecclk(i))
    begin
        if rising_edge(rxrecclk(i)) then
            if Bus2IP_Reset = '1' or los_cnt_rst(i) = '1' then
                los_cnt(i) <= (others => '0');
            else
                if los(i) = '1' and los_r(i) = '0' then --and los_cnt(i)(los_cnt(i)'left) = '0' then
                    los_cnt(i) <= los_cnt(i)+1;
                end if;
            end if;
        end if;
    end process;
end generate;

---------------------------------------------------------------------------
-- GTX components
---------------------------------------------------------------------------
  p0_fifo_rst(0) <= Bus2IP_Reset or   p0_fifo_rst_c(0);
  p0_fifo_rst(1) <= Bus2IP_Reset or   p0_fifo_rst_c(1);
 bpm_fifo_rst(0) <= Bus2IP_Reset or  bpm_fifo_rst_c(0);
 bpm_fifo_rst(1) <= Bus2IP_Reset or  bpm_fifo_rst_c(1);
 bpm_fifo_rst(2) <= Bus2IP_Reset or  bpm_fifo_rst_c(2);
 bpm_fifo_rst(3) <= Bus2IP_Reset or  bpm_fifo_rst_c(3);

--BACKPLANE LINK
P0_TILE : gtx_tile
generic map(
    --mgt
    G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(0),
    G_GTX_TILE_REFCLK_FREQ => C_P0_REFCLK_FREQ,
    G_GTX_BAUD_RATE        => C_P0_BAUD_RATE
)
port map(
    --MGT
    I_GTX_REFCLK1_IN => I_GTX_REFCLK1_IN,
    I_GTX_REFCLK2_IN => I_GTX_REFCLK2_IN,
    I_GTX_RX_N       => I_GTX_RX_N(1 downto 0),
    I_GTX_RX_P       => I_GTX_RX_P(1 downto 0),
    O_GTX_TX_N       => O_GTX_TX_N(1 downto 0),
    O_GTX_TX_P       => O_GTX_TX_P(1 downto 0),
    --
    i_loopback0      => p0_loopback(0),
    i_loopback1      => p0_loopback(1),
    o_mgt            => p0_mgt_o,
    ------------------------------------------------------------------------
    -- FIFO interface
    ------------------------------------------------------------------------
    i_clk             => user_clk,
    --Channel 0
    i_fifo_reset0     => p0_fifo_rst(0),
    --TX
    o_tx_vld0         => p0_txf_vld(0), --debug
    o_txfifo_full0    => p0_txf_full(0),
    i_txfifo_write0   => p0_txf_write(0),
    i_txfifo_charisk0 => p0_txf_charisk(0),
    i_txfifo_data0    => p0_txf_data(0),
    --RX
    o_rx_sync_done0   => p0_rx_sync(0),
    o_rx_vld0         => p0_rxf_vld(0),
    i_rxfifo_next0    => p0_rxf_next(0),
    o_rxfifo_empty0   => p0_rxf_empty(0),
    o_rxfifo_charisk0 => p0_rxf_charisk(0),
    o_rxfifo_data0    => p0_rxf_data(0),
    --Channel 1
    i_fifo_reset1     => p0_fifo_rst(1),
    --TX
    o_tx_vld1         => p0_txf_vld(1), --debug
    o_txfifo_full1    => p0_txf_full(1),
    i_txfifo_write1   => p0_txf_write(1),
    i_txfifo_charisk1 => p0_txf_charisk(1),
    i_txfifo_data1    => p0_txf_data(1),
    --RX
    o_rx_sync_done1   => p0_rx_sync(1),
    o_rx_vld1         => p0_rxf_vld(1),
    i_rxfifo_next1    => p0_rxf_next(1),
    o_rxfifo_empty1   => p0_rxf_empty(1),
    o_rxfifo_charisk1 => p0_rxf_charisk(1),
    o_rxfifo_data1    => p0_rxf_data(1)
);

--unused channels
p0_txf_write(0)   <= '0';
p0_txf_charisk(0) <= X"0";
p0_txf_data(0)    <= X"00000000";
p0_rxf_next(0)    <= not p0_rxf_empty(0);


--CROSS-FPGA LINK
BPM01_TILE : gtx_tile
generic map(
    --mgt
    G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(1),
    G_GTX_TILE_REFCLK_FREQ => C_BPM_REFCLK_FREQ,
    G_GTX_BAUD_RATE        => C_BPM_BAUD_RATE
)
port map(
    --MGT
    I_GTX_REFCLK1_IN => I_GTX_REFCLK1_IN,
    I_GTX_REFCLK2_IN => I_GTX_REFCLK2_IN,
    I_GTX_RX_N       => I_GTX_RX_N(3 downto 2),
    I_GTX_RX_P       => I_GTX_RX_P(3 downto 2),
    O_GTX_TX_N       => O_GTX_TX_N(3 downto 2),
    O_GTX_TX_P       => O_GTX_TX_P(3 downto 2),
    --
    i_loopback0      => bpm_loopback(0),
    i_loopback1      => bpm_loopback(1),
    o_mgt            => bpm01_mgt_o,
    ------------------------------------------------------------------------
    -- FIFO interface
    ------------------------------------------------------------------------
    i_clk             => user_clk, 
    --Channel 0
    i_fifo_reset0     => bpm_fifo_rst(0),
    --TX
    o_tx_vld0         => bpm_txf_vld(0), --debug
    o_txfifo_full0    => bpm_txf_full(0),
    i_txfifo_write0   => bpm_txf_write(0),
    i_txfifo_charisk0 => bpm_txf_charisk(0),
    i_txfifo_data0    => bpm_txf_data(0),
    --RX
    o_rx_sync_done0   => bpm_rx_sync(0),
    o_rx_vld0         => bpm_rxf_vld(0), --debug
    i_rxfifo_next0    => bpm_rxf_next(0),
    o_rxfifo_empty0   => bpm_rxf_empty(0),
    o_rxfifo_charisk0 => bpm_rxf_charisk(0),
    o_rxfifo_data0    => bpm_rxf_data(0),
    --Channel 1
    i_fifo_reset1     => bpm_fifo_rst(1),
    --TX
    o_tx_vld1         => bpm_txf_vld(1), --debug
    o_txfifo_full1    => bpm_txf_full(1),
    i_txfifo_write1   => bpm_txf_write(1),
    i_txfifo_charisk1 => bpm_txf_charisk(1),
    i_txfifo_data1    => bpm_txf_data(1),
    --RX
    o_rx_sync_done1   => bpm_rx_sync(1),
    o_rx_vld1         => bpm_rxf_vld(1), --debug
    i_rxfifo_next1    => bpm_rxf_next(1),
    o_rxfifo_empty1   => bpm_rxf_empty(1),
    o_rxfifo_charisk1 => bpm_rxf_charisk(1),
    o_rxfifo_data1    => bpm_rxf_data(1) 
);

--unused channels
bpm_txf_write(1)   <= '0';
bpm_txf_charisk(1) <= X"0";
bpm_txf_data(1)    <= X"00000000";
bpm_rxf_next(1)    <= not bpm_rxf_empty(1);

--following tile is not used
--BPM23_TILE : gtx_tile
--generic map(
--    --mgt
--    G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(2),
--    G_GTX_TILE_REFCLK_FREQ => C_BPM_REFCLK_FREQ,
--    G_GTX_BAUD_RATE        => C_BPM_BAUD_RATE
--)
--port map(
--    --MGT
--    I_GTX_REFCLK1_IN => I_GTX_REFCLK1_IN,
--    I_GTX_REFCLK2_IN => I_GTX_REFCLK2_IN,
--    I_GTX_RX_N       => I_GTX_RX_N(5 downto 4),
--    I_GTX_RX_P       => I_GTX_RX_P(5 downto 4),
--    O_GTX_TX_N       => O_GTX_TX_N(5 downto 4),
--    O_GTX_TX_P       => O_GTX_TX_P(5 downto 4),
--    --
--    i_loopback0      => bpm_loopback(0),
--    i_loopback1      => bpm_loopback(1),
--    o_mgt            => bpm23_mgt_o,
--    ------------------------------------------------------------------------
--    -- FIFO interface
--    ------------------------------------------------------------------------
--    i_clk             => user_clk, 
--    --Channel 0
--    i_fifo_reset0     => bpm_fifo_rst(2),
--    --TX
--    o_tx_vld0         => bpm_txf_vld(2), --debug
--    o_txfifo_full0    => bpm_txf_full(2),
--    i_txfifo_write0   => bpm_txf_write(2),
--    i_txfifo_charisk0 => bpm_txf_charisk(2),
--    i_txfifo_data0    => bpm_txf_data(2),
--    --RX
--    o_rx_sync_done0   => bpm_rx_sync(2),
--    o_rx_vld0         => bpm_rxf_vld(2), --debug
--    i_rxfifo_next0    => bpm_rxf_next(2),
--    o_rxfifo_empty0   => bpm_rxf_empty(2),
--    o_rxfifo_charisk0 => bpm_rxf_charisk(2),
--    o_rxfifo_data0    => bpm_rxf_data(2),
--    --Channel 1
--    i_fifo_reset1     => bpm_fifo_rst(3),
--    --TX
--    o_tx_vld1         => bpm_txf_vld(3), --debug
--    o_txfifo_full1    => bpm_txf_full(3),
--    i_txfifo_write1   => bpm_txf_write(3),
--    i_txfifo_charisk1 => bpm_txf_charisk(3),
--    i_txfifo_data1    => bpm_txf_data(3),
--    --RX
--    o_rx_sync_done1   => bpm_rx_sync(3),
--    o_rx_vld1         => bpm_rxf_vld(3), --debug
--    i_rxfifo_next1    => bpm_rxf_next(3),
--    o_rxfifo_empty1   => bpm_rxf_empty(3),
--    o_rxfifo_charisk1 => bpm_rxf_charisk(3),
--    o_rxfifo_data1    => bpm_rxf_data(3) 
--);
bpm_txf_vld(2 to 3)  <= "00";
bpm_txf_full(2 to 3) <= "00";
bpm_rx_sync(2 to 3)  <= "00";
bpm_rxf_vld(2 to 3)  <= "00";

--unused channels
bpm_txf_write(2)   <= '0';
bpm_txf_charisk(2) <= X"0";
bpm_txf_data(2)    <= X"00000000";
bpm_rxf_next(2)    <= not bpm_rxf_empty(2);

bpm_txf_write(3)   <= '0';
bpm_txf_charisk(3) <= X"0";
bpm_txf_data(3)    <= X"00000000";
bpm_rxf_next(3)    <= not bpm_rxf_empty(3);

---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- CORE LOGIC
---------------------------------------------------------------------------
---------------------------------------------------------------------------

-----------------------------------------------------------
--BPM packet generator
-----------------------------------------------------------
PKT_GEN : ibfb_bpm_pkt_gen
generic map(
    K_SOP => K_SOP,
    K_EOP => K_EOP 
)
port map(
    --DEBUG
    o_dbg_btt  => dbg_btt,
    o_dbg_xnew => dbg_xnew,
    o_dbg_ynew => dbg_ynew,
    o_dbg_fifo_next => dbg_fifo_next,
    o_dbg_fifo_fout => dbg_fifo_fout,
    o_dbg_fifo_bkt  => dbg_fifo_bkt,
    --cav_bpm_exfel interface
    i_adc_clk              => i_adc_clk,
    i_adc_bunch_train_trig => i_adc_bunch_train_trig,
    i_adc_x_new            => i_adc_x_new,
    i_adc_x_valid          => i_adc_x_valid,
    i_adc_x                => i_adc_x,
    i_adc_y_new            => i_adc_y_new,
    i_adc_y_valid          => i_adc_y_valid,
    i_adc_y                => i_adc_y,
    --output FIFO interface
    i_core_rst_n           => rst_n,
    i_core_clk             => user_clk,
    i_bpm_id               => bpm_id,
    o_bkt_rst              => sync_bunch_trig,
    o_pkt_fifo_werr        => pkt_fifo_werr,
    o_pkt_fifo_rerr        => pkt_fifo_rerr,
    o_pkt_fifo_empty       => pkt_fifo_empty,
    i_pkt_fifo_next        => pkt_fifo_next,
    o_pkt_fifo_isk         => pkt_fifo_isk,
    o_pkt_fifo_data        => pkt_fifo_data
);

--Packet FIFO write error counter
PKT_FIFO_WERRCNT : process(i_adc_clk)
begin
    if rising_edge(i_adc_clk) then
        if pkt_fifo_werr_rst = '1' or Bus2IP_Reset = '1' then
            pkt_fifo_werr_cnt <= (others => '0');
        elsif pkt_fifo_werr = '1' and pkt_fifo_werr_cnt(pkt_fifo_werr_cnt'left) = '0' then
            pkt_fifo_werr_cnt <= pkt_fifo_werr_cnt + 1;
        end if;
    end if;
end process;

--Packet FIFO read error counter
PKT_FIFO_RERRCNT : process(user_clk)
begin
    if rising_edge(user_clk) then
        if pkt_fifo_rerr_rst = '1' or Bus2IP_Reset = '1' then
            pkt_fifo_rerr_cnt <= (others => '0');
        elsif pkt_fifo_rerr = '1' and pkt_fifo_rerr_cnt(pkt_fifo_rerr_cnt'left) = '0' then
            pkt_fifo_rerr_cnt <= pkt_fifo_rerr_cnt + 1;
        end if;
    end if;
end process;

-----------------------------------------------------------
--Packet router input connections
-----------------------------------------------------------
--Input 0 = local BPM FIFO
pkt_fifo_next      <= rout_in_next(0);
rout_in_valid(0)   <= (not pkt_fifo_empty) and bpm_enable;
rout_in_charisk(0) <= pkt_fifo_isk;
rout_in_data(0)    <= pkt_fifo_data;

--Input 1 = cross-FPGA RX FIFO (BPM0)
bpm_rxf_next(0)    <= rout_in_next(1);
rout_in_valid(1)   <= not bpm_rxf_empty(0);
rout_in_charisk(1) <= bpm_rxf_charisk(0);
rout_in_data(1)    <= bpm_rxf_data(0);

--Input 2 = backplane RX FIFO (P0.1)
p0_rxf_next(1)     <= rout_in_next(2);
rout_in_valid(2)   <= not p0_rxf_empty(1);
rout_in_charisk(2) <= p0_rxf_charisk(1);
rout_in_data(2)    <= p0_rxf_data(1);

-----------------------------------------------------------
--Packet router instance
-----------------------------------------------------------
routing_table(0)(1 downto 0) <= route_bpm2back  & route_bpm2side;  -- (backplane, other fpga)
routing_table(1)(1 downto 0) <= route_side2back & route_side2side; -- (backplane, other fpga)
routing_table(2)(1 downto 0) <= route_back2back & route_back2side; -- (xfpga, backplane)

routing_table(0)(31 downto 2) <= (others => '0');
routing_table(1)(31 downto 2) <= (others => '0');
routing_table(2)(31 downto 2) <= (others => '0');

ROUTER : ibfb_packet_router 
generic map(
        K_SOP => K_SOP,
        K_EOP => K_EOP,
        N_INPUT_PORTS  => 3, --in0: local BPM, in1: xFPGA, in2: backplane
        N_OUTPUT_PORTS => 2 --out0: xFPGA, out1: backplane
        --ROUTING_TABLE => (X"00000003", --IN0: local BPM => to both outputs
        --                  X"00000002", --IN1: xFPGA     => to backplane 
        --                  X"00000002", --IN2: Backplane => to backplane
        --                  X"FFFFFFFF", 
        --                  X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF",
        --                  X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF",
        --                  X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF",
        --                  X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF",
        --                  X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF",
        --                  X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF",
        --                  X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF", X"FFFFFFFF")
)
port map(
    i_clk     => user_clk,
    i_rst     => Bus2IP_Reset,
    i_err_rst => '0',
    i_routing_table => routing_table,
    --input (FIFO, FWFT)
    o_next    => rout_in_next,
    i_valid   => rout_in_valid,
    i_charisk => rout_in_charisk,
    i_data    => rout_in_data,
    --output (STREAMING. i_next is used only to detect errors, but does not control data flow)
    i_out_en  => "11", --all outputs always enabled
    i_next    => rout_out_next,
    o_valid   => rout_out_valid,
    o_err     => rout_out_err,
    o_charisk => rout_out_charisk,
    o_data    => rout_out_data
);

--Packet router error counters
ROUTER_ERRCNT0 : process(user_clk)
begin
    if rising_edge(user_clk) then
        if router_err_rst0 = '1' or Bus2IP_Reset = '1' then
            router_err_cnt0 <= (others => '0');
        elsif rout_out_err(0) = '1' then -- and router_err_cnt0(router_err_cnt0'left) = '0' then
            router_err_cnt0 <= router_err_cnt0 + 1;
        end if;
    end if;
end process;

ROUTER_ERRCNT1 : process(user_clk)
begin
    if rising_edge(user_clk) then
        if router_err_rst1 = '1' or Bus2IP_Reset = '1' then
            router_err_cnt1 <= (others => '0');
        elsif rout_out_err(1) = '1' then -- and router_err_cnt1(router_err_cnt1'left) = '0' then
            router_err_cnt1 <= router_err_cnt1 + 1;
        end if;
    end if;
end process;

-----------------------------------------------------------
--Packet router output connections
-----------------------------------------------------------
--Output 0 = cross-FPGA TX FIFO
rout_out_next(0)   <= not bpm_txf_full(0);
bpm_txf_write(0)   <= rout_out_valid(0);
bpm_txf_charisk(0) <= rout_out_charisk(0);
bpm_txf_data(0)    <= rout_out_data(0);

--Output 1 = backplane  TX FIFO channel 1 => GPAC P0_2MGT(0) => MBU_COM BPMx_MGT0 => Rear SFP
rout_out_next(1)  <= not p0_txf_full(1);
p0_txf_write(1)   <= rout_out_valid(1);
p0_txf_charisk(1) <= rout_out_charisk(1);
p0_txf_data(1)    <= rout_out_data(1);

end architecture behavioral;

------------------------------------------------------------------------------
-- End of file
------------------------------------------------------------------------------

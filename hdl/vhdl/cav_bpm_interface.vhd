library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Needed for FIFO36
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

--needed for ibfb_comm_packet type
library ibfb_common_v1_00_a;
use ibfb_common_v1_00_a.ibfb_comm_package.all;

entity cav_bpm_interface is
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
end entity cav_bpm_interface;

architecture rtl of cav_bpm_interface is

-----------------------------------------------------------
--  SIGNALS DECLARATIONS  ---------------------------------
-----------------------------------------------------------
--edge detection
signal adc_x_new_r,  adc_y_new_r,  adc_btt_r : std_logic;
signal adc_x_new_re, adc_y_new_re, adc_btt_re : std_logic;

--fifo reset
signal rst_n_r, rst_fe, fifo_rst : std_logic;
signal rst_sr : std_logic_vector(3 downto 0);

--fifo write interface
signal x_wr,       y_wr       : std_logic;
signal xfifo_wr,   yfifo_wr   : std_logic;
signal xfifo_full, yfifo_full : std_logic;
signal xfifo_fin,  yfifo_fin  : std_logic_vector(3 downto 0);
signal xfifo_din,  yfifo_din  : std_logic_vector(31 downto 0);

--fifo read interface
signal fifo_next : std_logic;
signal xfifo_empty, yfifo_empty : std_logic;
signal xfifo_fout,  yfifo_fout  : std_logic_vector(3 downto 0);
signal xfifo_dout,  yfifo_dout  : std_logic_vector(31 downto 0);

signal bkt_cnt : unsigned(15 downto 0);

signal bpm_id_valid : std_logic;

--type ibfb_comm_packet is record
--    ctrl   : std_logic_vector( 7 downto 0);
--    bpm    : std_logic_vector( 7 downto 0);
--    bucket : std_logic_vector(15 downto 0);
--    xpos   : std_logic_vector(31 downto 0);
--    ypos   : std_logic_vector(31 downto 0);
--    crc    : std_logic_vector( 7 downto 0);
--end record ibfb_comm_packet;

--DEBUG
signal adc_x_new_rr, adc_y_new_rr, adc_btt_rr : std_logic;
signal dbg_xnew, dbg_ynew, dbg_btt : std_logic;

begin

-----------------------------------------------------------
--INPUT SECTION: ADC CLOCK DOMAIN  
-----------------------------------------------------------

-----------------------------------------------------------
--edge detection for input triggers
-----------------------------------------------------------
INPUT_REG_P : process(i_adc_clk)
begin
    if rising_edge(i_adc_clk) then
        adc_x_new_r <= i_adc_x_new;
        adc_y_new_r <= i_adc_y_new;
        adc_btt_r   <= i_adc_bunch_train_trig;
    end if;
end process;
adc_x_new_re <= i_adc_x_new and not adc_x_new_r;
adc_y_new_re <= i_adc_y_new and not adc_y_new_r;
adc_btt_re   <= i_adc_bunch_train_trig and not adc_btt_r;

-----------------------------------------------------------
--DEBUG
-----------------------------------------------------------
DEBUG_P_IN : process(i_adc_clk)
begin
    if rising_edge(i_adc_clk) then
        adc_x_new_rr <= adc_x_new_r;
        adc_y_new_rr <= adc_y_new_r;
        adc_btt_rr   <= adc_btt_r;
    end if;
end process;
--extend pulses to make sure they're sampled by core clock
dbg_xnew <= adc_x_new_r or adc_x_new_rr;
dbg_ynew <= adc_y_new_r or adc_y_new_rr;
dbg_btt  <= adc_btt_r   or adc_btt_rr;

--Synchronize debug signals with output clock
DEBUG_P_OUT : process(i_core_clk)
begin
    if rising_edge(i_core_clk) then
        o_dbg_xnew <= dbg_xnew;
        o_dbg_ynew <= dbg_ynew;
        o_dbg_btt  <= dbg_btt;
    end if;
end process;

-----------------------------------------------------------
--data valid signals (either data or BTTrigger)
-----------------------------------------------------------
x_wr <= adc_x_new_re or adc_btt_re;
y_wr <= adc_y_new_re or adc_btt_re;

-----------------------------------------------------------
--FIFO write signals (mask write signals when FIFO is full)
-----------------------------------------------------------
xfifo_wr <= x_wr and not xfifo_full;
yfifo_wr <= y_wr and not yfifo_full;

-----------------------------------------------------------
--FIFO data buses
-----------------------------------------------------------
xfifo_fin <= "00" & adc_btt_re & i_adc_x_valid;
yfifo_fin <= "00" & adc_btt_re & i_adc_y_valid;
xfifo_din <= i_adc_x;
yfifo_din <= i_adc_y;

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
fifo_rst <= rst_sr(0) or rst_sr(1) or rst_sr(2);

-----------------------------------------------------------
--FIFOs
-----------------------------------------------------------
CDC_FIFO_X : FIFO36
generic map(
    DATA_WIDTH              => 36,
    ALMOST_FULL_OFFSET      => X"0010", --ALMOST_FULL when EMPTY LOCATIONS are less than this value
    ALMOST_EMPTY_OFFSET     => X"0010", --ALMOST_EMPTY when FULL LOCATIONS are less than this value
    DO_REG                  => 1, --pipeline register. Must be enabled for asynchronous operation
    EN_SYN                  => FALSE, --synchronous/asynchronous mode
    FIRST_WORD_FALL_THROUGH => TRUE
)
port map(
    RST         => fifo_rst, --must be asserted for at least 3 clock cycles
    --
    WRCLK       => i_adc_clk,
    FULL        => xfifo_full,
    ALMOSTFULL  => open,
    WREN        => xfifo_wr,
    WRCOUNT     => open,
    WRERR       => o_xfifo_wr_err,
    DIP         => xfifo_fin,
    DI          => xfifo_din,
    --
    RDCLK       => i_core_clk,
    EMPTY       => xfifo_empty,
    ALMOSTEMPTY => open,
    RDEN        => fifo_next,
    RDCOUNT     => open,
    RDERR       => open,
    DOP         => xfifo_fout,
    DO          => xfifo_dout
);

CDC_FIFO_Y : FIFO36
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
    WRCLK       => i_adc_clk,
    FULL        => yfifo_full,
    ALMOSTFULL  => open,
    WREN        => yfifo_wr,
    WRCOUNT     => open,
    WRERR       => o_yfifo_wr_err,
    DIP         => yfifo_fin,
    DI          => yfifo_din,
    --
    RDCLK       => i_core_clk,
    EMPTY       => yfifo_empty,
    ALMOSTEMPTY => open,
    RDEN        => fifo_next,
    RDCOUNT     => open,
    RDERR       => open,
    DOP         => yfifo_fout,
    DO          => yfifo_dout
);

-----------------------------------------------------------
-- FIFO READ ----------------------------------------------
-----------------------------------------------------------
--FIFOs are synchronized. If a different number of X and Y 
--values are written, then FIFOs go out of sync and
--must be reset
fifo_next <= (not xfifo_empty) and (not yfifo_empty) and (not i_pkt_tx_busy); 

-----------------------------------------------------------
-- FIFO READ ----------------------------------------------
-----------------------------------------------------------
BKT_CNT_P : process(i_core_clk)
begin
    if rising_edge(i_core_clk) then
        if i_core_rst_n = '0' then
            bkt_cnt <= (others => '0');
            o_bkt_rst <= '0';
        else
            if fifo_next = '1' then
                if xfifo_fout(1) = '1' then
                    bkt_cnt <= (others => '0');
                    o_bkt_rst <= '1';
                else
                    bkt_cnt <= bkt_cnt+1;
                    o_bkt_rst <= '0';
                end if;
            else
                o_bkt_rst <= '0'; --ML84 added 23.8.16
            end if;
        end if;
    end if;
end process;

-----------------------------------------------------------
-- DATA OUTPUT  -------------------------------------------
-----------------------------------------------------------
o_pkt_tx_valid <= fifo_next and (not xfifo_fout(1)) and bpm_id_valid; --ML84, 22.8.16: added bpm_id_valid

o_pkt_tx_data.ctrl   <= "000000" & xfifo_fout(0) & yfifo_fout(0); --valid flags

--ML84, 22.8.16: registered bpm_id input (static). Added bpm_id_valid
BPM_ID_REG : process(i_core_clk)
begin
    if rising_edge(i_core_clk) then
        o_pkt_tx_data.bpm    <= i_bpm_id; --registered to improve timing closure
        
        if i_bpm_id = X"00" then
            bpm_id_valid <= '0';
        else
            bpm_id_valid <= '1';
        end if;
    end if;
end process;

o_pkt_tx_data.bucket <= std_logic_vector(bkt_cnt);
o_pkt_tx_data.xpos   <= xfifo_dout;
o_pkt_tx_data.ypos   <= yfifo_dout;
o_pkt_tx_data.crc    <= (others => '0'); --computer by IBFB_PACKET_TX component

--DEBUG
o_dbg_fifo_next <= fifo_next;
o_dbg_fifo_fout <= yfifo_fout(1 downto 0) & xfifo_fout(1 downto 0);

end architecture rtl;

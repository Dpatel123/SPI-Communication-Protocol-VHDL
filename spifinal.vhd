----------------------------------------------------------------------------------
-- Create Date : 11 -01 -2021
-- Created By: Dharmesh Patel (38073)
-- Module Name : spifinal - Behavioral
-- Project Name : Pulse oximeter
-- Target Devices : FPGA
-- Description : 16 ,24 bit SPI state machine (for DAC ,PGA and ADC )
----------------------------------------------------------------------------------


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.std_logic_arith.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY spifinal IS
    GENERIC (DATA_LENGTH_BIT_SIZE   : INTEGER := 2;
             DATA_SIZE              : INTEGER := 32;
             BAUD_RATE_DIVIDER_SIZE : INTEGER := 8);
    PORT ( sysclk                : IN STD_LOGIC;
           reset              : IN STD_LOGIC;
           data_length        : IN STD_LOGIC_VECTOR (DATA_LENGTH_BIT_SIZE-1 DOWNTO 0);
           baud_rate_divider  : IN STD_LOGIC_VECTOR (BAUD_RATE_DIVIDER_SIZE-1 DOWNTO 0);
           clock_polarity     : IN STD_LOGIC;
           clock_phase        : IN STD_LOGIC;
           start_transmission : IN STD_LOGIC;
           transmission_done  : OUT STD_LOGIC;
           data_tx  : IN  STD_LOGIC_VECTOR (DATA_SIZE-1 DOWNTO 0);
           data_rx  : OUT STD_LOGIC_VECTOR (DATA_SIZE-1 DOWNTO 0) := (others => '0');
           spi_clk  : OUT STD_LOGIC;
           spi_MOSI : OUT STD_LOGIC;
           spi_MISO : IN STD_LOGIC;
           spi_cs   : OUT STD_LOGIC);
END spifinal;

ARCHITECTURE Behavioral OF spi IS

TYPE SPI_STATE_TYPE IS (SPI_IDLE, SPI_REDY, SPI_CLK_IDLE, SPI_CLK_ACTIVE, SPI_STOP);
SIGNAL current_state, next_state: SPI_STATE_TYPE;

SIGNAL clk_pulse : STD_LOGIC;

SIGNAL i_tx_buffer : STD_LOGIC_VECTOR (DATA_SIZE-1 DOWNTO 0) := (others => '0');
SIGNAL i_rx_buffer : STD_LOGIC_VECTOR (DATA_SIZE-1 DOWNTO 0) := (others => '0');
SIGNAL counter : INTEGER RANGE 0 TO DATA_SIZE-1 := 0;

CONSTANT DATA_LENGTH_1 : INTEGER := 16;
CONSTANT DATA_LENGTH_2 : INTEGER := 24;

BEGIN

    baud_rate_division_process: PROCESS (sysclk, reset, baud_rate_divider, clk_pulse)
    VARIABLE baud_rate_counter : UNSIGNED (7 DOWNTO 0) := (others => '0');
    BEGIN
        IF rising_edge(sysclk) THEN
            clk_pulse <= '0';
            IF reset = '1' OR current_state = SPI_IDLE THEN
                baud_rate_counter := (others => '0');
            ELSIF baud_rate_divider = CONV_STD_LOGIC_VECTOR(baud_rate_counter, BAUD_RATE_DIVIDER_SIZE) THEN
                baud_rate_counter := (others => '0');
                clk_pulse <= '1';
            ELSE
                baud_rate_counter := baud_rate_counter + 1;
            END IF;
        END IF;
    END PROCESS;

    spi_switch_state : PROCESS (sysclk, current_state, next_state)
    VARIABLE data_length_internal : UNSIGNED (1 DOWNTO 0);
    BEGIN
        IF rising_edge(sysclk) THEN
            IF reset = '1' THEN
                current_state <= SPI_IDLE;
                i_tx_buffer <= (others => '0');
                i_rx_buffer <= (others => '0');
                data_rx <= (others => '0');
            ELSIF next_state = SPI_REDY THEN -- Get redy immediately
                current_state <= SPI_REDY;
                data_rx <= (others => '0');
                i_rx_buffer <= (others => '0');
                
                CASE data_length IS
                    WHEN "01" =>
                        i_tx_buffer(DATA_SIZE-1 downto DATA_SIZE-DATA_LENGTH_1) <= data_tx(DATA_LENGTH_1-1 downto 0);
                        counter <= DATA_LENGTH_1-1;
                    WHEN "10" =>
                        i_tx_buffer(DATA_SIZE-1 downto DATA_SIZE-DATA_LENGTH_2) <= data_tx(DATA_LENGTH_2-1 downto 0);
                        counter <= DATA_LENGTH_2-1;
                    WHEN OTHERS => NULL;
                END CASE;
            ELSIF clk_pulse = '1' THEN       -- Or Wait for the pulse
                
                IF clock_phase = '0' THEN
                    -- PUSH INPUT
                    IF next_state = SPI_CLK_ACTIVE THEN
                        i_rx_buffer <= i_rx_buffer(DATA_SIZE-2 DOWNTO 0) & spi_MISO;
                    END IF;
                    -- POP OUTPUT
                    IF next_state = SPI_CLK_IDLE THEN
                        i_tx_buffer <= i_tx_buffer(DATA_SIZE-2 downto 0) & '-';
                        counter <= counter - 1;
                    END IF;
                END IF;
                
                IF clock_phase = '1' THEN
                    -- PUSH INPUT
                    IF current_state = SPI_CLK_ACTIVE THEN
                        i_rx_buffer <= i_rx_buffer(DATA_SIZE-2 DOWNTO 0) & spi_MISO;
                    END IF;
                    -- POP OUTPUT
                    IF current_state = SPI_CLK_IDLE AND next_state = SPI_CLK_ACTIVE THEN
                        i_tx_buffer <= i_tx_buffer(DATA_SIZE-2 downto 0) & '-';
                        counter <= counter - 1;
                    END IF;
                END IF;
                
                IF current_state = SPI_STOP THEN
                    data_rx <= i_rx_buffer;
                END IF;
                
                current_state <= next_state;
            END IF;
        END IF;
    END PROCESS;
    
    
    spi_mechanism :  process (next_state, clock_polarity, current_state, start_transmission, i_tx_buffer, clock_phase, counter)
    BEGIN
        next_state <= current_state;
        spi_clk <= clock_polarity;
        spi_cs <= '1';
        spi_MOSI <= '0';
        transmission_done <= '1';

        CASE current_state IS
            WHEN SPI_IDLE =>
                IF start_transmission = '1' THEN
                    next_state <= SPI_REDY;
                END IF;
            WHEN SPI_REDY =>
                spi_cs <= '0';
                transmission_done <= '0';
                IF clock_phase = '0' THEN
                    spi_MOSI <= i_tx_buffer(DATA_SIZE-1);
                END IF;
                next_state <= SPI_CLK_ACTIVE;
            WHEN SPI_CLK_ACTIVE =>
                spi_cs <= '0';
                transmission_done <= '0';
                spi_clk <= NOT clock_polarity;
                spi_MOSI <= i_tx_buffer(DATA_SIZE-1);
                IF counter = 0 THEN
                    next_state <= SPI_STOP;
                ELSE
                    next_state <= SPI_CLK_IDLE;
                END IF;
            WHEN SPI_CLK_IDLE =>
                spi_cs <= '0';
                transmission_done <= '0';
                spi_MOSI <= i_tx_buffer(DATA_SIZE-1);
                IF counter = 0 AND clock_phase = '1' THEN
                    next_state <= SPI_STOP;
                ELSE
                    next_state <= SPI_CLK_ACTIVE;
                END IF;
            WHEN SPI_STOP =>
                IF clock_phase = '1' THEN
                    spi_MOSI <= i_tx_buffer(DATA_SIZE-1);
                END IF;
                next_state <= SPI_IDLE;
                transmission_done <= '0';
                spi_cs <= '0';
        END CASE;
    END PROCESS;

END Behavioral;

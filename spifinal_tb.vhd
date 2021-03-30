----------------------------------------------------------------------------------
-- Create Date:    11-01-2021 
-- Created By: Dharmesh Patel(38073) 
-- Module Name:    spifinal_tb - Behavioral 
-- Project Name: Pulse oximeter
-- Target Devices: FPGA
-- Description:   Test bench file for 16,24 bit SPI state machine (for DAC,PGA and ADC)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity spifinal_tb is
end spifinal_tb;

architecture Behavioral of spifinal_tb is

COMPONENT spifinal IS
    PORT ( sysclk             : IN STD_LOGIC;
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
END COMPONENT spifinal;

SIGNAL sysclk      : STD_LOGIC := '0';
SIGNAL reset      : STD_LOGIC := '1';
SIGNAL data_length : STD_LOGIC_VECTOR (1 DOWNTO 0) := (others => '0');
SIGNAL clock_polarity     : STD_LOGIC := '0';
SIGNAL clock_phase     : STD_LOGIC := '0';
SIGNAL start_transmission : STD_LOGIC := '0';
SIGNAL transmission_done  : STD_LOGIC := '0';
SIGNAL data_tx  : STD_LOGIC_VECTOR (31 DOWNTO 0) := (others => '0');
SIGNAL data_rx  : STD_LOGIC_VECTOR (31 DOWNTO 0) := (others => '0');
SIGNAL spiclk  : STD_LOGIC := '0';
SIGNAL spi_data : STD_LOGIC := '0';
SIGNAL spi_cs   : STD_LOGIC := '0';
SIGNAL baud_rate_divider  : STD_LOGIC_VECTOR (BAUD_RATE_DIVIDER_SIZE-1 DOWNTO 0):= "10";

CONSTANT clock_period : time := 10 ns;

begin

      uut : spifinal PORT MAP (
							   sysclk => sysclk,
							   reset => reset,
							   data_length => data_length,
							   baud_rate_divider => baud_rate_divider,
							   clock_polarity => clock_polarity,
							   clock_phase => clock_phase,
							   start_transmission => start_transmission,
							   transmission_done => transmission_done,
							   data_tx => data_tx,
							   data_rx => data_rx,
							   spiclk => spiclk,
                               spi_MOSI => spi_data,
							   spi_MISO => spi_data);   
           
           -- Process to generate the system clock
           sysclk_p : PROCESS
           BEGIN
               sysclk <= '0';
               wait for clock_period / 2;
               sysclk <= '1';
               wait for clock_period / 2;
           END PROCESS sysclk_p;
           
           stim_p : PROCESS
           BEGIN
           wait for clock_period;
           reset <= '0';
           wait for clock_period;
           reset <= '1';
           wait for clock_period;
        ------- TEST DATA ---------
            data_tx <= x"00DACDAC";
            data_length <= "01";
            DAC_en <= '1';
            PGA_en <= '0';
        ------- clock_polarity=1 clock_phase=0 ---------
           clock_polarity <= '1';
           clock_phase <= '0';
           wait for clock_period;
           start_transmission <= '1';
           wait for clock_period;
           start_transmission <= '0';
           wait for 1224*clock_period;  
 
              
        ------- TEST DATA ---------
            data_tx <= x"a51188a5";
            data_length <= "00";
            DAC_en <= '0';          
            PGA_en <= '1';
           ------- clock_polarity=1 clock_phase=0 ---------
           clock_polarity <= '1';
           clock_phase <= '1';
           wait for clock_period;
           start_transmission <= '1';
           wait for clock_period;
           start_transmission <= '0';
           wait for 1200*clock_period;  
                    
           wait;
           END PROCESS stim_p;

end Behavioral;
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Antirebote IS 
	PORT (
	clk              : IN STD_LOGIC;
	reset            : IN STD_LOGIC;
	start            : IN STD_LOGIC;
	sw               : IN STD_LOGIC;
	sw_antB          : OUT STD_LOGIC
	);
END ENTITY Antirebote;
--------------------------------------------------------------------------------------------------------------------------------------------
ARCHITECTURE arch OF Antirebote IS

   SIGNAL rst,sw_N,sw_NAB,sw_AB        :STD_LOGIC;
   SIGNAL ZEROS                        :STD_LOGIC_VECTOR(18 DOWNTO 0) := (OTHERS => '0');
	SIGNAL count_B                      :STD_LOGIC_VECTOR(18 DOWNTO 0);
	SIGNAL count_3                      :STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL Ena_countB, Ena_count3       :STD_LOGIC;
	SIGNAL clear_countB, clear_count3   :STD_LOGIC;
	SIGNAL MaxTick_B, MaxTick_3         :STD_LOGIC;
--------------------------------------------------------------------------------------------------------------------------------------------	  
BEGIN

	Counter5ms: entity work.Univ_counter
	GENERIC MAP (	N	=> 19)
		PORT MAP(	clk		=> clk,
						rst		=> rst,
						ena		=> Ena_countB,
						syn_clr	=> clear_countB,
						load		=> '0',
						up			=> '1',
						d			=> ZEROS,
						Counter	=> count_B
						);
				
	clear_countB <= '1' WHEN count_B = "11110100001001000" ELSE 
             '0';
	MaxTick_B <= '1' WHEN count_B = "11110100001001000" ELSE 
             '0';
				 
	Counter3: entity work.Univ_counter
	GENERIC MAP(	N	=> 2 )
		PORT MAP(	clk		=> clk,
						rst		=> rst,
						ena		=> Ena_count3,
						syn_clr	=> clear_count3,
						load		=> '0',
						up			=> '1',
						d			=> ZEROS(1 DOWNTO 0),
						Counter	=> count_3
						);
						
	MaxTick_3 <= '1' WHEN count_3 = "10" ELSE 
             '0';

	FSM: entity work.FSM_Antirrebote
		PORT MAP(	clk		      => clk,
						rst		      => rst,
						sw		         => sw,
						MaxTick_B	   => MaxTick_B,
						MaxTick_3		=> MaxTick_3,
						Ena_countB		=> Ena_countB,
						Ena_count3		=> Ena_count3,
						clear_count3	=> clear_count3,
						sw_AntB        => sw_antB
						);

END ARCHITECTURE arch;
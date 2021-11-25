LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Paleta IS 
	GENERIC(	Sentido   :	STD_LOGIC	:= '0'); -- 0 lo hace izq y 1 lo hace derecha, reusable
	PORT ( rst            :IN STD_LOGIC;
			 clk            :IN STD_LOGIC;
			 start			 :IN STD_LOGIC;
			 Bola_Pos_X     :IN STD_LOGIC_VECTOR(9 DOWNTO 0);
			 Bola_Pos_Y     :IN STD_LOGIC_VECTOR(9 DOWNTO 0);
			 BT_up          :IN STD_LOGIC;
			 BT_down        :IN STD_LOGIC;
			 Bola_ra        :OUT STD_LOGIC;
			 Paleta_Pos_X  :OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
			 Paleta_Pos_Y  :OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
			 Est_Act        :OUT STD_LOGIC_VECTOR(2 DOWNTO 0)			 
	);
END ENTITY Paleta;

ARCHITECTURE arch OF Paleta IS
   TYPE state IS ( Iniciar, Limite_up, Limite_down, Arriba, Abajo, Refresh);
	SIGNAL pr_state, nx_state: state;
	SIGNAL ZEROSR                          : STD_LOGIC_VECTOR(9 DOWNTO 0):= (OTHERS => '0');
	SIGNAL Paleta_Pos                     : STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL count_WT,ZEROSC                 : STD_LOGIC_VECTOR(19 DOWNTO 0):= (OTHERS => '0');
	SIGNAL Ena_ctWT,clear_ctWT,Max_tick_WT : STD_LOGIC;
	SIGNAL Ena_countR                      : STD_LOGIC;
	SIGNAL up, up_change                   : STD_LOGIC;
	SIGNAL Limit_Y_Sup,Limit_Y_Inf         : STD_LOGIC;
	SIGNAL Paleta                         : INTEGER;
	CONSTANT wait_time                     : INTEGER:=250000;
	CONSTANT Limit_Paleta                 : INTEGER:=150;
	--------------------------------------------------------------------------------------------------------------------------------------------
BEGIN

Paleta_Pos_X<="0000000000" WHEN Sentido = '0' ELSE
	            "1001101101";

Paleta_Pos_Y<=Paleta_Pos;

Paleta<=to_integer(unsigned(Paleta_Pos));

Limit_Y_Sup	<=	'1' WHEN Paleta = 0 ELSE
	            '0';
Limit_Y_Inf	<=	'1' WHEN Paleta = (480-Limit_Paleta) ELSE
	            '0';			

Efectos: entity work.FMS_Mov
	GENERIC MAP(	Sentido	=> Sentido)
		PORT MAP(	clk		   => clk,
						rst		   => rst,
						Bola_Pos_X  => Bola_Pos_X,
						Bola_Pos_y  => Bola_Pos_Y,
						Paleta_Pos	=> Paleta_Pos,
						Colision    => Bola_ra,
						Est_Act		=> Est_Act
						);
	
Counter_Paleta: entity work.Univ_counter
	GENERIC MAP(	N	=> 10)
		PORT MAP(	clk		=> clk,
						rst		=> rst,
						ena		=> Ena_countR AND start,
						syn_clr	=> '0',
						load		=> '0',
						up			=> up,
						d			=> ZEROSR,
						Counter	=> Paleta_Pos
						);
						
				
Counter_Wait_Time: entity work.Univ_counter
	GENERIC MAP(	N	=> 20)
		PORT MAP(	clk		=> clk,
						rst		=> rst,
						ena		=> Ena_ctWT,
						syn_clr	=> clear_ctWT,
						load		=> '0',
						up			=> '1',
						d			=> ZEROSC,
						Counter	=> count_WT
						);
						
						
	Max_tick_WT <= '1' WHEN count_WT = std_logic_vector(to_unsigned(wait_time, count_WT'length)) ELSE 
                  '0';
						
--------------------------------------------------------------------------------------------------------------------------------------------


	PROCESS (rst, clk)
	BEGIN 
		IF (rst='1') THEN 
			pr_state <= Iniciar;
		ELSIF (rising_edge(clk)) THEN 
			pr_state <= nx_state;
		END IF;
	END PROCESS;

	PROCESS(Limit_Y_Sup, Limit_Y_Inf, BT_up, BT_down, Max_tick_WT, pr_state)
	BEGIN
		CASE pr_state IS
			WHEN Iniciar =>
			up<='0';
			Ena_countR<='0';
			Ena_ctWT<='1';
			clear_ctWT<='1';
			IF (BT_up = '1') THEN
				nx_state <= Limite_up;
			ELSIF (BT_down = '1') THEN 
				nx_state <= Limite_down;
			ELSE
				nx_state <= Iniciar;
			END IF;
			  
			WHEN Limite_up =>
			up<='0';
			Ena_countR<='0';
			Ena_ctWT<='0';
			clear_ctWT<='0';
			IF (Limit_Y_Sup = '0' ) THEN  
				nx_state <= Arriba;
			ELSE                     
			   nx_state <= Iniciar;
			END IF;
			
			WHEN Limite_down =>
			up<='0';
			Ena_countR<='0';
			Ena_ctWT<='0';
			clear_ctWT<='0';
			IF (Limit_Y_Inf = '0' ) THEN  
				nx_state <= Abajo;
			ELSE                     
			   nx_state <= Iniciar;
			END IF;
		
			WHEN Arriba =>
			up<='0';
			Ena_countR<='1';
			Ena_ctWT<='0';
			clear_ctWT<='0';
			   
				nx_state <= Refresh;
				
			WHEN Abajo =>
			up<='1';
			Ena_countR<='1';
			Ena_ctWT<='0';
			clear_ctWT<='0';
			   
				nx_state <= Refresh;
		
			WHEN Refresh =>
			up<='0';
			Ena_countR<='0';
			Ena_ctWT<='1';
			clear_ctWT<='0';
			IF (Max_tick_WT = '1') THEN 
			   nx_state <= Iniciar;
			ELSE 
				nx_state <= Refresh;
			END IF;
		END CASE;
	END PROCESS;
END ARCHITECTURE;
		
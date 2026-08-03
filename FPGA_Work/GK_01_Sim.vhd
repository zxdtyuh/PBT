library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity GK_01_Sim is
GENERIC(
    MeasureBit  : integer range 0 to 20 := 20;
    PointBit    : integer range 0 to 36 := 36;
    GaussNodes  : integer range 0 to 7 := 7;
    KronrodNodes: integer range 0 to 15 := 15;
    FuncLatency : integer range 0 to 10 := 10 -- How long one node takes to be processed and come back
    
  );

end GK_01_Sim;

architecture Sim of GK_01_Sim is
    signal clk            : STD_LOGIC;
    signal ZIn            : unsigned( MeasureBit - 1 downto 0);  -- Depth at which we're evaluating Q
    signal V_B            : unsigned( MeasureBit - 1 downto 0 ); -- Fit parameter related to Birks' contant
    signal V_Sig          : unsigned( MeasureBit - 1 downto 0 ); -- Fit parameter related to Gaussian range straggling
    signal V_R            : unsigned( MeasureBit - 1 downto 0 ); -- Fit parameter which is range of proton beam, between 30mm and 350mm
    signal MeasureValid   : STD_LOGIC := '0';
    signal EstimateOut    : unsigned( PointBit - 1 downto 0);
    signal OutValid       : STD_LOGIC := '0';
    signal GEstimateOut   : unsigned( PointBit - 1 downto 0);
    signal GOutValid      : STD_LOGIC := '0';
    
begin
    QEstimate : entity work.GK_01
            port map (
                clk           => clk,
                ZIn           => ZIn,
                V_B           => V_B,
                V_Sig         => V_Sig,
                V_R           => V_R,
                MeasureValid => MeasureValid,
                EstimateOut   => EstimateOut,
                OutValid      => OutValid,
                GEstimateOut  => GEstimateOut,
                GOutValid     => GOutValid
            );


    clk_gen : process
    begin
        clk <= '0'; wait for 5 ns;
        clk <= '1'; wait for 5 ns;
    end process;
    

    Q_test : process
    begin
        wait for 1000 ns; -- Start up pause

        -- First measurement
        ZIn <= to_unsigned(81920, 20);
        V_B <= to_unsigned(452984, 20);
        V_Sig <= to_unsigned(208087, 20);
        V_R <= to_unsigned(204800, 20);
        MeasureValid <= '1'; 
        wait for 10 ns;
        MeasureValid <= '0';
        report "Finished" severity note;
        wait;
    end process;
end Sim;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity GK_Sim_1 is
end GK_Sim_1;

architecture Sim of GK_Sim_1 is
    signal clk            : STD_LOGIC := '0';
    -- signal X_Measurement  : unsigned( 19 downto 0 );
    -- signal Y_Measurement  : unsigned( 19 downto 0 );
    -- signal Measure_Valid  : STD_LOGIC := '0';
    signal EstimateOut    : unsigned( 35 downto 0);
    signal OutValid       : STD_LOGIC := '0';
    signal GEstimateOut   : unsigned( 35 downto 0);
    signal GOutValid      : STD_LOGIC := '0';

begin
    GaussInst : entity work.GK_X_Squared
        port map (
            clk           => clk,
            -- X_Measurement => X_Measurement,
            -- Y_Measurement => Y_Measurement,
            -- Measure_Valid => Measure_Valid,
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

    Gauss_test : process
    begin
        wait for 20 ns; -- Start up pause

        report "Finished" severity note;
        wait;
    end process;
end Sim;
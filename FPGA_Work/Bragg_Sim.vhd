library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Bragg_Estimate_SIM is
end Bragg_Estimate_SIM;

architecture Sim of Bragg_Estimate_SIM is
    signal clk            : STD_LOGIC := '0';
    signal X_Measurement  : unsigned( 19 downto 0 );
    signal Y_Measurement  : unsigned( 19 downto 0 );
    signal Measure_Valid  : STD_LOGIC := '0';
    signal EstimateOut    : unsigned( 27 downto 0);
    signal OutValid       : STD_LOGIC := '0';

begin
    BraggEstimate : entity work.Bragg_Estimate
        port map (
            clk           => clk,
            X_Measurement => X_Measurement,
            Y_Measurement => Y_Measurement,
            Measure_Valid => Measure_Valid,
            EstimateOut   => EstimateOut,
            OutValid      => OutValid
        );


    clk_gen : process
    begin
        clk <= '0'; wait for 5 ns;
        clk <= '1'; wait for 5 ns;
    end process;

    Bragg_test : process
    begin
        wait for 20 ns; -- Start up pause

        -- First measurement
        X_Measurement <= to_unsigned(520947, 20);
        Y_Measurement <= to_unsigned(300102, 20);
        Measure_Valid <= '1';
        wait for 10 ns;
        Measure_Valid <= '0';

        wait for 200 ns;

        -- Second measurement -- low X, mid Y
        X_Measurement <= to_unsigned(1048, 20);
        Y_Measurement <= to_unsigned(63917, 20);
        Measure_Valid <= '1';
        wait for 10 ns;
        Measure_Valid <= '0';

        wait for 200 ns;

        -- Third measurement -- min X, min Y
        X_Measurement <= to_unsigned(0, 20);
        Y_Measurement <= to_unsigned(0, 20);
        Measure_Valid <= '1';
        wait for 10 ns;
        Measure_Valid <= '0';

        wait for 200 ns;

        -- Fourth measurement -- max X, max Y boundary
        X_Measurement <= to_unsigned(1048575, 20);
        Y_Measurement <= to_unsigned(1048575, 20);
        Measure_Valid <= '1';
        wait for 10 ns;
        Measure_Valid <= '0';

        wait for 200 ns;

        -- Fifth measurement
        X_Measurement <= to_unsigned(512000, 20);   -- X index 500 exactly
        Y_Measurement <= to_unsigned(524288, 20);   -- Y index 4 exactly
        Measure_Valid <= '1';
        wait for 10 ns;
        Measure_Valid <= '0';

        wait for 200 ns;

        -- Sixth measurement
        X_Measurement <= to_unsigned(700000, 20);
        Y_Measurement <= to_unsigned(800000, 20);
        Measure_Valid <= '1';
        wait for 10 ns;
        Measure_Valid <= '0';

        wait for 200 ns;

        report "Finished" severity note;
        wait;
    end process;
end Sim;
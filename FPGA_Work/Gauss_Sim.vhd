library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Gauss_1_SIM is
end Gauss_1_SIM;

architecture Sim of Gauss_1_SIM is
    signal clk            : STD_LOGIC := '0';
    signal X_Measurement  : unsigned( 29 downto 0 );
    signal Y_Measurement  : unsigned( 29 downto 0 );
    signal Measure_Valid  : STD_LOGIC := '0';
    signal EstimateOut    : unsigned( 31 downto 0);
    signal OutValid       : STD_LOGIC := '0';

begin
    GaussInst : entity work.Gauss_1
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

    Gauss_test : process
    begin
        wait for 20 ns; -- Start up pause

        -- First measurement -- mid-range X
        X_Measurement <= to_unsigned(2083788, 30);
        Y_Measurement <= (others => '0');  -- unused
        Measure_Valid <= '1';
        wait for 10 ns;
        Measure_Valid <= '0';

        wait for 80 ns; -- let the first pipeline finish

        -- Second measurement
        X_Measurement <= to_unsigned(4192, 30);
        Y_Measurement <= (others => '0');
        Measure_Valid <= '1';
        wait for 10 ns;
        Measure_Valid <= '0';

        wait for 80 ns;

        -- Third measurement -- min X boundary
        X_Measurement <= to_unsigned(0, 30);
        Y_Measurement <= (others => '0');
        Measure_Valid <= '1';
        wait for 10 ns;
        Measure_Valid <= '0';

        wait for 80 ns;

        -- Fourth measurement -- max X boundary
        X_Measurement <= to_unsigned(4194300, 30);
        Y_Measurement <= (others => '0');
        Measure_Valid <= '1';
        wait for 10 ns;
        Measure_Valid <= '0';

        wait for 80 ns;

        report "Finished" severity note;
        wait;
    end process;
end Sim;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity Function_for_GK is

-- Function here is G * j

  GENERIC(
    MeasureBit  : integer range 0 to 20 := 20;
    PointBit    : integer range 0 to 36 := 36;
    FuncResBit  : integer range 0 to 28 := 28;
    GaussNodes  : integer range 0 to 7 := 7;
    KronrodNodes: integer range 0 to 15 := 15;
    jII         : integer range 0 to 8  := 8;
    GII         : integer range 0 to 6  := 6  -- 6 clock cycles after G gets a value, it spits out a result
    
  );

    PORT(
           clk              : IN  STD_LOGIC;
           XNodeIn          : IN unsigned( PointBit - 1 downto 0);
           XNodeValid       : IN STD_LOGIC := '0';
           ZIn              : IN unsigned( MeasureBit - 1 downto 0);  -- Depth at which we're evaluating Q
           V_B              : IN unsigned( MeasureBit - 1 downto 0 ); -- Fit parameter related to Birks' contant
           V_Sig            : IN unsigned( MeasureBit - 1 downto 0 ); -- Fit parameter related to Gaussian range straggling
           V_R              : IN unsigned( MeasureBit - 1 downto 0 ); -- Fit parameter which is range of proton beam, between 30mm and 350mm
           GjResult         : OUT unsigned( 2 * FuncResBit - 1 downto 0 ) := (others => '0');
           GjResultValid    : OUT STD_LOGIC := '0'
          );
      
end Function_for_GK;

architecture Behavioral of Function_for_GK is

    constant One : unsigned( PointBit downto 0 ) := to_unsigned(2**PointBit, PointBit + 1);
    signal OneMinNode : unsigned( PointBit - 1 downto 0 ) := (others => '0');
    signal jXInput    : unsigned( MeasureBit - 1 downto 0 ) := (others => '0');
    signal GXInput    : unsigned( MeasureBit - 1 downto 0 ) := (others => '0');
    signal jOut       : unsigned( FuncResBit - 1 downto 0 ) := (others => '0');
    signal GOut       : unsigned( FuncResBit - 1 downto 0 ) := (others => '0');
    signal GOut1      : unsigned( FuncResBit - 1 downto 0 ) := (others => '0'); 
    signal V_B_Hold   : unsigned( MeasureBit - 1 downto 0 );
    signal V_B_Input  : unsigned( MeasureBit - 1 downto 0 );
    signal ZInHold    : unsigned( MeasureBit - 1 downto 0);
    signal V_RTimesX  : signed( PointBit + MeasureBit downto 0 );
    signal V_RTimesOneMinX : unsigned( PointBit + MeasureBit - 1 downto 0 );
    signal ZMinV_RTimesX : signed( PointBit + MeasureBit downto 0 );
    signal XInputReady : STD_LOGIC := '0';
    signal XPrep       : STD_LOGIC := '0';
    signal XPrep1      : STD_LOGIC := '0';
    signal jXReady     : STD_LOGIC := '0';
    signal GXReady     : STD_LOGIC := '0';
    signal jOutValid   : STD_LOGIC := '0';
    signal GOutValid   : STD_LOGIC := '0';
    signal GOutValid1  : STD_LOGIC := '0'; -- Same number of signals as above with GOut

begin

G_Function : entity work.Gauss_1
    
    port map (
        clk              => clk,
        X_Measurement    => GXInput,
        Y_Measurement    => V_B_Input,
        Measure_Valid    => GXReady,
        EstimateOut      => GOut,
        OutValid         => GOutValid
    );

j_Function : entity work.Bragg_Estimate
    
    port map (
        clk              => clk,
        X_Measurement    => jXInput,
        Y_Measurement    => V_B_Input,
        Measure_Valid    => jXReady,
        EstimateOut      => jOut,
        OutValid         => jOutValid
    );

PROCESS( clk )

  BEGIN
    IF RISING_EDGE( clk ) THEN
        
        -- Clock 1
        if XNodeValid = '1' then
            -- FuncOut <= XNodeIn * XNodeIn;
            -- FuncOutValid <= '1';
            OneMinNode <= resize(One - resize(XNodeIn, One'length), PointBit);
            V_RTimesX <= signed('0' & (V_R * XNodeIn));
            V_B_Hold <= V_B;
            ZInHold <= ZIn;
            XPrep <= '1';
        else
            XPrep <= '0';
        end if;
        
        -- Clock 2
        -- V_RTimesOneMinX <= V_R * OneMinNode;
        jXInput <= resize(shift_right(V_R * OneMinNode, PointBit), MeasureBit); -- input for j is here
        ZMinV_RTimesX <= resize(signed('0' & ZInHold), V_RTimesX'length) - shift_right(V_RTimesX, PointBit);
        XPrep1 <= XPrep;
        jXReady <= XPrep;
        V_B_Input <= V_B_Hold;
        
        -- Clock 3
        GXInput <= resize(unsigned(abs(shift_right(signed('0' & V_Sig) * ZMinV_RTimesX, MeasureBit))), MeasureBit);
        GXReady <= XPrep1;
        
        --Some Latency between clock 3 & 4 as G and j functions have to compute
        
        -- Clock 4
        GOut1 <= GOut;
        GOutValid1 <= GOutValid;
        
        -- Clock 5
        if GOutValid1 = '1' and jOutValid = '1' then
            GjResult <= GOut1 * jOut;
            GjResultValid <= '1';
        else
            GjResultValid <= '0';
        end if;
      
    END IF;
END PROCESS;
end Behavioral;

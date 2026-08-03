
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity Function_for_GK is

-- Function here is G * j

  GENERIC(
    MeasureBit    : integer range 0 to 20 := 20;
    GInputBit     : integer range 0 to 31 := 31;
    PointBit      : integer range 0 to 36 := 36;
    FuncResBit    : integer range 0 to 32 := 32; -- Bit of output from j and G functions
    GScaling      : integer range 0 to 16 := 16;
    jScaling      : integer range 0 to 20 := 20;
    FracBit       : integer range 0 to 17 := 17;
    GaussNodes    : integer range 0 to 7 := 7;
    KronrodNodes  : integer range 0 to 15 := 15;
    jII           : integer range 0 to 7  := 7;
    GII           : integer range 0 to 5  := 5;  -- 5 clock cycles after G gets a value, it spits out a result
    DispatchDelay : integer range 0 to 6 := 6 -- How often Bragg_Estimate can accept a new value
  );

    PORT(
           clk              : IN  STD_LOGIC;
           XNodeIn          : IN unsigned( PointBit - 1 downto 0);
           XNodeValid       : IN STD_LOGIC := '0';
           ZIn              : IN unsigned( MeasureBit - 1 downto 0);  -- Depth at which we're evaluating Q, 0 to 400 represented as 9i; 11f, so real value scaled by 2^11
           V_B              : IN unsigned( MeasureBit - 1 downto 0 ); -- Fit parameter related to Birks' contant, 0i; 20f
           V_Sig            : IN unsigned( MeasureBit - 1 downto 0 ); -- Fit parameter related to Gaussian range straggling, 0 to 2.242 represented as 2i; 18f
           V_R              : IN unsigned( MeasureBit - 1 downto 0 ); -- Fit parameter which is range of proton beam, 0 to 400 represented as 9i; 11f
           Ready            : OUT STD_LOGIC := '1';
           GjResult         : OUT unsigned( 2 * FuncResBit - 1 downto 0 ) := (others => '0');
           GjResultValid    : OUT STD_LOGIC := '0'
          );
      
end Function_for_GK;

architecture Behavioral of Function_for_GK is

    constant One      : unsigned( PointBit downto 0 ) := (PointBit => '1', others => '0'); 
    constant VSig_Range   : unsigned(MeasureBit - 1 downto 0) := to_unsigned(293863, MeasureBit);  -- round(2.242 * 2^17) 
    constant VSig_Start : unsigned(MeasureBit - 1 downto 0) := to_unsigned(257949, MeasureBit);   -- round((0.246) * 2^20)
    constant Vrz_Range  : unsigned( 8 downto 0 ) := to_unsigned(400, 9);  -- 400   No shift needed when using this value
    constant Vb_Range   : unsigned(MeasureBit - 1 downto 0) := to_unsigned(62915, MeasureBit);  -- round(0.06 * 2^20)
    constant Vb_Start   : unsigned(MeasureBit - 1 downto 0) := to_unsigned(419430, MeasureBit);  -- round(0.4 * 2^20)
    signal V_SigAdjust  : unsigned(MeasureBit - 1 downto 0);  
    signal V_SigAdjust1  : unsigned(MeasureBit - 1 downto 0); 
    signal V_SigAdjustHold  : unsigned(MeasureBit - 1 downto 0); 
    signal OneMinNode : unsigned( PointBit - 1 downto 0 ) := (others => '0');
    signal jXInput    : unsigned( MeasureBit - 1 downto 0 ) := (others => '0');
    signal GXInput    : unsigned( GInputBit - 1 downto 0 ) := (others => '0');
    signal jOut       : unsigned( FuncResBit - 1 downto 0 ) := (others => '0');
    signal GOut       : unsigned( FuncResBit - 1 downto 0 ) := (others => '0');
    signal GOut1      : unsigned( FuncResBit - 1 downto 0 ) := (others => '0'); 
    signal V_B_Hold   : unsigned( MeasureBit - 1 downto 0 );
    signal V_B_Input  : unsigned( MeasureBit - 1 downto 0 );
    signal ZInHold    : unsigned( MeasureBit - 1 downto 0);
    signal V_RTimesX  : unsigned( 2 * MeasureBit - 1 downto 0 );
    signal V_RTimesOneMinX : unsigned( PointBit + MeasureBit - 1 downto 0 );
    signal ZMinV_RTimesX : unsigned( 2 * MeasureBit - 1 downto 0 );
    signal SpacingCounter : integer range 0 to DispatchDelay - 1 := 0;
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
        if XNodeValid = '1' and Ready = '1' then
            OneMinNode <= resize(One - resize(XNodeIn, One'length), PointBit);
            V_RTimesX <= resize(shift_right((V_R * XNodeIn), 16), 40); -- result is 9i; 47f then shifted to 9i; 31f
            V_B_Hold <= V_B;
            V_SigAdjust <= V_Sig;
            ZInHold <= ZIn;
            XPrep <= '1';
            SpacingCounter <= 1;
            Ready <= '0'; -- Busy signal
            
        elsif GjResultValid = '1' then
            Ready <= '1';
        else
            XPrep <= '0';
                if Ready = '0' then
                    if SpacingCounter = DispatchDelay - 1 then
                        Ready <= '1';
                    else
                        SpacingCounter <= SpacingCounter + 1;
                    end if;
                end if;
        end if;
      
        
        -- Clock 2
        -- V_RTimesOneMinX <= V_R * OneMinNode;
        jXInput <= resize(shift_right(V_R * OneMinNode, PointBit), MeasureBit); -- input for j is here
        ZMinV_RTimesX <= unsigned(abs(shift_left(resize(signed('0' & ZInHold),V_RTimesX'length + 1), MeasureBit) - resize(signed('0' & V_RTimesX), V_RTimesX'length + 1))); -- result is 9i; 30f
        V_SigAdjustHold <= V_SigAdjust;
        XPrep1 <= XPrep;
        jXReady <= XPrep;
        V_B_Input <= V_B_Hold;
        
        -- Clock 3
        GXInput <= resize(shift_right(V_SigAdjustHold * ZMinV_RTimesX, 28), GInputBit); -- 11i; 48f, G expects 20f
        GXReady <= XPrep1;
        
        --Some Latency between clock 3 & 4 as G and j functions have to compute
        
        -- Clock 4
        GOut1 <= GOut;
        GOutValid1 <= GOutValid;
        
        -- Clock 5
        if GOutValid1 = '1' and jOutValid = '1' then
            GjResult <= GOut1 * jOut; -- This is the result scaled by 2^(GScaling + jScaling)
            GjResultValid <= '1';
        else
            GjResultValid <= '0';
        end if;
      
    END IF;
END PROCESS;
end Behavioral;

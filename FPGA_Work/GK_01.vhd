library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
LIBRARY work;
USE work.GK_X_Squared_Table.ALL;


entity GK_01 is

  GENERIC(
    MeasureBit  : integer range 0 to 20 := 20;
    PointBit    : integer range 0 to 36 := 36;
    GaussNodes  : integer range 0 to 7 := 7;
    KronrodNodes: integer range 0 to 15 := 15;
    FuncLatency : integer range 0 to 10 := 10; -- How long one node takes to be processed and come back
    GjBit  : integer range 0 to 32 := 32 -- Bit of result from G and j functions
    
  );

  PORT(
       clk            : IN STD_LOGIC;
       ZIn            : IN unsigned( MeasureBit - 1 downto 0);  -- Depth at which we're evaluating Q
       V_B            : IN unsigned( MeasureBit - 1 downto 0 ); -- Fit parameter related to Birks' contant
       V_Sig          : IN unsigned( MeasureBit - 1 downto 0 ); -- Fit parameter related to Gaussian range straggling
       V_R            : IN unsigned( MeasureBit - 1 downto 0 ); -- Fit parameter which is range of proton beam, between 30mm and 350mm
       MeasureValid   : IN STD_LOGIC;
       EstimateOut    : OUT unsigned( PointBit - 1 downto 0);
       OutValid       : OUT STD_LOGIC := '0';
       GEstimateOut   : OUT unsigned( PointBit - 1 downto 0);
       GOutValid      : OUT STD_LOGIC := '0'       
      );
      
end GK_01;

architecture Behavioral of GK_01 is

signal KronrodNode   : unsigned( PointBit - 1 downto 0 ) := (others => '0');
signal KronrodWeight : unsigned( PointBit - 1 downto 0 ) := (others => '0');
signal KronrodWeight1: unsigned( PointBit - 1 downto 0 ) := (others => '0');
signal KronrodWeightHold: unsigned( PointBit - 1 downto 0 ) := (others => '0');
signal GaussWeight   : unsigned( PointBit - 1 downto 0 ) := (others => '0');
signal GaussWeight1  : unsigned( PointBit - 1 downto 0 ) := (others => '0');
signal GaussWeightHold   : unsigned( PointBit - 1 downto 0 ) := (others => '0');
signal FunctionRes   : unsigned( 2 * GjBit - 1 downto 0 ) := (others => '0');
signal FunctionValid : STD_LOGIC := '0';
signal WeightedResult: unsigned( 2 * GjBit + PointBit - 1 downto 0 ) := (others => '0');
signal GaussWeightedResult: unsigned( 2 * GjBit + PointBit - 1 downto 0 ) := (others => '0');
signal AccumSum      : unsigned( 2 * GjBit + PointBit downto 0) := (others => '0');
signal GaussAccumSum : unsigned( 2 * GjBit + PointBit downto 0) := (others => '0');
signal SignCounter   : STD_LOGIC := '0';
signal GaussSignCounter: STD_LOGIC := '0';
signal NodeCounter   : integer range 0 to 14 := 0;
signal NodeHold      : integer range 0 to 14 := 0;
signal WeightCounter : integer range 0 to 14 := 0;
signal GaussNodeCounter   : integer range 0 to 6 := 0;
signal CounterD1     : integer range 0 to 14 := 0;
signal SampleIndex   : integer range 0 to 14 := 0;
signal CounterD2     : integer range 0 to 14 := 0;
signal CounterD3     : integer range 0 to 14 := 0;
signal ValidD1       : STD_LOGIC := '0';
signal ValidD2       : STD_LOGIC := '0';
signal ValidD3       : STD_LOGIC := '0';

signal CounterG1     : integer range 0 to 6 := 0;
signal GSampleIndex  : integer range 0 to 6 := 0;
signal CounterG2     : integer range 0 to 6 := 0;
signal CounterG3     : integer range 0 to 6 := 0;
signal ValidG1       : STD_LOGIC := '0';
signal ValidG2       : STD_LOGIC := '0';
signal ValidG3       : STD_LOGIC := '0';
signal PendingGauss  : STD_LOGIC := '0';

signal ZInForward    : unsigned( MeasureBit - 1 downto 0);
signal V_BForward    : unsigned( MeasureBit - 1 downto 0);
signal V_SigForward  : unsigned( MeasureBit - 1 downto 0);
signal V_RForward    : unsigned( MeasureBit - 1 downto 0);
signal FuncReady     : STD_LOGIC := '0';

signal LatencyCounter: integer range 0 to FuncLatency := 0;

signal NodesDone     : STD_LOGIC := '0';
signal GKReady       : STD_LOGIC := '1';


begin


Function_Inst : entity work.Function_for_GK
    generic map (
        PointBit     => PointBit,
        GaussNodes   => GaussNodes,
        KronrodNodes => KronrodNodes
    )
    port map (
        clk          => clk,
        XNodeIn      => KronrodNode,
        XNodeValid   => ValidD1,
        ZIn          => ZInForward,
        V_B          => V_BForward,
        V_Sig        => V_SigForward,
        V_R          => V_RForward,
        Ready        => FuncReady,
        GjResult     => FunctionRes,
        GjResultValid=> FunctionValid
    );


PROCESS( clk )
  BEGIN
    IF RISING_EDGE( clk ) THEN


    -- Clock 1
    ----------------------------------------------------------------------------------------------------------------------------------
    if MeasureValid = '1' and GKReady = '1' then
    
        ZInForward <= ZIn; -- Forwards measurements
        V_BForward <= V_B;
        V_SigForward <= V_Sig;
        V_RForward <= V_R;
        GKReady <= '0';
    
    end if;    
    
    if FuncReady = '1' and ValidD1 = '0' and GKReady = '0' then
        KronrodNode <= GK01_NODES(NodeCounter); -- X input
        KronrodWeightHold <= GK01_KRONROD_WEIGHTS(NodeCounter); -- Weight, need to figure out how to propagate
        CounterD1 <= NodeCounter;
        ValidD1 <= '1'; -- Triggers function to start next cycle
        
        
        
        -- Keeps track of weight through the function latency    --> 
        -- if LatencyCounter /= FuncLatency then
        --     LatencyCounter <= LatencyCounter + 1;
        -- else
        --    KronrodWeight <= GK01_KRONROD_WEIGHTS(WeightCounter);
         --   WeightCounter <= WeightCounter + 1;
        --end if;
        
        --if WeightCounter = 14 then
        --    LatencyCounter <= 0;
        --end if;
        -- Keeps track of weight through the function latency    <--
        
        
        ------ Gauss Section --------------------------------------------
        if NodeCounter mod 2 = 1 then
            GaussWeightHold <= GK01_GAUSS_WEIGHTS(GaussNodeCounter);
            PendingGauss <= '1';
            if GaussNodeCounter /= 6 then
                GaussNodeCounter <= GaussNodeCounter + 1;
            else 
                GaussNodeCounter <= 0;
            end if;
            
            CounterG1 <= GSampleIndex;
            
            if GSampleIndex /= 6 then
                GSampleIndex <= GSampleIndex + 1;
            end if;
           
            ValidG1 <= '1';
        else
            ValidG1 <= '0';
            PendingGauss <= '0';
        end if;
        -----------------------------------------------------------------
            
     
        
        if NodeCounter = 14 then
            NodeCounter <= 0;
            GKReady <= '1';
        else
            NodeCounter <= NodeCounter + 1;
        end if;
        
    else
        ValidD1 <= '0';
        ValidG1 <= '0';
    end if;
    
    ----------------------------------------------------------------------------------------------------------------------------------
    
    
    -- Clock 2
    if FunctionValid = '1' then
        WeightedResult <= FunctionRes * KronrodWeightHold;
        CounterD2 <= CounterD1;
        ValidD2 <= '1';
    
        GaussWeightedResult <= FunctionRes * GaussWeightHold;
        CounterG2 <= CounterG1;
        ValidG2 <= '1';
        
    else
        ValidD2 <= '0';
        ValidG2 <= '0';
    end if;
    
    
    -- Clock 3
    -- Kronrod Out
    if validD2 = '1' then                    
            if counterD2 = 0 then
                AccumSum <= resize(WeightedResult, AccumSum'length);
                OutValid <= '0';
            elsif counterD2 = 14 then
                EstimateOut <= resize(unsigned(shift_right(AccumSum + WeightedResult, 2 * PointBit)), PointBit);
                OutValid <= '1';
            else
                AccumSum <= AccumSum + resize(WeightedResult, AccumSum'length);
                OutValid <= '0';
            end if;
        else
            OutValid <= '0';
        end if;
        
    -- Gauss Out
    if ValidG2 = '1' then
                if counterG2 = 0 then
                    GaussAccumSum <= resize(GaussWeightedResult, GaussAccumSum'length);
                    GOutValid <= '0';
                elsif counterG2 = 6 then
                    GEstimateOut <= resize(unsigned(shift_right(GaussAccumSum + GaussWeightedResult, 2 * PointBit)), PointBit);
                    GOutValid <= '1';                    
                else
                    GaussAccumSum <= GaussAccumSum + GaussWeightedResult;
                    GOutValid <= '0';
                end if;
    else
        GOutValid <= '0';
    end if;

    END IF;
END PROCESS;
end Behavioral;


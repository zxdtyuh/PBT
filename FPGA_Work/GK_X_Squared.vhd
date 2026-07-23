library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
LIBRARY work;
USE work.GK_X_Squared_Table.ALL;


entity GK_X_Squared is

  GENERIC(
    -- y_bit       : integer range 0 to 3 := 3;
    -- x_bit       : integer range 0 to 10 := 10;
    -- MeasureBit  : integer range 0 to 20 := 20;
    PointBit    : integer range 0 to 36 := 36;
    -- FracBit     : integer range 0 to 17 := 17;
    GaussNodes  : integer range 0 to 7 := 7;
    KronrodNodes: integer range 0 to 15 := 15
    
  );

  PORT(
       clk            : IN  STD_LOGIC;
       --X_Measurement  : IN unsigned( MeasureBit - 1 downto 0 );
       --Y_Measurement  : IN unsigned( MeasureBit - 1 downto 0 );
       --Measure_Valid  : IN STD_LOGIC;
       EstimateOut    : OUT unsigned( PointBit - 1 downto 0);
       OutValid       : OUT STD_LOGIC := '0';
       GEstimateOut   : OUT unsigned( PointBit - 1 downto 0);
       GOutValid      : OUT STD_LOGIC := '0'       
      );
      
end GK_X_Squared;

architecture Behavioral of GK_X_Squared is

signal KronrodNode   : signed( PointBit downto 0 ) := (others => '0');
signal GaussNode     : signed( PointBit downto 0 ) := (others => '0');
signal KronrodWeight : unsigned( PointBit - 1 downto 0 ) := (others => '0');
signal KronrodWeight1: unsigned( PointBit - 1 downto 0 ) := (others => '0');
signal GaussWeight   : unsigned( PointBit - 1 downto 0 ) := (others => '0');
signal GaussWeight1  : unsigned( PointBit - 1 downto 0 ) := (others => '0');
signal FunctionRes   : signed( 2 * PointBit + 1 downto 0 ) := (others => '0');
signal FunctionValid : STD_LOGIC := '0';
signal GaussFunctionRes: signed( 2 * PointBit + 1 downto 0 ) := (others => '0');
signal WeightedResult: signed( 3 * PointBit + 1 downto 0 ) := (others => '0');
signal GaussWeightedResult: signed( 3 * PointBit + 1 downto 0 ) := (others => '0');
signal AccumSum      : signed( 3 * PointBit + 1 downto 0) := (others => '0');
signal GaussAccumSum : signed( 3 * PointBit + 1 downto 0) := (others => '0');
signal SignCounter   : STD_LOGIC := '0';
signal GaussSignCounter: STD_LOGIC := '0';
signal NodeCounter   : integer range 0 to 7 := 0;
signal GaussNodeCounter   : integer range 0 to 3 := 0;
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
        FuncOut      => FunctionRes,
        FuncOutValid => FunctionValid
    );


PROCESS( clk )
  BEGIN
    IF RISING_EDGE( clk ) THEN

    -- Clock 1
    if SignCounter = '0' then
        KronrodNode <= -signed('0' & KRONROD_NODES(NodeCounter));
        KronrodWeight <= KRONROD_WEIGHTS(NodeCounter);
        SignCounter <= '1';
        
        if NodeCounter mod 2 = 1 then
            GaussWeight <= GAUSS_WEIGHTS(GaussNodeCounter);
            if GaussNodeCounter /= 3 then
                GaussNodeCounter <= GaussNodeCounter + 1;
            end if;
            CounterG1 <= GSampleIndex;
            if GSampleIndex /= 6 then
                GSampleIndex <= GSampleIndex + 1;
            end if;
            ValidG1 <= '1';
        else
            ValidG1 <= '0';
        end if;
        
        CounterD1 <= SampleIndex;
        SampleIndex <= SampleIndex + 1;
        ValidD1 <= '1';
        
    elsif SignCounter = '1' and NodeCounter /= 7 then
        KronrodNode <= signed('0' & KRONROD_NODES(NodeCounter));
        SignCounter <= '0';
        
        if NodeCounter mod 2 = 1 then
            CounterG1 <= GSampleIndex;
            GSampleIndex <= GSampleIndex + 1;
            ValidG1 <= '1';
        else 
            ValidG1 <= '0';
        end if;
        
        NodeCounter <= NodeCounter + 1;
        CounterD1 <= SampleIndex;
        SampleIndex <= SampleIndex + 1;
        ValidD1 <= '1';
    else
        ValidD1 <= '0';
        ValidG1 <= '0';
    end if;
    
    -- Clock 2
    -- Function is x^2
    KronrodWeight1 <= KronrodWeight;
    CounterD2 <= CounterD1;
    ValidD2 <= ValidD1;
    
    GaussWeight1 <= GaussWeight;
    ValidG2 <= ValidG1;
    CounterG2 <= CounterG1;
    
    -- Clock 3
    WeightedResult <= FunctionRes * signed(KronrodWeight1);
    CounterD3 <= CounterD2;
    ValidD3 <= ValidD2;
    
    GaussWeightedResult <= FunctionRes * signed(GaussWeight1);
    CounterG3 <= CounterG2;
    ValidG3 <= ValidG2;
    
    -- Clock 4
    
    -- Kronrod Out
    if validD3 = '1' then                    
            if counterD3 = 0 then
                AccumSum <= resize(WeightedResult, AccumSum'length);
                OutValid <= '0';
            elsif counterD3 = 14 then
                EstimateOut <= resize(unsigned(shift_right(AccumSum + WeightedResult, 2 * PointBit)), PointBit);
                OutValid <= '1';
            else
                AccumSum <= AccumSum + WeightedResult;
                OutValid <= '0';
            end if;
        else
            OutValid <= '0';
        end if;
        
    -- Gauss Out
    if ValidG3 = '1' then
                if counterG3 = 0 then
                    GaussAccumSum <= resize(GaussWeightedResult, GaussAccumSum'length);
                    GOutValid <= '0';
                elsif counterG3 = 6 then
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


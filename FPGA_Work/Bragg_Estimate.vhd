library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
LIBRARY work;
USE work.LUT.ALL;


entity Bragg_Estimate is
  GENERIC(
    y_bit       : integer range 0 to 3 := 3;
    x_bit       : integer range 0 to 10 := 10;
    MeasureBit  : integer range 0 to 20 := 20;
    PointBit    : integer range 0 to 28 := 28;
    FracBit     : integer range 0 to 17 := 17
  );
  
  
  PORT(
       clk            : IN  STD_LOGIC;
       X_Measurement  : IN unsigned( MeasureBit - 1 downto 0 );
       Y_Measurement  : IN unsigned( MeasureBit - 1 downto 0 );
       Measure_Valid  : IN STD_LOGIC;
       EstimateOut    : OUT unsigned( PointBit - 1 downto 0);
       OutValid       : OUT STD_LOGIC := '0'       
      );
      
-- measurements coming in are 2^20 = 1048576
-- need to condense to 1024 for x and 8 for y
-- divide by 2^20 and multiply by 1024 and 8 respectivly?
-- multiply by 1024 and 8 then bitshift 2^20
-- is that the same as a bitshift by 2^10 and 2^3?
      
end Bragg_Estimate;


architecture Behavioral of Bragg_Estimate is

signal FractionX    : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal FractionX0   : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal FractionX1   : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal FractionX2   : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal FractionY    : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal FractionY0   : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal FractionY1   : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal FractionY2   : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal weight1      : unsigned( FracBit downto 0 ) := (others => '0');
signal weight2      : unsigned( FracBit downto 0 ) := (others => '0');
signal weight       : unsigned( 2*(FracBit + 1) - 1 downto 0 ) := (others => '0');
signal LUTOutput    : unsigned( PointBit - 1 downto 0 ) := (others => '0');
signal LUTWeighted  : unsigned( 2*(FracBit + 1) + PointBit - 1 downto 0) := (others => '0');
signal AccumSum     : unsigned( 2*(FracBit + 1) + PointBit downto 0) := (others => '0');
signal XShifted     : unsigned( (x_bit - 1) downto 0 );
signal XShifted0    : unsigned( (x_bit - 1) downto 0 );
signal XShifted1    : unsigned( (x_bit - 1) downto 0 );
signal XShifted2    : unsigned( (x_bit - 1) downto 0 );
signal XShiftedNext : unsigned( (x_bit - 1) downto 0 );
signal XShiftedNext0: unsigned( (x_bit - 1) downto 0 );
signal XShiftedNext1: unsigned( (x_bit - 1) downto 0 );
signal XShiftedNext2: unsigned( (x_bit - 1) downto 0 );
signal YShifted     : unsigned( (y_bit - 1) downto 0 );
signal YShifted0    : unsigned( (y_bit - 1) downto 0 );
signal YShifted1    : unsigned( (y_bit - 1) downto 0 );
signal YShifted2    : unsigned( (y_bit - 1) downto 0 );
signal YShiftedNext : unsigned( (y_bit - 1) downto 0 );
signal YShiftedNext0: unsigned( (y_bit - 1) downto 0 );
signal YShiftedNext1: unsigned( (y_bit - 1) downto 0 );
signal YShiftedNext2: unsigned( (y_bit - 1) downto 0 );
signal ShiftReady   : STD_LOGIC := '0';
signal Counter      : integer range 0 to 3 := 0;
signal counterD1    : integer range 0 to 3 := 0;
signal validD1      : STD_LOGIC := '0';
signal counterD2    : integer range 0 to 3 := 0;
signal validD2      : STD_LOGIC := '0';
signal counterD3    : integer range 0 to 3 := 0;
signal validD3      : STD_LOGIC := '0';
signal index        : integer range 0 to 8191;
constant FracOne    : unsigned(FracBit downto 0) := to_unsigned(2**FracBit, FracBit + 1);





begin

PROCESS( clk )
  BEGIN
    IF RISING_EDGE( clk ) THEN
    
    
        if Measure_Valid = '1' then
            XShifted <= X_Measurement( MeasureBit - 1 downto (MeasureBit - x_bit) ); -- shift the measurement down to the range given by the table
            YShifted <= Y_Measurement( MeasureBit - 1 downto (MeasureBit - y_bit) );
            
            if X_Measurement(MeasureBit - 1 downto (MeasureBit - x_bit)) = to_unsigned(2**x_bit - 1, x_bit) then  -- Make sure it doesn't overflow
                XShiftedNext <= X_Measurement( MeasureBit - 1 downto (MeasureBit - x_bit) );
            else
                XShiftedNext <= X_Measurement( MeasureBit - 1 downto (MeasureBit - x_bit) ) + 1;
            end if;
            
            if Y_Measurement(MeasureBit - 1 downto (MeasureBit - y_bit)) = to_unsigned(2**y_bit - 1, y_bit) then
                YShiftedNext <= Y_Measurement( MeasureBit - 1 downto (MeasureBit - y_bit) );
            else
                YShiftedNext <= Y_Measurement( MeasureBit - 1 downto (MeasureBit - y_bit) ) + 1;
            end if;
            -- X_Measurement((MeasureBit - x_bit - 1) downto 0) is 10 bit but we want 17 bit
            FractionX <= shift_left(resize(X_Measurement((MeasureBit - x_bit - 1) downto 0), FracBit), FracBit - x_bit);
            FractionY <= Y_Measurement(FracBit - 1 downto 0); -- Works as long as Y is 3 bit
            
            ShiftReady <= Measure_Valid;
        else
            ShiftReady <= '0'; 
        end if;
        
        
        
----------------------------------------------------------------------------------------------
-- start of new J code attempt
----------------------------------------------------------------------------------------------
        
-- P00 * (1 - fraction_x) * (1 - fraction_y) + P01 * (1 - fraction_x) * fraction_y + P10 * fraction_x * (1 - fraction_y) + P11 * fraction_x * fraction_y

        if ShiftReady = '1' or Counter /= 0 then
            -- clock 1
            if counter = 0 then
                index <= to_integer(XShifted & (y_bit - 1 downto 0 => '0')) + to_integer(YShifted);
                weight1 <= resize(FracOne - resize(FractionX, FracBit + 1), FracBit + 1);
                weight2 <= resize(FracOne - resize(FractionY, FracBit + 1), FracBit + 1);
                counterD1 <= counter;
                counter <= counter + 1;
                validD1 <= '1';
                FractionX0 <= FractionX;
                FractionY0 <= FractionY;
                XShifted0 <= XShifted;
                XShiftedNext0 <= XShiftedNext;
                YShifted0 <= YShifted;
                YShiftedNext0 <= YShiftedNext;
            
            
            elsif counter = 1 then
                index <= to_integer(XShifted0 & (y_bit - 1 downto 0 => '0')) + to_integer(YShiftedNext0);
                weight1 <= resize(FracOne - resize(FractionX0, FracBit + 1), FracBit + 1);
                weight2 <= resize(FractionY0, FracBit + 1);
                counterD1 <= counter;
                counter <= counter + 1;
                validD1 <= '1';
                FractionX1 <= FractionX0;
                FractionY1 <= FractionY0;
                XShifted1 <= XShifted0;
                XShiftedNext1 <= XShiftedNext0;
                YShifted1 <= YShifted0;
                YShiftedNext1 <= YShiftedNext0;
            
            
            elsif counter = 2 then
                index <= to_integer(XShiftedNext1 & (y_bit - 1 downto 0 => '0')) + to_integer(YShifted1);
                weight1 <= resize(FractionX, FracBit + 1);
                weight2 <= resize(FracOne - resize(FractionY1, FracBit + 1), FracBit + 1);
                counterD1 <= counter;
                counter <= counter + 1;
                validD1 <= '1';
                FractionX2 <= FractionX1;
                FractionY2 <= FractionY1;
                XShifted2 <= XShifted1;
                XShiftedNext2 <= XShiftedNext1;
                YShifted2 <= YShifted1;
                YShiftedNext2 <= YShiftedNext1;
            
            
            elsif counter = 3 then
                index <= to_integer(XShiftedNext2 & (y_bit - 1 downto 0 => '0')) + to_integer(YShiftedNext2);
                weight1 <= resize(FractionX2, FracBit + 1);
                weight2 <= resize(FractionY2, FracBit + 1);
                counterD1 <= counter;
                counter <= 0;
                validD1 <= '1';    
            end if;
        else
            validD1 <= '0'; 
        end if;
        
        -- clock 2
        LUTOutput <= BRAGG_LUT(index);
        weight <= weight1 * weight2;
        counterD2 <= CounterD1;
        validD2 <= validD1;
        
        -- clock 3
        LUTWeighted <= LUTOutput * weight;
        counterD3 <= counterD2;
        validD3 <= validD2;
        
        -- clock 4
        if validD3 = '1' then
            if counterD3 = 0 then
                AccumSum <= resize(LUTWeighted, AccumSum'length);
                OutValid <= '0';
            elsif counterD3 = 3 then
                EstimateOut <= resize(shift_right(AccumSum + LUTWeighted, 2 * FracBit), PointBit);
                OutValid <= '1';
            else
                AccumSum <= AccumSum + LUTWeighted;
                OutValid <= '0';
            end if;
        else
            OutValid <= '0';
        end if;
        
----------------------------------------------------------------------------------------------
-- end of new J code attempt
----------------------------------------------------------------------------------------------


    END IF;
END PROCESS;
end Behavioral;

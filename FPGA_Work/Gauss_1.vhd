library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
LIBRARY work;
USE work.LUT_Gauss.ALL;


entity Gauss_1 is
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
      
end Gauss_1;


architecture Behavioral of Gauss_1 is

signal FractionX    : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal FractionXHold: unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal OneMinusFractionX : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal FractionY    : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal OneMinusFractionY : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal weight1      : unsigned( FracBit downto 0 ) := (others => '0');
signal weight       : unsigned( FracBit downto 0 ) := (others => '0');
signal LUTOutput    : unsigned( PointBit - 1 downto 0 ) := (others => '0');
signal LUTWeighted  : unsigned( FracBit + PointBit downto 0) := (others => '0');
signal AccumSum     : unsigned( FracBit + PointBit downto 0) := (others => '0');
signal Output       : unsigned( FracBit + PointBit downto 0) := (others => '0');
signal XShifted     : unsigned( (x_bit - 1) downto 0 );
signal XShiftedNext : unsigned( (x_bit - 1) downto 0 );
signal YShifted     : unsigned( (y_bit - 1) downto 0 );
signal YShiftedNext : unsigned( (y_bit - 1) downto 0 );
signal ShiftReady   : STD_LOGIC := '0';
signal Counter      : STD_LOGIC := '0';
signal counterD1    : STD_LOGIC := '0';
signal validD1      : STD_LOGIC := '0';
signal counterD2    : STD_LOGIC := '0';
signal validD2      : STD_LOGIC := '0';
signal counterD3    : STD_LOGIC := '0';
signal validD3      : STD_LOGIC := '0';
signal index        : integer range 0 to 1023;
signal OutputValid  : STD_LOGIC := '0';
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
            ShiftReady <= Measure_Valid; 
        else
            ShiftReady <= '0';
        end if;


----------------------------------------------------------------------------------------------
-- start of new G code attempt
----------------------------------------------------------------------------------------------
  
  
       if ShiftReady = '1' or counter /= '0' then
            -- clock 1
            if counter = '0' then
                index <= to_integer(XShifted);
                weight1 <= resize(FracOne - resize(FractionX, FracBit + 1), FracBit + 1);
                FractionXHold <= FractionX; -- Hold FractionX in case of new measurement
                counterD1 <= counter;
                validD1 <= '1';
                counter <= '1';
            elsif counter = '1' then
                index <= to_integer(XShiftedNext);
                weight1 <= resize(FractionXHold, FracBit + 1);
                counterD1 <= counter;
                validD1 <= '1';
                counter <= '0';
            end if;
        else
            validD1 <= '0';
        end if;
        

        
        -- clock 2
        LUTOutput <= GAUSS_LUT(index);
        weight <= weight1;
        counterD2 <= counterD1;
        validD2 <= validD1;
        
        -- clock 3
        LUTWeighted <= LUTOutput * weight;
        counterD3 <= counterD2;
        validD3 <= validD2;
        
        -- clock 4
        if validD3 = '1' then
            if counterD3 = '0' then
                AccumSum <= resize(LUTWeighted, AccumSum'length);
                OutValid <= '0';
            elsif counterD3 = '1' then
                EstimateOut <= resize(shift_right(AccumSum + LUTWeighted, FracBit), PointBit);
                OutValid <= '1';
            end if;
        else
            OutValid <= '0';
        end if;
        
        
----------------------------------------------------------------------------------------------
-- end of new G code attempt
----------------------------------------------------------------------------------------------


    END IF;
END PROCESS;
end Behavioral;


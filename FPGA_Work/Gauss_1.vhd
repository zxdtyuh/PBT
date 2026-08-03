library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
LIBRARY work;
USE work.LUT_Gauss.ALL;


entity Gauss_1 is
  GENERIC(
    x_bit         : integer range 0 to 10 := 10;
    MeasureBit    : integer range 0 to 31 := 31;
    PointBit      : integer range 0 to 32 := 32;
    FracBit       : integer range 0 to 20 := 20;
    GaussRangeBit : integer range 0 to 2  := 2; -- Gauss range of 4
    ScaleFactor   : integer range 0 to 20  := 20
  );
  
  
  PORT(
       clk            : IN  STD_LOGIC;
       X_Measurement  : IN unsigned( MeasureBit - 1 downto 0 );
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
signal OneMinusFractionX : unsigned( FracBit downto 0 ) := (others => '0');
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
signal ShiftReady   : STD_LOGIC := '0';
signal Counter      : integer range 0 to 1 := 0;
signal counterD1 : integer range 0 to 1 := 0;
signal validD1      : STD_LOGIC := '0';
signal counterD2 : integer range 0 to 1 := 0;
signal validD2      : STD_LOGIC := '0';
signal counterD3 : integer range 0 to 1 := 0;
signal validD3      : STD_LOGIC := '0';
signal index        : integer range 0 to 1023;
constant FracOne    : unsigned(FracBit downto 0) := to_unsigned(2**FracBit, FracBit + 1);
constant One        : unsigned(MeasureBit - 1 downto 0) := to_unsigned(2**x_bit, MeasureBit);



begin

PROCESS( clk )
  BEGIN
    IF RISING_EDGE( clk ) THEN
    
    
        if Measure_Valid = '1' then -- X_Measurement gets an 11i; 20f from Function_for_GK
            if shift_right(X_Measurement, x_bit + GaussRangeBit) >= (One - 1) then  -- divides by 2^x_bit factor and the gauss range, checks if its within table range
                XShifted <= resize(One - 1, x_bit);
                XShiftedNext <= resize(One - 1, x_bit);
                FractionX <= to_unsigned(0 , FracBit);
            else
                --XShifted <= shift_right(X_Measurement, x_bit + GaussRangeBit);
                --FractionX <= resize(shift_left(X_Measurement, x_bit + GaussRangeBit), FracBit);
                --XShiftedNext <= shift_right(X_Measurement, x_bit + GaussRangeBit) + 1;
                
                
                XShifted <= resize(shift_right(X_Measurement, x_bit + GaussRangeBit), x_bit); -- shift the measurement down to the range given by the table
                FractionX <= shift_left(resize(X_Measurement(11 downto 0), ScaleFactor), 8); -- Cuts off integer bits. The bottom 12 bits determine how far you are to the next bin.
                XShiftedNext <= minimum(resize(shift_right(X_Measurement, x_bit + GaussRangeBit), x_bit) + 1, resize(One - 1, x_bit));
            end if;
            
                    
            ShiftReady <= Measure_Valid; 
        else
            ShiftReady <= '0';
        end if;


----------------------------------------------------------------------------------------------
-- start of new G code attempt
----------------------------------------------------------------------------------------------
  
  
       if ShiftReady = '1' or counter /= 0 then
            -- clock 1
            if counter = 0 then
                index <= to_integer(XShiftedNext);
                weight1 <= resize(FractionX, FracBit + 1);
                counterD1 <= counter;
                counter <= 1;
                validD1 <= '1';
                -- X_Measurement((MeasureBit - x_bit - 1) downto 0) is 10 bit but we want 17 bit
                OneMinusFractionX <= resize(FracOne - resize(FractionX, FracBit + 1), FracBit + 1);
            
            elsif counter = 1 then
                index <= to_integer(XShifted);
                weight1 <= OneMinusFractionX;
                counterD1 <= counter;
                counter <= 0;
                validD1 <= '1';
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
            if counterD3 = 0 then
                AccumSum <= resize(LUTWeighted, AccumSum'length);
                OutValid <= '0';
            elsif counterD3 = 1 then
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


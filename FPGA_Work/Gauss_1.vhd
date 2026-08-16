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
    FracBit       : integer range 0 to 12 := 12;
    GaussRangeBit : integer range 0 to 2  := 2; -- Gauss range of 4
    LUTBit        : integer range 0 to 17 := 17;
  );
  
  
  PORT(
       clk            : IN  STD_LOGIC;
       X_Measurement  : IN unsigned( MeasureBit - 1 downto 0 );
       Measure_Valid  : IN STD_LOGIC;
       GEstimateOut   : OUT unsigned( LUTBit - 1 downto 0);
       OutValid       : OUT STD_LOGIC := '0'       
      );
      
end Gauss_1;


architecture Behavioral of Gauss_1 is

signal FractionX    : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal OneMinusFractionX : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal weight1      : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal weight       : unsigned( FracBit - 1 downto 0 ) := (others => '0');
signal LUTOutput    : unsigned( LUTBit - 1 downto 0 ) := (others => '0');
signal LUTWeighted  : unsigned( LUTBit + FracBit - 1 downto 0) := (others => '0');
signal AccumSum     : unsigned( LUTBit + FracBit downto 0) := (others => '0');
signal XShifted     : unsigned( (x_bit - 1) downto 0 );
signal XShiftedHold : unsigned( (x_bit - 1) downto 0 );
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
constant FracOne    : unsigned(Fracbit downto 0) := to_unsigned(2**Fracbit, Fracbit + 1);
constant One        : unsigned(MeasureBit - 1 downto 0) := to_unsigned(2**x_bit, MeasureBit);



begin

PROCESS( clk )
  BEGIN
    IF RISING_EDGE( clk ) THEN
    
        -- clock 1
        if Measure_Valid = '1' then -- X_Measurement gets an 11i; 20f from Function_for_GK
            if shift_right(X_Measurement, x_bit + GaussRangeBit) >= (One - 1) then  -- divides by 2^x_bit factor and the gauss range, checks if its within table range
                XShifted <= resize(One - 1, x_bit);
                XShiftedNext <= resize(One - 1, x_bit);
                FractionX <= to_unsigned(0 , Fracbit);
            else
                --XShifted <= shift_right(X_Measurement, x_bit + GaussRangeBit);
                --FractionX <= resize(shift_left(X_Measurement, x_bit + GaussRangeBit), FracBit);
                --XShiftedNext <= shift_right(X_Measurement, x_bit + GaussRangeBit) + 1;
                
                
                XShifted <= resize(shift_right(X_Measurement, x_bit + GaussRangeBit), x_bit); -- shift the measurement down to the range given by the table
                FractionX <= X_Measurement(11 downto 0); -- Cuts off integer bits. The bottom 12 bits determine how far you are to the next bin. 0i; 12f
                XShiftedNext <= minimum(resize(shift_right(X_Measurement, x_bit + GaussRangeBit) + 1, x_bit), resize(One - 1, x_bit));
            end if;
            
                    
            ShiftReady <= Measure_Valid; 
        else
            ShiftReady <= '0';
        end if;


----------------------------------------------------------------------------------------------
-- start of new G code attempt
----------------------------------------------------------------------------------------------
  
       -- clock 2
       if ShiftReady = '1' or counter /= 0 then
            if counter = 0 then
                LUTOutput <= resize(GAUSS_LUT(to_integer(XShiftedNext)), LUTBit); -- 1i; 16f    (1i because of the posibility of 1)
                XShiftedHold <= XShifted;
                weight <= FractionX; -- 0i; 12f
                counterD1 <= counter;
                counter <= 1;
                validD1 <= '1';
                OneMinusFractionX <= resize(FracOne - resize(FractionX, Fracbit + 1), Fracbit);
            
            elsif counter = 1 then
                LUTOutput <= resize(GAUSS_LUT(to_integer(XShiftedHold)), LUTBit); -- 1i; 16f    (1i because of the posibility of 1)
                weight <= OneMinusFractionX;  -- 0i; 12f
                counterD1 <= counter;
                counter <= 0;
                validD1 <= '1';
            end if;
        else 
            validD1 <= '0';
        end if;
        
        -- clock 3
        LUTWeighted <= LUTOutput * weight; -- 1i; 28f
        counterD2 <= counterD1;
        validD2 <= validD1;
                
        -- clock 4
        if validD2 = '1' then
            if counterD2 = 0 then
                AccumSum <= resize(LUTWeighted, AccumSum'length); -- 2i; 36f
                OutValid <= '0';
            elsif counterD2 = 1 then
                GEstimateOut <= resize(shift_right(AccumSum + LUTWeighted, FracBit), LUTBit); -- 1i; 16f
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


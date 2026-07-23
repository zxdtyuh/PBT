
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity Function_for_GK is

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
           clk              : IN  STD_LOGIC;
           --X_Measurement  : IN unsigned( MeasureBit - 1 downto 0 );
           --Y_Measurement  : IN unsigned( MeasureBit - 1 downto 0 );
           --Measure_Valid  : IN STD_LOGIC;
           XNodeIn          : IN signed( PointBit downto 0);
           XNodeValid       : IN STD_LOGIC := '0';
           FuncOut          : OUT signed( 2 * PointBit + 1 downto 0 );
           FuncOutValid     : OUT STD_LOGIC := '0'       
          );
      
end Function_for_GK;

architecture Behavioral of Function_for_GK is

signal RangeSub : 

begin

PROCESS( clk )
  BEGIN
    IF RISING_EDGE( clk ) THEN
        
        -- Clock 1
        if XNodeValid = '1' then
            FuncOut <= XNodeIn * XNodeIn;
            FuncOutValid <= '1';
            -- RangeSub <= 2**PointBit - XNodeIn;
        end if;
        
        
      
    END IF;
END PROCESS;
end Behavioral;

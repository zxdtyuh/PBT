library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;


package GK_X_Squared_Table is

    constant GK_WIDTH : integer := 36; 
    type gk_array_t is array (natural range <>) of unsigned(GK_WIDTH-1 downto 0);
 
    ---------------------------------------------------------------------
    -- 7-point Gauss weights
    ---------------------------------------------------------------------
 
    constant GAUSS_WEIGHTS : gk_array_t(0 to 3) := (
        0 => x"2125ED3F0",  -- 0.12948496616886969327
        1 => x"479AC5C4F",  -- 0.27970539148927666790
        2 => x"61BF9D3B9",  -- 0.38183005050511894495
        3 => x"6AFF5F80F"   -- 0.41795918367346938776
    );
 
    ---------------------------------------------------------------------
    -- 15-point Kronrod nodes (magnitudes) and weights
    ---------------------------------------------------------------------
    constant KRONROD_NODES : gk_array_t(0 to 7) := (
        0 => x"FDD004EA7",  -- 0.99145537112081263921
        1 => x"F2F8BC73E",  -- 0.94910791234275926264  Gauss 0
        2 => x"DD67C13DD",  -- 0.86486442335976907279
        3 => x"BDD4FCDF2",  -- 0.74153118559939443986  Gauss 1
        4 => x"9609D024F",  -- 0.58608723546769113029
        5 => x"67E577C46",  -- 0.40584515137739716907  Gauss 2
        6 => x"353165126",  -- 0.20778495500789846760
        7 => x"000000000"   -- 0.00000000000000000000  Gauss 3
    );
 
    constant KRONROD_WEIGHTS : gk_array_t(0 to 7) := (
        0 => x"05DF16D9F",  -- 0.02293532201052922497
        1 => x"1026CDAA8",  -- 0.06309209262997855329
        2 => x"1AD384A35",  -- 0.10479001032225018384
        3 => x"2401DA1E9",  -- 0.14065325971552591875
        4 => x"2B43E4CDD",  -- 0.16900472663926790283
        5 => x"30BAD0C39",  -- 0.19035057806478540991
        6 => x"3455B797E",  -- 0.20443294007529889241
        7 => x"35A09F211"   -- 0.20948214108472782801
    );


end package GK_X_Squared_Table;

package body GK_X_Squared_Table is

end package body GK_X_Squared_Table;
# import time
import numpy as np
import scipy as sp
# from scipy.differentiate import derivative
# from scipy.interpolate import RegularGridInterpolator
import matplotlib.pyplot as plt
#import matplotlib.colors as colors
import matplotlib as mpl
mpl.rcParams.update(mpl.rcParamsDefault)
#import time

# ===============================================================
# True functions
# ===============================================================

c_p = 0.43
c_beta = 833.33333333
c_gamma = 0.6


def F( x , v_B ):
  return 1 / (( x**(c_p) ) + v_B )

@np.vectorize
def f( x , v_B ):
  return sp.integrate.quad( lambda u: F( u , v_B )  , 0 , x )[0]
  
def h( x , v_B ):
  return ( x + c_beta ) * F( x , v_B ) 

def j( x , v_B ):
  val = h( x , v_B ) + ( c_gamma * f( x , v_B ) )
  return val

# ===============================================================
# Lookup table construction
# ===============================================================

x_bits = 15   # anything after 15 bit shows no change in error
y_bits = 5    # anything after 5 bit shows no change in error
output_bits = 20 # no change after 20 bits
x_start = 0
y_start = 0.4
full_x_range = 512
full_y_range = .4625 - y_start

LUT = np.zeros((2**x_bits, 2**y_bits))

for Y in range( (2**y_bits) ):
  for X in range((2**x_bits) ):
    LUT[X,Y] = int( (2**output_bits) * j( full_x_range * X/(2**x_bits), full_y_range * Y/(2**y_bits) + y_start ) )

# np.savetxt("Bragg_LUT.csv", LUT.astype(int), delimiter=",")


# full_table_area = 2**x_bits * 2**y_bits

# VHDL_LUT = np.empty(full_table_area, dtype=object)

# i = 0
# while i < full_table_area:
#   for X in range((2**x_bits) ):
#     for Y in range( (2**y_bits) ):
#       VHDL_LUT[i] = f"{i} => 0x\"{LUT[X,Y].astype(int):08X}\", -- row = {X}  col = {Y}"
#       i = i + 1

# np.savetxt("Bragg_LUT_VHDL.csv", np.vstack(VHDL_LUT), delimiter="", fmt='%s')

# ===============================================================
# interpolation function
# ===============================================================

def j_int(x, v_B):
  scaled_x = (2**x_bits) * (x - x_start)/full_x_range 
  scaled_y = (2**y_bits) * (v_B - y_start)/full_y_range 
  
  index_x = min( int( scaled_x ), (2**x_bits)-1 )
  next_index_x = min( index_x+1 , (2**x_bits)-1 )  
  fraction_x = scaled_x - index_x
  
  index_y = min( int( scaled_y ), (2**y_bits)-1 )
  next_index_y = min( index_y+1 , (2**y_bits)-1 )  
  fraction_y = round(scaled_y - index_y, 20)
  
  P00, P01, P10, P11 = LUT[index_x, index_y], LUT[index_x, next_index_y], LUT[next_index_x, index_y], LUT[next_index_x, next_index_y]

  # bilinear interpolation
  #return P00 * (1 - fraction_x) * (1 - fraction_y) + P01 * (1 - fraction_x) * fraction_y + P10 * fraction_x * (1 - fraction_y) + P11 * fraction_x * fraction_y

  L1 = P00 + int(fraction_y * (P01 - P00))
  L2 = P10 + fraction_y * (P11 - P10)

  if L1 < 0:
    print("L1 negative")
  if L2 < 0:
    print("L2 negative")


  return((int(L1) + int( fraction_x * (L2 - L1) )) / 2**output_bits)


# print(j_int(((full_x_range) * (520947 / (2**20))) + x_start, ((full_y_range) * (300102 / (2**20))) + y_start))
# print(j_int(((full_x_range) * (1048 / (2**20))) + x_start, ((full_y_range) * (63917 / (2**20))) + y_start))
# print(j_int(((full_x_range) * (0 / (2**20))) + x_start, ((full_y_range) * (0 / (2**20))) + y_start))
# print(j_int(((full_x_range) * (1048575 / (2**20))) + x_start, ((full_y_range) * (1048575 / (2**20))) + y_start))
# print(j_int(((full_x_range) * (512000 / (2**20))) + x_start, ((full_y_range) * (524288 / (2**20))) + y_start))
# print(j_int(((full_x_range) * (700000 / (2**20))) + x_start, ((full_y_range) * (800000 / (2**20))) + y_start))

# ===============================================================
# Graphing
# ===============================================================


# fig, ax1 = plt.subplots(1)

# x = np.linspace(30, x_start+full_x_range - 1, 1000 )
# ax1.plot( x, np.vectorize( j )( x , .4 ) - np.vectorize( j )( x , .45 ), label=f"j( x , .4 ) - j( x , .45 )" )
# ax1.legend()

# plt.show()

# fig, ax1 = plt.subplots(1)

# y = np.linspace(0.4,0.45,1000)
# ax1.plot( y, np.vectorize( j )( 150 , y ), label=f"j( 150, y )" )
# ax1.legend()

# plt.show()


# fig, [ax1, ax2, ax3] = plt.subplots(1,3)

# x = np.linspace(30, x_start+full_x_range - 1, 1000 )
# ax1.plot( x, np.vectorize( j )( x , .44 ) , label=f"j( x , .44 )" )
# ax1.legend()

# x = np.linspace(30, x_start+full_x_range - 1, 1000 )
# ax2.plot( x, np.vectorize( j_int )( x , .44), label=f"j( x , .44 )" )
# ax2.legend()

# x = np.linspace(30, x_start+full_x_range - 1, 1000 ) 
# ax3.plot( x, ((np.vectorize( j_int )( x , .44 )) - np.vectorize( j )( x , .44 )), label=f"j( x , .44 )" )
# ax3.legend()

# plt.show()


# fig, [ax1, ax2, ax3] = plt.subplots(1,3)

# x,y = np.linspace(30, x_start+full_x_range - 1, 1000 ) , np.linspace(0.4,0.45,7)
# for Y in y: ax1.plot( x, np.vectorize( j )( x , Y ) , label=f"j( x , {Y:.02f} )" )
# ax1.set_title("Exact j function")
# ax1.set_xlabel("x")
# ax1.set_ylabel('j')
# ax1.legend()

# x,y = np.linspace(30, x_start+full_x_range - 1, 1000 ) , np.linspace(y_start, y_start+full_y_range - .01, 7) 
# for Y in y: ax2.plot( x, np.vectorize( j_int )( x , Y ), label=f"j( x , {Y:.02f} )" )
# ax2.set_title("Interpolated j function")
# ax2.set_xlabel("x")
# ax2.set_ylabel('j')
# ax2.legend()

# x,y = np.linspace(30, x_start+full_x_range - 1, 1000 ) , np.linspace(y_start, y_start+full_y_range -.01, 7) 
# for Y in y: ax3.plot( x, ((np.vectorize( j_int )( x , Y )) - np.vectorize( j )( x , Y )), label=f"j( x , {Y:.02f} )" )
# ax3.set_title("Difference between interpolated and exact j function")
# ax3.set_xlabel("x")
# ax3.set_ylabel('j')
# ax3.legend()

# plt.show()

# fig, ax1 = plt.subplots(1)

# x,y = np.linspace(0, 512, 1000 ) , np.linspace(0.4,0.45,7)
# for Y in y: ax1.plot( x, np.vectorize( j )( x , Y ) , label=f"j( x , {Y:.02f} )" )
# ax1.set_title("j function")
# ax1.set_xlabel("x")
# ax1.set_ylabel('j')
# ax1.legend()

# plt.show()

# fig, [ax1, ax2, ax3] = plt.subplots(1,3)

# x,y = np.linspace(30, x_start+full_x_range - 1, 10 ) , np.linspace(y_start, y_start+full_y_range -.01, 1000)
# for X in x: ax1.plot( y, np.vectorize( j )( X , y ) , label=f"j( {X:.0f} ," + r' $v_B$)')
# ax1.set_title("Exact j function")
# ax1.set_xlabel(r'$v_B$')
# ax1.set_ylabel('j')
# ax1.legend()


# x,y = np.linspace(30, x_start+full_x_range - 1, 10 ) , np.linspace(y_start, y_start+full_y_range -.01, 1000)
# for X in x: ax2.plot( y, np.vectorize( j_int )( X , y ), label=f"j( {X:.0f} ," + r' $v_B$)')
# ax2.set_title("Interpolated j function")
# ax2.set_xlabel(r'$v_B$')
# ax2.set_ylabel('j')
# ax2.legend()

# x,y = np.linspace(30, x_start+full_x_range - 1, 10 ) , np.linspace(y_start, y_start+full_y_range - .01, 1000)
# for X in x: ax3.plot( y, ((np.vectorize( j_int )( X , y )) - np.vectorize( j )( X , y )) , label=f"j( {X:.0f} ," + r' $v_B$)')
# ax3.set_title("Difference between interpolated and exact j function")
# ax3.set_xlabel(r'$v_B$')
# ax3.set_ylabel('j difference')
# ax3.legend()

# plt.show()

# fig, ax1 = plt.subplots(1)

# x,y = np.linspace(30, x_start+full_x_range - 1, 10 ) , np.linspace(y_start, y_start+full_y_range -.01, 1000)
# for X in x: ax1.plot( y, np.vectorize( j )( X , y ) , label=f"j( {X:.0f} ," + r' $v_B$)')
# ax1.set_title("Exact j function")
# ax1.set_xlabel(r'$v_B$')
# ax1.set_ylabel('j')
# ax1.legend()

# plt.show()





# fig, ax3 = plt.subplots(1)

# x,y = np.linspace(0, x_start+full_x_range - 1, 1000 ) , np.linspace(y_start, y_start+full_y_range -.01, 7) 
# for Y in y: ax3.plot( x, ((np.vectorize( j_int )( x , Y )) - np.vectorize( j )( x , Y )), label=f"j( x , {Y:.02f} )" )
# ax3.set_title("Difference between 15-bit x interpolated and exact j function")
# ax3.set_xlabel("x")
# ax3.set_ylabel('j')
# ax3.legend()

# plt.show()
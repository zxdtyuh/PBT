# import time
import numpy as np
# import scipy as sp
# from scipy.differentiate import derivative
# from scipy.interpolate import RegularGridInterpolator
import matplotlib.pyplot as plt
import matplotlib.colors as colors

import matplotlib as mpl
mpl.rcParams.update(mpl.rcParamsDefault)


std = 1/np.sqrt(2)
mean = 0

# ===============================================================
# True function
# ===============================================================

def G_true(x):
    return (1/(std * np.sqrt(2))) * np.exp(-(x - mean)**2 / (2 * std**2))
    
    
    
# ===============================================================
# Linear interpolation of a Gaussian
# Raw code part
# ===============================================================

input_bits = 10 # Effects the spacing between each x point in the look up table
output_bits = input_bits + 6  # Effects the scaling factor of the output
# The bigger, the more integer like
full_range = 4

LUT = [ int( (2**output_bits) * G_true( full_range * x/(2**input_bits) ) ) for x in range( (2**input_bits) ) ]
# 16777216 * G(8 * x/1024)
# y range of this gaussian is 0 to 1, but we want to work in integers
# same idea with scaling the input. We want to use integer x's

# VHDL_LUT = np.empty(2**input_bits, dtype=object)

# for X in range((2**input_bits) ):
#     VHDL_LUT[X] = f"{X} => 0x\"{LUT[X]:05X}\","

# np.savetxt("Gauss_LUT_VHDL.csv", np.vstack(VHDL_LUT), delimiter="", fmt='%s')

# print(max(LUT).bit_length())

def G_int(x):
  
  scaled_x = (2**input_bits) * abs(x)/full_range # This will give you the 0 - 1024. this then aligns with the indexing
  
  index = int( scaled_x )
  next_index = min( index+1 , (2**input_bits)-1 )  
  fraction = scaled_x - index

  if index >= 1023:
    index = 1023
    next_index = 1023
    fraction = 0
  
  P1 , P2 = LUT[ index ] , LUT[ next_index ] 
  return((int(P1) + int( fraction*(P2-P1) )) / 2**output_bits)

# x_max_test = 4 * 2^20



# print(G_int(((full_range) * (520947 / (2**20)))))
# print(G_int(((full_range) * (1048 / (2**20)))))
# print(G_int(((full_range) * (0 / (2**20)))))
# print(G_int(((full_range) * (1048575 / (2**20)))))

# fig, (ax1,ax2) = plt.subplots(2)

# x = np.linspace( 0, 3, 100000 )

# y1 = np.vectorize( G_true )(x)
# ax1.plot(x, y1)

# y2 = np.vectorize( G_int )(x) / (2**output_bits) 
# ax1.plot(x, y2, linestyle='dashed')

# ax2.plot(x, y1 - y2)

# plt.show()

# fig, [ax1, ax2, ax3] = plt.subplots(1,3)

# x = np.linspace(0, 4, 1000 )
# ax1.plot( x, np.vectorize( G_true )( x ) , label=f"G( x )" )
# ax1.legend()

# x = np.linspace(0, 4, 1000 )
# ax2.plot( x, np.vectorize( G_int )( x ), label=f"G( x )" )
# ax2.legend()

# x = np.linspace(0, 4, 1000 )
# ax3.plot( x, ((np.vectorize( G_int )( x )) - np.vectorize( G_true )( x )), label=f"G( x )" )
# ax3.legend()

# plt.show()

# fig, (ax1,ax2) = plt.subplots(2)

# x = np.linspace( -3, 3, 100000 )

# y1 = np.vectorize( G_true )(x)
# ax1.plot(x, y1)

# y2 = np.vectorize( G_int )(x)
# ax1.plot(x, y2, linestyle='dashed')

# ax2.plot(x, y1 - y2)

# plt.show()
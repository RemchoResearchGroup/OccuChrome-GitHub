import sys
import numpy as np
import matplotlib.pyplot as plt

fname = sys.argv[1]

data = np.genfromtxt(fname, delimiter=',', names=['b', 'g', 'r', 'time', 'stddev'])

plt.plot(data['time'], data['b'], 'b,')
plt.plot(data['time'], data['g'], 'g,')
plt.plot(data['time'], data['r'], 'r,')

plt.fill_between(data['time'], data['b'] + data['stddev'], data['b'] -
        data['stddev'], facecolor='blue', alpha=0.2)
plt.fill_between(data['time'], data['g'] + data['stddev'], data['g'] -
        data['stddev'], facecolor='green', alpha=0.2)
plt.fill_between(data['time'], data['r'] + data['stddev'], data['r'] -
        data['stddev'], facecolor='red', alpha=0.2)

plt.title(fname)

plt.show()

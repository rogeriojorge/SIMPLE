#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jan  8 14:51:30 2019

@author: calbert
"""

import os
import numpy as np
import matplotlib.pyplot as plt

inpath = ['/home/calbert/mnt/draco/run/NEO-ORB/2019-01-08_alphas/',
          '/home/calbert/mnt/draco/run/NEO-ORB/2019-01-08_alphas_sympl/',
          '/home/calbert/mnt/draco/run/NEO-ORB/2019-01-08_alphas_sympl2/',
          '/home/calbert/mnt/draco/run/NEO-ORB/2019-01-08_alphas_sympl3/',
          '/home/calbert/mnt/draco/run/NEO-ORB/2019-01-08_alphas_sympl4/',
          '/home/calbert/run/NEO-ORB/2019-01-08_alphas_sympl/']

def plotdata(infile):
    data = np.loadtxt(infile)
    t = data[:,0]
    fracpass = data[:,1]
    fractrap = data[:,2]
    
    plt.figure(1)
    plt.loglog(t+1e-4, fracpass+fractrap)
    plt.xlabel('t')
    plt.ylabel('% confined (total)')
    plt.grid(True, which="both")
    plt.tight_layout()
    
    plt.figure(2)
    plt.loglog(t+1e-4, fractrap/fractrap[0])
    plt.xlabel('t')
    plt.ylabel('% confined (trapped, relative)')
    plt.grid(True, which="both")
    plt.tight_layout()
    
cases = ['RKV', 'RK', '0016', '0032', '0064', '0128']


#plotdata(os.path.join(inpath[0], 'confined_fraction.dat'))
#plotdata(os.path.join(inpath[1], '016/confined_fraction.dat'))
#plotdata(os.path.join(inpath[5], 'confined_fraction.dat'))
for run in cases:
        plotdata(os.path.join(inpath[5], 'confined_fraction_{}.dat'.format(run)))

plt.figure(1)
plt.legend(cases)
plt.figure(2)
plt.legend(cases)

plt.show()

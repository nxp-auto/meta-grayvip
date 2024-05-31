===================
GrayVIP Yocto Layer
===================

This Yocto layer provides support for building NXP Gray Vehicle Integration 
Platform (GrayVIP) on top of NXP Auto Linux BSP and other real time packages.

Complete instructions for building a GrayVIP image are documented in the GrayVIP User Manual.

Dependencies
============
This layer depends on the following Yocto layers:

 - meta-alb: https://github.com/nxp-auto-linux/meta-alb

Note: The above layers have other dependencies that are automatically handled by
following the instructions from GrayVIP User Manual.

To manually add meta-grayvip layer to your build run the following command from
within the build directory::

  bitbake-layers add-layer meta-grayvip
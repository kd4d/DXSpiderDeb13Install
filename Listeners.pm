#
# Copy this file to /spider/local and modify it to your requirements
#
#
# This file specifies which local interfaces and ports you will be
# listening on
#
# You can add as many as you like
#

package main;

use vars qw(@listen);

@listen = (
		   ["0.0.0.0", 7300],     # IPV4 only
		   ["0.0.0.0", 8001],     # IPV4 only  - Cluster Connection Port
# ^
# |
# 		   
# OR (IF you listen on IPV6 as well) This one!!!!!
  #		   ["::", 7300],     # IPV4 and IPV6
# ^
# |
# This one!!!!!
);

1;

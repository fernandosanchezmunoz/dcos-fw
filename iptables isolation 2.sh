#!/bin/bash

#$NAME_1 apps can connect to $NAME_0  apps.
#$NAME_0  apps cannot connect to $NAME_1 apps.
#All $NAME_0  apps can communicate amongst themselves.
#All $NAME_1 apps can communicate amongst themselves.
#$NAME_0  only runs apps on port 80. 

#Assume a $NAME_0 overlay w/ the agent subnet carved from $SUBNET_0
#plus a   $NAME_1 overlay w/ the agent subnet carved from $SUBNET_1

#########
#create $POLICY_NAME chain
iptables -N $POLICY_NAME
#set $POLICY_NAME default --> Action=REJECT
#"REJECT anything that doesn't match any of the rules in the $POLICY"
iptables -A $POLICY_NAME -j REJECT 

#create the sets
#Overall traffic to apply this policy to as traffic is being forwarded
ipset create overlays list:set

#define the sets as subnets
ipset create $NAME_0 hash:net
ipset create $NAME_1 hash:net

#add the subnet values 
ipset add $NAME_0 $SUBNET_0
ipset add $NAME_1 $SUBNET_1

#Add $POLICY_NAME to FORWARD table in kernel - "overlays" src to "overlays" dst --> Action=send to "$POLICY_NAME"
iptables -I FORWARD -m set --match-set overlays src -m set --match-set overlays dst -j $POLICY_NAME

#####
#Action=RETURN takes the traffic back to the FORWARD table so it's allowed and keeps going through the stack.
####

#Add to "$POLICY_NAME": ESTABLISH/RELATED --> Action=RETURN
iptables -A $POLICY_NAME -m conntrack --ctstate RELATED,ESTABLISHED -j RETURN

#create $SIMPLE ip set: match on net,net
ipset create $SIMPLE hash:net,net
#$SIMPLE=Apply from $SUBNET1 to $SUBNET1
ipset add $SIMPLE $SUBNET_1,$SUBNET_1
#$SIMPLE=Apply from $SUBNET0 to $SUBNET0
ipset add $SIMPLE $SUBNET_0,$SUBNET_0
#Add to "$POLICY_NAME": "$SIMPLE" match --> Action=RETURN
iptables -A $POLICY_NAME -m set --match-set $SIMPLE src,dst -j RETURN

#create $COMPLEX ip set: match on net,port,net
ipset create $COMPLEX hash:net,port,net
#$COMPLEX="Apply to communication from $SUBNET1 to $SUBNET0:$PORT "
ipset add $COMPLEX $SUBNET_1,$PORT,$SUBNET_0 #this allows traffic from $NAME_1 to $NAME_0 on port $PORT
#Add to "$POLICY_NAME": "$COMPLEX" match --> Action=RETURN
iptables -A $POLICY_NAME -m set --match-set $COMPLEX src,dst,dst -j RETURN

#Internal to themselves "hairpin exception rules??"
#Add to "$POLICY_NAME": "$NAME_0 " to "$NAME_0 " --> Action=RETURN
iptables -I $POLICY_NAME -m set --match-set $NAME_0  src -m set --match-set $NAME_0  dst -j RETURN
#Add to "$POLICY_NAME": "$NAME_1" to "$NAME_1" --> Action=RETURN
iptables -I $POLICY_NAME -m set --match-set $NAME_1 src -m set --match-set $NAME_1 dst -j RETURN



#DEBUG
#iptables -L -v -n
#iptables -I $POLICY_NAME -j TRACE

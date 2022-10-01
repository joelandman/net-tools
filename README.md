# net-tools

lsnet:  Lists current network configuration in an easy to view manner

    joe@gandalf:~/dev$ lsnet 
           DEV [MST]   ST   SP IP                             MTU          TX          RX
           br0 [   ]   up      192.168.5.52/24               1500    4.687 GB    1.946 GB
           br0 [   ]   up      10.10.0.52/16                 1500    4.687 GB    1.946 GB
           br0 [   ]   up      fe80::bc1a:7161:97a:674f/64   1500    4.687 GB    1.946 GB
        br_int [   ]   up      10.100.0.1/16                 1500    1.106 MB           0
        br_int [   ]   up      fe80::c464:3aff:fe23:a223/64  1500    1.106 MB           0
    enp109s0f1 [br0]   up  1Gb                               1500    4.687 GB    2.012 GB
            lo [   ]   up      127.0.0.1/8                  65536   17.308 MB   17.308 MB
            lo [   ]   up      ::1/128                      65536   17.308 MB   17.308 MB
      wlp110s0 [   ]   up      192.168.5.154/24              1500   19.413 MB  612.783 MB
      wlp110s0 [   ]   up      fe80::af90:5fbb:33e0:fd59/64  1500   19.413 MB  612.783 MB


lsbr:  Lists current network bridges (linux bridge driver based) in terms of what interfaces are bridged

    joe@gandalf:~/dev$ lsbr 
    br0:	interfaces enp109s0f1


lsbond:  Lists current status of bonds (linux bonding driver, not teaming driver)


# vim: sw=2 sts=2 et ff=dos fdm=marker cms=\ #\ %s
#

/system {
  leds set 0 interface=wlan0
  clock set time-zone-name=Europe/Prague
  ntp client set enabled=yes primary-ntp=10.9.8.1
}

/interface {
  :local ssid XXXXXXXXXX
  :local psk  YYYYYYYYYY

# assign readable interface names
  set [find default-name=wlan1] name=wlan0
  set [find default-name=ether1] name=eth0-gw
  set [find default-name=ether2] name=eth1-local-master
  :for i from=2 to=4 do={
    :local n ($i + 1)
    set [find default-name="ether$n"] name="eth$i-local-slave"

    ethernet {
      set "eth$i-local-slave" master-port=eth1-local-master
    }
  }

  bridge {
    port {
      remove [find]
    }
    remove bridge-local
# protocol-mode=none disables [R]STP ([Rapid] Spanning Tree Protocol)
    add name=bridge-local admin-mac=D4:CA:6D:29:57:B1 auto-mac=no l2mtu=1598 protocol-mode=none
    port {
      add bridge=bridge-local interface=eth1-local-master
      add bridge=bridge-local interface=wlan0
    }
  }

  wireless {
    set wlan0 \
      ssid=$ssid \
      country="czech republic" \
      nv2-security=enabled \
      disabled=no \
      l2mtu=2290 mode=ap-bridge \
      band=2ghz-b/g/n channel-width=20/40mhz-ht-above distance=indoors \
      ht-supported-mcs="mcs-0,mcs-1,mcs-2,mcs-3,mcs-4,mcs-5,mcs-6,mcs-7,mcs-8,mcs-9,mcs-10,mcs-11,mcs-12,mcs-13,mcs-14,mcs-15"

    security-profiles {
      set [find default=yes] \
        authentication-types=wpa2-psk \
        wpa2-pre-shared-key=$psk \
        mode=dynamic-keys
    }
  }
}

/ip {
  firewall {
    nat { remove [find]; }
    filter { remove [find]; }
  }

  address {
    remove [find]
    add interface=eth1-local-master address=10.9.9.1/24 network=10.9.9.0
  }

  dhcp-client {
    remove [find]
    add interface=eth0-gw dhcp-options=hostname,clientid disabled=no
  }
  dhcp-server {
    remove [find]
  }
  dhcp-relay {
    remove [find]
    add interface=bridge-local name=default dhcp-server=10.9.8.1 add-relay-info=yes disabled=no
  }

  dns {
    set allow-remote-requests=no
    static {
      remove [find]
    }
  }

  upnp {
    set enabled=no
    set allow-disable-external-interface=no
  }

  :foreach i in=[/interface find] do={
    :local ifname [/interface get $i name]
    neighbor discovery
      set $ifname discover=no
  }
}

/tool mac-server {
  remove [find default=no]
  set [find] disabled=yes
  mac-winbox {
    remove [find default=no]
    set [find] disabled=yes
  }
}


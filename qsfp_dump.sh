#!/bin/sh
echo 'Start'
echo '############################################################'
echo '############################################################'
#echo 'bus0 device'
#i2cdetect -r -y 0
#echo '0x70 address register'
#i2cdump -y 0 0x70
#echo '0x50 address  register'
#i2cdump -y 0 0x50
#echo 'open channel 0'
i2cset -f -y 0 0x70 0x0 0x00
i2cset -f -y 0 0x71 0x0 0x00
#echo  -e "read 0x50 address device 128 register data\n\t"
#lower_memory_page=0x00
#lower_memory=1
upper_page00h=2
upper_page03h=3

read_eeprom()
{
 page=$1
 index=0
#echo -e "read in 0x50 address register data number is 128\n"
if [ ${page} -eq ${upper_page00h} ]
 then
   i2cset -f -y 0 0x50 0x7f 0x00
 elif [ ${page} -eq ${upper_page03h} ] 
   then
   i2cset -f -y 0 0x50 0x7f 0x03
 fi
#  echo "the page is ${page}"
for ((j=0; j<256; j++))
do
   value[j]=`i2cget -f -y 0 0x50 $index`
   index=`expr $index + 1`
 #  echo "data[$j]= ${value[$j]}"
done
#echo -e "\n"

}   
 show_temperature()
{
  shift_value=0
 #  echo  "Temperature: ${value[22]}${value[23]} " 
   temp1=$(echo ${value[22]} | awk -F "0x" '{print $2}')
 #  echo "zhuanhuanhou: $temp1"   
   temp2=$(echo ${value[23]} | awk -F "0x" '{print $2}')
  shift_value=$(($((16#${templ}))>>7))
#  echo -e "shift_value : $shift_value"
   combine=${temp1}${temp2} 
  if [ $shift_value -eq 1 ]
   then
    #negative
 #  echo $combine
   calculate=$(($((16#10000))-$((16#$combine))))
 #  echo "$calculate"
 # result=$(echo "`expr $calculate / 256`" )
   result=$(echo "scale=8;$calculate / 256 " | bc )
  if [ $(echo $result | cut -c 1) = "." ]
    then
      echo -e "Temperature: -0"$result" C"
   else
     echo -e "Temperature: -"$result" C"
  fi
 
  
else 
   #positive
   combine=${temp1}${temp2}
 #  echo $combine
   calculate=$((16#$combine))
 #  echo "$calculate"
   result=$(echo "scale=8;$calculate / 256 " | bc )
  if [ $(echo $result | cut -c 1) = "." ]
    then
      echo -e "Temperature: 0"$result" C"
   else
     echo -e "Temperature: "$result" C"
  fi

fi


}
    
 show_supply_voltage()
{
 #echo "Supply voltage ${value[26]}${value[27]}"
  volt1=$(echo ${value[26]} | awk -F "0x" '{print $2}')
  volt2=$(echo ${value[27]} | awk -F "0x" '{print $2}')
  combine=${volt1}${volt2}
  calculate=$((16#$combine ))
 #volt=$(expr $calculate / 10000)
  volt=$(echo "scale=8;$calculate / 10000" | bc) 
  echo -e "Supply Voltage : $volt V"

} 
 
show_RX_power_channel()
{
  rx_ch=$1
  msb=$2
  lsb=$3
#combine=${value[${msb}]}${value[${lsb}]}
# value[34]=0x55
# value[35]=0x20
  powerm=$(echo ${value[${msb}]} | awk -F "0x" '{print $2}')
  powerl=$(echo ${value[${lsb}]} | awk -F "0x" '{print $2}')
  combine=${powerm}${powerl}
  calculate=$((16#$combine))
  echo "${calculate}"
  result=$(echo "scale=4;$calculate/10000" | bc)
  if [ $(echo $result | cut -c 1) = "." ]
  then 
     echo -e "RX$rx_ch Power: 0"$result" mW"
  else
    echo -e "RX$rx_ch Power: "$result" mW"
  fi
 # echo -e "RX$rx_ch power: "$result" mW"
}

 show_RX_power()
{
#  echo "Rx1 Power ${value[34]} ${value[35]}"
#  echo "Rx2 Power ${value[36]} ${value[37]}"
#  echo "Rx3 Power ${value[38]} ${value[39]}"
#  echo "Rx4 Power ${value[40]} ${value[41]}"
 
  show_RX_power_channel 1 34 35
  show_RX_power_channel 2 36 37
  show_RX_power_channel 3 38 39
  show_RX_power_channel 4 40 41

}

show_tx_bias_channel()
{
  bias_ch=$1
  msb=$2
  lsb=$3
  biasm=$(echo ${value[${msb}]} | awk -F "0x" '{print $2}')
  biasl=$(echo ${value[${lsb}]} | awk -F "0x" '{print $2}')
  combine=${biasm}${biasl}
  calculate=$((16#$combine))
  result=$(echo "scale=3;$calculate/1000*2" | bc)
  if [ $(echo $result | cut -c 1) = "." ]
  then
     echo -e "TX$bias_ch Bias: 0"$result" mA"
  else
    echo -e "TX$bias_ch Bias: "$result" mA"
  fi
  
 

}

show_tx_bias()
{
# echo "Tx1 Bias ${value[42]} ${value[43]}"
# echo "Tx2_Bias ${value[44]} ${value[45]}"
# echo "Tx3_Bias ${value[46]} ${value[47]}"
# echo "Tx3_Bias ${value[48]} ${value[49]}"

 show_tx_bias_channel 1 42 43
 show_tx_bias_channel 2 44 45
 show_tx_bias_channel 3 46 47
 show_tx_bias_channel 4 48 49

}

show_tx_power_channel()
{
  tx_ch=$1
  msb=$2
  lsb=$3
  powerm=$(echo ${value[$msb]} | awk -F "0x" '{print $2}')
  powerl=$(echo ${value[$lsb]} | awk -F "0x" '{print $2}')
  combine=$powerm$powerl
  calculate=$((16#$combine))
  result=$(echo "scale=4;$calculate/10000" | bc)
  if [ $(echo $result | cut -c 1) = "." ]
  then
     echo -e "TX$tx_ch Power: 0"$result" mW"
  else
    echo -e "TX$tx_ch Power: "$result" mW"
  fi 
 
}

show_tx_power()
{
#  echo "Tx1 power ${value[50]} ${value[51]}"
#  echo "Tx2 power ${value[52]} ${value[53]}"
#  echo "Tx3 power ${value[54]} ${value[55]}"
#  echo "Tx4 power ${value[56]} ${value[57]}"

  show_tx_power_channel 1 50 51
  show_tx_power_channel 2 52 53
  show_tx_power_channel 3 54 55
  show_tx_power_channel 4 56 57

}


show_lower_memory()
{
 # echo '0x70 address register'
 # i2cdump -y 0 0x70
  read_eeprom 2
  show_temperature
  show_supply_voltage
  show_RX_power
  show_tx_bias
  show_tx_power
 # port=0
}

show_hex_to_ascii()
{
  title=$1
  start=$2
  end=$3
 # ${DPRINT} -n "$title "
 # for ((x=$start; x<=$end; x++))
 # do
  #  ${DPRINT} -n ${eeprom_upper_page00h[${x}]}" "
 # done
  
#  ${DPRINT}
  
  echo -n "$title "
  for ((x=$start; x<=$end; x++))
  do
    vd[x]=$(echo ${value[${x}]} | awk -F "0x" '{print $2}')

    printf "%b" "\x${vd[${x}]}"
  done
  echo
}

show_vendor_name()
{
  show_hex_to_ascii "Vendor Name:" 148 163
}

show_vendor_OUI()
{
  echo -n "Vendor OUI: "
  for ((x=165; x<=167; x++))
  do
    vd[x]=$(echo ${value[${x}]} | awk -F "0x" '{print $2}')

    echo -n ${vd[${x}]}" " | tr '[a-z]' '[A-Z]'
  done
  
  echo
}

show_vendor_PN()
{
  show_hex_to_ascii "Vendor PN:" 168 183
}

show_vendor_rev()
{
  show_hex_to_ascii "Vendor rev:" 184 185
}

show_vendor_SN()
{
  show_hex_to_ascii "Vendor SN:" 196 211
}

show_date_code()
{
  show_hex_to_ascii "Date Code:" 212 219
}

show_upper_page00h()
{
  read_eeprom 2
  show_vendor_name
  show_vendor_OUI
  show_vendor_PN
  show_vendor_rev
  show_vendor_SN
  show_date_code
}

 

show_temp_threshold()
{
  msb=$1
  lsb=$2
 
  eeprom_upper_page03h[${msb}]=$(echo ${value[${msb}]} | awk -F "0x" '{print $2}')
  eeprom_upper_page03h[${lsb}]=$(echo ${value[${lsb}]} | awk -F "0x" '{print $2}')
  shift_value=$(($((16#${eeprom_upper_page03h[${msb}]}))>>7))
  if [ $shift_value -eq 1 ]
  then
    #negative
    combine=${eeprom_upper_page03h[${msb}]}${eeprom_upper_page03h[${lsb}]}
    calculate=$(($((16#10000))-$((16#$combine))))
    result=$(echo "scale=8;$calculate/256" | bc)
    if [ $(echo $result | cut -c 1) = "." ]
    then
      echo -n " -0"$result" C";echo
    else
      echo -n " -"$result" C";echo
    fi
  else
    #positive
    combine=${eeprom_upper_page03h[${msb}]}${eeprom_upper_page03h[${lsb}]}
    calculate=$((16#$combine))
    result=$(echo "scale=8;$calculate/256" | bc)
    if [ $(echo $result | cut -c 1) = "." ]
    then
      echo -n " 0"$result" C";echo
    else
      echo -n " "$result" C";echo
    fi
  fi

}

show_Temp_High_Alarm()
{
  echo -n "Temp High Alarm:"
  show_temp_threshold 128 129
}

show_Temp_Low_Alarm()
{
  echo -n "Temp Low Alarm:"
  show_temp_threshold 130 131
}

show_Temp_High_Warning()
{
  echo -n "Temp High Warning:"
  show_temp_threshold 132 133
}

show_Temp_Low_Warning()
{
  echo -n "Temp Low Warning:"
  show_temp_threshold 134 135
}

show_temp_xz()
{
read_eeprom 3
show_Temp_High_Alarm
show_Temp_Low_Alarm
show_Temp_High_Warning
show_Temp_Low_Warning 
}


show_vcc_threshold()
{
  msb=$1
  lsb=$2
  eeprom_upper_page03h[${msb}]=$(echo ${value[${msb}]} | awk -F "0x" '{print $2}')
  eeprom_upper_page03h[${lsb}]=$(echo ${value[${lsb}]} | awk -F "0x" '{print $2}')

  combine=${eeprom_upper_page03h[${msb}]}${eeprom_upper_page03h[${lsb}]}
  calculate=$((16#$combine))
  result=$(echo "scale=4;$calculate/10000" | bc)
  echo -n " $result V";echo
}

show_Vcc_High_Alarm()
{
  echo -n "Vcc High Alarm:"
  show_vcc_threshold 134 135
}

show_Vcc_Low_Alarm()
{
  echo -n "Vcc Low Alarm:"
  show_vcc_threshold 136 137
}

show_Vcc_High_Warning()
{
  echo -n "Vcc High Warning:"
  show_vcc_threshold 148 149
}

show_Vcc_Low_Warning()
{
  echo -n "Vcc Low Warning:"
  show_vcc_threshold 150 151
}

show_vcc_xz()
{
  read_eeprom 3
  show_Vcc_High_Alarm
  show_Vcc_Low_Alarm
  show_Vcc_High_Warning
  show_Vcc_Low_Warning

}


show_rx_power_threshold()
{
  msb=$1
  lsb=$2
   eeprom_upper_page03h[${msb}]=$(echo ${value[${msb}]} | awk -F "0x" '{print $2}')
  eeprom_upper_page03h[${lsb}]=$(echo ${value[${lsb}]} | awk -F "0x" '{print $2}')

  combine=${eeprom_upper_page03h[${msb}]}${eeprom_upper_page03h[${lsb}]}
  #echo $combine
  calculate=$((16#$combine))
  result=$(echo "scale=4;$calculate/10000" | bc)
  if [ $(echo $result | cut -c 1) = "." ]
  then
    echo -n " 0$result mW";echo
  else
    echo -n " $result mW";echo
  fi
}

show_RX_Power_High_Alarm()
{
  echo -n "RX Power High Alarm:"
  show_rx_power_threshold 176 177
}

show_RX_Power_Low_Alarm()
{
  echo -n "RX Power Low Alarm:"
  show_rx_power_threshold 178 179
}

show_RX_Power_High_Warning()
{
  echo -n "RX Power High Warning:"
  show_rx_power_threshold 180 181
}

show_RX_Power_Low_Warning()
{
  echo -n "RX Power Low Warning:"
  show_rx_power_threshold 182 183
}

show_rx_power_xz()
{
read_eeprom 3
show_RX_Power_High_Alarm
show_RX_Power_Low_Alarm
show_RX_Power_High_Warning
show_RX_Power_Low_Warning
}

show_tx_bias_threshold()
{
  msb=$1
  lsb=$2
   eeprom_upper_page03h[${msb}]=$(echo ${value[${msb}]} | awk -F "0x" '{print $2}')
  eeprom_upper_page03h[${lsb}]=$(echo ${value[${lsb}]} | awk -F "0x" '{print $2}')

  combine=${eeprom_upper_page03h[${msb}]}${eeprom_upper_page03h[${lsb}]}
  #echo $combine
  calculate=$((16#$combine))
  result=$(echo "scale=3;$calculate/1000*2" | bc)
  if [ $(echo $result | cut -c 1) = "." ]
  then
    echo -n " 0"$result" mA";echo
  else
    echo -n " "$result" mA";echo
  fi
}

show_TX_Bias_High_Alarm()
{
  echo -n "TX Bias High Alarm:"
  show_tx_bias_threshold 184 185
}

show_TX_Bias_Low_Alarm()
{
  echo -n "TX Bias Low Alarm:"
  show_tx_bias_threshold 186 187
}

show_TX_Bias_High_Warning()
{
  echo -n "TX Bias High Warning:"
  show_tx_bias_threshold 188 189
}

show_TX_Bias_Low_Warning()
{
  echo -n "TX Bias Low Warning:"
  show_tx_bias_threshold 190 191
}



show_tx_power_threshold()
{
  msb=$1
  lsb=$2
    eeprom_upper_page03h[${msb}]=$(echo ${value[${msb}]} | awk -F "0x" '{print $2}')
  eeprom_upper_page03h[${lsb}]=$(echo ${value[${lsb}]} | awk -F "0x" '{print $2}')

  combine=${eeprom_upper_page03h[${msb}]}${eeprom_upper_page03h[${lsb}]}
  #echo $combine
  calculate=$((16#$combine))
  result=$(echo "scale=4;$calculate/10000" | bc)
  if [ $(echo $result | cut -c 1) = "." ]
  then
    echo -n " 0"$result" mW";echo
  else
    echo -n " "$result" mW";echo
  fi
}

show_TX_Power_High_Alarm()
{
  echo -n "TX Power High Alarm:"
  show_tx_power_threshold 192 193
}

show_TX_Power_Low_Alarm()
{
  echo -n "TX Power Low Alarm:"
  show_tx_power_threshold 194 195
}

show_TX_Power_High_Warning()
{
  echo -n "TX Power High Warning:"
  show_tx_power_threshold 196 197
}

show_TX_Power_Low_Warning()
{
  echo -n "TX Power Low Warning:"
  show_tx_power_threshold 198 199
}

show_upper_page03h()
{
  read_eeprom 3
  show_Temp_High_Alarm
  show_Temp_Low_Alarm
  show_Temp_High_Warning
  show_Temp_Low_Warning
  
  show_Vcc_High_Alarm
  show_Vcc_Low_Alarm
  show_Vcc_High_Warning
  show_Vcc_Low_Warning
  
  show_RX_Power_High_Alarm
  show_RX_Power_Low_Alarm
  show_RX_Power_High_Warning
  show_RX_Power_Low_Warning
  
  show_TX_Bias_High_Alarm
  show_TX_Bias_Low_Alarm
  show_TX_Bias_High_Warning
  show_TX_Bias_Low_Warning
  
  show_TX_Power_High_Alarm
  show_TX_Power_Low_Alarm
  show_TX_Power_High_Warning
  show_TX_Power_Low_Warning
}


port=0
#check parameter
while getopts "p:e:" arg
do
  case $arg in
  #  e)
    #  mode=$OPTARG
    #  if [ ${mode} -eq 1 ]
    #   then
     #   i2cset -f -y 0 0x70 0x0 0x01
     #   show_upper_page00h
       # show_temp_xz
       # show_vcc_xz
      
     #  show_upper_page03h
     #  fi
 #     echo "EXT_type : $EXT_type"
 #    # check_EXT_type
    #  ;;
    
    p)
      port=$OPTARG
      echo "port : $port"
if [ "${port}" = "all" ]; then
     echo -e "port all\n"
    for ((k=1;k<9;k++))
      do 
         bit=$((1<<($k-1)))   
         i2cset -f -y 0 0x70 0x0 $bit
         echo -e "Port : $k"
         show_lower_memory
         show_upper_page03h
         show_upper_page00h
      done
     for ((k=1;k<9;k++))
      do
         bit=$((1<<($k-1)))
         i2cset -f -y 0 0x71 0x0 $bit
         echo -e "Port : $(($k+8))"
         show_lower_memory
         show_upper_page03h
         show_upper_page00h
      done 
     
elif [ $port -ge 1 ] && [ $port -le 8 ]; then
     echo -e "Port "$port"\n"
      bit=$((1<<($port-1)))
      i2cset -f -y 0 0x70 0x0 $bit
      i2cset -f -y 0 0x71 0x0 0x00
       show_lower_memory
       show_upper_page03h
       show_upper_page00h
elif [ $port -ge 9 ] && [ $port -le 16 ]; then
     echo -e "Port "$port"\n"
   #  bit=$((1<<`expr $port-9`))
     bit=$((1<<($port-9)))
     i2cset -f -y 0 0x71 0x0 $bit
     i2cset -f -y 0 0x70 0x0 0x00
     show_lower_memory
     show_upper_page03h
     show_upper_page00h
  else
     echo -e  "Port is ERROR! please enter right port!/n "

  fi

      ;;

    ?)
      echo "unknown argument"
      usage
      exit 1
  esac
done











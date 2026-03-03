#!/bin/bash

set -euo pipefail

PLACEHOLDER_FILE=./placeholder/defaults/main.yml
OUTPUT_FILE=./roles/vmware/defaults/main.yml

main() {
  read -p "[*] Management IPv4 (with CIDR, ex: 10.10.10.231/24): " MANAGEMENT_IPV4_CIDR
  read -p "[*] Management Gateway IPv4 (ex: 10.10.10.254): " MANAGEMENT_GTW
  read -p "[*] Management DNS Address (default: 1.1.1.1): " MANAGEMENT_DNS
  
  if [[ -z "$MANAGEMENT_DNS" ]]; then
    echo -e "[!] Management DNS Address has been set to default."
    MANAGEMENT_DNS="1.1.1.1"
  fi
  
  read -p "[*] Workload IPv4 (with CIDR, ex: 10.10.20.231/24): " WORKLOAD_IPV4_CIDR
  read -p "[*] Workload Gateway IPv4 (ex: 10.10.20.254): " WORKLOAD_GTW
  read -p "[*] Frontend IPv4 (with CIDR, ex: 10.10.30.231/24): " FRONTEND_IPV4_CIDR
  read -p "[*] Frontend Gateway IPv4 (ex: 10.10.30.254): " FRONTEND_GTW
  read -p "[*] Frontend Virtual IP Network CIDR (ex: 10.10.30.192/28): " FRONTEND_VIP_CIDR

  MANAGEMENT_IPV4="${MANAGEMENT_IPV4_CIDR%/*}"
  WORKLOAD_IPV4="${WORKLOAD_IPV4_CIDR%/*}"
  FRONTEND_IPV4="${FRONTEND_IPV4_CIDR%/*}"
  
  # label if empty
  vars="MANAGEMENT_IPV4_CIDR MANAGEMENT_DNS MANAGEMENT_GTW WORKLOAD_IPV4_CIDR WORKLOAD_GTW FRONTEND_IPV4_CIDR FRONTEND_GTW FRONTEND_VIP_CIDR MANAGEMENT_IPV4 WORKLOAD_IPV4 FRONTEND_IPV4"
  
  echo ""
  for var in $vars; do
    if [[ -z "${!var}" ]]; then
      echo "[!] Warning: $var is empty."
      printf -v "$var" "(empty)"
    fi
  done
  
  echo ""
  echo "[!] Review your configuration below."
  echo "MANAGEMENT_IPV4_CIDR:   $MANAGEMENT_IPV4_CIDR"
  echo "MANAGEMENT_DNS:         $MANAGEMENT_DNS"
  echo "MANAGEMENT_GTW:         $MANAGEMENT_GTW"
  echo "WORKLOAD_IPV4_CIDR:     $WORKLOAD_IPV4_CIDR"
  echo "WORKLOAD_GTW:           $WORKLOAD_GTW"
  echo "FRONTEND_IPV4_CIDR:     $FRONTEND_IPV4_CIDR"
  echo "FRONTEND_GTW:           $FRONTEND_GTW"
  echo "FRONTEND_VIP_CIDR:      $FRONTEND_VIP_CIDR"
  echo "MANAGEMENT_IPV4:        $MANAGEMENT_IPV4"
  echo "WORKLOAD_IPV4:          $WORKLOAD_IPV4"
  echo "FRONTEND_IPV4:          $FRONTEND_IPV4"
  echo ""

  while true; do
    read -p "[?] Confirm configuration? (y=Yes|n=No|r=Repeat): " choice
    case "$choice" in
      y|Y ) 
        break 
        ;;
      n|N ) 
        echo "[!] Script aborted by user."
        exit 0 
        ;;
      r|R ) 
        echo -e "[!] Repeating input process...\n"
        main
        return
        ;;
      * ) echo "[!] Invalid input!" ;;
    esac
  done

  echo "[+] Writing values to $OUTPUT_FILE"
  generate_yml
  echo "[!] Done!"
}

generate_yml() {
    cp "$PLACEHOLDER_FILE" "$OUTPUT_FILE"

    sed -i "s|MANAGEMENT_IPV4_CIDR|$MANAGEMENT_IPV4_CIDR|g" "$OUTPUT_FILE"
    sed -i "s|MANAGEMENT_IPV4|$MANAGEMENT_IPV4|g" "$OUTPUT_FILE"
    sed -i "s|MANAGEMENT_DNS|$MANAGEMENT_DNS|g" "$OUTPUT_FILE"
    sed -i "s|MANAGEMENT_GTW|$MANAGEMENT_GTW|g" "$OUTPUT_FILE"
    
    sed -i "s|WORKLOAD_IPV4_CIDR|$WORKLOAD_IPV4_CIDR|g" "$OUTPUT_FILE"
    sed -i "s|WORKLOAD_IPV4|$WORKLOAD_IPV4|g" "$OUTPUT_FILE"
    sed -i "s|WORKLOAD_GTW|$WORKLOAD_GTW|g" "$OUTPUT_FILE"
    
    sed -i "s|FRONTEND_IPV4_CIDR|$FRONTEND_IPV4_CIDR|g" "$OUTPUT_FILE"
    sed -i "s|FRONTEND_IPV4|$FRONTEND_IPV4|g" "$OUTPUT_FILE"
    sed -i "s|FRONTEND_GTW|$FRONTEND_GTW|g" "$OUTPUT_FILE"
    sed -i "s|FRONTEND_VIP_CIDR|$FRONTEND_VIP_CIDR|g" "$OUTPUT_FILE"
}

main

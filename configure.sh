#!/bin/bash

set -euo pipefail

PLACEHOLDER_FILE=./placeholder/defaults/main.yml
OUTPUT_FILES=(
    "./roles/vmware/defaults/main.yml"
    "./roles/common/defaults/main.yml"
    "./roles/sysprep/defaults/main.yml"
    "./roles/certs/defaults/main.yml"
    "./roles/haproxy/defaults/main.yml"
)

main() {
  read -e -p "[*] Machine hostname (FQDN): " HOSTNAME_FQDN
  read -e -p "[*] Management IPv4 (with CIDR, ex: 192.168.1.23/24): " MANAGEMENT_IPV4_CIDR
  MANAGEMENT_IPV4="${MANAGEMENT_IPV4_CIDR%/*}"
  MANAGEMENT_GTW_TMP="${MANAGEMENT_IPV4%.*}.254"
  read -e -p "[*] Management Gateway IPv4 (default: $MANAGEMENT_GTW_TMP): " MANAGEMENT_GTW
  
  if [[ -z "$MANAGEMENT_GTW" ]]; then
    echo -e "[!] Management Gateway Address has been set to default."
    MANAGEMENT_GTW="$MANAGEMENT_GTW_TMP"
  fi

  read -e -p "[*] Management DNS Address (default: 1.1.1.1): " MANAGEMENT_DNS
  
  if [[ -z "$MANAGEMENT_DNS" ]]; then
    echo -e "[!] Management DNS Address has been set to default."
    MANAGEMENT_DNS="1.1.1.1"
  fi
  
  read -e -p "[*] Workload IPv4 (with CIDR, ex: 10.10.20.231/24): " WORKLOAD_IPV4_CIDR
  WORKLOAD_IPV4="${WORKLOAD_IPV4_CIDR%/*}"
  WORKLOAD_GTW_TMP="${WORKLOAD_IPV4%.*}.254"

  read -e -p "[*] Workload Gateway IPv4 (default: $WORKLOAD_GTW_TMP): " WORKLOAD_GTW
  
  if [[ -z "$WORKLOAD_GTW" ]]; then
    echo -e "[!] Workload Gateway Address has been set to default."
    WORKLOAD_GTW="$WORKLOAD_GTW_TMP"
  fi

  read -e -p "[*] Frontend IPv4 (with CIDR, ex: 10.10.30.231/24): " FRONTEND_IPV4_CIDR
  FRONTEND_IPV4="${FRONTEND_IPV4_CIDR%/*}"
  FRONTEND_GTW_TMP="${FRONTEND_IPV4%.*}.254"

  read -e -p "[*] Frontend Gateway IPv4 (default: $FRONTEND_GTW_TMP): " FRONTEND_GTW
  
  if [[ -z "$FRONTEND_GTW" ]]; then
    echo -e "[!] Frontend Gateway Address has been set to default."
    FRONTEND_GTW="$FRONTEND_GTW_TMP"
  fi

  read -e -p "[*] Frontend Virtual IP Network CIDR (ex: 10.10.30.192/28): " FRONTEND_VIP_CIDR

  read -e -p "[*] Set HAproxy DataplaneAPI username: " DPAPI_USERNAME
  echo "[!] You are entering password! Characters won't be displayed."
  IFS= read -rsp "[*] Set HAproxy DataplaneAPI password: " DPAPI_PASSWORD
  echo ""
  
  vars="HOSTNAME_FQDN MANAGEMENT_IPV4_CIDR MANAGEMENT_DNS MANAGEMENT_GTW WORKLOAD_IPV4_CIDR WORKLOAD_GTW FRONTEND_IPV4_CIDR FRONTEND_GTW FRONTEND_VIP_CIDR MANAGEMENT_IPV4 WORKLOAD_IPV4 FRONTEND_IPV4 DPAPI_USERNAME DPAPI_PASSWORD"
  
  echo ""
  for var in $vars; do
    if [[ -z "${!var}" ]]; then
      echo "[!] Warning: $var is empty."
      printf -v "$var" "(empty)"
    fi
  done
  
  DPAPI_PASSWORD_HASH=$(mkpasswd -m sha-256 $DPAPI_PASSWORD)

  echo ""
  echo "[!] Review your configuration below."
  echo "HOSTNAME_FQDN:          $HOSTNAME_FQDN"
  echo "MANAGEMENT_IPV4:        $MANAGEMENT_IPV4"
  echo "WORKLOAD_IPV4:          $WORKLOAD_IPV4"
  echo "FRONTEND_IPV4:          $FRONTEND_IPV4"
  echo ""
  echo "MANAGEMENT_DNS:         $MANAGEMENT_DNS"
  echo "MANAGEMENT_IPV4_CIDR:   $MANAGEMENT_IPV4_CIDR"
  echo "MANAGEMENT_GTW:         $MANAGEMENT_GTW"
  echo "WORKLOAD_IPV4_CIDR:     $WORKLOAD_IPV4_CIDR"
  echo "WORKLOAD_GTW:           $WORKLOAD_GTW"
  echo "FRONTEND_IPV4_CIDR:     $FRONTEND_IPV4_CIDR"
  echo "FRONTEND_GTW:           $FRONTEND_GTW"
  echo ""
  echo "FRONTEND_VIP_CIDR:      $FRONTEND_VIP_CIDR"
  echo ""
  echo "DATAPLANEAPI_USERNAME:  $DPAPI_USERNAME"
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

  echo "[+] Writing files..."
  generate_yml
  echo "[!] Done!"
}

generate_yml() {
  for FILE in "${OUTPUT_FILES[@]}"; do
    DIR=$(dirname "$FILE")
    mkdir -p "$DIR"
    cp "$PLACEHOLDER_FILE" "$FILE"

    sed -i "s|HOSTNAME_FQDN|$HOSTNAME_FQDN|g" "$FILE"
    sed -i "s|MANAGEMENT_IPV4_CIDR|$MANAGEMENT_IPV4_CIDR|g" "$FILE"
    sed -i "s|MANAGEMENT_IPV4|$MANAGEMENT_IPV4|g" "$FILE"
    sed -i "s|MANAGEMENT_DNS|$MANAGEMENT_DNS|g" "$FILE"
    sed -i "s|MANAGEMENT_GTW|$MANAGEMENT_GTW|g" "$FILE"
    
    sed -i "s|WORKLOAD_IPV4_CIDR|$WORKLOAD_IPV4_CIDR|g" "$FILE"
    sed -i "s|WORKLOAD_IPV4|$WORKLOAD_IPV4|g" "$FILE"
    sed -i "s|WORKLOAD_GTW|$WORKLOAD_GTW|g" "$FILE"
    
    sed -i "s|FRONTEND_IPV4_CIDR|$FRONTEND_IPV4_CIDR|g" "$FILE"
    sed -i "s|FRONTEND_IPV4|$FRONTEND_IPV4|g" "$FILE"
    sed -i "s|FRONTEND_GTW|$FRONTEND_GTW|g" "$FILE"
    sed -i "s|FRONTEND_VIP_CIDR|$FRONTEND_VIP_CIDR|g" "$FILE"

    sed -i "s|DPAPI_USERNAME|$DPAPI_USERNAME|g" "$FILE"
    sed -i "s|DPAPI_PASSWORD_HASH|$DPAPI_PASSWORD_HASH|g" "$FILE"

    echo "[!] Successfully wrote to $FILE"
  done
}

main

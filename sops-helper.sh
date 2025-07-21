#!/bin/bash
# SOPS helper script for dotenv files

# Function to encrypt dotenv files
encrypt_dotenv() {
	local input_file="$1"
	local output_file="${2:-${input_file}.enc}"

	# Use SOPS without format specification - let .sops.yaml handle it
	sops -e "$input_file" >"$output_file"
	echo "Encrypted: $input_file -> $output_file"
}

# Function to decrypt dotenv files
decrypt_dotenv() {
	local input_file="$1"
	local output_file="${2:-${input_file%.enc}}"

	# Decrypt without format specification
	sops -d "$input_file" >"$output_file"
	echo "Decrypted: $input_file -> $output_file"
}

# Main script
case "$1" in
encrypt)
	encrypt_dotenv "$2" "$3"
	;;
decrypt)
	decrypt_dotenv "$2" "$3"
	;;
*)
	echo "Usage: $0 {encrypt|decrypt} <input_file> [output_file]"
	echo "Examples:"
	echo "  $0 encrypt auth/.secrets.env"
	echo "  $0 decrypt auth/.secrets.env.enc"
	exit 1
	;;
esac
